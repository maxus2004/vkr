#import "../../version.typ": *

#show: приложение.with(буква: "В", содержание: [ Фрагменты исходного кода компонентов])

#листинг(```
#include "pi_regulator.h"

#define KP 7.0f
#define KI 0.5f

float integral[4] = {0,0,0,0};

void pi_update(float *speeeds, float *tragets, float *pwms, float dt){
    for(int i = 0; i<4; i++){
        float error = tragets[i] - speeeds[i];

        integral[i] += error * dt;

        float output = KP * error + KI * integral[i];

        if (output > 255) {
            output = 255;
        } else if (output < -255) {
            output = -255;
        }

        pwms[i] = output;
    }
}
```)[ Фрагмент исходного кода (ПИ-регулятор) ]

#листинг(```
#include "motors.h"
#include <stm32f4xx_hal.h>

TIM_HandleTypeDef htim3, htim4;

void setup_motors(){
    // TIM3 ------

    __HAL_RCC_TIM3_CLK_ENABLE();

    htim3.Instance = TIM3;
    htim3.Init.Prescaler = 100-1; // 1MHz
    htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim3.Init.Period = 255;
    htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim3.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
    HAL_TIM_Base_Init(&htim3);

    // Configure channels with initial pulse widths
    TIM_OC_InitTypeDef sConfigOC3 = {0};
    sConfigOC3.OCMode = TIM_OCMODE_TIMING;
    sConfigOC3.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfigOC3.Pulse = 0;
    HAL_TIM_OC_ConfigChannel(&htim3, &sConfigOC3, TIM_CHANNEL_1);
    HAL_TIM_OC_ConfigChannel(&htim3, &sConfigOC3, TIM_CHANNEL_2);
    HAL_TIM_OC_ConfigChannel(&htim3, &sConfigOC3, TIM_CHANNEL_3);
    HAL_TIM_OC_ConfigChannel(&htim3, &sConfigOC3, TIM_CHANNEL_4);

    // Start channels in interrupt mode
    HAL_TIM_OC_Start_IT(&htim3, TIM_CHANNEL_1);
    HAL_TIM_OC_Start_IT(&htim3, TIM_CHANNEL_2);
    HAL_TIM_OC_Start_IT(&htim3, TIM_CHANNEL_3);
    HAL_TIM_OC_Start_IT(&htim3, TIM_CHANNEL_4);

    //enable overflow interrupt
    __HAL_TIM_ENABLE_IT(&htim3, TIM_IT_UPDATE);

    // NVIC
    HAL_NVIC_SetPriority(TIM3_IRQn, 1, 0);
    HAL_NVIC_EnableIRQ(TIM3_IRQn);

    // TIM4 ------

    __HAL_RCC_TIM4_CLK_ENABLE();

    htim4.Instance = TIM4;
    htim4.Init.Prescaler = 100-1; // 1MHz
    htim4.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim4.Init.Period = 255;
    htim4.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim4.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
    HAL_TIM_Base_Init(&htim4);

    // Configure channels with initial pulse widths
    TIM_OC_InitTypeDef sConfigOC4 = {0};
    sConfigOC4.OCMode = TIM_OCMODE_TIMING;
    sConfigOC4.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfigOC4.Pulse = 0;
    HAL_TIM_OC_ConfigChannel(&htim4, &sConfigOC4, TIM_CHANNEL_1);
    HAL_TIM_OC_ConfigChannel(&htim4, &sConfigOC4, TIM_CHANNEL_2);
    HAL_TIM_OC_ConfigChannel(&htim4, &sConfigOC4, TIM_CHANNEL_3);
    HAL_TIM_OC_ConfigChannel(&htim4, &sConfigOC4, TIM_CHANNEL_4);

    // Start channels in interrupt mode
    HAL_TIM_OC_Start_IT(&htim4, TIM_CHANNEL_1);
    HAL_TIM_OC_Start_IT(&htim4, TIM_CHANNEL_2);
    HAL_TIM_OC_Start_IT(&htim4, TIM_CHANNEL_3);
    HAL_TIM_OC_Start_IT(&htim4, TIM_CHANNEL_4);

    //enable overflow interrupt
    __HAL_TIM_ENABLE_IT(&htim4, TIM_IT_UPDATE);

    // NVIC
    HAL_NVIC_SetPriority(TIM4_IRQn, 1, 0);
    HAL_NVIC_EnableIRQ(TIM4_IRQn);
}

void TIM3_IRQHandler(void) {
    HAL_TIM_IRQHandler(&htim3);
}

void TIM4_IRQHandler(void) {
    HAL_TIM_IRQHandler(&htim4);
}

void set_motors_pwm(float fl, float fr, float bl, float br){
    if(fl>255)fl=255;
    if(fr>255)fr=255;
    if(bl>255)bl=255;
    if(br>255)br=255;
    if(fl<-255)fl=-255;
    if(fr<-255)fr=-255;
    if(bl<-255)bl=-255;
    if(br<-255)br=-255;
    if(fl>1){
        TIM4->CCR2 = 255-fl;
        TIM4->CCR1 = 255;
    }else if(fl<-1){
        TIM4->CCR2 = 255;
        TIM4->CCR1 = 255+fl;
    }else{
        TIM4->CCR2 = 1;
        TIM4->CCR1 = 1;
    }
    if(fr>1){
        TIM4->CCR4 = 255-fr;
        TIM4->CCR3 = 255;
    }else if(fr<-1){
        TIM4->CCR4 = 255;
        TIM4->CCR3 = 255+fr;
    }else{
        TIM4->CCR4 = 1;
        TIM4->CCR3 = 1;
    }
    if(fr>1){
        TIM3->CCR3 = 255-fr;
        TIM3->CCR4 = 255;
    }else if(fr<-1){
        TIM3->CCR3 = 255;
        TIM3->CCR4 = 255+fr;
    }else{
        TIM3->CCR3 = 1;
        TIM3->CCR4 = 1;
    }
    if(br>1){
        TIM3->CCR1 = 255-br;
        TIM3->CCR2 = 255;
    }else if(br<-1){
        TIM3->CCR1 = 255;
        TIM3->CCR2 = 255+br;
    }else{
        TIM3->CCR1 = 1;
        TIM3->CCR2 = 1;
    }
}
```)[ Фрагмент исходного кода (ШИМ моторов) ]

#листинг(```
TELEM_PORT = 5555
PACKET_SIZE = 746
HEADER = 0xBB

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", TELEM_PORT))


def parse_telemetry(data: bytes) -> dict | None:
    if data[0] != HEADER:
        return None
    offset = 1
    speeds = struct.unpack_from("<4h", data, offset); offset += 8
    uwb    = struct.unpack_from("<4h", data, offset); offset += 8
    imu    = struct.unpack_from("<3f", data, offset); offset += 12
    lidar  = struct.unpack_from("<360H", data, offset)
    return {
        "speeds": speeds,
        "uwb":    uwb,
        "yaw":    imu[0],
        "pitch":  imu[1],
        "roll":   imu[2],
        "lidar":  lidar,
    }

def lidar_to_pointcloud(distances: tuple) -> np.ndarray:
    """
    Преобразует массив расстояний лидара (360 значений в мм по углам 0-359°)
    в облако точек XYZ в метрах. Z = 0, так как лидар одноплоскостной.
    Точки с расстоянием 0 (нет данных) исключаются.
    """
    angles_deg = np.arange(360, dtype=float)
    angles_rad = np.deg2rad(angles_deg)
    dists_m    = np.array(distances, dtype=float) / 1000.0

    # Исключаем точки без данных и вне допустимого диапазона
    valid = (dists_m > config.data.min_range) & (dists_m < config.data.max_range)

    x = dists_m[valid] * np.cos(angles_rad[valid])
    y = dists_m[valid] * np.sin(angles_rad[valid])
    z = np.zeros(valid.sum())

    return np.column_stack([x, y, z])


while True:
    data, _ = sock.recvfrom(PACKET_SIZE)
    telem = parse_telemetry(data)
    if telem is None:
        continue

    # Преобразуем данные лидара в облако точек
    pointcloud = lidar_to_pointcloud(telem["lidar"])

    if len(pointcloud) < 10:
        # Слишком мало точек — скан пропускается
        continue

    # Передаём скан в KISS-ICP
    # register_frame возвращает матрицу позы 4x4 (SE3)
    pose = pipeline.register_frame(pointcloud)

    # Извлекаем позицию и ориентацию из матрицы позы
    x_m   = pose[0, 3]
    y_m   = pose[1, 3]
    yaw_rad = np.arctan2(pose[1, 0], pose[0, 0])
    yaw_deg = np.rad2deg(yaw_rad)

    # Переводим в мм для совместимости с остальным API
    x_mm = x_m * 1000.0
    y_mm = y_m * 1000.0

    print(f"SLAM положение: x={x_mm:.1f} мм  y={y_mm:.1f} мм  yaw={yaw_deg:.1f}°")
```)[ Фрагмент исходного кода (Lidar SLAM) ]