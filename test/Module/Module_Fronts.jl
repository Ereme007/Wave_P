module Module_Fronts
    include("Functions_for_Module_Fronts.jl")
    include("../../src/my_filt.jl")
    include("env.jl")
    
    #Определение фронтов
    function Defenition_Fronts(signals_channel, Frequency, koef, Ref_qrs, start_signal, end_signal)
    
        signal_without_qrs = Line_qrs(Ref_qrs, signals_channel)

        all_graph_butter = Graph_my_butter(signal_without_qrs, Frequency)
        
        Left, Right = Segment_left_right_P(Frequency, Ref_qrs, start_signal, end_signal)
        Place_found_P_Left_and_Right = [Left, Right]

        dist = floor(Int64, Dsit_Diff/koef)
        all_graph_diff = Graph_diff(all_graph_butter, dist)    

        All_Points_Min_Max = All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS_LOCAL)
        Massiv_Points_channel = Sort_points_with_channel(All_Points_Min_Max)
        
        Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)

        return Massiv_Amp_all_channels, Massiv_Points_channel
    end
    
    export Defenition_Fronts
end