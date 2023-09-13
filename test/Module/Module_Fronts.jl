module Module_Fronts
    include("Functions_for_Module_Fronts.jl")
    include("../../src/my_filt.jl")
    include("env.jl")
    
    #Определение фронтов
    #На вход: начальный сигнал (signals_channel), частота (Frequency), коэффициент (koef), Референтная разметка QRS (Ref_qrs), Начало/Конец сигнала по референтной разметке (start_signal/end_signal)
    #На выход: Массив Amp (Massiv_Amp_all_channels), массив экстремумов (Massiv_Points_channel)
    function Defenition_Fronts(signals_channel, Frequency, koef, Ref_qrs, start_signal, end_signal)
        #Сигнал без QRS
        signal_without_qrs = Line_qrs(Ref_qrs, signals_channel)
        
        #Сигнал под фильтром my_butter()
        all_graph_butter = Graph_my_butter(signal_without_qrs, Frequency)
        
        #Сигнал под дифференциированным фильтром
        dist = floor(Int64, Dsit_Diff/koef)
        all_graph_diff = Graph_diff(all_graph_butter, dist)    

        #Первоначальная детекция области посика зубца P зная разметку QRS (кодовое название Первая_Обл_Р)
        Left, Right = Segment_left_right_P(Frequency, Ref_qrs, start_signal, end_signal)
        Place_found_P_Left_and_Right = [Left, Right]

        #Нахождение всех экстремумов на Первая_Обл_Р
        All_Points_Min_Max = All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS_LOCAL)
        
        #Сортировка всех экстремумов на Первая_Обл_Р
        Massiv_Points_channel = Sort_points_with_channel(All_Points_Min_Max)
        
        #Нахождение AMP на Первая_Обл_Р с учётом того, что уменьшаем фронт, если значение сигнала на дифф будет около 0 (Diff_ZERO)
        Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)

        return Massiv_Amp_all_channels, Massiv_Points_channel
    end
    
    export Defenition_Fronts
end