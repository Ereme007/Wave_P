# из HotBox

using DSP

# + добавить парсинг аргументов из JSON для построения этого объекта
mutable struct DSPFilter{T} # <: RecalcAlg
    a::Vector{Float64} #::NTuple{N,Float64}
    b::Vector{Float64} #::NTuple{N,Float64}
    si::Vector{Float64}
    s0::Vector{Float64}
    need_restart::Bool
    function DSPFilter{T}() where {T}
        new([],[],[],[],true)
    end
end

function init(obj::DSPFilter, ftype::FilterType, coefs::FilterCoefficients)
    df = digitalfilter(ftype, coefs) |> DF2TFilter
    obj.a = coefa(df.coef)
    obj.b = coefb(df.coef)

    order = length(obj.a) - 1
    resize!(obj.s0, order);
    resize!(obj.si, order);

    _setzerostate(obj, ftype)
    return obj
end

function _setzerostate(obj::DSPFilter, ftype::Union{Lowpass, Bandstop})
    a, b, si, s0, order = obj.a, obj.b, obj.si, obj.s0, length(obj.si)

    s0[order] = b[order + 1] - a[order + 1]
    for k in order:-1:2
      s0[k - 1] = b[k] - a[k] + s0[k]
    end
end

function _setzerostate(obj::DSPFilter, ftype::Union{Highpass, Bandpass})
    a, b, si, s0, order = obj.a, obj.b, obj.si, obj.s0, length(obj.si)

    s0[order] = b[order + 1]
    for k in order:-1:2
      s0[k - 1] = b[k] + s0[k]
    end
end


function run(obj::DSPFilter{T}, y::AbstractVector{T}, x::AbstractVector{T}) where T
    a, b, si, s0 = obj.a, obj.b, obj.si, obj.s0
    order = length(si)
    if obj.need_restart
        @inbounds for k in 1:order
            si[k] = s0[k] * x[1] # был xi
        end
        obj.need_restart = false
    end

    @inbounds for i in 1:length(x)
        xi = x[i]
        yi = si[1] + b[1]*xi
        for j in 2:order
            si[j-1] = si[j] + b[j]*xi - a[j]*yi
        end
        si[order] = b[order+1]*xi - a[order+1]*yi
        if T == Int32
            y[i] = round(T,yi)
        else
            y[i] = T(yi)
        end
    end
    return obj
end

function runbackward(obj::DSPFilter{T}, y::AbstractVector{T}, x::AbstractVector{T}) where T
    a, b, si, s0 = obj.a, obj.b, obj.si, obj.s0
    order = length(si)
    if obj.need_restart
        @inbounds for k in 1:order
            si[k] = s0[k] * x[end] # был xi
        end
        obj.need_restart = false
    end

    @inbounds for i in length(x):-1:1
        xi = x[i]
        yi = si[1] + b[1]*xi
        for j in 2:order
            si[j-1] = si[j] + b[j]*xi - a[j]*yi
        end
        si[order] = b[order+1]*xi - a[order+1]*yi
        if T == Int32
            y[i] = round(T,yi)
        else
            y[i] = T(yi)
        end
    end
    obj.need_restart = true
    return obj
end

function restart(obj)
    obj.need_restart = true
end

# фильтрация сигнала стандартными фильтрами
function dspfilt(data::AbstractVector{T}, Fs::Float64, filttype::String) where T
    # расчитываем фильтр
    filterObj = _newfilter(T, Fs, filttype)
    run(filterObj, data, data)
    return data
end
# 
# пример использования bitvec2seg([false, false, true, true, false, true, false, false, false, true, true, false])
function bitvec2seg(bitvec)
    N = length(bitvec)
    seg = UnitRange{Int}[]
    ibeg = 0
    prev = false

    for i in 1:N
        curr = bitvec[i]
        if ~prev & curr
            ibeg = i
        elseif prev & ~curr
            push!(seg, ibeg : i-1)
        end
        prev = curr
    end

    if prev
        push!(seg, ibeg:N)
    end

return seg
end
# фильтрация сигнала двойным прохождением
function dspfiltfilt(data::AbstractVector{T}, Fs::Float64, filttype::String) where T
    # расчитываем фильтр
    filterObj = _newfilter(T, Fs, filttype)

    L = length(data)
    def_nonval = typemin(T) # невалидное знач по умолчанию - Теперь всегда тайпмин!
  
    out = fill(def_nonval,L) # выход флоатный всегда из фильтра

    # минимальная длина сигнала исходя из фильтра (иначе падает)
    thr_len = 1 + 3 * (max(length(filterObj.b), length(filterObj.a)) - 1)

    #сегменты ВАЛИДНОГО сигнала
    take_seg = bitvec2seg(isfinite.(data) .& (data.!=typemin(T)))

    for seg in take_seg
        chunk = view(data, seg);
        if length(chunk) >= thr_len #в фильтр подаем только достаточно длинные
           out[seg] = filtfilt(filterObj.b, filterObj.a, chunk)
           # короткие сегменты останутся невалидом
        end
    end

    if T<:Integer
        out = trunc.(T,out)
    else
        out = T.(out)
    end

    # run(filterObj, data, data)
    # restart(filterObj)
    # runbackward(filterObj, data, data)

    return out
end


function _newfilter(::Type{T}, Fs::Float64, filttype::String) where T
    filterObj = DSPFilter{T}()
    if filttype=="stimul"
        Fc = Fs/4
        init(filterObj, Lowpass(2*Fc/Fs), Butterworth(2))
    elseif filttype=="35hz"
        Fc = 35
        init(filterObj, Lowpass(2*Fc/Fs), Butterworth(2))
    elseif filttype=="50hz"
        Fc = [40,60]
        init(filterObj, Bandstop(2*Fc[1]/Fs,2*Fc[2]/Fs), Butterworth(2))
    elseif filttype=="bandpass"
        Fc = [0.1,40]
        init(filterObj, Bandpass(2*Fc[1]/Fs,2*Fc[2]/Fs), Butterworth(2))
    elseif filttype=="isoline"
        Fc = 0.1
        init(filterObj, Highpass(2*Fc/Fs), Butterworth(2))
    end
    return filterObj
end
