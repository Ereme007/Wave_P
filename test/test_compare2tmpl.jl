# Скрипт для работы по одному каналу или одному файлу
# Сравнение участков ЭКГ с темплейтом

using Plots, CSV
#plotly() # если вызвать позволит масштабировать графики. Но не даст сохранить картинки на диск

include("../src/readfiles.jl");
include("OneLeadQRS.jl");

# нужную базу раскомменчиваем
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS" # синтетические ЭКГ
# dir = raw"Y:\Yuly\ГОСТ51\bin\CSE_MA" # биологические ЭКГ
          
allbinfiles = getfileslist(dir)                     # Читаем все имена файлов базы
tmpl_dict = gettemplates("test/qrs_tmpl.toml")      # Получаем словарь темплейтов # tmpl_2["R"] # пример шаблона

# ВАЖНО изменить путь в зависимости от обрабатываемой базы
ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv")
# ref = read_all_ref("Y:/Yuly/ГОСТ51/CSE/ref.csv")

fn = 4  # Номер файла
# fn = findfirst(allbinfiles.=="CAL05000.bin")

fname = allbinfiles[fn] # Имя файла

signals, fs, timestart, units = readbin(dir*"/"*fname); # Зачитываем файл
ch_names = keys(signals)

# # СЦЕНАРИЙ 1: РАБОТА ПО ОДНОМУ КАНАЛУ
ch_num = 1  # Номер канала
sig = signals[ch_num]                                   # Берём один канал

 filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x = OneLeadQRS(sig, fs) # Получаем код, границы и инфу для графиков
zc
 # Пример построения графика по одному каналу
# if !isempty(filtered60_norm) # Если канал не был пустым
#     plot(filtered60_norm)
#     scatter!(zc,filtered60_norm[zc])
#     scatter!(pos_cmpx, filtered60_norm[pos_cmpx],mc="green",ms=4,label="")
#     scatter!(pos_cmpx, filtered60_norm[pos_cmpx].+0.5,series_annotations=tmpl_name, ms=0.01)
#     vline!(bounds_x, legend = false)
# end
# plot!(xlim=(2000,3000))

# # СЦЕНАРИЙ 2: РАБОТА ПО ВСЕМ КАНАЛАМ ОДНОГО ФАЙЛА
fname_ref = fname[1:2] == "MA" ? "MO"*fname[3:end] : fname 
refrow = ref[ref.File .== fname_ref, :] 

# bounds = OneFileBounds(signals, refrow, true)

# СЦЕНАРИЙ 3: РАБОТА ПО ВСЕМ ФАЙЛАМ
function run_all_files(dir::String, allbinfiles, ref::DataFrame, plot::Bool = true)
    stata = Dict{String, Dict{String, Dict{String, Float64}}}() # Сбор статистики
    for fname in allbinfiles[1:10]
        signals, fs, timestart, units = readbin(dir*"/"*fname); # Зачитываем файл
        ch_names = keys(signals)
        fname_ref = fname[1:2] == "MA" ? "MO"*fname[3:end] : fname 
        refrow = ref[ref.File .== fname_ref, :]
        bounds = OneFileBounds(signals, refrow, plot, fname)
        stata[fname] =  GetStata(bounds, refrow, ch_names)
        @info "$fname is done" # так спокойнее наблюдать за долгим процессом обработки (:
    end

    return stata
end

stata = run_all_files(dir, allbinfiles, ref, false)

# Разворачиваем статистику в датафрейм, чтобы сохранить в таблицу
# ПОКА СОХРАНЯЕМ СТАТУ ТОЛЬКО ДЛЯ ОДНОГО КОМПЛЕКСА, Т.К. НЕЗАЧЕМ ДУБЛИРОВАТЬ ИНФУ
stata_predf = Dict{String, Any}()
stata_predf["Filename"] = String[]
stata_predf["Leadname"] = String[]
stata_predf["QrsOnset Error"] = Float64[]
stata_predf["QrsOfset Error"] = Float64[]
stata_predf["QrsDuration Error"] = Float64[]

for fname in allbinfiles
    isfirstlead = true
    for leadsymb in ch_names
        leadname = "$leadsymb"
        filename = isfirstlead ? fname : ""
        push!(stata_predf["Filename"], filename)
        push!(stata_predf["Leadname"], leadname)
        push!(stata_predf["QrsOnset Error"], stata[fname][leadname]["dOn"])
        push!(stata_predf["QrsOfset Error"], stata[fname][leadname]["dOff"])
        push!(stata_predf["QrsDuration Error"], stata[fname][leadname]["dDur"])
        isfirstlead = false
    end
end

stata_df = DataFrame(stata_predf)
CSV.write("stata1.csv", stata_df, delim = ';')