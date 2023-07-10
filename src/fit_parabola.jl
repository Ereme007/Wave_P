# ```
# аппроксимирует данные параболой
# версия без матричного процессора, большие формулы

# Входные параметры:
# `x`, `y` - координаты точек

# Выходные параметры:
# `x_extrema` - координата экстремума параболы
# `err` - средняя ошибка на точку
# `a` - коэффициенты при степенях 0,1,2
# ```
function fit_parabola(x::AbstractVector{Tx}, y::AbstractVector{Ty}) where {Tx<:Real, Ty<:Real}

    p = 3  # degree of the polynomial p-1 = 2
    n = length(y)  # number of points

    # find the sums at different powers of x
    sx = zeros(2*p-1,1)
    for k = 0:2*p-2
        for i = 1:n
            sx[k+1] += x[i]^k
        end
    end

    # find sums at different powers of x*y
    sy = zeros(p,1)
    for k = 0:p-1
        for i = 1:n
            sy[k+1] += y[i]*x[i]^k
        end
    end

    # read the coefficients of the parabola
    a = zeros(3)

    a[1+2] = - (-sx[2]^2*sy[3] + sx[4]*sx[2]*sy[1] + sx[3]*sx[2]*sy[2] - sx[3]^2*sy[1] - sx[1]*sx[4]*sy[2] + sx[1]*sx[3]*sy[3]) / (sx[3]^3 - 2*sx[2]*sx[4]*sx[3] - sx[1]*sx[5]*sx[3] + sx[1]*sx[4]^2 + sx[2]^2*sx[5]) # a

    a[1+1] = - (-sx[3]^2*sy[2] + sx[4]*sx[3]*sy[1] + sx[2]*sx[3]*sy[3] - sx[2]*sx[5]*sy[1] + sx[1]*sx[5]*sy[2] - sx[1]*sx[4]*sy[3]) / (sx[3]^3 - 2*sx[2]*sx[4]*sx[3] - sx[1]*sx[5]*sx[3] + sx[1]*sx[4]^2 + sx[2]^2*sx[5]) # b

    a[1+0] = - (-sx[3]^2*sy[3] + sx[5]*sx[3]*sy[1] + sx[4]*sx[3]*sy[2] - sx[4]^2*sy[1] - sx[2]*sx[5]*sy[2] + sx[2]*sx[4]*sy[3]) / (sx[3]^3 - 2*sx[2]*sx[4]*sx[3] - sx[1]*sx[5]*sx[3] + sx[1]*sx[4]^2 + sx[2]^2*sx[5]) # c

    # extrema
    x_extrema = - a[2]/(2*a[3])

    removed = similar(y)
    poly = zeros(Ty, n)
    err = zero(Ty)
    for i in 1:n
        for k in 0:p-1
            poly[i] += a[k+1]*x[i]^k
        end
        removed[i] = y[i] - poly[i]
        err += (y[i] - poly[i])^2
    end

    err = sqrt(err/n)

    plot(x, y)
    p = plot!(x, poly)
    display(p)

    return a, x_extrema, err
end

# i = 1:100
# x = rand(1:10, 100).+ i .- .+ i.^2 ./100
# a, x_extrema, err = fit_parabola(i, x)


# ```
# аппроксимирует данные параболой
# версия без матричного процессора, большие формулы

# Входные параметры:
# `y` - значения точек (`x` берется в индексах `1:length(y)`)

# Выходные параметры:
# `x_extrema` - координата экстремума параболы
# `err` - средняя ошибка на точку
# `a` - коэффициенты при степенях 0,1,2
# ```
function fit_parabola_i(y::AbstractVector{T}) where {T<:Real}

    p = 3  # degree of the polynomial p-1 = 2
    n = length(y)  # number of points

    # find the sums at different powers of x
    sx = zeros(2*p-1,1)
    for k = 0:2*p-2
        for i = 1:n
            sx[k+1] += i^k
        end
    end

    # find sums at different powers of x*y
    sy = zeros(p,1)
    for k = 0:p-1
        for i = 1:n
            sy[k+1] += y[i]*i^k
        end
    end

    # read the coefficients of the parabola
    a = zeros(T, 3)

    a[1+2] = - (-sx[2]^2*sy[3] + sx[4]*sx[2]*sy[1] + sx[3]*sx[2]*sy[2] - sx[3]^2*sy[1] - sx[1]*sx[4]*sy[2] + sx[1]*sx[3]*sy[3]) / 
        (sx[3]^3 - 2*sx[2]*sx[4]*sx[3] - sx[1]*sx[5]*sx[3] + sx[1]*sx[4]^2 + sx[2]^2*sx[5]) # a

    a[1+1] = - (-sx[3]^2*sy[2] + sx[4]*sx[3]*sy[1] + sx[2]*sx[3]*sy[3] - sx[2]*sx[5]*sy[1] + sx[1]*sx[5]*sy[2] - sx[1]*sx[4]*sy[3]) / 
        (sx[3]^3 - 2*sx[2]*sx[4]*sx[3] - sx[1]*sx[5]*sx[3] + sx[1]*sx[4]^2 + sx[2]^2*sx[5]) # b

    a[1+0] = - (-sx[3]^2*sy[3] + sx[5]*sx[3]*sy[1] + sx[4]*sx[3]*sy[2] - sx[4]^2*sy[1] - sx[2]*sx[5]*sy[2] + sx[2]*sx[4]*sy[3]) / 
        (sx[3]^3 - 2*sx[2]*sx[4]*sx[3] - sx[1]*sx[5]*sx[3] + sx[1]*sx[4]^2 + sx[2]^2*sx[5]) # c

    # находим разницу
    x_extrema = - a[2]/(2*a[3]) # оптимум

    removed = similar(y)
    poly = zeros(T, n)
    err = zero(T)
    for i in 1:n
        for k in 0:p-1
            poly[i] += a[k+1]*i^k
        end
        removed[i] = y[i] - poly[i]
        err += (y[i] - poly[i])^2
    end

    err = sqrt(err/n)

    # i = 1:n
    # plot(i, y)
    # p = plot!(i, poly)
    # display(p)

    return a, x_extrema, err
end

# i = 1:100
# x = rand(-5:5, 100).+ i .- i.^2 ./100
# a, x_extrema, err= fit_parabola_i(x)
