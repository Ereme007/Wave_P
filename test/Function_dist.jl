#Файл, содержащий функции для реферетной разметки QRS & P; Фильтр границ, которые нашли с помощью алгоритма (Test1, Test2); Способы сведения границ (Min_dist_to_all_points & Mean_value)
include("Markup_function_P.jl")
include(".env")

#Функция составления реферетной разметки для волны Р
#Вход - количество областей поисак P
#Выход - Массив реферетных значений волны P на всём сигнале
function Function_Ref_P(ALL_SELECTION, Referents_by_File)
    Ref_P = []
    
    for Selection in 1:ALL_SELECTION
        k = ([Referents_by_File.P_onset - 1 + (Selection - 1) * (Referents_by_File.iend - Referents_by_File.ibeg + 1), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg + 1) - 1 ]);
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
#Выход - Максимальная дистанция, индекс точки, значение точки
function Min_dist_to_all_points(Massiv_Edge)
    size_left = length(Massiv_Edge)
    Max = []
    for i in 1:size_left
        Now_point = Massiv_Edge[i]
        #@info "Now_point = $Now_point"
        Max_dist = -Inf
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
    distance = sort_massiv_points[1]
    index_point = sort_massiv_points[2]
    value_point = sort_massiv_points[3]

   # @info "distance = $distance"
   # @info "index_point = $index_point"
   # @info "value_point = $value_point"

    return distance, index_point, value_point
end



function Square_dist(Massiv_Edge)
    size_left = length(Massiv_Edge)
    Max = []
    for i in 1:size_left
        Now_point = Massiv_Edge[i]
        #@info "Now_point = $Now_point"
        Max_dist = -Inf
        j = 1
        Index = 0
        Value = 0
        dist = 0
        while(j <= size_left)
            dist = dist + abs(Now_point - Massiv_Edge[j])*abs(Now_point - Massiv_Edge[j])
            #@info "Massiv_Edge[j] =  $(Massiv_Edge[j])"
            #if (dist > Max_dist)
            #    Max_dist = dist
            #    Index = i
            #    Value = Now_point
            #   end
            j = j + 1
        end
        if (dist > Max_dist)
           # @info "dist = $dist"
            Max_dist = dist
            Index = i
            Value = Now_point
        end
        #@info "Max_dist = $Max_dist"
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


#Не использую
#Функция по нахождению среднего значение, потом поиска ближайшей точки для данного числа
#Вход - Массив точек
#Выход - Максимальная дистанция, индекс точки, значение точки
function Mean_value(Massiv_points)
    sums = 0
    size_Massiv_points = length(Massiv_points)
    
    for i in 1:size_Massiv_points
        sums = sums + Massiv_points[i]
    end
    
    Average_value = sums/size_Massiv_points
    Massiv_dist_ind_val = []
    
    for i in 1:size_Massiv_points
        distance = abs(Massiv_points[i] - Average_value)
        Index = i
        value = Massiv_points[i]
        push!(Massiv_dist_ind_val, [distance, Index, value])
    end

    sort_massiv_points = sort(Massiv_dist_ind_val)
    distance = sort_massiv_points[1][1]
    index_point = floor(Int64, sort_massiv_points[1][2])
    value_point = floor(Int64, sort_massiv_points[1][3])

    return distance, index_point, value_point
end


#Фильтр, который рассматривает все точки на 12ти отведениях
#Вход - границы на всех отведениях
#Вызод - границы, разбитые на левую и правую часть с помощью данного фильтра
function Test1(Selection_Edge) 
    left = []
    right = []   
    
    for Selection in 1:12
        push!(left, Selection_Edge[Selection].Left)
        push!(right, Selection_Edge[Selection].Right)
    end
    
    return left, right
end

#Фильтр, который рассматривает некоторые точки на 12ти отведениях (без "всплесков")
#Вход - границы на всех отведениях
#Выход - границы, разбитые на левую и правую часть с помощью данного фильтра
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
         if(abs(left[Curr_Sel_left-1] - Selection_Edge[Selection].Left) < Global_Edge)
            push!(left, Selection_Edge[Selection].Left)
            Curr_Sel_left = Curr_Sel_left + 1
         end
         
         if(abs(right[Curr_Sel_right-1] - Selection_Edge[Selection].Right) < Global_Edge)
            push!(right, Selection_Edge[Selection].Right)
            Curr_Sel_right = Curr_Sel_right + 1
         end
     end 
     
     return left, right
end

#Функции вычисления Дельта для разных филтров и алгоритмов
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

function Test1_Square(Selection_Edge)
    Left_edge_Filtr, Right_edge_Filtr = Test1(Selection_Edge)
    _, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MD = Square_dist(Left_edge_Filtr)
    _, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MD = Square_dist(Right_edge_Filtr)

    return Value_Left_edge_Filtr_MD, Value_Right_edge_Filtr_MD
end

function Test2_Square(Selection_Edge)
    Left_edge_Filtr, Right_edge_Filtr = Test2(Selection_Edge)
    _, Index_Left_edge_Filtr, Value_Left_edge_Filtr_MD = Square_dist(Left_edge_Filtr)
    _, Index_Right_edge_Filtr, Value_Right_edge_Filtr_MD = Square_dist(Right_edge_Filtr)

    return Value_Left_edge_Filtr_MD, Value_Right_edge_Filtr_MD
end

#Функция вычисления Дельта граны от реферетной границы
#Вход: Реферетные значения левой/правой границы (Ref_P_L/Ref_P_R), найденная левая/правая граница (P_L/P_R)
#Выход:погрешность для левой/правой границы (delta_L/delta_R)
function Delta(Ref_P_L, Ref_P_R, P_L, P_R)
    delta_L = P_L - Ref_P_L
    delta_R = Ref_P_R - P_R

    return delta_L, delta_R
end


#Функция, которая находит для данного файла дельта границ для 2х фильтров метода сведения MD (от MV отказались)
#Вход: Имя базы данных(Name_Data_Base), номер файла(Number_File)
#Выход: номер файла(Number_File), имя файла (Names_files[Number_File]), дельта для левой/правой границы для Теста1 (Left_Test_1/Right_Test_1), дельта для левой/правой границы для Теста2 (Left_Test_2/Right_Test_2)
function Comparson_Delta_Edge(Name_Data_Base, Number_File)
    channel = 1 #Здесь не имеет значение
    Names_files, signal_const, _, _, _, _, Ref_P, _, Massiv_Amp_all_channels, Massiv_Points_channel, _ = all_the(Name_Data_Base, Number_File)
    #Сигнал в виде массива для более удобного поканальной отрисовки
    Massiv_Signal = Sign_Channel(signal_const)
    
    Selection = 2 #Здесь не имеет значение, но по итогу рассматриваем на 3ем отсеке (все отсеки между собой одинаковы, кроме первого)
    Selection_Edge = []
    
    for Current_chanel in 1:12
        Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
        #Тут Функцию по КАК РАЗ поканально в одной секции
        push!(Selection_Edge, Points_fronts)
    end

    #Value_Left_Edge_All_MV, Value_Right_Edge_All_MV = Test1_MV(Selection_Edge) #отказались
    #Value_Left_Edge_Filtr_MV, Value_Right_Edge_Filtr_MV = Test2_MV(Selection_Edge) #отказались
    Value_Left_Edge_All_MD, Value_Right_Edge_All_MD = Test1_MD(Selection_Edge)
    Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = Test2_MD(Selection_Edge) 

    Left_p = Ref_P[channel][Selection][1]
    Right_p = Ref_P[channel][Selection][2]

    #MD All
    Left_Test_1, Right_Test_1 = Delta(Left_p, Right_p, Value_Left_Edge_All_MD, Value_Right_Edge_All_MD)
    #MD Filter
    Left_Test_2, Right_Test_2 = Delta(Left_p, Right_p, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD)

    #MV All отказались
    #Left_Test_1_mv, Right_Test_1_mv = Delta(Left_p, Right_p, Value_Left_Edge_All_MV, Value_Right_Edge_All_MV) #отказались
    #MV Filter отказались
    #Left_Test_2_mv, Right_Test_2_mv = Delta(Left_p, Right_p, Value_Left_Edge_Filtr_MV, Value_Right_Edge_Filtr_MV) отказались

    return Number_File, Names_files[Number_File], Left_Test_1, Right_Test_1, Left_Test_2, Right_Test_2
end


function Comparson_Delta_Edge2(Name_Data_Base, Number_File)
    channel = 1 #Здесь не имеет значение
    Names_files, signal_const, _, _, _, _, Ref_P, _, Massiv_Amp_all_channels, Massiv_Points_channel, _ = all_the(Name_Data_Base, Number_File)
    #Сигнал в виде массива для более удобного поканальной отрисовки
    Massiv_Signal = Sign_Channel(signal_const)
    
    Selection = 2 #Здесь не имеет значение, но по итогу рассматриваем на 3ем отсеке (все отсеки между собой одинаковы, кроме первого)
    Selection_Edge = []
    
    for Current_chanel in 1:12
        Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
        #Тут Функцию по КАК РАЗ поканально в одной секции
        push!(Selection_Edge, Points_fronts)
    end

    #Value_Left_Edge_All_MV, Value_Right_Edge_All_MV = Test1_MV(Selection_Edge) #отказались
    #Value_Left_Edge_Filtr_MV, Value_Right_Edge_Filtr_MV = Test2_MV(Selection_Edge) #отказались
    Value_Left_Edge_All_MD, Value_Right_Edge_All_MD = Test2_Square(Selection_Edge)
    Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = Test2_MD(Selection_Edge) 

    Left_p = Ref_P[channel][Selection][1]
    Right_p = Ref_P[channel][Selection][2]

    #MD All
   # Left_Test_1, Right_Test_1 = Delta(Left_p, Right_p, Value_Left_Edge_All_MD, Value_Right_Edge_All_MD)
    #MD Filter
    Left_Test_2, Right_Test_2 = Delta(Left_p, Right_p, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD)

    Left_Sq, Right_Sq = Delta(Left_p, Right_p, Value_Left_Edge_All_MD, Value_Right_Edge_All_MD)

    #MV All отказались
    #Left_Test_1_mv, Right_Test_1_mv = Delta(Left_p, Right_p, Value_Left_Edge_All_MV, Value_Right_Edge_All_MV) #отказались
    #MV Filter отказались
    #Left_Test_2_mv, Right_Test_2_mv = Delta(Left_p, Right_p, Value_Left_Edge_Filtr_MV, Value_Right_Edge_Filtr_MV) отказались

    return Number_File, Names_files[Number_File], Left_Test_2, Right_Test_2, Left_Sq, Right_Sq
end




function Comparson_Delta_Edge3(Name_Data_Base, Number_File)
    channel = 1 #Здесь не имеет значение
    Names_files, signal_const, _, _, _, _, Ref_P, _, Massiv_Amp_all_channels, Massiv_Points_channel, _ = all_the(Name_Data_Base, Number_File)
    #Сигнал в виде массива для более удобного поканальной отрисовки
    Massiv_Signal = Sign_Channel(signal_const)
    
    Selection = 2 #Здесь не имеет значение, но по итогу рассматриваем на 3ем отсеке (все отсеки между собой одинаковы, кроме первого)
    Selection_Edge = []
    
    for Current_chanel in 1:12
        Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
        #Тут Функцию по КАК РАЗ поканально в одной секции
        push!(Selection_Edge, Points_fronts)
    end

    #Value_Left_Edge_All_MV, Value_Right_Edge_All_MV = Test1_MV(Selection_Edge) #отказались
    #Value_Left_Edge_Filtr_MV, Value_Right_Edge_Filtr_MV = Test2_MV(Selection_Edge) #отказались
    Value_Left_Edge_All_Sq, Value_Right_Edge_All_Sq = Test1_Square(Selection_Edge)
    Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq = Test2_Square(Selection_Edge) 

    Left_p = Ref_P[channel][Selection][1]
    Right_p = Ref_P[channel][Selection][2]

    #MD All
   # Left_Test_1, Right_Test_1 = Delta(Left_p, Right_p, Value_Left_Edge_All_MD, Value_Right_Edge_All_MD)
    #MD Filter

    Left_Sq_Test_1, Right_Sq_Test_1 = Delta(Left_p, Right_p, Value_Left_Edge_All_Sq, Value_Right_Edge_All_Sq)

    Left_Sq_Test_2, Right_Sq_Test_2 = Delta(Left_p, Right_p, Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq)
    #MV All отказались
    #Left_Test_1_mv, Right_Test_1_mv = Delta(Left_p, Right_p, Value_Left_Edge_All_MV, Value_Right_Edge_All_MV) #отказались
    #MV Filter отказались
    #Left_Test_2_mv, Right_Test_2_mv = Delta(Left_p, Right_p, Value_Left_Edge_Filtr_MV, Value_Right_Edge_Filtr_MV) отказались

    return Number_File, Names_files[Number_File], Left_Sq_Test_1, Right_Sq_Test_1, Left_Sq_Test_2, Right_Sq_Test_2
end


#Функция, выдающая значение границ для двух фильтров метода сведения MD
#Вход: Массив Амплитуд (Massiv_Amp_all_channels), Массив Точек (Massiv_Points_channel)
#Выход: Значение левой/правой границы для фильтра 1 и фильтра 2 (All & Filtr)
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
   # @info "Value_Right_Edge_Filtr_MD = $Value_Right_Edge_Filtr_MD"
    Value_Left_Edge_All_Sq, Value_Right_Edge_All_Sq = Test1_Square(Selection_Edge)
    Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq = Test2_Square(Selection_Edge)
    return Value_Left_Edge_All_MD, Value_Right_Edge_All_MD, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD, Value_Left_Edge_All_Sq, Value_Right_Edge_All_Sq, Value_Left_Edge_Filtr_Sq, Value_Right_Edge_Filtr_Sq
end


function My_Edge_P_All_Channel(All_points, Massiv_Amp)
    size = length(All_points[1])
    Left_and_Right_All_Channel = []
    
    for channel in 1:12
        Left_and_Right = []

        for i in 1:size
            Left_index = floor(Int64, Massiv_Amp[channel][i][2])
            Left = All_points[channel][i][Left_index]
        
            Right_index = floor(Int64, Massiv_Amp[channel][i][3])
            Right = All_points[channel][i][Right_index]
        
            push!(Left_and_Right, [Left, Right])
        end
    
        push!(Left_and_Right_All_Channel, Left_and_Right)
    end
    
    return Left_and_Right_All_Channel
end


function My_Edge_P_One_Channel(All_points, Massiv_Amp, channel)
    Left_and_Right = My_Edge_P_All_Channel(All_points, Massiv_Amp)

    return Left_and_Right[channel]
end


function My_Edge_P(All_points, Massiv_Amp, channel, selection)
    Edge = My_Edge_P_One_Channel(All_points, Massiv_Amp, channel)
    
    return Edge[selection]
end


function squear_edge_P(Massiv_Points_channel, Massiv_Amp_all_channels)
    #Le_Ri = My_Edge_P(Massiv_Points_channel, Massiv_Amp_all_channels, Channel, Selection)
    size = length(Massiv_Points_channel[1])
    Left = []
    Right = []
    for Current_Selection in 1:size
        for Current_Channel in 1:12
            current_left =  My_Edge_P(Massiv_Points_channel, Massiv_Amp_all_channels, Current_Channel, Current_Selection)[1]
            push!(Left, current_left)

            current_right =  My_Edge_P(Massiv_Points_channel, Massiv_Amp_all_channels, Current_Channel, Current_Selection)[2]
            push!(Right, current_right)
        end
    end

    return Left, Right
end