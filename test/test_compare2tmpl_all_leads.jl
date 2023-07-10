# Сравнение участков ЭКГ с темплейтом

using Plots
# plotly() # если вызвать позволит масштабировать графики. Но не даст сохранить картинки на диск

include("../src/detector_funcs.jl");
include("../src/templates.jl");
include("../src/readfiles.jl")
include("../src/my_filt.jl")
include("../src/lynn_filter.jl")
include("../src/find_fronts.jl")

# нужную базу раскомменчиваем    
# by skv: имена баз вынесла отдельно, чтобы не пришлось вручную перебивать пути и файлы при прогоне по другой базе (не даёт использовать raw, но пока работает и без этого)
basenm = "CTS"        # синтетические ЭКГ
# basenm = "CSE_MA"       # биологические ЭКГ

dir = "Y:/Yuly/ГОСТ51/bin/$basenm" # синтетические ЭКГ

listoffiles = readdir(dir)

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)
                    
allbinfiles = allbinfiles[allbinfiles.!=nothing]

using TOML
# читаем темплейты из файла и преобразуем словарь в структуру темплейта
str = read("test/qrs_tmpl.toml", String)
dict = TOML.parse(str)
tmpl_dict = template_dict(dict)
# tmpl_2["R"] # пример шаблона

# стата по ширинам 
allelems = String[]
for name in keys(tmpl_dict)
    for p in tmpl_dict[name].points
        push!(allelems, p.name)
    end
end
unique!(allelems)

complexdist = Dict{String, Dict{String, Vector{Int64}}}()
for name in keys(tmpl_dict)

    allelems = String[]
    for p in tmpl_dict[name].points
        push!(allelems, p.name)
    end
    unique!(allelems)

    elemdist = Dict{String, Vector{Int64}}()
    for el in allelems
        elemdist[el] = Int64[]
    end

    complexdist[name] = elemdist
end

# для прогона по всем файлам расскомментить
for fn=1:lastindex(allbinfiles)
# for fn=1:3
    # fn = 126
    # fn = findfirst(allbinfiles.=="CAL20200.bin")

    fname = allbinfiles[fn]

    pos_cmpx_all = Vector{Vector{Int64}}()
    tmpl_name_all = Vector{Vector{String}}()
    dist_all = Vector{Vector{Vector{Float64}}}()
    signals_normed_all = Vector{Vector{Float64}}() 
    zc_all = Vector{Vector{Int64}}() 

    signals, fs, timestart, units = readbin(dir*"/"*fname);
    nCh = lastindex(signals)
    for ch_num = 1:nCh
        sig = signals[ch_num]
        # Предпочтительный вариант предобработки 
        notrend = detrend(sig)    # удаление линейного тренда
        hpass = my_butter(notrend, 2, 0.01, fs, Highpass)  # ФВЧ 0.01 Гц
        sig_norm = hpass./maximum(abs.(hpass))
        # filtered60 = my_butter(hpass, 2, 60, fs, Lowpass)       # ФНЧ 40 Гц
        filtered60 = lynn_filter(hpass, fs, 60, 1) # используем для параметризации
        filtered60_norm = filtered60./maximum(abs.(filtered60)) # нормировка сигнала в диап. -1 1
        filtered35 = lynn_filter(hpass, fs, 35, 1) # используем для сглаживания перед дифференцированием
        differed = DiffFilt(filtered35, 20) # производная с окном 5
        differed_norm = differed./maximum(abs.(differed))
        differed_norm = fixdelay(differed_norm, 10)
        # # заменяем маленькие значения (<0.015) на 0
        # differed_norm = set_small_to_zero(differed_norm)

        # # Предобработка СТАРАЯ. Потом изменю.
        # # убираем дрейф
        # isoline = LFfilt(sig,fs, 1, 0)
        # # вычитаем дрейф из сигнала с учетом коэфф.усиления
        # sig_iso = sig - isoline./(fs^2)
        # # убираем ВЧ 
        # filtered60 = LFfilt(sig_iso,fs, 60)
        # # производная 
        # differed_original, delay_2 = fivepointdiff(filtered60, fs)
        # # differed = fixdelay(differed, delay_2)
        # differed_original = normalize(differed_original, fs, 2 )
        # # заменяем маленькие значения (<0.15) на 0
        # differed = set_small_to_zero(differed_original)
        # # интеграл квадрата производной в скользящем окне
        sqred = differed_norm.^2
        integrated, delay_3 = movingaverage(sqred, 0.096, fs)
        integrated = fixdelay(integrated, delay_3)

        # # Поиск всех реперных точек (изменение направления интегрированного сигнала с возрастания на убывание)
        maxpos, maxrng = fndmax(integrated, 0.2, fs)

        # # Отладка 
        # plot(filtered60)
        # plot!(differed_norm)
        # plot!(integrated)
        # scatter!(maxpos, integrated[maxpos])

        # Поиск точек пересечения нуля дифференцированным сигналом
        DERFI = LFfilt(differed,fs, 40,2) # для P и T

        # проверить задержку!!
        # zerocrosses = zerocross(differed_norm)
        # zc = map(x->x.pos, zerocrosses)
        # fr = find_fronts(differed_norm, 20*5, 0.015)
        # zc = [f.ibeg for f in fr]
        fr = find_fronts(differed_norm, 75, 0.015)
        zc = zcposcorrect(filtered60_norm, fr, 20)
        push!(zc_all, zc)
        push!(signals_normed_all,filtered60_norm) # для графика
        
        # отладка
        # plot(filtered60_norm)
        # plot!(differed_norm)
        # scatter!(zc,filtered60_norm[zc])
        # scatter!(maxpos, integrated[maxpos])

        L = lastindex(zc) 
        tmpl_lvl = Dict() # для сохранения результатов сравнения
        for tmpl_name in keys(tmpl_dict)
        tmpl_lvl[tmpl_name] = [0.0]
        end
        for i=2:L
            # tmpl_name="QS"
            # i=66
            for tmpl_name in keys(tmpl_dict)
                # сравниваем с темплейтом
                similarity , ampl_vec, dist_vec = compare2template(tmpl_dict[tmpl_name].points, zc, i, filtered60_norm, differed, fs)
                push!(tmpl_lvl[tmpl_name],similarity)
            end  
        end

        # выбираем приоритетные темплейты
        pos_cmpx, tmpl_name, dist = select_template2(tmpl_lvl, tmpl_dict, zc,integrated, fs)

        # добавляем стату по ширинам (# ПОКА НЕ РАБОТАЕТ В СЛУЧАЯХ, КОГДА ТЕМПЛЕЙТ НЕ ВЫБРАН)
        # complexdist = try getdiststata(pos_cmpx, tmpl_name, tmpl_dict, zc, complexdist) catch e complexdist end

        # собираем для графика
        push!(pos_cmpx_all,pos_cmpx)
        push!(tmpl_name_all, tmpl_name)
        push!(dist_all, dist)
       
    end
    
    # построение графика уровня совпадения с темплейтом
    plts = Vector()
    shift = 0
    ch=1
    plot(signals_normed_all[ch].+shift,label=string(ch),title = "$fname")
    push!(plts,scatter!(zc_all[ch], signals_normed_all[ch][zc_all[ch]].+shift,label="",mc="red",ms=2))
    tmpl_name_all[ch]
    annotations = map((x,y) -> "$x \ndist $y", tmpl_name_all[ch], dist_all[ch])
    push!(plts,scatter!(pos_cmpx_all[ch], signals_normed_all[ch][pos_cmpx_all[ch]].+shift.+0.5,series_annotations=annotations,ms=0.01,label=""))
    push!(plts,scatter!(pos_cmpx_all[ch], signals_normed_all[ch][pos_cmpx_all[ch]].+shift,mc="green",ms=4,label=""))
    for ch = 2:nCh
        shift -= 1.5
        push!(plts,plot!(signals_normed_all[ch].+shift,label=string(ch)))
        if ~isnothing(zc_all[ch])
            push!(plts,scatter!(zc_all[ch], signals_normed_all[ch][zc_all[ch]].+shift,label="",mc="red",ms=2))
            # текст с темплейтом 
            annotations = map((x,y) -> "$x \ndist $y", tmpl_name_all[ch], dist_all[ch])
            push!(plts,scatter!(pos_cmpx_all[ch], signals_normed_all[ch][pos_cmpx_all[ch]].+shift.+0.5,series_annotations=annotations,ms=0.01,label=""))
            push!(plts,scatter!(pos_cmpx_all[ch], signals_normed_all[ch][pos_cmpx_all[ch]].+shift,mc="green",ms=4,label=""))
        end
    end
    
    # plot(plts[end], size = (500, 800),xlim=(0,2000))
    plot(plts[end], size = (1000, 1000),xlim=(0,1000))
    # сохранить на диск
    # не работает с запущенным plotly()
    mkpath("pics/tmpl/!all_leads")  # by skv: создаёи путь (если ещё не существует), чтобы не выдавало ошибку при первом прогоне, когда пути ещё не существует 
    savefig("pics/tmpl/!all_leads/$(basenm)_$(fname[1:end-4])_all.png")

    println(allbinfiles[fn])
end

# оценка статы по ширинам
histogram(complexdist["QRS"]["R"]./fs, label = "QRS")
histogram(complexdist["QR"]["R"]./fs, label = "QR")
histogram(complexdist["RS"]["R"]./fs, label = "RS")
histogram(complexdist["R"]["R"]./fs, label = "R")
histogram(vcat(complexdist["RSR2"]["R"], complexdist["RSR2"]["R2"])./fs, label = "RSR2")

histogram(complexdist["QRS"]["Q"]./fs, label = "QRS")
histogram(complexdist["Q"]["Q"]./fs, label = "QS")
histogram(complexdist["QR"]["Q"]./fs, label = "QR")

histogram(complexdist["RSR2"]["S"]./fs, label = "RSR2")
histogram(complexdist["RS"]["S"]./fs, label = "RS")
histogram(complexdist["QRS"]["S"]./fs, label = "QRS")