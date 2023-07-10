"""
Функция вычисляет фильтр Лина для заданной
частоты дискретизации `fs`,
частоты среза (нуля) `fcut`,
номера фильтра (из статьи) `nr`

Возвращает
`b`, `a` - коэффициенты фильтра,
`gain` - коэффициент усиления,
`delay` - задержку в отсчетах.
Для единичного усиления нужно отмасштабировать: `b = b ./ gain`.
Для учета задержки: сдвинуть выход на `delay` точек влево.

Lynn, P.A. Recursive digital filters for biological signals.
Med. & biol. Engng. 9, 37–43 (1971). https://doi.org/10.1007/BF02474403

Пример:
```julia
using DSP, Plots
x = randn(500)
fs = 1000; fcut = 50; nr = 3
b, a, gain, delay = lynn_filter_coef(fs, fcut, nr)
b = b ./ gain
y = DSP.filt(b, a, x)
y[1:end-delay] = y[1+delay:end] # учитываем задержку
y[end-delay+1:end] .= NaN
plot([x, y])
```
"""
function lynn_filter_coef(fs, fcut, nr = 2)

    if nr == 1
        k = round(Int, (fs/fcut - 1)/2)
        a = [1, -1]
        b = zeros(1 + 2*k+1)
        b[1] = 1
        b[1 + 2*k+1] = -1
        gain = (2*k + 1)
        delay = k

    elseif nr == 2
        k = round(Int, fs/fcut - 1)
        a = [1, -2, 1]
        b = zeros(1 + 2*k+2)
        b[1] = 1
        b[1 + k+1] = -2
        b[1 + 2*k+2] = 1
        gain = (k+1)^2
        delay = k

    elseif nr == 3
        k = round(Int, (fs/fcut - 1)/2)
        a = [1, -3, 3, -1]
        b = zeros(1 + 6*k+3)
        b[1] = 1
        b[1 + 2*k+1] = -3
        b[1 + 4*k+2] = 3
        b[1 + 6*k+3] = -1
        gain = (2*k+1)^3
        delay = k*3

    elseif nr == 4
        k = round(Int, fs/fcut - 1)
        a = [1, -4, 6, -4, 1]
        b = zeros(1 + 6*k+4) # by skv: эту строку подставила по примеру меньших порядков, мб неправильно
        b[1] = 1
        b[1 + k+1] = -4
        b[1 + 2*k+2] = 6
        b[1 + 3*k+3] = -4
        b[1 + 4*k+4] = 1
        gain = (k+1)^4
        delay = k*2

    else
        error("invalid nr!")
    end

    return b, a, gain, delay
end

# by skv
function lynn_filter(sig, fs, fcut, nr)
    b, a, gain, delay = lynn_filter_coef(fs, fcut, nr)
    b = b ./ gain
    y = DSP.filt(b, a, sig)
    # y[1:end-delay] = y[1+delay:end] # учитываем задержку
    # y[end-delay+1:end] .= NaN

    # by skv
    y[1:end-delay] = y[1+delay:end] # учитываем задержку
    y[end-delay+1:end] .= y[end-delay]
    return y
end
