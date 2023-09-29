module Module_Amp_CSV
    using CSV
    using DataFrames

    include("Module_Get_Signal.jl")
    import .Module_Get_Signal as m_get_signal

    include("Module_Fronts.jl")
    import .Module_Fronts as m_fronts

    include("Module_Edge.jl")
    import .Module_Edge as m_edge

    function func(BaseName, Name_Project)
        Number = Int[]
         Av_or_Not = [] 
         amp = [] 

        count_Out = 0
       # left, right, Out_In = m_st.Statistic(Left_Right_Edge, Left_Right_Ref_P)
        push!(Number, 0)
        push!(Av_or_Not, "available or not available")
        push!(amp, "AMP")

    i = 1
        while(i <= 125 ) #для CSE
            none = 1
            @info "i = $i"
            #Нет разметки в этих файлах
            if(i == 67 || i == 70)
                i = i + 1
            end
            #Нет Р в реферетной разметке
            if (i == 10 || i == 18 || i == 45 || i == 52 || i == 57 || i == 89 || i == 92 || i == 93 || i == 100 || i == 111 || i == 120)
                none = 0
            end
    #Defenition_Fronts или Three
            Names_files3, signals_channel3, const_signal3,  Frequency3, koef3, Ref_qrs3, Ref_P3, start_signal3, end_signal3 = m_get_signal.Signal_all_channels(BaseName, i)
            Massiv_Amp_all_channels3, Massiv_Points_channel3 = m_fronts.Defenition_Fronts(signals_channel3, Frequency3, koef3, Ref_qrs3, start_signal3, end_signal3)
            left_right_one_selection3 = m_edge.function_edge(Massiv_Amp_all_channels3, Massiv_Points_channel3)
          #  left, right, Out_In = m_statistics.Statistic(left_right_one_selection3[3], Ref_P3[3])
    #        
            push!(Number, i)
            push!(Av_or_Not, none)        
            push!(amp, Massiv_Amp_all_channels3[1][3][1])
            i = i + 1
        end
    #
    #
        text = DataFrame(Number_File = Number,
       # Name_File = Name,
       Available_or_Not = Av_or_Not, 
        Amp = amp)
    #    
        CSV.write("test/Stat_Amp/$(Name_Project).csv", text, delim = ';')
    #
    end

    export func
end