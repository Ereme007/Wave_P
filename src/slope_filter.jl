"""
Функция вычисляет коэффициенты фильтра наклона на окне `n`,
Фильтр является аналогом производной и расчитывает в окне
МНК-оптимальный коэффициент линейной регрессии `k` (приращение на одну точку):
`y[i] --> k*x[i] + b`.

Возвращает
`b`, `a` - коэффициенты фильтра,
`gain` - коэффициент усиления,
`delay` - задержку в отсчетах.
Для единичного усиления нужно отмасштабировать: `b = b ./ gain`.
Для учета задержки: сдвинуть выход на `delay` точек влево.

C. S. Turner, "Slope filtering: An FIR approach to linear regression [DSP Tips&Tricks],"
in IEEE Signal Processing Magazine, vol. 25, no. 6, pp. 159-163, November 2008,
doi: 10.1109/MSP.2008.929816. http://www.claysturner.com/dsp/FIR_Regression.pdf

Пример:
```julia
using DSP, Plots
x = randn(500)
fs = 1000; fcut = 50; nr = 3
b, a, gain, delay = slope_filter_coef(fs, fcut, nr)
b = b ./ gain
y = DSP.filt(b, a, x)
y[1:end-delay] = y[1+delay:end] # учитываем задержку
y[end-delay+1:end] .= NaN
plot([x, y])
```
"""
function slope_filter_coef(n::Int)
    s1 = n * (n+1) ÷ 2 # sum(1:N)
    s2 = n * (n+1) * (2n+1) ÷ 6 # sum((1:N).^2)
    b = map(n:-1:1) do i
        (n*i - s1) # / (n * s2 - s1^2)
    end
    gain = (n * s2 - s1^2)
    delay = (n-1) / 2
    return b, 1, gain, delay
end

# delta в смысле производной
function slope_filter(sig, window, gaincoeff = 1)
    b, a, gain, delay = slope_filter_coef(window)
    b = b ./ gain .*gaincoeff
    y = DSP.filt(b, a, sig)
    # y[1:end-delay] = y[1+delay:end] # учитываем задержку
    # y[end-delay+1:end] .= NaN

    # by skv
    delay = round(Int, delay)
    y[1:end-delay] = y[1+delay:end] # учитываем задержку
    y[end-delay+1:end] .= y[end-delay]
    return y
end
