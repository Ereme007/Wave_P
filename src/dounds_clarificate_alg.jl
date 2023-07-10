# Алгоритмы уточнения границ

include("../src/fit_polynomial.jl")
include("../src/fit_parabola.jl")

# Поиск шумовой подставки - ищем сренее в симметричном относительно точки окне 2*r и обновляем значение, только если оно меньше предыдущего
# !!!Не учитывает ширину подставки
function noisestang(sig::Vector, r::Int)
    len = lastindex(sig)
    noise = fill(typeof(sig[1])(0), len)
    noiseLvl = mean(sig[1:r])
    for i in 1:len
        if i > r && i <= len - r
            m = mean(sig[i-r:i+r])
            noiseLvl = m < noiseLvl ? m : noiseLvl
        end
        noise[i] = noiseLvl
    end

    return noise
end

# Лмнейная аппроксимация (возвращает к-ты a и b для уравнения аппроксимирующей прямой y = ax + b)
function linearapprox_coeffs(x::Vector, y::Vector)

    sumx = sum(x)
    sumy = sum(y)
    sumx2 = sum(x.^2)
    sumxy = sum(x.*y)
    n = lastindex(x)

    a = (n*sumxy - sumx*sumy)/(n*sumx2 - sumx^2)
    b = (sumy - a*sumx)/n

    # aprx = a.*x.+b

    return a, b
end

# Линейная аппроксимация в скользящем окне и расчёт средней (для окна) ошибки
function fit_line(sig::Vector, r::Int)

    x = range(1, r) |> Vector{Int}
    error = fill(0.0, lastindex(sig))

    # ??? Скользящее окно должно быть симметричным или справа от точки приложения аппроксимации?
    for i in 1 : lastindex(sig) - r + 1
        y = sig[i:i+r-1]
        a, b = linearapprox_coeffs(x, y)
        approxline = a.*x.+b

        error[i] = sqrt(sum((approxline.-y).^2) / r)
    end

    return error
end

# Аппроксимация параболой в скользящем окне
function fit_parabol(sig::Vector, r::Int)

    x = 1:length(sig)
    error = fill(0.0, lastindex(sig))

    for i in 1 : lastindex(sig) - r + 1
        y = sig[i:i+r-1]
        _, _, error[i] = fit_parabola_i(y)
    end

    return error
end

# Ищем участок с наименьше ошибкой аппроксимации прямой и точку его пересечения сигналом
function clarificate_bound(sig::Vector, peak_pos::Int, r::Int, err::Vector, r_aprox::Int, side = 'r')

    if side == 'l'
        # Ищем границу слева (по участку изолинии до пика)
        start = maximum([1, peak_pos - r ])
        aprox_start_pos = start + findmin(err[start:peak_pos])[2] - 1 # индекс минимума ошибки аппроксимации
        stop = minimum([lastindex(sig), aprox_start_pos+r_aprox-1])
        x = range(aprox_start_pos, stop) |> Vector{Int64}
        a, b = linearapprox_coeffs(x, sig[aprox_start_pos:stop])
        bound = peak_pos
        for i in peak_pos-1:-1:maximum([peak_pos-r, 1])
            if (sig[i] < a*i+b && sig[i+1] >= a*i+b) || (sig[i] > a*i+b && sig[i+1] <= a*i+b)
                bound = i
                break
            end
        end
    elseif side == 'r'
        # Ищем границу справа (по участку изолинии после пика)
        stop = minimum([lastindex(err), peak_pos+r])
        aprox_start_pos = peak_pos + findmin(err[peak_pos:stop])[2] - 1 # индекс минимума ошибки аппроксимации
        stop = minimum([lastindex(sig), aprox_start_pos+r_aprox-1])
        x = range(aprox_start_pos, stop) |> Vector{Int64}
        a, b = linearapprox_coeffs(x, sig[aprox_start_pos:stop])
        bound = peak_pos
        for i in peak_pos+1:minimum([peak_pos+r, lastindex(sig)])
            if (sig[i] < a*i+b && sig[i-1] >=a*i+b) || (sig[i] > a*i+b && sig[i-1] <=a*i+b)
                bound = i
                break
            end
        end
    end

    x = x
    aprox = a.*x.+b

    return bound, x, aprox
end