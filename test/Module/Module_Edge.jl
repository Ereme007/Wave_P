module Module_Edge
    include("Functions_for_Module_Edge.jl")
    include("env.jl")
    include("Markup_function_P.jl")
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

    export function_edge
end