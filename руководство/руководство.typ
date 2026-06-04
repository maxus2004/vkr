#import "../version.typ": *

#page(align(left, image("./титул_руководства.jpg", width: 100%)), margin: (left: 3cm, right: 1.5cm, top: 2cm, bottom: 2cm), footer: align(center)[#text(fill: white)[1]])

= Введение

Данное руководство предназначено для разработчиков, желающих интегрировать собственные алгоритмы управления и обработки данных с программно-аппаратной системой автопилотирования. Система предоставляет API для получения телеметрии, видеопотока и данных сенсоров, а также для отправки управляющих команд.

Для работы с системой не требуется знание внутреннего устройства микроконтроллера или одноплатного компьютера — достаточно реализовать взаимодействие с бортовой частью макета по описанным ниже интерфейсам.

= Архитектура взаимодействия

Программа запускается на сервере и взаимодействует с бортовой частью макета через два канала: UDP-поток телеметрии от макета к программе и UDP-поток управляющих команд от программы к макету. Дополнительно доступны HTTP-эндпоинт для получения состояния светофора, MJPEG-стрим видеопотока с камеры и HTTP-эндпоинт для передачи траектории.

Макет доступен по адресу \`mashina.local\` или статическому IP-адресу, выданному администратором стенда.

= UDP API телеметрии

Макет с частотой 20 Гц отправляет на порт \`5555\` бинарный пакет фиксированной структуры. Пакет начинается с маркера \`0xBB\` и завершается контрольной суммой, вычисляемой как XOR всех байт между маркером и контрольной суммой.

Пакет содержит следующие поля: маркер начала пакета (1 байт, значение \`0xBB\`), скорости четырёх моторов — переднего левого, переднего правого, заднего левого и заднего правого — в мм/с (4 значения типа \`int16\`), расстояния до четырёх UWB-меток в мм (4 значения типа \`int16\`), углы ориентации корпуса — рыскание, тангаж и крен — в градусах (3 значения типа \`float\`), массив расстояний лидара по углам от 0 до 359 градусов в мм (360 значений типа \`uint16\`, значение 0 означает отсутствие данных на данном угле), контрольная сумма (1 байт). Итоговый размер пакета составляет 746 байт.

```c
typedef struct {
    uint8_t  header;
    int16_t  speed_fl;
    int16_t  speed_fr;
    int16_t  speed_rl;
    int16_t  speed_rr;
    int16_t  uwb_dist[4];
    float    orientation_yaw;
    float    orientation_pitch;
    float    orientation_roll;
    uint16_t lidar_distances[360];
    uint8_t  checksum;
} TelemetryPacket_t;
```

Четыре UWB-метки размещены по углам макета города. Начало координат — центр макета, ось X направлена вправо, ось Y направлена вверх. Метка 0 находится в точке (-1200, -900) мм, метка 1 — в точке (1200, -900) мм, метка 2 — в точке (1200, 900) мм, метка 3 — в точке (-1200, 900) мм.

Пример приёма телеметрии на Python:

```python
import socket
import struct

TELEM_PORT = 5555
HEADER = 0xBB
PACKET_SIZE = 746

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", TELEM_PORT))

while True:
    data, addr = sock.recvfrom(PACKET_SIZE)

    if data[0] != HEADER:
        continue

    offset = 1
    speed_fl, speed_fr, speed_rl, speed_rr = struct.unpack_from("<4h", data, offset)
    offset += 8

    uwb_dist = struct.unpack_from("<4h", data, offset)
    offset += 8

    yaw, pitch, roll = struct.unpack_from("<3f", data, offset)
    offset += 12

    lidar = struct.unpack_from("<360H", data, offset)
    offset += 720

    checksum = data[offset]
```

= UDP API управления

Для отправки команд управления необходимо отправлять бинарный пакет на адрес \`mashina.local\` порт \`5555\`. Пакет начинается с маркера \`0xAA\` и содержит целевую скорость в мм/с в диапазоне от -1000 до 1000 (отрицательное значение соответствует движению назад) и угол поворота в десятых долях градуса в диапазоне от -450 до 450. Пакет завершается контрольной суммой XOR байт скорости и угла поворота.

```c
typedef struct {
    uint8_t header;
    int16_t speed;
    int16_t steer_angle;
    uint8_t checksum;
} ControlPacket_t;
```

Пример отправки управляющего пакета на Python:

```python
import socket
import struct

CAR_HOST = "mashina.local"
CTRL_PORT = 5555

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def send_control(speed_mms: int, steer_tenths: int):
    speed_bytes = struct.pack("<h", speed_mms)
    steer_bytes = struct.pack("<h", steer_tenths)
    checksum = 0
    for b in speed_bytes + steer_bytes:
        checksum ^= b
    packet = struct.pack("<BhhB", 0xAA, speed_mms, steer_tenths, checksum)
    sock.sendto(packet, (CAR_HOST, CTRL_PORT))

send_control(300, 0)    // прямо, 300 мм/с
send_control(200, 150)  // вперёд с поворотом 15° вправо
send_control(0, 0)      // остановка
send_control(-200, 0)   // назад
```

= HTTP API видеопотока

Камера OV5647 транслирует видеопоток в формате MJPEG по адресу \`http://mashina.local/video\`. Разрешение потока составляет 640×480 пикселей. Поток можно получить стандартными средствами, в частности через OpenCV.

```python
import cv2

cap = cv2.VideoCapture("http://mashina.local/video")

while True:
    ret, frame = cap.read()
    if not ret:
        break
    # frame — numpy array BGR 640x480
```

= HTTP API светофора (V2X)

Контроллер светофора предоставляет HTTP GET-эндпоинт по адресу \`http://mashina.local:8081/traffic_light\`. Ответ возвращается в формате JSON и содержит два поля: \`state\` — текущий сигнал светофора, принимающий значения \`"red"\`, \`"green"\` или \`"yellow"\`, и \`remaining_ms\` — время до смены сигнала в миллисекундах.

```python
import requests

def get_traffic_light():
    response = requests.get(
        "http://trafficlight.local/get_state",
    )
    data = response.json()
    return data["state"], data["remaining_ms"]

state, remaining = get_traffic_light()
```

= HTTP API траектории

Альтернативный способ управления автомобилем — передача заранее рассчитанной траектории в виде последовательности путевых точек. В этом случае бортовая программа на Raspberry Pi самостоятельно формирует управляющие команды для микроконтроллера по методу Pure Pursuit, а студенческая программа занимается только планированием маршрута.

Траектория передаётся HTTP POST-запросом на адрес \`http://mashina.local:8082/trajectory\` с телом в формате JSON — массивом объектов с полями \`x\` и \`y\` в мм относительно центра макета города. Ось X направлена вправо, ось Y направлена вверх. После получения траектории Raspberry Pi немедленно начинает движение по путевым точкам по порядку. Каждая новая отправленная траектория полностью заменяет предыдущую. Для остановки автомобиля достаточно отправить пустой массив.

Ответ сервера содержит поле \`status\` со значением \`"ok"\` в случае успеха или \`"error"\` с описанием ошибки в поле \`message\`.

```python
import requests

CAR_HOST = "mashina.local"

def send_path(points: list[dict]):
    response = requests.post(
        f"http://mashina.local/send_path",
        json=points,
    )
    return response.json()

def stop():
    send_path([])

send_path([
    {"x": -500, "y":  300},
    {"x": -200, "y":  300},
    {"x":    0, "y":  100},
    {"x":  300, "y":    0},
])
```

Использование API траектории предпочтительно когда задача студента — планирование маршрута. Использование UDP API управления предпочтительно когда требуется низкоуровневое управление или реализация нестандартного алгоритма движения.

= Вычисление координат по UWB

Пакет телеметрии содержит расстояния до четырёх меток. Для вычисления координат автомобиля методом трилатерации можно использовать следующую функцию:

```python
import numpy as np

ANCHORS = np.array([
    [-1200, -900],
    [ 1200, -900],
    [ 1200,  900],
    [-1200,  900],
], dtype=float)

def trilaterate(distances):
    distances = np.array(distances, dtype=float)
    valid = distances > 0
    if valid.sum() < 3:
        return None
    A = ANCHORS[valid]
    d = distances[valid]
    A_mat = 2 * (A[1:] - A[0])
    b_vec = d[0]**2 - d[1:]**2 - (A[0]**2).sum() + (A[1:]**2).sum(axis=1)
    pos, _, _, _ = np.linalg.lstsq(A_mat, b_vec, rcond=None)
    return pos[0], pos[1]
```

=  Требования к окружению

Для работы с API системы необходим Python версии 3.9 и выше со следующими библиотеками: \`numpy\` версии 1.24 и выше, \`opencv-python\` версии 4.7 и выше, \`requests\` версии 2.28 и выше.

```bash
pip install numpy opencv-python requests
```