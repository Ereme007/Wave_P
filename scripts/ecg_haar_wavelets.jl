include("../src/detector_funcs.jl");

# складывает в конец, длина = степень двойки
function haar_fwt(
    signal::Vector{Float64}, 
    level::Int = log2(length(signal)) |> Int
)

    s = .5;                  # scaling -- try 1 or ( .5 ** .5 )
    #s = 1/sqrt(2)       # to preserve L2-norm
    h = (1.0,  1.0)           # lowpass filter
    g = (1.0, -1.0)           # highpass filter        
    f = length(h)         # length of the filter

    t = copy(signal)          # 'workspace' array
    l = length(t)           # length of the current signal
    y = zeros(eltype(s), l)             # initialise output

    t = append!(t, [0, 0])        # padding for the workspace

    for _ in 1:level

        y[1:l] .= 0.0 # initialise the next level 
        l2 = l >> 1;  # half approximation, half detail

        for j in 0:l2-1          
            for k in 1:f              
                y[j+1]    += t[2*j + k] * h[k] * s
                y[j+1+l2] += t[2*j + k] * g[k] * s
            end
        end
        l = l2  # continue with the approximation
        t[1:l] .= y[1:l]
    end
    return y
end

haar_fwt(Float64[56, 40, 8, 24, 48, 48, 40, 16])

using Plots

signals, fs, timestart, units = readbin(raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin\CSE_MA\MA1_001.bin");
t = signals.II
i0 = 10000
x = t[1:1024].|> Float64
plot(x)

log2(length(x)) |> Int

w = haar_fwt(x)
w[1:3] .= 0
plot(w)

# получаем скейлограмму из вейвлет преобразования
function fwt2map(x)
    len = length(x)
    level = log2(len) |> Int
    map = zeros(Float64, len, level)
    i0 = 0
    l = 1
    for lv = 1:level
        for i in 1:l
            k1 = 1 + (i-1) * len ÷ l |> Int
            k2 = i * len ÷ l |> Int
            #@info k1, k2, i, l
            map[k1:k2, lv] .= x[i + i0]
        end
        i0 += l
        l = l << 1
    end
    return map
end

m = fwt2map(w)
plot(m[:,end])
plot!(m[:,end-1])
plot!(m[:,end-2])
plot!(m[:,end-3])
plot!(x./5)

heatmap(m')

heatmap(m'.>0)

