module Module_Edge
    Global_Edge = 48

    #Главная функция
    #суть - вывод седённых границ. План - все границы запустить в функции mediana, после чего отбросить всплески, после чего метод средних квадратов. Это и есть сведение границ
    #Функция, которая на вход:

    function function_edge(Mass_amp, Mass_points)
        size = length(Mass_amp[1]) #Кол-во сегментов в сигнале
        mass_by_selection = []

        for Curr_Selection in 1:size
            Selection_Edge = []
 
            for Current_chanel in 1:12
                Points_fronts = Mark_Amp_Left_Right(Mass_amp[Current_chanel][Curr_Selection], Mass_points[Current_chanel][Curr_Selection])
                #Тут Функцию по КАК РАЗ поканально в одном сегменте
                push!(Selection_Edge, Points_fronts)
            end
            #Фронты на текущей области на всех сегментах

            Left_Edge, Right_Edge = Edge_Left_Right(Selection_Edge) #разбиение на левуие и правые границы
           #Selection_Edge, left_Mediana, right_Mediana = Mediana_Left_Right(Mass_amp, Mass_points, Curr_Selection)
    
           #Определение левой и правой границы медианы
           Value_Left_Edge_Mediana = Mediana(Left_Edge) 
           Value_Right_Edge_Mediana = Mediana(Right_Edge)

           #Фильтр по левой и правой границе медианы (убираем выбросы)
            left_filtr, right_filtr = Filter_Mediana(Selection_Edge, Value_Left_Edge_Mediana, Value_Right_Edge_Mediana)
    
            #Оставшиеся точки(границы) накладываем фильтр Среднекваратичное расстояние
            left_Sq, right_Sq = Sq_Filtr(left_filtr, right_filtr)
            push!(mass_by_selection, [left_Sq, right_Sq])
        end
    
        return mass_by_selection #Левая и правая граница на текущем сегменте
    end

    #Второстепенные функции
    #Фильтр, который рассматривает все точки на 12ти отведениях и группирует на левые и правые с помощью Mark_Amp_Left_Right
    #Вход - границы на всех отведениях (Selection_Edge)
    #Вызод - границы, разбитые на левую и правую часть (left и right)
    function Edge_Left_Right(Selection_Edge) 
        left = []
        right = []   
        
        for Selection in 1:12
            push!(left, Selection_Edge[Selection].Left)
            push!(right, Selection_Edge[Selection].Right)
        end
        
        return left, right
    end
    
    
    
    #Функция медиана
    #Вход: массив границ (Massiv_Edge)
    #Выход: Значение точки по алгоритму медианы (Value)
    function Mediana(Massiv_points)
        size_Massiv_points = length(Massiv_points)
        Sort_massiv_points = sort(Massiv_points) 
        middle = floor(Int64, (size_Massiv_points / 2))
        
        if (iseven(size_Massiv_points)) #Проверка на четнось. Четное = true, нечетное = false
            Value = (Sort_massiv_points[middle + 1] + Sort_massiv_points[middle])/2
        else
            Value = Sort_massiv_points[middle + 1]
        end
    
        return Value
    end
    
    
    #Фильтр, который оставляет только те границы на данном сегменте, которые не дальше чем Global_Edge от медианы (правая граница от правой медианы, аналогично с левой стороной)
    #Вход - Точки на текущем сегменте(Selection_Edge), левая медиана(Left), правая медиана(Right)
    #Выход - выборка границ, левые и правые (которые расстояние к левой/правой медиане, не более чем Global_Edge из env.jl)
    function Filter_Mediana(Selection_Edge, Left, Right)
        left = []
        right = []
    
            for Selection in 1:12
                 if(abs(Selection_Edge[Selection].Left - Left) < Global_Edge)
                    push!(left, Selection_Edge[Selection].Left)
                 end
                 
                 if(abs(Selection_Edge[Selection].Right - Right) < Global_Edge)
                    push!(right, Selection_Edge[Selection].Right)
                 end
             end 
             
             return left, right
        end
    
    
    #Применение фильтра Square_dist для левой и правой грницы
    #На вход: левые/правые границы (left/right)
    #На выход: Значение (по времени) точки левой и правой границы (Value_Left_Edge_Filtr и Value_Right_Edge_Filtr)
    function Sq_Filtr(left, right)
        _, Index_Left_Edge_Filtr, Value_Left_Edge_Filtr = Square_dist(left)
        _, Index_Right_Edge_Filtr, Value_Right_Edge_Filtr = Square_dist(right)
        
        return Value_Left_Edge_Filtr, Value_Right_Edge_Filtr
    end
    
        
    #Функция среднее квадратичное расстояние
    #Вход: массив границ (Massiv_Edge)
    #Выход: Наименьшее квадратичное расстояние (distance), индекс найденной точки (index_point), значение найденой точки (value_point)
    function Square_dist(Massiv_Edge)
        size_left = length(Massiv_Edge)
        Max = []
    
        for i in 1:size_left
            Now_point = Massiv_Edge[i]
            Max_dist = -Inf
            j = 1
            Index = 0
            Value = 0
            dist = 0
        
            while(j <= size_left)
                dist = dist + abs(Now_point - Massiv_Edge[j])*abs(Now_point - Massiv_Edge[j])
                j = j + 1
            end
            if (dist > Max_dist)
                Max_dist = dist
                Index = i
                Value = Now_point
            end
        
            push!(Max, [Max_dist, Index, Value])
        end
        
        sort_massiv_points = sort(Max)[1]
        distance = sort_massiv_points[1]
        index_point = sort_massiv_points[2]
        value_point = sort_massiv_points[3]
    
        return distance, index_point, value_point
    end
    
    mutable struct Markup_Left_Right_Front_Wave_P_amp_2
        Amp::Float64
        Left::Int     
        Right::Int
    
    
        function Markup_Left_Right_Front_Wave_P_amp_2()
            new(0, 0, 0)
        end
    
        function Markup_Left_Right_Front_Wave_P_amp_2(amp, left, right)
            new(amp, left, right)
        end
    end
    
    markup_front_wave_P_amp = Dict{String, Markup_Left_Right_Front_Wave_P_amp_2}()
    
    #= Функция, которая переводит массив Massiv_Amp_all_channels в Amp Left Right (Points_fronts)=#
    #Вход: Массив амплитуд и массив точек
    #Выход: Структура, у которой поля Amp Left Right
    function Mark_Amp_Left_Right(massiv_amp_all_channels, massiv_points_channel)
        Current_amp = massiv_amp_all_channels
        Amp_extrem = Current_amp[1];
        Left_extrem = floor(Int64, Current_amp[2]);
        Right_extrem =  floor(Int64, Current_amp[3]);
        Current_points = massiv_points_channel
        Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
        
        return Points_fronts
    end

    export function_edge
end