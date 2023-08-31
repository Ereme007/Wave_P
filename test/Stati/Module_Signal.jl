module Module_Signal
    using CSV, DataFrames, Dates

    include("../../src/readfiles.jl")
    include("Markup_function_P.jl")
    include("env.jl")   
    include("Function_P.jl")
    include("Function_P_file2.jl")


    #Определение сигнала
    #Вход: Имя базы данных(BaseName), порядковый номер (N)
    #Выход: Список файлов (Names_files), Первоначальный сигнал (Signal_const), Сигнал без QRS (signal_without_qrs), Сигнал my_butter (all_graph_butter), Сигнал дифференцированный (all_graph_diff), 
    #Реферетная разметка QRS (Ref_qrs), Рефертеная разметка Р (Ref_P), Область поиска P (Place_found_P_Left_and_Right), 
    #Массив амплитуд (Massiv_Amp_all_channels), массив точек (Massiv_Points_channel), референтные значения для данного файла (Referents_by_File)
    function all_the1(BaseName, N)
        _, Signal_const, _, _, _, _ = One_Case(BaseName, N)
        Names_files, Signal_copy, Frequency, _, _, Ref_File = One_Case(BaseName, N)
        koef  = 1000/Frequency

        Referents_by_File = _read_ref(N)
        start_qrs = floor(Int64, Ref_File.QRS_onset) #начало комплекса QRS (INT)
        end_qrs = floor(Int64, Ref_File.QRS_end) #конец комплекса QRS (INT) 
        #Неизменный сигнал (массив)
            signal_const = Sign_Channel(Signal_const) #12 каналов
        #Сигнал для обработки (массив)
        signals_channel = Sign_Channel(Signal_copy) #12 каналов

        Ref_qrs = All_Ref_QRS(signals_channel[1], start_qrs, end_qrs, Referents_by_File.ibeg, Referents_by_File.iend)

        signal_without_qrs = Line_qrs(Ref_qrs, signals_channel)
        
        all_graph_butter = Graph_my_butter(signal_without_qrs, Frequency)    
        
        Left, Right = Segment_left_right_P(Frequency, Ref_qrs, Referents_by_File.ibeg, Referents_by_File.iend)
        Place_found_P_Left_and_Right = [Left, Right]

        dist = floor(Int64, Dsit_Diff/koef)
        all_graph_diff = Graph_diff(all_graph_butter, dist)    

        All_Points_Min_Max = All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS_LOCAL)
        #@info "все точки мин мах на всех отведениях и участках: $(All_Points_Min_Max[1])"
        Massiv_Points_channel = Sort_points_with_channel(All_Points_Min_Max)
        #@info "Massiv_Points_channel[1] = $(Massiv_Points_channel[1])"
        
        Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)
        #@info "Massiv_Amp_all_channels[1] = $(Massiv_Amp_all_channels[1])"
        Ref_P = []
        
        for i in 1:12
            count_selections = length(Massiv_Amp_all_channels[i]);
            push!(Ref_P, Function_Ref_P(count_selections, Referents_by_File))
        end

        return Names_files, Signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File
    end


    #Определение сигнала
    #Вход: Имя базы данных(BaseName), порядковый номер (N)
    #Выход: Список файлов (Names_files), Первоначальный сигнал (Signal_const), Сигнал без QRS (signal_without_qrs), Сигнал my_butter (all_graph_butter), Сигнал дифференцированный (all_graph_diff), 
    #Реферетная разметка QRS (Ref_qrs), Рефертеная разметка Р (Ref_P), Область поиска P (Place_found_P_Left_and_Right), 
    #Массив амплитуд (Massiv_Amp_all_channels), массив точек (Massiv_Points_channel), референтные значения для данного файла (Referents_by_File)
    function all_the2(BaseName, N)
        _, Signal_const, _, _, _, _ = One_Case(BaseName, N)
        Names_files, Signal_copy, Frequency, _, _, Ref_File = One_Case(BaseName, N)
        koef  = 1000/Frequency

        Referents_by_File = _read_ref(N)
        start_qrs = floor(Int64, Ref_File.QRS_onset) #начало комплекса QRS (INT)
        end_qrs = floor(Int64, Ref_File.QRS_end) #конец комплекса QRS (INT) 
        #Неизменный сигнал (массив)
        signal_const = Sign_Channel(Signal_const) #12 каналов
        #Сигнал для обработки (массив)
        signals_channel = Sign_Channel(Signal_copy) #12 каналов

        Ref_qrs = All_Ref_QRS(signals_channel[1], start_qrs, end_qrs, Referents_by_File.ibeg, Referents_by_File.iend)

        signal_without_qrs = Line_qrs(Ref_qrs, signals_channel)

        all_graph_butter = Graph_my_butter(signal_without_qrs, Frequency)    

        Left, Right = Segment_left_right_P(Frequency, Ref_qrs, Referents_by_File.ibeg, Referents_by_File.iend)
        Place_found_P_Left_and_Right = [Left, Right]

        dist = floor(Int64, Dsit_Diff/koef)
        all_graph_diff = Graph_diff(all_graph_butter, dist)    

        All_Points_Min_Max = All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS_LOCAL)
        #@info "все точки мин мах на всех отведениях и участках: $(All_Points_Min_Max[1])"
        Massiv_Points_channel = Sort_points_with_channel(All_Points_Min_Max)
        #@info "Massiv_Points_channel[1] = $(Massiv_Points_channel[1])"

        Massiv_Amp_all_channels = amp_all_cannel2(Massiv_Points_channel, all_graph_diff, koef, RADIUS)
        #@info "Massiv_Amp_all_channels[1] = $(Massiv_Amp_all_channels[1])"
        Ref_P = []

        for i in 1:12
            count_selections = length(Massiv_Amp_all_channels[i]);
            push!(Ref_P, Function_Ref_P(count_selections, Referents_by_File))
        end

        return Names_files, Signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File
    end

    export all_the, all_the2
end