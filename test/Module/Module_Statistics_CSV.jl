module Module_Statistics_CSV
    using CSV
    using DataFrames

    include("Module_Get_Signal.jl")
    import .Module_Get_Signal as m_get_signal

    include("Module_Fronts.jl")
    import .Module_Fronts as m_fronts

    include("Module_Edge.jl")
    import .Module_Edge as m_edge

    include("Module_Statistics.jl")
    import .Module_Statistics as m_statistics

    function func(BaseName, Name_Project)
        Number = Int[]
        delta_left = [] #дельта левой границы тест1
        delta_right = [] #дельта правой границы тест1
        In_or_Out = [] #выходит или нет за референтную разметку

        count_Out = 0
       # left, right, Out_In = m_st.Statistic(Left_Right_Edge, Left_Right_Ref_P)
        push!(Number, 0)
        push!(delta_left, "left_name")
        push!(delta_right, "right_name")
        push!(In_or_Out, "Out_In_name")

    i = 1
        while(i <= 125 ) #для CSE
            @info "i = $i"
            #Нет разметки в этих файлах
            if(i == 67 || i == 70)
                i = i + 1
            end
            #Нет Р в реферетной разметке
            if (i == 10 || i == 18 || i == 45 || i == 52 || i == 57 || i == 89 || i == 92 || i == 93 || i == 100 || i == 111 || i == 120)
                i = i + 1
            end
    ##Defenition_Fronts или Three
            Names_files3, signals_channel3, const_signal3,  Frequency3, koef3, Ref_qrs3, Ref_P3, start_signal3, end_signal3 = m_get_signal.Signal_all_channels(BaseName, i)
            Massiv_Amp_all_channels3, Massiv_Points_channel3 = m_fronts.Defenition_Fronts(signals_channel3, Frequency3, koef3, Ref_qrs3, start_signal3, end_signal3)
            left_right_one_selection3 = m_edge.function_edge(Massiv_Amp_all_channels3, Massiv_Points_channel3)
            left, right, Out_In = m_statistics.Statistic(left_right_one_selection3[3], Ref_P3[3])
    #        
            push!(Number, i)
            push!(delta_left, left)
            push!(delta_right, right)
            push!(In_or_Out, Out_In)

            if(Out_In == 0)
                count_Out = count_Out + 1
            end

            i = i + 1
        end
        push!(Number, 1000)
        push!(delta_left, "-")        
        push!(delta_right, "-")
        push!(In_or_Out, count_Out)   
    #
    #
        text = DataFrame(Number_File = Number,
       # Name_File = Name,
        first_left = delta_left, 
        first_right = delta_right,
        In_Out_1 = In_or_Out)
    #    
        CSV.write("test/Stat_Edge/$(Name_Project).csv", text, delim = ';')
    #
    end

    export func
end