include("Markup_function_P.jl")


#Функция составления реферетной разметки для волны Р
#Вход - количество областей поисак P
#Выход - Массив реферетных значений волны P на всём сигнале
function Function_Ref_P(ALL_SELECTION, Referents_by_File)
    Ref_P = []
    
    for Selection in 1:ALL_SELECTION
        k = ([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ]);
        push!(Ref_P, k)
    end
    
    return Ref_P
end

#Функция составления реферетной разметки для QRS
#На вход границы qrs и границы сигнала, на выход все рефенетнаые границы qrs 
#Верно только для искусственнного сигнала
function All_Ref_QRS(signals, start_qrs, end_qrs, start_sig, end_sig)
    #  @info "length(signals) = $(length(signals))"
    #  @info "length(signals) = $(length(signals))"
    #  @info "length(signals) = $(length(signals))"

    Distance = end_sig - start_sig
    dur_qrs = end_qrs - start_qrs
    All_ref_qrs = Int64[]

    push!(All_ref_qrs, start_qrs)
    push!(All_ref_qrs, end_qrs)

    index = start_qrs + Distance #+ 1

    while (index < length(signals))
        push!(All_ref_qrs, index)

        if (index + dur_qrs < length(signals))
            push!(All_ref_qrs, index + dur_qrs)
        end
        #  @info "index = $index"
        index = index + Distance + 1
        #  @info "index + Distance + 1 = $index"
    end
    return All_ref_qrs
end


#Функция, которая ищет точку, которая равноудалена от всех остальных точек
#Вход - Массив точек
#Выход - максимальная дситанция, индекс точки, значение точки
function Min_dist_to_all_points(Massiv_Edge)
    size_left = length(Massiv_Edge)
    Max = []
    for i in 1:size_left
        Now_point = Massiv_Edge[i]
        #@info "Now_point = $Now_point"
        Max_dist = 0
        j = 1
        Index = 0
        Value = 0
        while(j <= size_left)
            dist = abs(Now_point - Massiv_Edge[j])
            #@info "Massiv_Edge[j] =  $(Massiv_Edge[j])"
            if (dist > Max_dist)
                Max_dist = dist
                Index = i
                Value = Now_point
            end
            j = j + 1
        end
        push!(Max, [Max_dist, Index, Value])
    end
    
    sort_massiv_points = sort(Max)[1]
    distance = ma[1]
    index_point = ma[2]
    value_point = ma[3]

   # @info "distance = $distance"
   # @info "index_point = $index_point"
   # @info "value_point = $value_point"

    return distance, index_point, value_point
end


function Mean_value(Massiv_points)
    sums = 0
    size_Massiv_points = length(Massiv_points)
    for nn in 1:size_Massiv_points
        sums = sums + Massiv_points[nn]
    end
    sums
    Sred = sums/size_Massiv_points

    DDist = []
    for nn in 1:size_Massiv_points
        dd = abs(Massiv_points[nn] - Sred)
        Index =  nn
        value = Massiv_points[nn]
        push!(DDist, [dd, Index, value])
    end
    DDist
    sort(DDist)
    di = sort(DDist)[1][1]
    ini = floor(Int64, sort(DDist)[1][2])
    val = floor(Int64, sort(DDist)[1][3])
    return di, ini, val
end



function Test1(Selection_Edge) 
    left = []
    right = []   
    for Selection in 1:12
        push!(left, Selection_Edge[Selection].Left)
        push!(right, Selection_Edge[Selection].Right)
    end
    return left, right
end


function Test2(Selection_Edge)
    Selection = 1
    left = []
    right = []
    Curr_Sel_left = 2
    Curr_Sel_right = 2
    push!(left, Selection_Edge[Selection].Left)
    push!(right, Selection_Edge[Selection].Right)
    for Selection in 2:12
        # @info "abs(left[Selection-1] - left[Selection]) = $(abs(left[Selection-1] - left[Selection-1]))"
        # @info "Sel = $(left[Selection-1])"
         if(abs(left[Curr_Sel_left-1] - Selection_Edge[Selection].Left) < 78)
         push!(left, Selection_Edge[Selection].Left)
         Curr_Sel_left = Curr_Sel_left + 1
         end
         if(abs(right[Curr_Sel_right-1] - Selection_Edge[Selection].Right) < 78)
         push!(right, Selection_Edge[Selection].Right)
         Curr_Sel_right = Curr_Sel_right + 1
         end
     end 
     return left, right
end

function Test1_MV(Selection_Edge)
    Left_Edge_All, Right_Edge_All = Test1(Selection_Edge)
    _, Index_Left_Edge_All, Value_Left_Edge_All_MV = Mean_value(Left_Edge_All)
_, Index_Right_Edge_All, Value_Right_Edge_All_MV = Mean_value(Right_Edge_All)
return Value_Left_Edge_All_MV, Value_Right_Edge_All_MV
end

function Test2_MV(Selection_Edge)
Left_edge_Filtr, Right_edge_Filtr = Test2(Selection_Edge)
_, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MV = Mean_value(Left_edge_Filtr)
_, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MV = Mean_value(Right_edge_Filtr)
return Value_Left_edge_Filtr_MV, Value_Right_edge_Filtr_MV
end

function Test1_MD(Selection_Edge)
Left_Edge_All, Right_Edge_All = Test1(Selection_Edge)
_, Index_Left_Edge_All, Value_Left_Edge_All_MD = Min_dist_to_all_points(Left_Edge_All)
_, Index_Right_Edge_All, Value_Right_Edge_All_MD = Min_dist_to_all_points(Right_Edge_All)
return Value_Left_Edge_All_MD, Value_Right_Edge_All_MD
end

function Test2_MD(Selection_Edge)
    Left_edge_Filtr, Right_edge_Filtr = Test2(Selection_Edge)
    _, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MD = Min_dist_to_all_points(Left_edge_Filtr)
    _, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MD = Min_dist_to_all_points(Right_edge_Filtr)
    return Value_Left_edge_Filtr_MD, Value_Right_edge_Filtr_MD
end

function Delta(Ref_P_L,Ref_P_R, P_L, P_R)
    delta_L = P_L - Ref_P_L
    delta_R = Ref_P_R - P_R
    return delta_L, delta_R
end



function Fin(Name_Data_Base, Number_File)
    channel = 1
    Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, All_left_right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
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

Value_Left_Edge_All_MV, Value_Right_Edge_All_MV = Test1_MV(Selection_Edge)
Value_Left_Edge_Filtr_MV, Value_Right_Edge_Filtr_MV = Test2_MV(Selection_Edge)
Value_Left_Edge_All_MD, Value_Right_Edge_All_MD = Test1_MD(Selection_Edge)
Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = Test2_MD(Selection_Edge) 

Left_p = Ref_P[channel][Selection][1]
Right_p = Ref_P[channel][Selection][2]
#MD
Left_Test_1, Right_Test_1 = Delta(Left_p, Right_p, Value_Left_Edge_All_MD, Value_Right_Edge_All_MD)
#MD
Left_Test_2, Right_Test_2 = Delta(Left_p, Right_p, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD)
return Number_File, Names_files[Number_File], Left_Test_1, Right_Test_1, Left_Test_2, Right_Test_2
end

function function_Points_fronts(Massiv_Amp_all_channels)
    
Selection_Edge = []
for Current_chanel in 1:12
    #Current_chanel = 1
    Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
    #Тут Функцию по КАК РАЗ поканально в одной секции
    push!(Selection_Edge, Points_fronts)
end

Value_Left_Edge_All_MD, Value_Right_Edge_All_MD = Test1_MD(Selection_Edge)
Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = Test2_MD(Selection_Edge) 
return Value_Left_Edge_All_MD, Value_Right_Edge_All_MD,Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD 
end
#=
Selection_Edge = []
for Current_chanel in 1:12
    #Current_chanel = 1
    Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
    #Тут Функцию по КАК РАЗ поканально в одной секции
    push!(Selection_Edge, Points_fronts)
end
=#
#Value_Left_Edge_All_MD, Value_Right_Edge_All_MD = Test1_MD(Selection_Edge)
#Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = Test2_MD(Selection_Edge) 
