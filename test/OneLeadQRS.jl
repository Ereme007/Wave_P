# Прогон по одному файлу или одному отведению

include("../src/templates.jl")
include("../src/my_filt.jl")
include("../src/lynn_filter.jl")
include("../src/find_fronts.jl")
include("../src/detector_funcs.jl")

include("../src/slope_filter.jl")
include("../test/wavelets.jl")

include("../src/dounds_clarificate_alg.jl")

# Поиск по интегралу квадрата произвордной областей для поиска QRS
function getsearchbounds(differed_norm::Vector{Float64}, thr)
    sqred = differed_norm.^2
    integrated, delay_3 = movingaverage(sqred, 0.096, fs)
    integrated = fixdelay(integrated, delay_3)
    integrated = integrated .>= thr

    return integrated
end

# Предобработка для QRS
function preprocess(sig::Vector{Float64}, fs)
    hpass = my_butter(sig, 2, 2, fs, Highpass)              # ФВЧ 0.01 Гц
    filtered60 = lynn_filter(hpass, fs, 50, 1)              # используем для параметризации
    filtered60_norm = filtered60./maximum(abs.(filtered60)) # нормировка сигнала в диап. -1 1
    filtered35 = lynn_filter(hpass, fs, 35, 1)              # используем для сглаживания перед дифференцированием
    differed = DiffFilt(filtered35, 20)                     # производная с окном 5
    # differed = slope_filter(filtered35, 20, 3)
    differed_norm = differed./maximum(abs.(differed))
    differed_norm = fixdelay(differed_norm, 10)

    return filtered60_norm, differed_norm
end

# выбор приоритетного темплейта
function find_template(zc::Vector{Int}, tmpl_dict, filtered60_norm::Vector{Float64}, differed_norm::Vector{Float64}, integrated::AbstractVector{Bool}, fs)
    L = lastindex(zc)
    tmpl_lvl = Dict{String, Vector{Float64}}() # для сохранения результатов сравнения
    tmpl_bounds = Dict{String, Vector{NamedTuple{(:left, :right), Tuple{Int64, Int64}}}}()

    for tmpl_name in keys(tmpl_dict)
    tmpl_lvl[tmpl_name] = [0.0]
    tmpl_bounds[tmpl_name] = [(left = 0, right = 0)]
    end
    for i=2:L
        # tmpl_name="qRS"
        # i=66
        for tmpl_name in keys(tmpl_dict)
            # сравниваем с темплейтом
            similarity , bounds = compare2template(tmpl_dict[tmpl_name].points, zc, i, filtered60_norm, differed_norm, fs)
            # println("SIM = $similarity \n __________________")
            push!(tmpl_lvl[tmpl_name],similarity)
            push!(tmpl_bounds[tmpl_name],bounds)
        end
    end

    # выбираем приоритетные темплейты
    pos_cmpx, tmpl_name, bounds_tmpl = select_template2(tmpl_lvl, tmpl_bounds, tmpl_dict, zc, integrated, fs)

    # формирование из границ наборов для изображения на графиках !!!!! УБРАТЬ ЭТОТ КОСТЫЛЬ И ПИСАТЬ ИЗНАЧАЛЬНО В ВЕКТОРА, А НЕ В ИМЕНОВАННЫЕ КОРТЕЖИ
    bounds_x = fill([0, 0], lastindex(bounds_tmpl))
    for i in 1:lastindex(bounds_tmpl)
        l, r = bounds_tmpl[i][1]
        bounds_x[i] = [l, r]
    end

    return pos_cmpx, tmpl_name, bounds_x, tmpl_lvl
end

function find_clear_bounds(filtered60_norm::Vector{Float64}, bounds_x::Vector{Vector{Int}})
    err50 = fit_line(filtered60_norm, 50)
    err80 = fit_line(filtered60_norm, 80)

    bounds_clr = fill(Int[], lastindex(bounds_x))
    for i in 1:lastindex(bounds_x)
        left, right = bounds_x[i]
        left_clr, _, _ = clarificate_bound(filtered60_norm, left, 50, err50, 50, 'l')
        right_clr, _, _ = clarificate_bound(filtered60_norm, right, 80, err80, 80, 'r')
        bounds_clr[i] = [left_clr, right_clr]
    end

    return bounds_clr
end

function findQRSbounds(filtered60_norm::Vector{Float64}, differed_norm::Vector{Float64}, integrated::AbstractVector{Bool}, fs, tmpl_dict)
    # поиск всех фронтов по дифференцированному сигналу
    fr = find_fronts(differed_norm, 0.015)
    # zc0 = [f.ibeg for f in fr] # для отладки

    # "надевание" точек перегиба дифференциала на нужный сигнал (поиск действительных пиков) + разделение и/или слияние фронтов
    zc = zcposcorrect(filtered60_norm, fr, 20, 50)

    pos_cmpx, tmpl_name, bounds, tmpl_lvl = find_template(zc, tmpl_dict, filtered60_norm, differed_norm, integrated, fs)

    # уточняем границы
    bounds_x = find_clear_bounds(filtered60_norm, bounds)

    return filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x, tmpl_lvl
end

# QRS по одному отведению
function OneLeadQRS(sig::Vector, fs::Float64, tmpl_dict)

    if length(unique(sig)) <= 1 # Чтобы не обрабатывать пустой канал
        return Float64[], Int64[], Int64[], String[], Int[], Float64[], Float64[]
    end

    filtered60_norm, differed_norm = preprocess(sig, fs)

    integrated = getsearchbounds(differed_norm, 0.05)

    filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x, tmpl_lvl = findQRSbounds(filtered60_norm, differed_norm, integrated, fs, tmpl_dict)

    return filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x, integrated, tmpl_lvl
end

# QRS по одному файлу
function OneFileQRS(signals, fs, tmpl_dict)
    filtered60_norm = fill(Float64[], 12)
    zc = fill(Int[], 12)
    pos_cmpx = fill(Int[], 12)
    tmpl_name = fill(String[], 12)
    bounds_x = fill(Vector{Int}[], 12)

    for ch_num in 1:12
        sig = signals[ch_num]
        filtered60_norm[ch_num], zc[ch_num], pos_cmpx[ch_num], tmpl_name[ch_num], bounds_x[ch_num], _, _ = OneLeadQRS(sig, fs, tmpl_dict) # Получаем код, краницы и инфу для графиков
    end

    return filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x
end

# Все алгоритмы по одному файлу
function OneFileBounds(signals, fs, tmpl_dict)
    # Получение границ QRS по каждому отведению
    filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x = OneFileQRS(signals, fs, tmpl_dict)

    

    # Сведение границ QRS по всем отведениеям
    # Определение границ поиска P и T
    # Поиск границ P и T

    return filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x
end

# Получаем статистику по отклонению от реф. границ
function GetStata(testbounds, refrow, leadnames) # Пока исходим из того, что разметка есть только для первого комплекса => с ним и сравниваем
    refOnset = try refrow.QrsOn[1] catch e refrow[:,"Qrs-Onset"][1] end
    refOfset = try refrow.QrsOff[1] catch e refrow[:,"Qrs-End"][1] end
    refQRSdur = try refrow.QRS[1] catch e refrow[:,"QRS-duration"][1] end
    stata = Dict{String, Dict{String, Float64}}()
    for i in 1:lastindex(testbounds)        # По каждому отведению
        dOnset, dOfset, dDur = 0, 0, 0
        j = 1                               # По первому комплексу
        if !isempty(testbounds[i])
            dOnset = refOnset - testbounds[i][j][1]
            dOfset = refOfset - testbounds[i][j][2]
            dDur = refQRSdur - (testbounds[i][j][2] - testbounds[i][j][1])
        end
        stata["$(leadnames[i])"] = Dict("dOn" => dOnset, "dOff" => dOfset, "dDur" => dDur)
    end

    return stata
end
