#import "../version.typ": *

// Костыль, чтобы убрать отступы в списке использованных источников
#set bibliography(
  style: "bib.csl",
  full: нет
)
#show bibliography: it_bib => {
  set block(inset: 0pt)
  show block: it_block => {
    par(it_block.body)
  }
  it_bib
}

#страница(image("титул.pdf", height: 100%), номер: нет)
// #[
//   #pagebreak(weak: true)
//   Задание.
//   #pagebreak(weak: true)
// ]
// #[
//   #pagebreak(weak: true)
//   Календарный план.
//   #pagebreak(weak: true)
// ]

#page(align(left, image("../Задание-календарный план_0.jpg", width: 100%)), margin: (left: 3cm, right: 1.5cm, top: 2cm, bottom: 2cm), footer: align(center)[#text(fill: white)[1]])
#page(align(left, image("../Задание-календарный план_1.jpg", width: 100%)), margin: (left: 3cm, right: 1.5cm, top: 2cm, bottom: 2cm), footer: align(center)[#text(fill: white)[1]])
#page(align(left, image("../Задание-календарный план_2.jpg", width: 100%)), margin: (left: 3cm, right: 1.5cm, top: 2cm, bottom: 2cm), footer: align(center)[#text(fill: white)[1]])

#counter(page).update(4)
#include "разделы/0-аннотация.typ"
#include "разделы/1-реферат.typ"
#содержание()
// #определения_обозначения_сокращения_раздел()
#include "разделы/2-сокращения.typ"
#include "разделы/3-введение.typ"
#include "разделы/4-исследовательская.typ"
#include "разделы/5-конструкторская.typ"
#include "разделы/6-технологическая.typ"
#include "разделы/7-заключение.typ"
#bibliography("bibliography.yml")
#include "разделы/8-приложение-а.typ"
#include "разделы/9-приложение-б.typ"
#include "разделы/10-приложение-в.typ"
#include "разделы/11-приложение-г.typ"
