# тест вейвлетов как варианта расчета фронтов на разных масштабах

# https://neuropsychology.github.io/NeuroKit/_modules/neurokit2/ecg/ecg_delineate.html#ecg_delineate
function _dwt_compute_multiscales(ecg::Array{Float64,1}, max_degree::Int)
    """Return multiscales wavelet transforms."""

    function _apply_H_filter(signal_i::Array{Float64,1}, power::Int)
        zeros_arr = zeros(2^power - 1)
        timedelay = 2^power
        banks = [
            1.0 / 8;
            zeros_arr;
            3.0 / 8;
            zeros_arr;
            3.0 / 8;
            zeros_arr;
            1.0 / 8;
        ]
        # @info banks
        signal_f = conv(signal_i, banks)
        signal_f[1:end-timedelay] .= signal_f[timedelay+1:end]  # timeshift: 2 steps
        return signal_f
    end

    function _apply_G_filter(signal_i::Array{Float64,1}, power::Int)
        zeros_arr = zeros(2^power - 1)
        timedelay = 2^power
        banks = [2; zeros_arr; -2]
        # @info banks
        signal_f = conv(signal_i, banks)
        signal_f[1:end-timedelay] .= signal_f[timedelay+1:end]  # timeshift: 1 step
        return signal_f
    end

    dwtmatr = []
    intermediate_ret = copy(ecg)
    for deg in 0:max_degree-1
        S_deg = _apply_G_filter(intermediate_ret, deg)
        T_deg = _apply_H_filter(intermediate_ret, deg)
        push!(dwtmatr, S_deg)
        intermediate_ret = copy(T_deg)
    end
    dwtmatr = [arr[1:length(ecg)] for arr in dwtmatr]  # rescale transforms to the same length
    return hcat(dwtmatr...), intermediate_ret
end

# df = read_all_ref()

# row = df[1,:]
# row["File"]
# dir = raw"Y:\Yuly\ГОСТ51\bin\CTS" # биологические ЭКГ
# filelist = readdir(dir)
# allbinfiles = filter(x->endswith(lowercase(x), ".bin"), filelist)
# fn = 1
# # fn = findfirst(allbinfiles.=="CAL05000.bin")
# fname = allbinfiles[fn]
# signals, fs_raw, timestart, units = readbin(dir*"/"*fname)

# ch_num = 6
# len = round(Int, 2*fs)
# ecg = signals[ch_num][1:len]
# plot(ecg)

# max_scale = 6
# ecg_scales, residual = _dwt_compute_multiscales(ecg, max_scale)

# p0 = plot(ecg);
# ps = map(1:max_scale) do scale
#     plot(ecg_scales[:, scale]);
# end

# p1 = plot(ecg)
# p2 = plot(ecg_scales[:, 1])
# plot!(ecg_scales[:, 2])
# plot!(ecg_scales[:, 3])
# plot!(ecg_scales[:, 4])
# plot!(ecg_scales[:, 5])
# plot!(ecg_scales[:, 6])

# plot(p1, p2, layout = (2,1), link = :x, size = (800, 600))

# ## skv
# plot(ecg.-mean(ecg))
# plot!(ecg_scales[:, 1])
# plot!(ecg_scales[:, 2])
# plot!(ecg_scales[:, 3])
# plot!(ecg_scales[:, 4])
# plot!(ecg_scales[:, 5])
# plot!(ecg_scales[:, 6])
# plot!(size = (800, 600))