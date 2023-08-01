include("Function_dist.jl")
using DataFrames

function Table_P(Name_Project)
    Number = Int[] #номер файла
    Name = [] #наименование файла
    delta_left1 = Float64[] #дельта лев границы тест1
    delta_right1 = Float64[] #дельта пр границы тест1
    In_or_Out1 = [] #выходит или нет за реф разметку
    delta_left2 = Float64[] #дельта лев границы тест2
    delta_right2 = Float64[] #дельта пр границы тест2
    In_or_Out2 = [] #выходит или нет за реф разметку
    
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
    
        number_file, names_files, left_test_1, right_test_1, left_test_2, right_test_2 = Fin("CSE", i)
        push!(Number, number_file)
        push!(Name, names_files)
        push!(delta_left1, left_test_1)
        push!(delta_right1, right_test_1)
    
        if(left_test_1 < 0 || right_test_1 < 0)
            push!(In_or_Out1, "Out")
        else
            push!(In_or_Out1, "In")
        end
    
        push!(delta_left2, left_test_2)
        push!(delta_right2, right_test_2)
    
        if(left_test_2 < 0 || right_test_2 < 0)
            push!(In_or_Out2, "Out")
        else
            push!(In_or_Out2, "In")
        end
       
    
        i = i+1
    end

    ab = DataFrame(Number_File = Number,
    Name_File = Name,
    Delta_Left_1 = delta_left1, 
    Delta_Right_1 = delta_right1,
    In_Out_1 = In_or_Out1, 
    Delta_Left_2 = delta_left2, 
    Delta_Right_2 = delta_right2,
    In_Out_2 = In_or_Out2)
  #  CSV.write("test/Projects/$(Name_Project).csv", ab, delim = ';')

 
end


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
        Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, All_left_right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
        #Сигнал в виде массива для более удобного поканальной отрисовки
        Massiv_Signal = Sign_Channel(signal_const)
        Fin(Name_Data_Base, Number_File)
        Value_Left_Edge_All_MD, Value_Right_Edge_All_MD, Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD = function_Points_fronts(Massiv_Amp_all_channels)
        
        @info "Name files = $(Names_files[i])"

        plot_all_channels_const_signal(Name_Data_Base, Number_File, signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File)
        xlims!(Ref_P[1][Selection][1]-50, Ref_P[1][Selection][2]+50)
        vline!([Value_Left_Edge_All_MD, Value_Right_Edge_All_MD]) #желтый
        vline!([Value_Left_Edge_Filtr_MD, Value_Right_Edge_Filtr_MD]) #зелёный

        savefig("pictures_edge_CSE/$(Names_files[i]).png")

        i = i+1    
    end
end