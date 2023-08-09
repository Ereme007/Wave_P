#Изменения от 18.05

using Plots, StructArrays, Tables#, PlotlyBase, PlotlyKaleido
#для толго чтобы видеть координаты на графиках
plotly()
include("Function_P.jl")
include("../src/readfiles.jl");
include("../src/plots.jl");
include("OneLeadQRS.jl");
include("../src/find_localmin.jl")


#Номер сигнала
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)  
n = 5
fn = allbinfiles[n]

#Чтение сигнала
signals, fs, _, _ = readbin("$dir/$(fn)") 
signals = StructVector(signals)
signals_copy = copy(signals)

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
ref.P_onset
ref.P_offset

#start_qrs = floor(Int64, ref.:Qrs_onset) #начало комплекса QRS 
#end_qrs= floor(Int64, ref.Qrs_end) #конец комплекса QRS
#dur_qrs= floor(Int64, ref.Qrs_dur) #длительность комплекса QRS

#Разбиение сигнала по каналам
signals_channel = Sign_Channel(signals_copy) #12 каналов

plot(signals_channel[8])
fs
#Разметка qrs на всём сигнале
Ref_qrs = All_Ref_QRS(start_qrs, end_qrs, ref.ibeg, ref.iend)
#Графики по определённым каналам с реф разметкой
plot_vertical_ref(Ref_qrs, signals_channel[1], signals_channel[2], signals_channel[3], signals_channel[4], signals_channel[5], signals_channel[6], signals_channel[7], signals_channel[8], signals_channel[9], signals_channel[10], signals_channel[11], signals_channel[12]; label="")

plot_vertical_ref(Ref_qrs, signals_channel[1], signals_channel[2], signals_channel[3]; label="") # по первым трём


plot(signals.I)

#Зануление qrs
signal_without_qrs = Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)
#signal_without_qrs = Simple_Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)

#построение графиков с текущим занулением
plot_vertical_ref(Ref_qrs, signal_without_qrs[1], signal_without_qrs[2], signal_without_qrs[3], signal_without_qrs[4], signal_without_qrs[5], signal_without_qrs[6], signal_without_qrs[7], signal_without_qrs[8], signal_without_qrs[9], signal_without_qrs[10], signal_without_qrs[11], signal_without_qrs[12]; label="")

plot_vertical_ref(Ref_qrs, signal_without_qrs[8], signal_without_qrs[2]; label="")

#Функция определяющая приблезительные участки P зубца (+ график на 12 каналах)
Left, Right = Segment_left_right_P(fs, Ref_qrs, ref.ibeg, ref.iend)
Place_found_P_Left_and_Right = [Left, Right] #записываем в 2-хмерный массив
plot_vertical_ref(Place_found_P_Left_and_Right, signal_without_qrs[1], signal_without_qrs[2], signal_without_qrs[3], signal_without_qrs[4], signal_without_qrs[5], signal_without_qrs[6], signal_without_qrs[7], signal_without_qrs[8], signal_without_qrs[9], signal_without_qrs[10], signal_without_qrs[11], signal_without_qrs[12]; label="")
Tester = Place_found_P_Left_and_Right
#теперь по всем каналам my_butter
all_graph_butter = Graph_my_butter(signal_without_qrs)
#график
plot_vertical(all_graph_butter[1], all_graph_butter[2], all_graph_butter[3], all_graph_butter[4], all_graph_butter[5], all_graph_butter[6], all_graph_butter[7], all_graph_butter[8], all_graph_butter[9], all_graph_butter[10], all_graph_butter[11], all_graph_butter[12]; label="")
#график с границами области где ищем зубец P (орандевый - начало, зелёный - правый край поиска)
plot_vertical_ref(Place_found_P_Left_and_Right, all_graph_butter[1], all_graph_butter[2], all_graph_butter[3], all_graph_butter[4], all_graph_butter[5], all_graph_butter[6], all_graph_butter[7], all_graph_butter[8], all_graph_butter[9], all_graph_butter[10], all_graph_butter[11], all_graph_butter[12]; label="")


#Дальше рассматриваем коэффициент относительно того какой fs 
koef  = 1000/fs
dist = floor(Int64, 20/koef) #20мск это для fs = 1000, поэтому и преобразовывем для текущего fs с помощью коэффициента
#теперь по всем каналам дифференциируем с расстоянием в 20мск
all_graph_diff = Graph_diff(all_graph_butter, dist)


#график с границами области где ищем зубец P (орандевый - начало, зелёный - правый край поиска)
plot_vertical_ref(Place_found_P_Left_and_Right, all_graph_diff[1], all_graph_diff[2], all_graph_diff[3], all_graph_diff[4], all_graph_diff[5], all_graph_diff[6], all_graph_diff[7], all_graph_diff[8], all_graph_diff[9], all_graph_diff[10], all_graph_diff[11], all_graph_diff[12]; label="")
plot_vertical_ref(Place_found_P_Left_and_Right, all_graph_diff[1], all_graph_diff[2], all_graph_diff[3], label = "")




#Пример на графике
#Проверка на одном канале
channel = 8
plot(all_graph_diff[channel], title = "Channel $channel ",  label="Дифф граф")
#Start_first_qrs = Place_found_P_Left_and_Right[1][1]
#End_first_qrs = Place_found_P_Left_and_Right[2][1]
#xlims!(Start_first_qrs, End_first_qrs)
#all_local_max = []
#ploints_max = find_localmax(all_graph_diff[channel][Start_first_qrs:End_first_qrs], 8)
#scatter!(ploints_max, all_graph_diff[channel][ploints_max])
#ploints_min = find_localmin2(all_graph_diff[channel][Start_first_qrs:End_first_qrs], 10)
#scatter!(ploints_min, all_graph_diff[channel][ploints_min])
#points_max_min = [ploints_max, ploints_min]
#Start = Place_found_P_Left_and_Right
massiv = All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff)
#Создаётся 3-хмерный массив, 1-ое это канал(12 значений), 2-е это max [1] и min [2] (2 значения), 3-е - номер участка поиска волны P (тут значение зависит от сигнала)
Test_Max_First = massiv[channel][1][1]
Test_Min_First = massiv[channel][2][1]
Test_Max_Sec = massiv[channel][1][2]
Test_Min_Sec = massiv[channel][2][2]

Test_Max_3 = massiv[channel][1][3]
Test_Min_3 = massiv[channel][2][3]

#Сортируем точки min и max в порядке возрастания по областям поиска зубца P
Massiv_Points_channel = Sort_points_with_channel(All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff))
Massiv_Points_channel[channel]

#all_graph_diff[channel]
#plot(all_graph_diff[channel], label = "диф график")
#p_x = Massiv_Points_channel[channel][1]
#scatter!(p_x, all_graph_diff[channel][p_x])
#xlims!(1, 150)

#Проверка используя графики (первые три участка)
plot(all_graph_diff[channel], label = "диф график")
scatter!(Test_Max_First, all_graph_diff[channel][Test_Max_First], label = "Max 1 Selection")
scatter!(Test_Min_First, all_graph_diff[channel][Test_Min_First], label = "Min 1 Selection")
scatter!(Test_Max_Sec, all_graph_diff[channel][Test_Max_Sec], label = "Max 2 Selection")
scatter!(Test_Min_Sec, all_graph_diff[channel][Test_Min_Sec], label = "Min 2 Selection")
scatter!(Test_Max_3, all_graph_diff[channel][Test_Max_3], label = "Max 3 Selection")
scatter!(Test_Min_3, all_graph_diff[channel][Test_Min_3], label = "Min 3 Selection")
xlims!(Place_found_P_Left_and_Right[1][1], Place_found_P_Left_and_Right[2][3])
vline!([Place_found_P_Left_and_Right[2][1], Place_found_P_Left_and_Right[1][2]], label = "кр обл поиска Р")
vline!([Place_found_P_Left_and_Right[2][2], Place_found_P_Left_and_Right[1][3]], label = "кр обл поиска Р")

#Пояснение многомерного массива "Massiv_Points_channel"
Massiv_Points_channel[channel] # на отведении channel столько отрезков (length)
Massiv_Points_channel[channel][1] #облать имеющий номер 2
Massiv_Points_channel[channel][2][1] #точка по X

#Нахождение амплитуды и границ по одному каналу (последняя цифра - номер канала)
amp_one_channel(Massiv_Points_channel, all_graph_diff, koef, 1)

#Массив всех 12ти каналов по амплитуде и границам участков
Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef)

#Пример проверки (для 1го канала)
#Massiv_Amp_all_channels[1]
                  

##дальше надо эти точки отобразить на исходном графике 
#ообразим для 1го канала текущего файла 
One_channel = amp_one_channel(Massiv_Points_channel, all_graph_diff, koef, 1)

#Проверка результатов
Selection = 2 #Область в которой мы рассматриваем зубец Р
Start_test = floor(Int64, One_channel[Selection][2])
End_test = floor(Int64, One_channel[Selection][3])



Start_sig_p = Massiv_Points_channel[1][Selection][Start_test]
End_sig_p = Massiv_Points_channel[1][Selection][End_test]

#На исходном сигнале
plot(signals.I)
xlims!(Place_found_P_Left_and_Right[1][Selection], Place_found_P_Left_and_Right[2][Selection])
scatter!((Start_sig_p, signals.I[Start_sig_p]))
scatter!((End_sig_p, signals.I[End_sig_p]))

#На отфильтрованном сигнале
plot(all_graph_diff[channel], label = "Отфильтрованный сигнал")
xlims!(Place_found_P_Left_and_Right[1][Selection], Place_found_P_Left_and_Right[2][Selection])
scatter!((Start_sig_p, all_graph_diff[channel][Start_sig_p]), label = "Левая граница")
scatter!((End_sig_p, all_graph_diff[channel][End_sig_p]), label = "Правая граница")

#Реферетные значения
vline!([ref.P_onset, ref.P_offset], label = "Реф разметка")

#3я производная
ind1 = Second_Diff_Left_Right(all_graph_diff, channel,End_sig_p, Place_found_P_Left_and_Right[2][Selection])
ind2 = Second_Diff_Right_Left(all_graph_diff, channel,Start_sig_p, Place_found_P_Left_and_Right[1][Selection])
scatter!([ind1, ind2], [all_graph_diff[channel][ind1], all_graph_diff[channel][ind2]], label = "3я производаня")


p1 = (plot(all_graph_diff[channel], label = "Отфильтрованный сигнал");
vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], label = "Реф разметка");
scatter!((Start_sig_p, all_graph_diff[channel][Start_sig_p]), label = "Левая граница");
scatter!((End_sig_p, all_graph_diff[channel][End_sig_p]), label = "Правая граница");
)


p2 = (plot(all_graph_diff[channel], label = "Отфильтрованный сигнал");
vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], label = "Реф разметка");
scatter!((Start_sig_p, all_graph_diff[channel][Start_sig_p]), label = "Левая граница");
scatter!((End_sig_p, all_graph_diff[channel][End_sig_p]), label = "Правая граница");

scatter!([ind1, ind2], [all_graph_diff[channel][ind1], all_graph_diff[channel][ind2]], label = "3я производаня");)


Massiv_Points_channel[1]
Selec = 8

Start_sig_p = Massiv_Points_channel[channel][Selec][Start_test];
Start_sig_p



plot_vertical_ref(Place_found_P_Left_and_Right, signal_without_qrs[channel], all_graph_butter[channel], p1)


Tester
Place_found_P_Left_and_Right
















referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
ref = read_all_ref(referent)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]


#минимальный набор функций
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)  

n = 1
channel = 1

fn = allbinfiles[n]
signals, fs, _, _ = readbin("$dir/$(fn)") 
signals = StructVector(signals)
signals_copy = copy(signals)
referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
ref = read_all_ref(referent)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]
ref = _read_ref(n)
start_qrs = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
end_qrs= floor(Int64, refrow.QRS_end) #конец комплекса QRS
dur_qrs= floor(Int64, refrow.QRS_dur)
signals_channel = Sign_Channel(signals_copy) #12 каналов
signals_start = Sign_Channel(signals_copy) #12 каналов

Ref_qrs = All_Ref_QRS(start_qrs, end_qrs, ref.ibeg, ref.iend)

Left, Right = Segment_left_right_P(fs, Ref_qrs, ref.ibeg, ref.iend)
Place_found_P_Left_and_Right = [Left, Right]
all_graph_butter = Graph_my_butter(signal_without_qrs)
koef  = 1000/fs
dist = floor(Int64, 20/koef)
all_graph_diff = Graph_diff(all_graph_butter, dist)
amp_one_channel(Massiv_Points_channel, all_graph_diff, koef, 1)
Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef)
Selection = 2 #Область в которой мы рассматриваем зубец Р
Start_test = floor(Int64, One_channel[Selection][2])
End_test = floor(Int64, One_channel[Selection][3])



Start_sig_p = Massiv_Points_channel[1][Selection][Start_test]
End_sig_p = Massiv_Points_channel[1][Selection][End_test]
ind1 = Second_Diff_Left_Right(all_graph_diff, channel,End_sig_p, Place_found_P_Left_and_Right[2][Selection])
ind2 = Second_Diff_Right_Left(all_graph_diff, channel,Start_sig_p, Place_found_P_Left_and_Right[1][Selection])


p1 = (plot(all_graph_diff[channel], label = "Отфильтрованный сигнал");
vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], label = "Реф разметка");
scatter!((Start_sig_p, all_graph_diff[channel][Start_sig_p]), label = "Левая граница");
scatter!((End_sig_p, all_graph_diff[channel][End_sig_p]), label = "Правая граница");
)

Massiv_Points_channel[8]
Selec = 2
p2 = (plot(all_graph_diff[channel], label = "Отфильтрованный сигнал");
vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], label = "Реф разметка");
scatter!((Start_sig_p, all_graph_diff[channel][Start_sig_p]), label = "Левая граница");
scatter!((End_sig_p, all_graph_diff[channel][End_sig_p]), label = "Правая граница");
scatter!([ind1, ind2], [all_graph_diff[channel][ind1], all_graph_diff[channel][ind2]], label = "3я производаня");)

Start_sig_p = Massiv_Points_channel[channel][Selec][Start_test];
Start_sig_p

channel

plot_vertical_ref(Place_found_P_Left_and_Right, signals_start[channel], signal_without_qrs[channel], all_graph_butter[channel], p1)





stop
#Хочется отображать точки на исходном сигнале. Но он "подпортился" из-за удаления qrsте
#Как вариант?! зная координаты по X исходный (если решили проблему в предыдущем пункте) сделать сглаживающий фильтр и по нему определять зубец?! на исходном сигнале проблематично
#от полученных границ (2 точки) рассматирваем слева и справа приведя границы близким к референтным значениям


##часть где провверялась local min max
#Tester_massiv = []
#for i in 1:150
#    push!(Tester_massiv, all_graph_diff[3][i])
#end


#include("Function_P.jl")

#Tester_massiv
#plot(Tester_massiv)
#point_x_max = new_localmax(Tester_massiv, 10)
#scatter!(point_x_max, Tester_massiv[point_x_max])
#point_x_min = new_localmin(Tester_massiv, 10)
#scatter!(point_x_min, Tester_massiv[point_x_min])

#point_x_min
#Tester_massiv[point_x_min]
##using DelimitedFiles
### Open file in append mode and then write to it
##open("example.txt","w") do io
##    writedlm(io, Tester_massiv)
##end