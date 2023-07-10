using Plots, StructArrays, Tables#, PlotlyBase, PlotlyKaleido
#для толго чтобы видеть координаты на графиках
plotly()
include("Function_P.jl")
include("../src/readfiles.jl");
include("../src/plots.jl");
include("OneLeadQRS.jl");
include("../src/find_localmin.jl")

# 2. Функция чтения списка файлов
#dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS" # синтетические ЭКГ
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)   # Читаем все имена файлов базы

#Полученние имени файла по номеру (CTS вроде только с 4го, так как первые три нет реф разметок **ANE не определены)
n = 2
fn = allbinfiles[n]


# 2. Функция чтения сигнала одной записи (12 каналов)
signals, fs, _, _ = readbin("$dir/$(fn)") # Зачитываем файл
ch_names = keys(signals) #наименования каналов

# 3. Функция чтения референотной разметки (сведённых позиций границ) 
#выбираем одну из 2-х баз
#ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv") #CTS
ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv")  #CSE
#Замена MA на MO но для чего...
#БЫЛО НО ВРОДЕ ИЗМЕНЕНИЕ!!!!!!!!! #fn_ref = fn[2:2] == "MA" ? "MO" * fn[3:end] : fn
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
#fn_ref = fn

#fn_ref = "MO1_002"
refrow = ref[fn_ref] #числа, имеющий тип Float


#Сигнал без фильтров (для CTS разницы не почувствуем)
#показываем на 12 каналах графики с референотной разметкой
#show_record_CTS(n)
show_record(n) #Для CSE



#типизируем сигнал для удобного использования
fs
Start_QRS = floor(Int64, refrow.QRS_onset) - 2
signals = StructVector(signals)
signals_pice = signals[2:Start_QRS]
#фильтр my_butter - РАЗОБРАТЬСЯ!!!
#my_butter(sig, alth, (A, B), fs, Bandpass) - sig сигнал; alth что это; A - B диапозон частоты?!; fs - частота дискритизации; Bandpass - какая-то функция
filtered_signals = map(Tables.columntable(signals_pice)) do sig
    hpass = my_butter(sig, 2, (5, 20), fs, Bandpass)
end
filtered_signals = StructVector(filtered_signals)

#фильтр производная
diff_signals = map(Tables.columntable(filtered_signals)) do sig
    DiffFilt(sig, 2)
end

diff_signals = StructVector(diff_signals)



signals_dd = signals[110:370]
f_dd = map(Tables.columntable(signals_dd)) do sig
    hpass = my_butter(sig, 2, (5, 20), fs, Bandpass)
end
f_dd = StructVector(f_dd)


diff_start_signals = map(Tables.columntable(signals_pice)) do sig
    DiffFilt(sig, 2)
end
diff_start_signals = StructVector(diff_start_signals)


#Проверка что читается референтные значения и понять какие там типы (Float ли Int)
#refrow.P_onset  #начало P по референотной разметке
#refrow.P_end #конец P по референотной разметке
#refrow.QRS_onset #начало комплекса QRS
#refrow.T_end #конец T по референотной разметке
Start = floor(Int64, refrow.P_onset)  #Это для изменения из Float в Int
End = floor(Int64, refrow.T_end) #Так же есть функция trunc
timer_all = Start:End + 20  #время одного сокращения (+20)
timer_all2 = 2:Start_QRS
Ref_P_Start = floor(Int64, refrow.P_onset)

Ref_P_End = floor(Int64, refrow.P_end)



Start_sig = 2
Start_QRS

#Start и Start_QRS получаю исходя от оценки QRS
#Channel_Left = Int64[]
#Channel_Right = Int64[]
#for k in 2:length(ch_names)
#    Left_P, Right_P = Border_L_R(ch_names, filtered_signals, Start, Start_QRS, Ref_P_Start, Ref_P_End, k)
#    push!(Channel_Left, Left_P)
#    push!(Channel_Right, Right_P)
#end

#channel = 2
#Chanel_filter = [filtered_signals.I, filtered_signals.II, filtered_signals.III, filtered_signals.aVR, filtered_signals.aVL, filtered_signals.aVF, filtered_signals.V1, filtered_signals.V2, filtered_signals.V3, filtered_signals.V4, filtered_signals.V5, filtered_signals.V6]
#points_max = find_localmax(Chanel_filter[channel][2:Start_QRS], 15)
#points_min = find_localmin2(Chanel_filter[channel][2:Start_QRS], 2)

#Left, Right = Border_tr(points_max, points_min)



#Start_QRS
#Chanel_filter = [Signal.I, Signal.II, Signal.III, Signal.aVR, Signal.aVL, Signal.aVF, Signal.V1, Signal.V2, Signal.V3, Signal.V4, Signal.V5, Signal.V6]

#points_max = find_localmax(Chanel_filter[channel][2:Start_QRS], 15)
#Left_Border_Max

#Start_sig = 2
#Start_QRS

Channel_Left, Channel_Right = Border_L_R(ch_names, filtered_signals, Start_sig, Start_QRS)
Chanel_filter = [signals.I, signals.II, signals.III, signals.aVR, signals.aVL, signals.aVF, signals.V1, signals.V2, signals.V3, signals.V4, signals.V5, signals.V6]
Chanel_sign = [filtered_signals.I, filtered_signals.II, filtered_signals.III, filtered_signals.aVR, filtered_signals.aVL, filtered_signals.aVF, filtered_signals.V1, filtered_signals.V2, filtered_signals.V3, filtered_signals.V4, filtered_signals.V5, filtered_signals.V6]

#plot(Chanel_filter[4])
#find_localmax(Chanel_filter[4], 15)
#(:I, :II, :III, :aVR, :aVL, :aVF, :V1, :V2, :V3, :V4, :V5, :V6)
Ref_Points = [Ref_P_Start, Ref_P_End]
plot(signals_pice.II)
numb = 2

plot(Chanel_filter[numb], label = "Filt signal")
if(Ref_P_Start != 0 && Ref_P_End != 0)
    vline!(Ref_Points, label = "Ref")
end
   # scatter!((points_max, filtered_signals.II[points_max]))#max
#scatter!((points_min, filtered_signals.II[points_min]))#min

y_L = Channel_Left[numb]
Oy_L = Chanel_filter[numb][y_L]
scatter!((Channel_Left[numb], Oy_L))
y_R = Channel_Right[numb]
Oy_R = Chanel_filter[numb][y_R]
scatter!((Channel_Right[numb], Oy_R))



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#ref = _read_ref_CTS(n) #Длия CTS
ref = _read_ref(n) #Для CSE

#_show_signals_mark(signals[timer_all], ref) #Использовалось для проверки

#refrow_int = show_record_CTS(n) #Графики 12 каналов для CTS
refrow_int = show_record(n) #Графики 12 каналов для CSE

#возникает ошибка так как значения типа Float и такой тип не может быть индексом
#floor(Int64, refrow.P_onset)# |> Int64
#refrow.T_end
#timer_all = refrow.P_onset:refrow.T_end + 20 
#_show_signals_mark(signals[timer_all], refrow)

#Используя алгоритм находим границы пока что грубо, через экстремумы
#На интервале от "начала" до QRS (Int)
Chanel_filter = [filtered_signals.I, filtered_signals.II, filtered_signals.III, filtered_signals.aVR, filtered_signals.aVL, filtered_signals.aVF, filtered_signals.V1, filtered_signals.V2, filtered_signals.V3, filtered_signals.V4, filtered_signals.V5, filtered_signals.V6]


#points_max = find_localmax(filtered_signals.I[2:Start_QRS], 15)
#points_min = find_localmin2(filtered_signals.I[2:Start_QRS], 2)
k = 2
points_max = find_localmax(Chanel_filter[k][2:Start_QRS], 15)
points_min = find_localmin2(Chanel_filter[k][2:Start_QRS], 2)


#points_max = [5, 2, 3, 6, -3]
#Поиск минимума
Maxx = Inf
Minn = -Inf
for i in 2:length(points_max)
    if points_max[i] > Minn
        #push!(PP, points_max[i])
        Minn = points_max[i]
    end
    if points_max[i]< Maxx
        #push!(PP, points_max[i])
        Maxx = points_max[i]
    end
end

Minn
Maxx

dist_min = Inf
dist_max = Inf
for j in 2:length(points_min)
    if points_min[j] < Minn && dist_min > points_min[j]
        dist_min = points_min[j]
    end
    if points_min[j] > Maxx && dist_max > points_min[j]
        dist_max = points_min[j]
    end
end
St = dist_min
En = dist_max

#PP = Int64[]
#for i in 2:length(points_max)
#    push!(PP, points_max[i])
#end
#for j in 2:length(points_min)
#    push!(PP, points_min[j])
#end
#PP

Ref_Points = [Ref_P_Start, Ref_P_End]
#Сигнал до QRS
plot(signals_pice.II)


plot(filtered_signals.II, label = "Filt signal")
if(Ref_P_Start != 0 && Ref_P_End != 0)
    vline!(Ref_Points, label = "Ref")
end
    scatter!((points_max, filtered_signals.II[points_max]))#max
scatter!((points_min, filtered_signals.II[points_min]))#min





plot(diff_signals.I)
vline!(Ref_Points)
Ref_Points = Ref_Points
#scatter!((Ref_Points, diff_signals.I[Ref_Points]))



dist_min = Inf
dist_max = -Inf

d_m, d_ma = Inf, -Inf
d_m



#Изменяем фильтр так, чтобы убрат QRS

#референтные значения QRS
start_qrs1 = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
end_qrs1= floor(Int64, refrow.QRS_end) #конец комплекса QRS
dur_qrs1= floor(Int64, refrow.QRS_dur) #длительность комплекса QRS
#интервал!
ref
ref.ibeg #Начало
ref.iend #конец
#длительность
Distance = ref.iend - ref.ibeg + 2

All_ref_qrs = Int64[]
push!(All_ref_qrs, start_qrs1)
push!(All_ref_qrs, end_qrs1)
ind = start_qrs1 + Distance

while (ind < length(signals))
    push!(All_ref_qrs, ind)
    if(ind + dur_qrs1 < length(signals))
        push!(All_ref_qrs, ind + dur_qrs1)
    end
    ind = ind + Distance
end

plot(signals.II)
P_qrs = [89, 133]


vline!(All_ref_qrs)
P_qrs[2] = P_qrs[2]+265
P_qrs[2] = P_qrs[2]+265
vline!(P_qrs)


ref.ibeg
ref.iend






#
#Изменяем фильтр так, чтобы убрат QRS
include("Function_P.jl")
n = 2
fn = allbinfiles[n]
#референтные значения QRS
signals, fs, _, _ = readbin("$dir/$(fn)") 
signals = StructVector(signals)

start_qrs1 = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
end_qrs1= floor(Int64, refrow.QRS_end) #конец комплекса QRS
dur_qrs1= floor(Int64, refrow.QRS_dur) #длительность комплекса QRS
#интервал!
ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv")  #CSE
#Замена MA на MO но для чего...
fn_ref = fn[2:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]
ref = _read_ref(n)
ref
ref.ibeg #Начало
ref.iend

refrow.T_end
Ref_qrs = All_Ref_QRS(start_qrs1, end_qrs1, ref.ibeg, ref.iend)
plot(signals.II)
vline!(All_ref_qrs)

change_sig = Int64[]
change_sig =signals.II
plot(signals.II)
plot(change_sig)

refrow.QRS_onset

refrow.P_onset = refrow.P_onset + (ref.iend - ref.ibeg) + 2
refrow.P_end = refrow.P_end + (ref.iend - ref.ibeg) + 2
refrow.T_end = refrow.T_end #+ (ref.iend - ref.ibeg) + 2

p_ref = [refrow.P_onset, refrow.P_end]
t_ref = [refrow.T_end]
#Изменяем исходный сигнал
i = 2

length(All_ref_qrs)
while (i <= (length(All_ref_qrs)))
    
    change_sig[All_ref_qrs[i-2]:(floor(Int64, All_ref_qrs[i-2]+(end_qrs1-start_qrs1)/2))] .= change_sig[All_ref_qrs[i-2] - 2]
    change_sig[(floor(Int64, All_ref_qrs[i-2]+(end_qrs1-start_qrs1)/2)):All_ref_qrs[i]] .= change_sig[All_ref_qrs[i] + 2]
    i = i + 2
end

change_sig
plot!(change_sig)
plot!(signals.II)
131231231231312333333333333333333333333333333333


vline!(p_ref)
xlims!(All_ref_qrs[2]-5, All_ref_qrs[3]+5)
vline!((t_ref))
change_sig[All_ref_qrs[2]-5:All_ref_qrs[3]+5]
#new = DiffFilt(change_sig, 2)
new = my_butter(signals.II, 2, (2, 20), fs, Bandpass)
new2 = my_butter(change_sig, 2, (2, 20), fs, Bandpass)

plot!(new)
plot!(new2)

xlims!(All_ref_qrs[2]-5, All_ref_qrs[3]+5)
vline!(p_ref)
vline!((t_ref))



## Разработка от 12.05 с чётким указанием
include("Function_P.jl")
#Номер сигнала
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)  
n = 1
fn = allbinfiles[n]

#Чтение сигнала
signals, fs, _, _ = readbin("$dir/$(fn)") 
signals = StructVector(signals)

#Построение по 12 каналам графиков с реф значениями, только первый кусок 
show_record(n)

#По вертикали смотрим графики: "пример"
#plot_vertical(signals.I, signals.II, signals.III; label="")

#Чтение реф значений
read_refer = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
ref = read_all_ref(read_refer)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]

ref = _read_ref(n)
ref.ibeg #Начало сигнала
ref.iend #Конец сигнала
start_qrs = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
end_qrs= floor(Int64, refrow.QRS_end) #конец комплекса QRS
dur_qrs= floor(Int64, refrow.QRS_dur) #длительность комплекса QRS


#start_qrs = floor(Int64, ref.:Qrs_onset) #начало комплекса QRS 
#end_qrs= floor(Int64, ref.Qrs_end) #конец комплекса QRS
#dur_qrs= floor(Int64, ref.Qrs_dur) #длительность комплекса QRS


#Разбиение сигнала по каналам
signals_channel = Sign_Channel(signals) #12 каналов


#Разметка qrs на всём сигнале
Ref_qrs = All_Ref_QRS(start_qrs, end_qrs, ref.ibeg, ref.iend)

#Графики по определённым каналам с реф разметкой
plot_vertical_ref(Ref_qrs, signals_channel[1], signals_channel[2], signals_channel[3], signals_channel[4], signals_channel[5], signals_channel[6], signals_channel[7], signals_channel[8], signals_channel[9], signals_channel[10], signals_channel[11], signals_channel[12]; label="") #по всем 12ти
plot_vertical_ref(Ref_qrs, signals_channel[1], signals_channel[2], signals_channel[3]; label="") # по первым трём

#Зануление qrs
signal_without_qrs = Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)

#построение графиков с занулением
plot_vertical_ref(Ref_qrs, signal_without_qrs[1], signal_without_qrs[2], signal_without_qrs[3], signal_without_qrs[4], signal_without_qrs[5], signal_without_qrs[6], signal_without_qrs[7], signal_without_qrs[8], signal_without_qrs[9], signal_without_qrs[10], signal_without_qrs[11], signal_without_qrs[12]; label="")

#Функция определяющая приблезительные участки P зубца (+ график на 12 каналах)
Left, Right = Segment_left_right_P(fs, Ref_qrs, ref.ibeg, ref.iend)
All_left_right = [Left, Right ]
plot_vertical_ref(All_left_right, signal_without_qrs[2], signal_without_qrs[2], signal_without_qrs[3], signal_without_qrs[4], signal_without_qrs[5], signal_without_qrs[6], signal_without_qrs[7], signal_without_qrs[8], signal_without_qrs[9], signal_without_qrs[10], signal_without_qrs[11], signal_without_qrs[12]; label="")

#Проверка для 1го канала на первом участке pice (1 или 2)
pice = 2

plot(signal_without_qrs[2])
vline!(All_left_right, label="~ P граница")
referent_p = [refrow.P_onset , refrow.P_end ]
referent_p2 = [refrow.P_onset + ( ref.iend - ref.ibeg) , refrow.P_end + ( ref.iend - ref.ibeg) ]

midd = floor(Int64, refrow.QRS_dur/2)
if (pice == 1)
vline!(referent_p, label="p_1")
xlims!(1, Ref_qrs[2] + midd)
end
if (pice == 2)
vline!(referent_p2, label="P граница")
xlims!(Ref_qrs[2]-midd, Ref_qrs[3] + midd)
end


#18.05


loc_min, loc_max = all_min_max(All_left_right, signal_without_qrs, midd, fs)

chan = 5
plot(signal_without_qrs[chan])



loc_min_chan = loc_min[chan]
loc_max_chan = loc_max[chan]
scatter!((loc_min_chan, signal_without_qrs[chan][loc_min_chan]))
scatter!((loc_max_chan, signal_without_qrs[chan][loc_max_chan]))

gr_d = DiffFilt(signal_without_qrs[chan], 1)
plot(gr_d)

gr_b = my_butter(signal_without_qrs[chan], 2, (2, 20), fs, Bandpass)
plot(gr_b)
scatter!((loc_min_chan, gr_b[loc_min_chan]), laybel = "min")
scatter!((loc_max_chan, gr_b[loc_max_chan]))


#Небольшие изменения от 18.05

include("Function_P.jl")
#Номер сигнала
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)  
n = 1
fn = allbinfiles[n]

#Чтение сигнала
signals, fs, _, _ = readbin("$dir/$(fn)") 
signals = StructVector(signals)

#Построение по 12 каналоам графиков с реф значениями
#show_record(n)

#По вертикали смотрим графики: "пример"
#plot_vertical(signals.II, filtered_signals.II, diff_signals.II; label="")

#Чтение реф значений
referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
ref = read_all_ref(referent)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]

ref = _read_ref(n)
ref.ibeg #Начало сигнала
ref.iend #Конец сигнала
start_qrs = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
end_qrs= floor(Int64, refrow.QRS_end) #конец комплекса QRS
dur_qrs= floor(Int64, refrow.QRS_dur) #длительность комплекса QRS


#start_qrs = floor(Int64, ref.:Qrs_onset) #начало комплекса QRS 
#end_qrs= floor(Int64, ref.Qrs_end) #конец комплекса QRS
#dur_qrs= floor(Int64, ref.Qrs_dur) #длительность комплекса QRS
signals

#Разбиение сигнала по каналам
signals_channel = Sign_Channel(signals) #12 каналов

fs
#Разметка qrs на всём сигнале
Ref_qrs = All_Ref_QRS(start_qrs, end_qrs, ref.ibeg, ref.iend)

#Графики по определённым каналам с реф разметкой
plot_vertical_ref(Ref_qrs, signals_channel[1], signals_channel[2], signals_channel[3], signals_channel[4], signals_channel[5], signals_channel[6], signals_channel[7], signals_channel[8], signals_channel[9], signals_channel[10], signals_channel[11], signals_channel[12]; label="")
plot_vertical_ref(Ref_qrs, signals_channel[1], signals_channel[2], signals_channel[3]; label="") # по первым трём

#Зануление qrs
signal_without_qrs = Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)
#signal_without_qrs = Simple_Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)

#построение графиков с текущим занулением
plot_vertical_ref(Ref_qrs, signal_without_qrs[1], signal_without_qrs[2], signal_without_qrs[3], signal_without_qrs[4], signal_without_qrs[5], signal_without_qrs[6], signal_without_qrs[7], signal_without_qrs[8], signal_without_qrs[9], signal_without_qrs[10], signal_without_qrs[11], signal_without_qrs[12]; label="")

#Функция определяющая приблезительные участки P зубца (+ график на 12 каналах)
Left, Right = Segment_left_right_P(fs, Ref_qrs, ref.ibeg, ref.iend)
All_left_right = [Left, Right ]
plot_vertical_ref(All_left_right, signal_without_qrs[1], signal_without_qrs[2], signal_without_qrs[3], signal_without_qrs[4], signal_without_qrs[5], signal_without_qrs[6], signal_without_qrs[7], signal_without_qrs[8], signal_without_qrs[9], signal_without_qrs[10], signal_without_qrs[11], signal_without_qrs[12]; label="")
#теперь по всем каналам my_butter
all_graph_butter = Graph_my_butter(signal_without_qrs)
#график
plot_vertical(all_graph_butter[1], all_graph_butter[2], all_graph_butter[3], all_graph_butter[4], all_graph_butter[5], all_graph_butter[6], all_graph_butter[7], all_graph_butter[8], all_graph_butter[9], all_graph_butter[10], all_graph_butter[11], all_graph_butter[12]; label="")

koef  = 1000/fs
dist = floor(Int64, 20 / koef)
#теперь по всем каналам диф
all_graph_diff = Graph_diff(all_graph_butter, dist)
plot_vertical(all_graph_diff[1], all_graph_diff[2], all_graph_diff[3], all_graph_diff[4], all_graph_diff[5], all_graph_diff[6], all_graph_diff[7], all_graph_diff[8], all_graph_diff[9], all_graph_diff[10], all_graph_diff[11], all_graph_diff[12]; label="")

All_left_right

st = All_left_right[1][1]
en = All_left_right[2][1]
xlims!(st, en)
all_local_max = []

kk = []
ch = 2
ss = find_localmax(all_graph_diff[ch][st:en], 20)
scatter!(ss, all_graph_diff[ch][ss])
mm = find_localmin2(all_graph_diff[ch][st:en], 10)
scatter!(mm, all_graph_diff[ch][mm])

nm = [ss, mm]
push!(kk, nm)

Start = All_left_right

Massiv_Points_channel = Sort_points_with_channel(All_points_with_cannels_min_max(All_left_right, all_graph_diff))
Massiv_Points_channel[1]

# [*] Алгоритм:
# на участке области P рассматриваем все local_min и local_max, высчитываем амлитуду

# pos[i] - это амплитуда на Diff_Filt 

# Max_amp = 0
# first_index = 0
# last_index = 0

# #Вылезет за край массива!
# pos[] - локальные min и max в порядке по времени и в одной области
# val[] == diff_sigmal[pos[]]
# for (цикл от 1 области зубца P, который возможен в сигнале до последней области - OBL)
    
#     for(int i = 1, i < колчиество точеек в одной области, i++)
#     amp = 0
        
#         for(k = i + 1, k < i + 4 && (k + 1) < length(колчиество точеек в одной области) && abs(pos[i] - pos[k]) < 80мск, k++) #тут вылезет!
#                 amp+ = abs(val[k-1] - val[k]) 
#                 f_index = i
#                 l_index = k
#         end

#         if (Max_amp < amp)
#             Max_amp = amp
#             first_index = i
#             last_index = l_index
#     end

#     запоминаем, что на участке под номером OBL, амплитуду Max_amp, начало и конец first_index last_index
# end

# ~заполняем массив 

# return first_index, last_index, amp- тут наши фронты
channel = 1

all_graph_diff[channel]
plot(all_graph_diff[channel], label = "диф график")
#xlims!(1, start_qrs)
#scatter!(Massiv_Points_channel[channel][1], all_graph_diff[channel][Massiv_Points_channel[channel][1]])
#for ll in 1:11
ll = 1
scatter!(Massiv_Points_channel[channel][ll], all_graph_diff[channel][Massiv_Points_channel[channel][ll]])
#end
as
# koeff = 2
# function hell(Massiv_Points_channel, all_graph_diff,  koeff)
#     f_index = first_index = 0
#     l_index = last_index = 0
#     #только 1ая облась
#     OBLAST = []
#  #   OBLAST_with_channel = []
#     for points_in in 1:length(Massiv_Points_channel[channel]) # (цикл от 1 области зубца P, который возможен в сигнале до последней области - OBL)
#         @info "points_in = $points_in" 
#         Max_amp = 0
        
#         for  i in 1:length(Massiv_Points_channel[channel][points_in]) 
#             @info "i = $i" 
#             amp = 0
        
#             for k in (i + 1):(i + 4) 
#                 if((k + 1) < length(Massiv_Points_channel[channel][points_in])  && abs(Massiv_Points_channel[channel][points_in][i] - Massiv_Points_channel[channel][points_in][k]) < 80) #тут вылезет!
#                     mm1 = Massiv_Points_channel[channel][points_in][k-1]
#                     mm2 = Massiv_Points_channel[channel][points_in][k]
#                     amp = amp + abs(all_graph_diff[channel][mm1] - all_graph_diff[channel][mm2]) 
                   
#                     @info "abs = $mm "
#                     f_index = i
#                     l_index = k
#                     @info "inside amp = $amp" 
#                 end

#                 if (Max_amp < amp)
#                     Max_amp = amp
#                     first_index = i
#                     last_index = l_index
#                 end
#             end
#             push!(OBLAST, [Max_amp, first_index, last_index])
        
#             end
#         OBLAST
#   #  запоминаем, что на участке под номером OBL, амплитуду Max_amp, начало и конец first_index last_index
#     end

# #push!(OBLAST_with_channel, OBLAST)

# return OBLAST
# end


koef
LMAO = []
LMAO = Fronts(Massiv_Points_channel, all_graph_diff, koef)
LMAO[1]

#if((k + 1) < length(Massiv_Points_channel[channel][1])  && abs(Massiv_Points_channel[channel][1][i] - Massiv_Points_channel[channel][1][k]) < 80/koeff)

    # length(Massiv_Points_channel[channel][1])
    # k = 2
    # mm1 = Massiv_Points_channel[channel][points_in][k-1]
    # mm2 = Massiv_Points_channel[channel][points_in][k]
    # amp = amp + abs(all_graph_diff[channel][mm1] - all_graph_diff[channel][mm2]) 



    # abs(Massiv_Points_channel[channel][1][i] - Massiv_Points_channel[channel][1][k])


    # Massiv_Points_channel[channel][1]
    # all_graph_diff[channel][k-1]

    # abs(all_graph_diff[channel][k-1] - all_graph_diff[channel][k]) 

    # all_graph_diff[channel]