using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames
using Match
#Если хотим сохранить картинки - отключчаем ploty()
plotly()


include("Markup_function_P.jl");
include("Function_P.jl");
include(".env");
include("../src/readfiles.jl");
include("../src/plots.jl");
include("Function_P_file.jl");
include("Plots_P.jl")
include("Create_Table.jl")
include("Statistic.jl");


#Наименование базы данных и номер файла ("CSE")
Name_Data_Base, Number_File = "CSE", 2
#Определённое отведение (channel)
channel = 4
Selection = 3
#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)

#В зависимости от фильтра и алгоритма рассматривается дельта от реф границ
comparison("T1_Med", "T1_Sq", "CSE", Number_File) #тут по X

##Сохранение статистики
#T1 - фильтр точек (все);
#T2 - фильтр точек (некоторые);
#MD - mid distance; - 
#Sq - square;
#Med - mediana
RADIUS
Global_Edge #используется в T2

#Table_with_comparison("T2_Sq", "T2_Med", "T2_Sq_Med_TWC_Rad100GE42_3")

#все значения разметки 

Value_Left_Edge_All_MD, Value_Right_Edge_All_MD, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD, Value_Left_Edge_All_Mediana, Value_Right_Edge_All_Mediana, Value_Left_Edge_Filtr_Mediana, Value_Right_Edge_Filtr_Mediana, Value_Left_Edge_All_Sq, Value_Right_Edge_All_Sq, Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq = function_Points_fronts(Massiv_Amp_all_channels, Massiv_Points_channel)
#Value_Left_Edge_All_MD
#Value_Right_Edge_All_MD
#Value_Left_Edge_Filtr_MD
#Value_Right_Edge_Filtr_MD
Value_Left_Edge_All_Mediana
Value_Right_Edge_All_Mediana
Value_Left_Edge_Filtr_Mediana
Value_Right_Edge_Filtr_Mediana
Value_Left_Edge_All_Sq
Value_Right_Edge_All_Sq
Value_Left_Edge_Filtr_Sq
Value_Right_Edge_Filtr_Sq


Selection = 3
plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
xlims!(Ref_P[1][Selection][1] - 50, Ref_P[1][Selection][2] + 50)
vline!([Value_Left_Edge_All_Mediana, Value_Right_Edge_All_Mediana], color = "purple") #фиолетовый сведение Mediana
vline!([Value_Left_Edge_Filtr_Mediana, Value_Right_Edge_Filtr_Mediana], color = "green") #зелёный сведение Mediana
vline!([Value_Left_Edge_All_Sq, Value_Right_Edge_All_Sq], color = "brown") #коричневый сведение square
vline!([Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq], color = "black") #черный сведение square
Value_Left_Edge_Filtr_Sq

#Два графика. Сверху - исходный сигнал с референтной разметкой P и моей детекцией P; снизу - график с фильтрами, референтной разметкой P и всеми точками,если Charr = 'p' (который находит алгоритм. Те точки, которые отличаются по цвету, являются фронтами)
Charr = 'p'
#Charr = 0
plot_channel_points(channel, Charr, signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Ref_P)
@info "Massiv_Amp_all_channels = $(Massiv_Amp_all_channels[4][3])"
plot!()
xlims!(Ref_P[1][Selection][1] - 50, Ref_P[1][Selection][2] + 50)
