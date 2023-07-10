using Plots
plotly()

include("../src/readfiles.jl");
include("../src/plots.jl");
include("OneLeadQRS.jl");
include("../src/plots.jl");

# Переделать ран по всем файлам с учётом всех изменений и вывести концы наружу
# function run_all_files(dir::String, allbinfiles::Vector{String}, ref::DataFrame, plot::Bool = true)
#     stata = Dict{String, Dict{String, Dict{String, Float64}}}() # Сбор статистики
#     for fname in allbinfiles[1:10]
#         signals, fs, _, _ = readbin(dir*"/"*fname); # Зачитываем файл
#         ch_names = keys(signals)
#         fname_ref = fname[1:2] == "MA" ? "MO"*fname[3:end] : fname 
#         refrow = ref[ref.File .== fname_ref, :]
#         bounds = OneFileBounds(signals, refrow, plot, fname)
#         stata[fname] =  GetStata(bounds, refrow, ch_names)
#         @info "$fname is done" # так спокойнее наблюдать за долгим процессом обработки (:
#     end

#     return stata
# end

# 1. Функция чтения списка файлов
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS" # синтетические ЭКГ
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)   # Читаем все имена файлов базы

# ***Полученние имени файла по номеру
n = 14
fn = allbinfiles[n]

# 2. Функция чтения сигнала одной записи (12 каналов)
signals, fs, _, _ = readbin("$dir/$(fn)") # Зачитываем файл
ch_names = keys(signals)
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS"
# 3. Функция чтения референотной разметки (сведённых позиций границ)
ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv")
ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv")
fn_ref = fn[1:2] == "MA" ? "MO"*fn[3:end] : fn
refrow = ref[ref.File .== fn_ref, :] 

## ??? Функция чтения темплейтов для алгоритма QRS
tmpl_dict = gettemplates("test/qrs_tmpl.toml")

# 4. Функция построения на графике всех каналов с реф. разметкой
show_record(14)

# 5. Функция обработки одной записи
filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x = OneFileBounds(signals, fs, tmpl_dict) # Вывести информацию для графиков наружу + добавить функцию построения/сохранения

# 5.0 Функции построения графиков по всему файлу
p = show_file_qrs_bounds(filtered60_norm, bounds_x, zc, pos_cmpx, tmpl_name, refrow)

#     5.1 Функция обаботки одного канала (QRS)
sig = signals[1]
filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x, integrated, tmpl_lvl = OneLeadQRS(sig, fs, tmpl_dict) # Получаем код, границы и инфу для графиков

# 5.1.1 Функции пострения графиков для QRS по одному каналу
p = show_lead_bounds(filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x, refrow)
p = show_lead_templates(filtered60_norm, integrated, zc, pos_cmpx, tmpl_lvl, tmpl_name)

#... Детализация алгоритма (по одному отведению)
#     5.0 Первичный детектор R (области поиска QRS)
filtered60_norm, differed_norm = preprocess(sig, fs)     # Предобработка
integrated = getsearchbounds(differed_norm, 0.05)        # Поиск областей обнаружения QRS
fr = find_fronts(differed_norm, 0.015)                   # Поиск фронтов по дифференцированному сигналу
zc = zcposcorrect(filtered60_norm, fr, 20, 50)           # Уточнение позиций пиков по фильтрованному сигналу
pos_cmpx, tmpl_name, bounds = find_template(zc, tmpl_dict, filtered60_norm, differed_norm, integrated, fs) # Поиск приоритетного темплейта и грубых границ
bounds_clr = find_clear_bounds(filtered60_norm, bounds_x) # Уточнение границ

plot(integrated)

# ...

#     5.2 Функция сведения границ QRS
# 
#     5.3 Функция определения областей поиска P по сведённым границам QRS

#     5.4 Функция определения областей поиска T по сведённым границам QRS
# 
#     5.5 Функция обаботки одного канала (P)
#     5.6 Функция обаботки одного канала (T)
# 
#     5.7 Функция сведения границ P
#     5.8 Функция сведения границ T
# 6. Сравнение референтной и тестовой разметки по одной записи
stata =  GetStata(bounds_x, refrow, ch_names)
# 7. Функция обработки всех файлов и объединения результатов
# stata = run_all_files(dir, allbinfiles, ref, false)



exe = raw"Y:\#KTAuto\microbox\microbox.exe"
file = raw"Y:\Yuly\ГОСТ51\bin\CSE_MA\MA1_001"
cmd = `$exe $file $file Settings StartupConfig_debug.toml`
run(cmd)


###
