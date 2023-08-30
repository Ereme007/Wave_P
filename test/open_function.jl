using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames
using Match
#Если хотим сохранить картинки - отключчаем ploty()
plotly()




#include("Function_dist.jl")

#include("module_statistic.jl")
#using .Stati
#comparison("T1_Med", "T2_Med", "CSE", 2) #тут по X

#Name_Data_Base, Number_File = "CSE", 2
#Определённое отведение (channel)
#channel = 1
#Selection = 1
#Сигнал
#nam, _, _, _, _, _, _, _, _, _, _ = all_the(Name_Data_Base, Number_File)








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
Name_Data_Base, Number_File = "CSE", 35
#Определённое отведение (channel)
channel = 1
Selection = 5
#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter, all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
Names_files2, signal_const2, signal_without_qrs2, all_graph_butter2, all_graph_diff2, Ref_qrs2, Ref_P2, Place_found_P_Left_and_Right2, Massiv_Amp_all_channels2, Massiv_Points_channel2, Referents_by_File2 = all_the2(Name_Data_Base, Number_File)

include("Function_P.jl");

#all_graph_diff[channel][12]
#Два графика. Сверху - исходный сигнал с референтной разметкой P и моей детекцией P; снизу - график с фильтрами, референтной разметкой P и всеми точками,если Charr = 'p' (который находит алгоритм. Те точки, которые отличаются по цвету, являются фронтами)
Charr = 'p'
#Charr = 0
plot_channel_points(channel, Charr, signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Ref_P)
@info "Massiv_Amp_all_channels = $(Massiv_Amp_all_channels[4][3])"
plot!()
xlims!(Ref_P[1][Selection][1] - 50, Ref_P[1][Selection][2] + 50)



all_test_plot(channel, Charr, signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Ref_P, Massiv_Amp_all_channels2, Massiv_Points_channel2)
xlims!(Ref_P[1][Selection][1] - 50, Ref_P[1][Selection][2] + 50)





Charr = 'p'
#Charr = 0
plot_channel_points(channel, Charr, signal_const2, Massiv_Amp_all_channels2, Massiv_Points_channel2, all_graph_diff2, Ref_P2)
@info "Massiv_Amp_all_channels2 = $(Massiv_Amp_all_channels2[4][3])"
plot!()
xlims!(Ref_P2[1][Selection][1] - 50, Ref_P2[1][Selection][2] + 50)


#В зависимости от фильтра и алгоритма рассматривается дельта от реф границ
comparison("T1_Med", "T1_Sq", "CSE", Number_File) #тут по X
stat_all_test("T1_Med", "T1_Med", "CSE", Number_File)
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


Selection = 1
Selection_Edge = []

for Current_chanel in 1:12
    Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
    #Тут Функцию по КАК РАЗ поканально в одной секции
    push!(Selection_Edge, Points_fronts)
end
Value_Left_Edge_All_Mediana, Value_Right_Edge_All_Mediana = Test1_Mediana(Selection_Edge)


Selection = 3
plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
xlims!(Ref_P[1][Selection][1] - 50, Ref_P[1][Selection][2] + 50)
vline!([Value_Left_Edge_All_Mediana, Value_Right_Edge_All_Mediana], color = "purple") #фиолетовый сведение Mediana
vline!([Value_Left_Edge_Filtr_Mediana, Value_Right_Edge_Filtr_Mediana], color = "green") #зелёный сведение Mediana
vline!([Value_Left_Edge_All_Sq, Value_Right_Edge_All_Sq], color = "brown") #коричневый сведение square
vline!([Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq], color = "black") #черный сведение square
Value_Left_Edge_Filtr_Sq



Value_Left_Edge_All_Mediana
Value_Right_Edge_All_Mediana

include("Function_dist.jl")
M_l, M_r = function_Points_fronts_Selection(Massiv_Amp_all_channels, Massiv_Points_channel)
44.5-514.5#-984.5
44.5-83
553.0-514.5
1023.0 - 984.5

M_l[1]
#plot(signal_const.I)
#vline!(M_l, color = ["red"])
#vline!(M_r)
plot(signal_const.I)
vline!([M_l, M_r], color = "red")


My_Edge_P_All_Channel(Massiv_Points_channel, Massiv_Amp_all_channels)
My_Edge_P_One_Channel(Massiv_Points_channel, Massiv_Amp_all_channels, 1)
My_Edge_P(Massiv_Points_channel, Massiv_Amp_all_channels, 1, 1)




#Фильтр, который рассматривает некоторые точки на 12ти отведениях (без "всплесков")
#Вход - границы на всех отведениях
#Выход - границы, разбитые на левую и правую часть с помощью данного фильтра
function Test3(Massiv_Points_channel, Massiv_Amp_all_channels)

mas_left_channel = []
mas_right_channel =[]
M_l, M_r = function_Points_fronts_Selection(Massiv_Amp_all_channels, Massiv_Points_channel)

for j in 1:length(Massiv_Points_channel[1])
    mas_left = []
    mas_right =[]
    #M_l[j]
    for i in 1:12
        left, right = My_Edge_P(Massiv_Points_channel, Massiv_Amp_all_channels, i, j)
        delta_left = abs(M_l[j] - left)
        delta_right = abs(M_r[j] -  right)
       #@info "M_l[$j] - left = $(M_l[j]) - $(left) = $delta_left"
       #@info "M_r[$j] - right = $(M_r[j]) - $(right) = $delta_right"
        if(delta_left < Global_Edge)
            push!(mas_left, left)
        end
        if(delta_right < Global_Edge)
            push!(mas_right, right)
        end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

    end
    push!(mas_left_channel, mas_left)
    push!(mas_right_channel, mas_right)
end

return mas_left_channel, mas_right_channel
end

l, r = Test3(Massiv_Points_channel, Massiv_Amp_all_channels)
l[1][1]
M_l[1]
l[2][1]
M_l[2]
l[3][1]
M_l[3]
l[4][1]
M_l[4]



r[1]
M_r[1]
r[2][1]
M_r[2]

r[3][1]
M_r[3]
r[4][1]
M_r[4]

M_l, M_r = function_Points_fronts_Selection(Massiv_Amp_all_channels, Massiv_Points_channel)
M_l[5]
M_r