using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames

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

#Наименование базы данных и номер файла ("CSE")
Name_Data_Base, Number_File = "CSE", 1
#Определённое отведение (channel)
channel = 4

#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
#Сигнал в виде массива для более удобного поканальной отрисовки
Massiv_Signal = Sign_Channel(signal_const)


#График исходного канала на всех отведениях (P.S. к сожалению, имя файла не указать)
plot_vertical(signal_const.I, signal_const.II, signal_const.III, signal_const.aVR, signal_const.aVL, signal_const.aVF, signal_const.V1, signal_const.V2, signal_const.V3, signal_const.V4, signal_const.V5, signal_const.V6);
plot!()

#График исходного канала на определённом отведении
plot(Massiv_Signal[channel], label = false)
title!("$(Names_files[Number_File]), $Name_Data_Base, Отведение $channel")

#График исходного канала на всех отведениях с референтной разметкой для QRS(P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Ref_qrs, signal_const.I, signal_const.II, signal_const.III, signal_const.aVR, signal_const.aVL, signal_const.aVF, signal_const.V1, signal_const.V2, signal_const.V3, signal_const.V4, signal_const.V5, signal_const.V6);
plot!()

#График исходного канала на определённом отведении с референтной разметкой для QRS
plot_vertical_ref(Ref_qrs, Massiv_Signal[channel]);
title!("$(Names_files[Number_File]), $Name_Data_Base, Отведение $channel")

#График исходного канала на всех отведениях с первичной областью поиска P (P.S. к сожалению, имя файла не указать) Красная - левая; Зелёная - правая
plot_vertical_ref(Place_found_P_Left_and_Right, signal_const.I, signal_const.II, signal_const.III, signal_const.aVR, signal_const.aVL, signal_const.aVF, signal_const.V1, signal_const.V2, signal_const.V3, signal_const.V4, signal_const.V5, signal_const.V6);
plot!()

#График исходного канала на определённом отведении с первичной областью поиска P; Красная - левая; Зелёная - правая
plot_vertical_ref(Place_found_P_Left_and_Right, Massiv_Signal[channel]);
title!("$(Names_files[Number_File]), $Name_Data_Base, Отведение $channel, red=left, green=right")

#График исходного канала на всех отведениях с "занулением" QRS (P.S. к сожалению, имя файла не указать)
plot_vertical(signal_without_qrs[1], signal_without_qrs[2], signal_without_qrs[3], signal_without_qrs[4], signal_without_qrs[5], signal_without_qrs[6], signal_without_qrs[7], signal_without_qrs[8], signal_without_qrs[9], signal_without_qrs[10], signal_without_qrs[11], signal_without_qrs[12]);
plot!()

#График исходного канала на определённом отведении с"занулением" QRS
plot(signal_without_qrs[channel], legend = false);
title!("$(Names_files[Number_File]), $Name_Data_Base, Отведение $channel")

#График отфильрованного сигнала my_butter канала на всех отведениях с "занулением" QRS (P.S. к сожалению, имя файла не указать)
plot_vertical(all_graph_butter[1], all_graph_butter[2], all_graph_butter[3], all_graph_butter[4], all_graph_butter[5], all_graph_butter[6], all_graph_butter[7], all_graph_butter[8], all_graph_butter[9], all_graph_butter[10], all_graph_butter[11], all_graph_butter[12]);
plot!()

#График отфильрованного сигнала my_butter канала на определённом отведении с "занулением" QRS
plot(all_graph_butter[channel], legend = false);
title!("My_butter, $(Names_files[Number_File]), $Name_Data_Base, Отведение $channel")

#График отфильрованного сигнала my_butter канала на всех отведениях с "занулением" QRS и реферетной разметкой QRS (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Ref_qrs, all_graph_butter[1], all_graph_butter[2], all_graph_butter[3], all_graph_butter[4], all_graph_butter[5], all_graph_butter[6], all_graph_butter[7], all_graph_butter[8], all_graph_butter[9], all_graph_butter[10], all_graph_butter[11], all_graph_butter[12]);
plot!()

#График отфильрованного сигнала my_butter канала на определённом отведени с "занулением" QRS и реферетной разметкой QRS (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Ref_qrs, all_graph_butter[channel]);
plot!()

#График отфильрованного сигнала my_butter канала на всех отведениях с "занулением" QRS и первичной областью поиска Р (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Place_found_P_Left_and_Right, all_graph_butter[1], all_graph_butter[2], all_graph_butter[3], all_graph_butter[4], all_graph_butter[5], all_graph_butter[6], all_graph_butter[7], all_graph_butter[8], all_graph_butter[9], all_graph_butter[10], all_graph_butter[11], all_graph_butter[12]);
plot!()

#График отфильрованного сигнала my_butter канала на определённом отведении с "занулением" QRS и первичной областью поиска Р (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Place_found_P_Left_and_Right, all_graph_butter[channel]);
title!("My_butter+first_P, $(Names_files[Number_File]), $Name_Data_Base, Отведение $channel, red=left, green=right")

#График дифференцированного сигнала на всех отведениях (P.S. к сожалению, имя файла не указать)
plot_vertical(all_graph_diff[1], all_graph_diff[2], all_graph_diff[3], all_graph_diff[4], all_graph_diff[5], all_graph_diff[6], all_graph_diff[7], all_graph_diff[8], all_graph_diff[9], all_graph_diff[10], all_graph_diff[11], all_graph_diff[12]);
plot!()

#График дифференцированного сигнала на определённом отведении 
plot(all_graph_diff[channel]);
title!("Дифф, $(Names_files[Number_File]), $Name_Data_Base, Отведение $channel")

#График дифференцированного сигнала на всех отведениях c реферетной разметкой QRS (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Ref_qrs, all_graph_diff[1], all_graph_diff[2], all_graph_diff[3], all_graph_diff[4], all_graph_diff[5], all_graph_diff[6], all_graph_diff[7], all_graph_diff[8], all_graph_diff[9], all_graph_diff[10], all_graph_diff[11], all_graph_diff[12]);
plot!()

#График дифференцированного сигнала на определённом отведении c c реферетной разметкой QRS  (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Ref_qrs, all_graph_diff[channel]);
title!("Дифф+ref_qrs, $(Names_files[Number_File]), $Name_Data_Base, Отведение $channel")

#График дифференцированного сигнала на всех отведениях c первичной областью поиска Р (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Place_found_P_Left_and_Right, all_graph_diff[1], all_graph_diff[2], all_graph_diff[3], all_graph_diff[4], all_graph_diff[5], all_graph_diff[6], all_graph_diff[7], all_graph_diff[8], all_graph_diff[9], all_graph_diff[10], all_graph_diff[11], all_graph_diff[12]);
plot!()

#График дифференцированного сигнала на определённом отведении c первичной областью поиска Р (P.S. к сожалению, имя файла не указать)
plot_vertical_ref(Place_found_P_Left_and_Right, all_graph_diff[channel]);
title!("Дифф+first_P, $(Names_files[Number_File]), $Name_Data_Base, Отведение $channel, red=left, green=right")
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################

using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames

#Если хотим сохранить картинки - отключчаем ploty()
plotly()

include("Markup_function_P.jl");
include("Function_P.jl");
include(".env");
include("../src/readfiles.jl");
include("../src/plots.jl");
include("Function_P_file.jl");
include("Plots_P.jl");
include("Create_Table.jl");
include("Function_dist.jl")
#Наименование базы данных и номер файла ("CSE")

Name_Data_Base, Number_File = "CSE", 107
#Определённое отведение (channel)
channel = 1

#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter, all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
#Сигнал в виде массива для более удобного поканальной отрисовки
Massiv_Signal = Sign_Channel(signal_const)

Selection = 3

include("Create_Table.jl")

Comparson_Delta_Edge("CSE", Number_File)
#Table_P_Sq("Rad100_GlEdge42_Sq")
#Table_P("Rad100_GlEdge42_Sq")
Table_P_Sq_1and2("Rad100_GlEdge42_Sq_1and2")
#save_pictures_p(Selection)
# savefig("pictures_edge_CSE/$(names_files).png")
Value_Left_Edge_All_MD, Value_Right_Edge_All_MD, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD, Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq = function_Points_fronts(Massiv_Amp_all_channels, Massiv_Points_channel)
#Value_Left_Edge_All_MD, Value_Right_Edge_All_MD, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD, Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq = function_Points_fronts2(Massiv_Amp_all_channels, Massiv_Points_channel)

Ref_P[channel][Selection] 
include("Plots_P.jl")//Z..\

plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
xlims!(Ref_P[1][Selection][1]-50, Ref_P[1][Selection][2]+50)
vline!([Value_Left_Edge_All_MD, Value_Right_Edge_All_MD], color = "purple") #фиолетовый
vline!([Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD], color = "green") #зелёный
vline!([Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq], color = "black") #черный ТУТ НОВОе СВЕДЕНИЕ
Value_Left_Edge_All_MD
Value_Right_Edge_All_MD
Value_Left_Edge_Filtr_MD
Value_Right_Edge_Filtr_MD
Value_Left_Edge_Filtr_Sq
Value_Right_Edge_Filtr_Sq

стоп
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################

#Функция, строящая график на дифференцированном сигнале, границы P из реферетного файла и найденные границы зубца Р
plot_all_channels_points(Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Ref_P)
xlims!(Ref_P[1][1][1] - 50, Ref_P[1][1][2] + 50)

#Функция строит исходный сигнал на заданном отведении
plot_const_signal(Name_Data_Base, channel, signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
plot!()
xlims!(Ref_P[1][3][1] - 50, Ref_P[1][3][2] + 50)



Number_File
Ref_P[1][1]
#Два графика. Сверху - исходный сигнал с референтной разметкой P и моей детекцией P; снизу - график с фильтрами, референтной разметкой P и всеми точками,если Charr = 'p' (который находит алгоритм. Те точки, которые отличаются по цвету, являются фронтами)
Charr = 'p'
#Charr = 0
plot_channel_points(channel, Charr, signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Ref_P)
@info "Massiv_Amp_all_channels = $(Massiv_Amp_all_channels[4][3])"
plot!()
xlims!(Ref_P[1][1][1] - 50, Ref_P[1][1][2] + 50)





#Функция строит отфильтрованный сигнал на заданном отведении
plot_const_signal(Name_Data_Base, channel, all_graph_diff, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
plot!()
xlims!(Ref_P[1][3][1]-50, Ref_P[1][3][2]+50)


#Функция, строящая график исходного сигнала на 12 отведениях с реф разметкой P и моей детекцией зубца Р.
Selection_Edge = []
for Current_chanel in 1:12
    #Current_chanel = 1
    Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
    #Тут Функцию по КАК РАЗ поканально в одной секции
    push!(Selection_Edge, Points_fronts)
end
Value_Left_Edge_All_MD, Value_Right_Edge_All_MD = Test1_MD(Selection_Edge)
Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = Test2_MD(Selection_Edge) 


plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
xlims!(Ref_P[1][Selection][1]-50, Ref_P[1][Selection][2]+50)
#1.1 не нужно
#Left_Edge_All, Right_Edge_All = Test1(Selection_Edge)
#_, Index_Left_Edge_All, Value_Left_Edge_All_MV = Mean_value(Left_Edge_All)
#_, Index_Right_Edge_All, Value_Right_Edge_All_MV = Mean_value(Right_Edge_All)
#vline!([Value_Left_Edge_All_MV, Value_Right_Edge_All_MV])
#x = 1:length(Left_Edge_All)
#plot(x, Left_Edge_All)
#x = 1:length(Right_Edge_All)
#plot(x, Right_Edge_All)
#1.2 не нужно
#Left_edge_Filtr, Right_edge_Filtr = Test2(Selection_Edge)
#_, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MV = Mean_value(Left_edge_Filtr)
#_, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MV = Mean_value(Right_edge_Filtr)
#vline!([Value_Left_edge_Filtr_MV, Value_Right_edge_Filtr_MV])
#x = 1:length(Left_edge_Filtr)
#plot!(x, Left_edge_Filtr)
#x = 1:length(Right_edge_Filtr)
#plot!(x, Right_edge_Filtr)


plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
xlims!(Ref_P[1][Selection][1]-50, Ref_P[1][Selection][2]+50)
#2.1
#Left_Edge_All, Right_Edge_All = Test1(Selection_Edge)
#_, Index_Left_Edge_All, Value_Left_Edge_All_MD = Min_dist_to_all_points(Left_Edge_All)
#_, Index_Right_Edge_All, Value_Right_Edge_All_MD = Min_dist_to_all_points(Right_Edge_All)
vline!([Value_Left_Edge_All_MD, Value_Right_Edge_All_MD], color = "purple") #фиолетовый
#x = 1:length(Left_Edge_All)
#plot(x, Left_Edge_All)
#x = 1:length(Right_Edge_All)
#plot(x, Right_Edge_All)
#2.2
#Left_edge_Filtr, Right_edge_Filtr = Test2(Selection_Edge)
#_, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MD = Min_dist_to_all_points(Left_edge_Filtr)
#_, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MD = Min_dist_to_all_points(Right_edge_Filtr)
vline!([Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD], color = "green") #зелёный
#x = 1:length(Left_edge_Filtr)
#plot(x, Left_edge_Filtr)
#x = 1:length(Right_edge_Filtr)
#plot!(x, Right_edge_Filtr)


plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
xlims!(Ref_P[1][Selection][1] - 20, Ref_P[1][Selection][2] + 20)
#vline!([Value_Left_Edge_All_MV, Value_Right_Edge_All_MV]) #розовый
vline!([Value_Left_Edge_All_MD, Value_Right_Edge_All_MD], color = "purple") #фиолетовый


plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
xlims!(Ref_P[1][Selection][1]-50, Ref_P[1][Selection][2]+50)
#vline!([Value_Left_edge_Filtr_MV, Value_Right_edge_Filtr_MV]) #розовый
#vline!([Value_Left_edge_Filtr_MD, Value_Right_edge_Filtr_MD]) #желтый

#проверка значений
Left_p = Ref_P[channel][Selection][1]
Right_p = Ref_P[channel][Selection][2]

#All (Test1)
Delta(Left_p, Right_p, Value_Left_Edge_All_MD, Value_Right_Edge_All_MD)

#Filtr (Test2)
Delta(Left_p, Right_p, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD)

include("Function_P_file.jl")
My_Edge_P_All_Channel(Massiv_Points_channel, Massiv_Amp_all_channels)
My_Edge_P_One_Channel(Massiv_Points_channel, Massiv_Amp_all_channels, 1)
My_Edge_P(Massiv_Points_channel, Massiv_Amp_all_channels, 1, 1)


plot(all_graph_diff[channel])
for_scatter_x = My_Edge_P_One_Channel(Massiv_Points_channel, Massiv_Amp_all_channels, channel)
for_scatter_x
vline!(for_scatter_x, color = "green")
vline!(Ref_P[channel], color = "red")
