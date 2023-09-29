using DSP

function my_butter(sig::Vector, order::Int, freq, fs, Ftype::Type{<:FilterType})
    responsetype = Ftype(freq; fs=fs)
    designmethod = Butterworth(order)
    fsig = DSP.filtfilt(digitalfilter(responsetype, designmethod), sig)

    return fsig
end

function my_butter(sig::Vector, order::Int, freq::Tuple, fs, Ftype::Type{<:FilterType} = Bandpass)
    responsetype = Ftype(freq[1], freq[2]; fs=fs)
    designmethod = Butterworth(order)
    fsig = DSP.filtfilt(digitalfilter(responsetype, designmethod), sig)

    return fsig
end

function DiffFilt(sig::Vector, Npoints::Int)
    filtered = fill(typeof(sig[1])(0), length(sig))
    for i in Npoints+1 : length(sig)
        filtered[i] = sig[i] - sig[i-Npoints]
    end

    return filtered
end

function AFC_find(order::Int, freq, fs, Ftype::Type{<:FilterType})
    # проектирвоание ФНЧ или ФВЧ
    responsetype = Ftype(freq; fs=fs)
    designmethod = Butterworth(order)
    flt = digitalfilter(responsetype, designmethod)

    # АЧХ
    h, w = freqresp(flt)
    mag = abs.(h)
    f = w.*fs./(2*pi)

    # Частота режекции
    thr = sqrt(2)/2
    f0_ind = (Ftype == Lowpass) ? findlast(x -> x >= thr, mag) : findfirst(x -> x >= thr, mag)
    f0 = round(f[f0_ind], digits = 2)

    # График
    p = plot(f, mag, label = "")
    hline!([thr], label = "sqrt(2)/2")
    vline!([f0], label = "Частота режекции: $f0 Гц")
    title!("$Ftype Butterworth, $order order, $freq Hz")

    display(p)
end

function AFC_find(order::Int, freq::Tuple, fs::Union{Int, Float64}, Ftype::Type{<:FilterType} = Bandpass)
    # Проектирование полосового фильтра
    responsetype = Ftype(freq[1], freq[2]; fs=fs)
    designmethod = Butterworth(order)
    flt = digitalfilter(responsetype, designmethod)

    # АЧХ
    h, w = freqresp(flt)
    mag = abs.(h)
    f = w.*fs./(2*pi)

    # Полоса пропускания
    thr = sqrt(2)/2
    f1, f2 = 0.0, 0.0
    s_f2 = false

    f1_ind = findfirst(x -> x >= thr, mag)
    f2_ind = findlast(x -> x >= thr, mag)
    f1, f2 = round(f[f1_ind], digits = 2), round(f[f2_ind], digits = 2)

    # График
    p = plot(f, mag, label = "")
    hline!([thr], label = "sqrt(2)/2")
    vline!([f1, f2], label = "Полоса пропускания: \n $f1 - $f2 Гц")
    title!("$Ftype Butterworth, $order order, $(freq[1]) - $(freq[2]) Hz")

    display(p)
end

function detrend(y::Vector)

    n = lastindex(y)
    x = range(1, n, step = 1) |> Vector
    mx = mean(x)
    my = mean(y)

    mx2 = mx^2
    xy = sum(x.*y)
    x2 = sum(x.^2)

    k = (xy - (n  * mx * my)) / (x2 - (n * mx2))
    b = my - k * mx

    return y.-(x.*k.+b)
end


#Функция нахождения локального максимума с заданным радиусом 
#Вход: сигнал(Signal), радиус(rad)
#Выход: массив максимумов (Massiv_max)
function new_localmax(Signal, rad)
    Massiv_max = Int64[]
    size_signal = length(Signal)
    i = 1

    while (i <= size_signal)
        max = Signal[i]
        
        for j in (i-rad):(i+rad)
            if (j >= 1 && j < size_signal && Signal[j] > max)
                max = Signal[j]
            end
        end

        if (Signal[i] == max)
            push!(Massiv_max, i)
            i = i + rad
        else
            i = i + 1
        end

    end

    return Massiv_max
end


#Функция нахождения локального минимума с заданным радиусом 
#Вход: сигнал(Signal), радиус(rad)
#Выход: массив минимумов (Massiv_min)
function new_localmin(Signal, rad)
    Massiv_min = Int64[]
    size_signal = length(Signal)
    i = 1

    while (i <= size_signal)
        min = Signal[i]
        for j in (i-rad):(i+rad)
            if (j >= 1 && j < size_signal && Signal[j] < min)
                min = Signal[j]
                #    @info j
            end
        end

        if (Signal[i] == min)
            push!(Massiv_min, i)
            i = i + rad - 1
        else
            i = i + 1
        end
    end

    return Massiv_min
end