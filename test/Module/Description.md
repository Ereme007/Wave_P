Описание:
Модули:
+ Module_Get_signal.jl
    - Функция получение сигнала
+ Module_Fronts.jl
    - Функция фронтов (можно изменить)
+ Module_Edge.jl
    - Функция сведение границ
+ Module_Plots.jl
    - Функция построение графиков

В файлах 93 и 107 большие погрешности


UPD:
Нужно добавить в гит
====
Upd 26.09

Добавила функцию Three рассматривается из двух фронтов правый (ошибка возрасла)
Был вылет в Defenition_Fronts || исправился ли в Three (при 130)
31 - нет
37 - нет
47 - нет
50 - нет
93 - нет
94 - нет
107 - нет
110 - да
Плохая статистика
можно изменить abs(FINAL_amp[1] - FINAL_amp[2]) < 130 на меньшее значение
===
Upd 29.09

Добавила функцию, которая сохраняет все AMP, имеет название 