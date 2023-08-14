include("Function_dist.jl")

function function_Points_fronts(Massiv_Amp_all_channels, Massiv_Points_channel)
    Selection = 3
    Selection_Edge = []

    for Current_chanel in 1:12
        Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
        #Тут Функцию по КАК РАЗ поканально в одной секции
        push!(Selection_Edge, Points_fronts)
    end

    Value_Left_Edge_All_MD, Value_Right_Edge_All_MD = Test1_MD(Selection_Edge)
    Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = Test2_MD(Selection_Edge) 
    new_left, new_right = New_Test(Selection_Edge)
    return Value_Left_Edge_All_MD, Value_Right_Edge_All_MD, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD, new_left, new_right
end


function Test2_MD(Selection_Edge)
    Left_edge_Filtr, Right_edge_Filtr = Test2(Selection_Edge)
    _, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MD = Min_dist_to_all_points(Left_edge_Filtr)
    _, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MD = Min_dist_to_all_points(Right_edge_Filtr)

    return Value_Left_edge_Filtr_MD, Value_Right_edge_Filtr_MD
end


function New_Test(Selection_Edge)
    Left_edge_Filtr, Right_edge_Filtr = Test2(Selection_Edge)
    _, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MD = Square_dist(Left_edge_Filtr)
    _, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MD = Square_dist(Right_edge_Filtr)

    return Value_Left_edge_Filtr_MD, Value_Right_edge_Filtr_MD
end


function Square_dist(Massiv_Edge)
    size_left = length(Massiv_Edge)
    Max = []
    for i in 1:size_left
        Now_point = Massiv_Edge[i]
        #@info "Now_point = $Now_point"
        Max_dist = 0
        j = 1
        Index = 0
        Value = 0
        dist = 0
        while(j <= size_left)
            dist = dist + abs(Now_point - Massiv_Edge[j])*abs(Now_point - Massiv_Edge[j])
            @info "Massiv_Edge[j] =  $(Massiv_Edge[j])"
            #if (dist > Max_dist)
            #    Max_dist = dist
            #    Index = i
            #    Value = Now_point
            #   end
            j = j + 1
        end
        if (dist > Max_dist)
            #@info "dist = $dist"
            Max_dist = dist
            Index = i
            Value = Now_point
        end
        @info "Max_dist = $Max_dist"
        push!(Max, [Max_dist, Index, Value])
    end
    
    sort_massiv_points = sort(Max)[1]
    distance = sort_massiv_points[1]
    index_point = sort_massiv_points[2]
    value_point = sort_massiv_points[3]

   # @info "distance = $distance"
   # @info "index_point = $index_point"
   # @info "value_point = $value_point"

    return distance, index_point, value_point
end


ma = [1, 1, 1, 5, 10]
Square_dist(ma)
Square_dist(only_left)
Name_Data_Base, Number_File = "CSE", 32
#Определённое отведение (channel)
channel = 1

#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter, all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
#Сигнал в виде массива для более удобного поканальной отрисовки
Massiv_Signal = Sign_Channel(signal_const)

Selection = 3

Selection_Edge = []
for Current_chanel in 1:12
    #Current_chanel = 1
    Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
    #Тут Функцию по КАК РАЗ поканально в одной секции
    push!(Selection_Edge, Points_fronts)
end

Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = New_Test(Selection_Edge)

Selection = 3
Selection_Edge = []

for Current_chanel in 1:12
    Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
    #Тут Функцию по КАК РАЗ поканально в одной секции
    push!(Selection_Edge, Points_fronts)
end
only_left = []
for i in 1:12
    push!(only_left, Selection_Edge[i].Left)
end

only_left

Selection_Edge
new_left, new_right = New_Test(Selection_Edge)
Selection_Edge[1].Left





Left_edge_Filtr, Right_edge_Filtr = Test1(Selection_Edge)
_, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MD = Min_dist_to_all_points(Left_edge_Filtr)
_, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MD = Min_dist_to_all_points(Right_edge_Filtr)
Left_edge_Filtr
Right_edge_Filtr