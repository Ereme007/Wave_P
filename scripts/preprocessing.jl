using Plots
plotly()
using DSP
using Statistics

include("../src/readfiles.jl")
include("../src/my_filt.jl")

dir = "Y:/Yuly/ГОСТ51/bin"    # указать директорию, где расположены базы
basenm = "CSE_MA"             # указать имя папки (= имя базы) с бинарными файлами базы

allfiles = readdir("$dir/$basenm")                  # все файлы папки
binfiles = map(x -> split(x, '.')[1], allfiles)     # все файлы без расширения
unique!(binfiles)                                   # только уникальные имена (т.к. бинари и хедеры называются одинаково)

# тест предобработки
for bin in binfiles[12:12]    # указать диапазон в несколько файлов, чтобы не строить сразу много графиков
    leads, fs, _, _ = readbin("$dir/$basenm/$bin")
    leadnames = keys(leads)
    for leadname in leadnames # цикл по всем отведениям записи
        sig = leads[leadname]

        # Предпочтительный вариант предобработки 
        notrend = detrend(sig)    # удаление линейного тренда
        hpass = my_butter(notrend, 2, 0.01, fs, Highpass)  # ФВЧ 0.01 Гц
        lpass = my_butter(hpass, 2, 40, fs, Lowpass)       # ФНЧ 40 Гц
        diff = DiffFilt(lpass, 5) # производная с окном 5

        p1 = plot(sig, label = "raw")
        plot!(notrend, label = "detrend")
        plot!(hpass, label = "hpass 0.01")
        plot!(lpass, linewidth = 2, label = "lpass 40")
        plot!(diff, label = "diff window = 5 points")
        title!("$bin/$leadname")

        # "Классический" вариант предобработки
        # без детренда и с частотной полосой 0.05 - 35 Гц
        hpass = my_butter(sig, 2, 0.05, fs, Highpass)
        lpass = my_butter(hpass, 2, 35, fs, Lowpass)
        diff  = DiffFilt(lpass, 1)  # производная с окном 1

        p2 = plot(sig, label = "raw")
        plot!(hpass, label = "hpass 0.05")
        plot!(lpass, linewidth = 2, label = "lpass 35")
        plot!(diff, label = "diff window = 1 point")
        
        p = plot(p1, p2, layouts = (2, 1))

        plot!(size = (1000, 800))
        display(p)
    end
end