#Файл, включающие функции Table_P, save_pictures_p(не реализовано)
include("Function_dist.jl")
using DataFrames

#Функция записи в файл Номер проекта; Имя проекта; дельта левой границы, дельта правой границы, In/out для тест1; дельта левой границы, дельта правой границы, In/out для тест2; 
#Вход: наименование проекта (как хоти его записать в папку Project)
#Выход: NULL
function Table_P(Name_Project)
    Number = Int[] #номер файла
    Name = [] #наименование файла
    delta_left1 = Float64[] #дельта левой границы тест1
    delta_right1 = Float64[] #дельта правой границы тест1
    In_or_Out1 = [] #выходит или нет за референтную разметку
    delta_left2 = Float64[] #дельта левую границы тест2
    delta_right2 = Float64[] #дельта правую границы тест2
    In_or_Out2 = [] #выходит или нет за референтную разметку
    
    i = 1
    while(i <= 125 )
        #@info "i = $i"
        #Нет разметки в этих файлах
        if(i == 67 || i == 70)
            i = i + 1
        end
        #Нет Р в реферетной разметке
        if (i == 10 || i == 18 || i == 45 || i == 52 || i == 57 || i == 89 || i == 92 || i == 93 || i == 100 || i == 111 || i == 120)
            i = i + 1
        end
    
        number_file, names_files, left_test_1, right_test_1, left_test_2, right_test_2 = Comparson_Delta_Edge("CSE", i)
        push!(Number, number_file)
        push!(Name, names_files)
        push!(delta_left1, left_test_1)
        push!(delta_right1, right_test_1)
    
        if(left_test_1 < 0 || right_test_1 < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out1, "Out")
        else
            push!(In_or_Out1, "In")
        end
    
        push!(delta_left2, left_test_2)
        push!(delta_right2, right_test_2)
    
        if(left_test_2 < 0 || right_test_2 < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out2, "Out")
        else
            push!(In_or_Out2, "In")
        end
       
        i = i + 1
    end

    text = DataFrame(Number_File = Number,
    Name_File = Name,
    Delta_Left_1 = delta_left1, 
    Delta_Right_1 = delta_right1,
    In_Out_1 = In_or_Out1, 
    Delta_Left_2 = delta_left2, 
    Delta_Right_2 = delta_right2,
    In_Out_2 = In_or_Out2)
    CSV.write("test/Projects/$(Name_Project).csv", text, delim = ';')
end

# Функция сохраняющая картинки (несделано, так как нужно без ploty(), но без него картинки "некрасивые")
function save_pictures_p(Selection)
    i = 1
    while(i <= 125 )
        @info "i = $i"
        #Нет разметки
        if(i == 67 || i == 70)
            i = i + 1
        end
        #Нет Р в реф разметке
        if (i == 10 || i == 18 || i == 45 || i == 52 || i == 57 || i == 89 || i == 92 || i == 93 || i == 100 || i == 111 || i == 120 )
            i = i + 1
        end

        Name_Data_Base= "CSE";
        Number_File =  i;
        Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
        #Сигнал в виде массива для более удобного поканальной отрисовки
        Massiv_Signal = Sign_Channel(signal_const)
        Comparson_Delta_Edge(Name_Data_Base, Number_File)
        Value_Left_Edge_All_MD, Value_Right_Edge_All_MD, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD, _, _, _, _ = function_Points_fronts(Massiv_Amp_all_channels, Massiv_Points_channel)
        
        @info "Name files = $(Names_files[i])"

        plot_all_channels_const_signal(signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
        xlims!(Ref_P[1][Selection][1]-50, Ref_P[1][Selection][2]+50)
        vline!([Value_Left_Edge_All_MD, Value_Right_Edge_All_MD]) #желтый
        vline!([Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD]) #зелёный

        savefig("pictures_edge_CSE/$(Names_files[i]).png") #Сохранение в папку pictures_edge_CSE

        i = i + 1    
    end
end


#Сравнение TEST2 между Square и MD
#Функция записи в файл Номер проекта; Имя проекта; дельта левой границы, дельта правой границы, In/out для тест1; дельта левой границы, дельта правой границы, In/out для тест2; 
#Вход: наименование проекта (как хоти его записать в папку Project)
#Выход: NULL
function Table_P_Sq(Name_Project)
    Number = Int[] #номер файла
    Name = [] #наименование файла
    delta_left_MD = Float64[] #дельта левой границы тест1
    delta_right_MD = Float64[] #дельта правой границы тест1
    In_or_Out1 = [] #выходит или нет за референтную разметку
    delta_left_Sq = Float64[] #дельта левую границы тест2
    delta_right_Sq = Float64[] #дельта правую границы тест2
    In_or_Out2 = [] #выходит или нет за референтную разметку
    
    i = 1
    while(i <= 125 )
        #@info "i = $i"
        #Нет разметки в этих файлах
        if(i == 67 || i == 70)
            i = i + 1
        end
        #Нет Р в реферетной разметке
        if (i == 10 || i == 18 || i == 45 || i == 52 || i == 57 || i == 89 || i == 92 || i == 93 || i == 100 || i == 111 || i == 120)
            i = i + 1
        end
    
        number_file, names_files, left_MD, right_MD, left_Sq, right_Sq = Comparson_Delta_Edge2("CSE", i)
        push!(Number, number_file)
        push!(Name, names_files)
        push!(delta_left_MD, left_MD)
        push!(delta_right_MD, right_MD)
    
        if(left_MD < 0 || right_MD < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out1, "Out")
        else
            push!(In_or_Out1, "In")
        end
    
        push!(delta_left_Sq, left_Sq)
        push!(delta_right_Sq, right_Sq)
    
        if(left_Sq < 0 || right_Sq < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out2, "Out")
        else
            push!(In_or_Out2, "In")
        end
       
        i = i + 1
    end

    text = DataFrame(Number_File = Number,
    Name_File = Name,
    Delta_Left_MD = delta_left_MD, 
    Delta_Right_MD = delta_right_MD,
    In_Out_MD = In_or_Out1, 
    Delta_Left_Sq = delta_left_Sq, 
    Delta_Right_Sq = delta_right_Sq,
    In_Out_Sq = In_or_Out2)
    CSV.write("test/Projects/$(Name_Project).csv", text, delim = ';')
end




#Сравнение  Square между Test1 и Test2
#Rad**_GlEdge**_Sq_1and2
#Функция записи в файл Номер проекта; Имя проекта; дельта левой границы, дельта правой границы, In/out для тест1; дельта левой границы, дельта правой границы, In/out для тест2; 
#Вход: наименование проекта (как хоти его записать в папку Project)
#Выход: NULL
function Table_P_Sq_1and2(Name_Project)
    Number = Int[] #номер файла
    Name = [] #наименование файла
    delta_left_Sq_1 = Float64[] #дельта левой границы тест1
    delta_right_Sq_1 = Float64[] #дельта правой границы тест1
    In_or_Out1 = [] #выходит или нет за референтную разметку
    delta_left_Sq_2 = Float64[] #дельта левую границы тест2
    delta_right_Sq_2 = Float64[] #дельта правую границы тест2
    In_or_Out2 = [] #выходит или нет за референтную разметку
    
    i = 1
    while(i <= 125 )
        #@info "i = $i"
        #Нет разметки в этих файлах
        if(i == 67 || i == 70)
            i = i + 1
        end
        #Нет Р в реферетной разметке
        if (i == 10 || i == 18 || i == 45 || i == 52 || i == 57 || i == 89 || i == 92 || i == 93 || i == 100 || i == 111 || i == 120)
            i = i + 1
        end
    
        number_file, names_files, left_Sq_1, right_Sq_1, left_Sq_2, right_Sq_2 = Comparson_Delta_Edge3("CSE", i)
        push!(Number, number_file)
        push!(Name, names_files)
        push!(delta_left_Sq_1, left_Sq_1)
        push!(delta_right_Sq_1, right_Sq_1)
    
        if(left_Sq_1 < 0 || right_Sq_1 < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out1, "Out")
        else
            push!(In_or_Out1, "In")
        end
    
        push!(delta_left_Sq_2, left_Sq_2)
        push!(delta_right_Sq_2, right_Sq_2)
    
        if(left_Sq_2 < 0 || right_Sq_2 < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out2, "Out")
        else
            push!(In_or_Out2, "In")
        end
       
        i = i + 1
    end

    text = DataFrame(Number_File = Number,
    Name_File = Name,
    Delta_Left_Sq_1 = delta_left_Sq_1, 
    Delta_Right_Sq_1 = delta_right_Sq_1,
    In_Out_Sq_1 = In_or_Out1, 
    Delta_Left_Sq_2 = delta_left_Sq_2, 
    Delta_Right_Sq_2 = delta_right_Sq_2,
    In_Out_Sq_2 = In_or_Out2)
    CSV.write("test/Projects/$(Name_Project).csv", text, delim = ';')
end

function Table_with_comparison(Obj1, Obj2, Name_Project)#, Name_Data_Base, Number_File)
    Number = Int[] #номер файла
  #  Name = [] #наименование файла
    delta_first_left = [] #дельта левой границы тест1
    delta_first_right = [] #дельта правой границы тест1
    In_or_Out_first = [] #выходит или нет за референтную разметку
    delta_second_left = [] #дельта левую границы тест2
    delta_second_right = [] #дельта правую границы тест2
    In_or_Out_second = [] #выходит или нет за референтную разметку
    
    i = 1

first_left_name = "$(Obj1)_left"
first_right_name = "$(Obj1)_right"
first_Out_In_name = "$(Obj1)_In_Out"
second_left_name = "$(Obj2)_left"
second_right_name = "$(Obj2)_right"
second_Out_In_name = "$(Obj2)_In_Out"

    push!(Number, 0)
    # push!(Name, names_files)
    push!(delta_first_left, first_left_name)
    push!(delta_first_right, first_right_name)
    push!(In_or_Out_first, first_Out_In_name)
    push!(delta_second_left, second_left_name)
    push!(delta_second_right, second_right_name)
    push!(In_or_Out_second, second_Out_In_name)


    while(i <= 125 ) #для CSE
        #@info "i = $i"
        #Нет разметки в этих файлах
        if(i == 67 || i == 70)
            i = i + 1
        end
        #Нет Р в реферетной разметке
        if (i == 10 || i == 18 || i == 45 || i == 52 || i == 57 || i == 89 || i == 92 || i == 93 || i == 100 || i == 111 || i == 120)
            i = i + 1
        end
    
        delta_left_1, delta_right_1, delta_left_2, delta_right_2 = comparison(Obj1, Obj2, "CSE", i)
        #number_file, names_files, left_Sq_1, right_Sq_1, left_Sq_2, right_Sq_2 = Comparson_Delta_Edge3("CSE", i)
        push!(Number, i)
       # push!(Name, names_files)
        push!(delta_first_left, delta_left_1)
        push!(delta_first_right, delta_right_1)
    
        if(delta_left_1 < 0 || delta_right_1 < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out_first, "Out")
        else
            push!(In_or_Out_first, "In")
        end
    
        push!(delta_second_left, delta_left_2)
        push!(delta_second_right, delta_right_2)
    
        if(delta_left_2 < 0 || delta_right_2 < 0) #Проверка внутри или вне реферетной разметки
            push!(In_or_Out_second, "Out")
        else
            push!(In_or_Out_second, "In")
        end
       
        i = i + 1
    end

    text = DataFrame(Number_File = Number,
   # Name_File = Name,
    first_left = delta_first_left, 
    first_right = delta_first_right,
    In_Out_1 = In_or_Out_first, 
    second_left = delta_second_left, 
    second_right = delta_second_right,
    In_Out_2 = In_or_Out_second)
    
    CSV.write("test/Projects2/$(Name_Project).csv", text, delim = ';')
end