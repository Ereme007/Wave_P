"""
вычитает из ряда x МНК-аппроксимацию 
полиномом n-1-й степени вида Pn: a1*x^0+a2*x^1+...+an*x^(n-1)
y - полученный ряд
a=[a1; a2; ...; an]
err - средняя квадратическая ошибка аппроксимации на отсчет
"""
function fit_polynomial(y::Vector{T}, p::Int) where T<:Real
    
    n = length(y)
    sum_i = zeros(T, 2*p-1)
    for k in 0:2*p-2
        for i in 1:n
            sum_i[k+1] += i^k
        end
    end

    sum_y = zeros(p)
    for k in 0:p-1
        for i in 1:n
            sum_y[k+1] += y[i]*i^k
        end
    end

    A = zeros(p,p)
    B = zeros(p)
    d = 0
    for i in 1:p
        for j in 1:p
            A[i,p+1-j] = sum_i[j+d]
        end
        d += 1
        B[i] = sum_y[i]
    end

    # too big values -> matrix is close to singular
    a = A \ B 
    a = reverse(a)

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

    return removed, a, err
end

# i = 1:100
# x = rand(1:10, 100).+ i .- .+ i.^2 ./100
# removed, a, err = fit_polynomial(x, 3)