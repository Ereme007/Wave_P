using Plots
plotly()

include("find_fronts.jl")
include("endpoint_segmentation.jl")

# генерация сигнала нужной частоты и амплитуды
function signal_generate(F::Union{Int, Float64}, A::Union{Int, Float64}, time::Union{Int, Float64}, Fs::Union{Int, Float64})
    
    Length = time * Fs # кол-во точек всего

    w = 2*pi*F

    sig = fill(0.0, Length)

    for i in 1:Length
        t = (i-1)/Fs
        sig[i] = A*sin(w*t)
    end

    return sig
end

x = rand(-10:10, 100)

fr = find_fronts(x)
peaks = [f.pos for f in fr]

plot(x)
scatter!(peaks, x[peaks])

bnd = [4, 5]

points = segmentation(x[peaks[bnd[1]]:peaks[bnd[2]]], 0.5)

xi = peaks[bnd]
yi = x[xi]

scatter!(xi, yi)

xd = points.+xi[1].-1
yd = x[xd]

scatter!(xd, yd, markersize = 1)

point, _ = findbreakpoint(x[peaks[bnd[1]]:peaks[bnd[2]]])

xb = point+xi[1]-1
yb = x[xb]

scatter!([xb], [yb], markersize = 3)


########################################
# peaks = [f.pos for f in fr]
# scatter!(peaks, x[peaks])

# x1, x2 = peaks[16], peaks[17]
# y1, y2 = x[x1], x[x2]

# i = range(x1, x2)
# y = map(x -> (x-x1)*(y2-y1)/(x2-x1)+y1, i) # уравнение прямой, проходящей через две точки

# k = (y[2] - y[1])/(i[2]-i[1])              # k в уравнении прямой, соединяющей две точки
# b = y[1] - k*i[1]

# scatter!([x1, x2], [y1, y2])
# plot!(i, y)

# # test = map(x -> k*x+b, i)
# # plot!(test)

# # координаты точки на прямой, из которой строим перпендикуляр
# x0 = i[3]
# y0 = y[3]

# yn = map(x -> y0 - (1/k) * (x - x0), i) # перпендикуляр

# plot!(i, yn)

# yns = map(n -> )