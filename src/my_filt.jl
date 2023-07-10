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