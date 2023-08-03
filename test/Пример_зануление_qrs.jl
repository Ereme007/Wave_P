include("Function_P.jl")
include("Markup_function_P.jl")
include("Function_dist.jl")
include("Test_P_5.jl")


#Сигнал определение
function all_the3(BaseName, N)
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


    signal_without_qrs = Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)
    
   
    #Проверка графиков
    #График Исходного сигнала, Сигнал без QRS (1 отведеление)
    #plot_vertical(signal_const[1], signal_without_qrs[1])
    Left, Right = Segment_left_right_P(Frequency, Ref_qrs, Referents_by_File.ibeg, Referents_by_File.iend)
    All_left_right = [Left, Right]

    all_graph_butter = Graph_my_butter(signal_without_qrs, Frequency)
    
    #Проверка графиков
    #График Исходного сигнала, Сигнал без QRS, Отфильтрованный сигнал (1 отведение)
    #plot_vertical(signal_const[1], signal_without_qrs[1], all_graph_butter[1])
    #График с разметкой областью поиска P, график Исходного сигнала, Сигнал без QRS, Отфильтрованный сигнал (1 отведение)
    #plot_vertical_ref(All_left_right, signal_const[1], signal_without_qrs[1], all_graph_butter[1])
    
    
    dist = floor(Int64, Dsit_Diff/koef)
    all_graph_diff = Graph_diff(all_graph_butter, dist)
    #Проверка графика
    #График с разметкой областью поиска P, график Исходного сигнала, Сигнал без QRS, Отфильтрованный сигнал, Дифференц сигнал (1 отведение)
   # plot_vertical_ref(All_left_right, signal_const[Ch], signal_without_qrs[Ch], all_graph_butter[Ch], all_graph_diff[Ch]) 
    

    All_Points_Min_Max = All_points_with_channels_max_min(All_left_right, all_graph_diff, RADIUS_LOCAL)
    #@info "все точки мин мах на всех отведениях и участках: $(All_Points_Min_Max[1])"
    Massiv_Points_channel = Sort_points_with_channel(All_Points_Min_Max)
    #@info "Massiv_Points_channel[1] = $(Massiv_Points_channel[1])"
    
    Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)
    #@info "Massiv_Amp_all_channels[1] = $(Massiv_Amp_all_channels[1])"
    return Names_files, Signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, All_left_right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File
end



include("Function_dist.jl")
BaseName = "CSE"
    N = 1
    Names_files, Signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, All_left_right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the3(BaseName, N)
        Referents_by_File
        size_mass = length(Massiv_Amp_all_channels[1]);

    #for Selection in 1:size_mass
    Selection = 3   
    Selection_Edge = []

        for Current_chanel in 1:12
            #Current_chanel = 1
            Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
            #Тут Функцию по КАК РАЗ поканально в одной секции
            push!(Selection_Edge, Points_fronts)
        end
        #push!(Selection_Edge, Points_fronts)
    #end
    #return Selection_Edge
    Selection_Edge
    

    
    left, right = Test1(Selection_Edge)
    left 
    right
    x = 1:length(left)
    plot(x, left)

    left, right = Test2(Selection_Edge)
    left 
    right
    x = 1:length(left)
    plot(x, left)
    

    
dist_ll, index_ll, value_ll = Min_dist_to_all_points(left)
x = 1:length(right)
plot(x, right)
dist_rr, index_rr, value_rr = Min_dist_to_all_points(right)


function plot_all_channels_const_signal(BaseName, N, Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File)

    Mass_plots = []
    for Channel in 1:12 
        co = 1
        plot_plot = (
            plot(Signal_const[Channel]);
            size_mass = length(Massiv_Amp_all_channels[Channel]);
            for Selection in 1:size_mass
            # Selection = 1;
                vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Channel][Selection][3]
#scatter!([Left, Right], [Signal_const[Channel][Left], Signal_const[Channel][Right]])
                Current_amp = Massiv_Amp_all_channels[Channel][Selection]
                Amp_extrem = Current_amp[1];
                Left_extrem = floor(Int64, Current_amp[2]);
                Right_extrem =  floor(Int64, Current_amp[3]);
#Massiv_Points_channel[Channel][Selection][Left_extrem]
#Massiv_Points_channel[Channel][Selection][Right_extrem]
                Current_points = Massiv_Points_channel[Channel][Selection]
                Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
                scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[Channel][Points_fronts.Left], Signal_const[Channel][Points_fronts.Right]]);
            if (co == 1)
               # @info "Amp_extrem[$Channel] = $(Points_fronts.Amp)";
            co = 2
            end
            end;
            
            plot!(title = "Отведение $Channel", legend=false)
        )

    push!(Mass_plots, plot_plot)
end
plot_vertical(Mass_plots[1], Mass_plots[2], Mass_plots[3], Mass_plots[4], Mass_plots[5], Mass_plots[6], Mass_plots[7], Mass_plots[8], Mass_plots[9], Mass_plots[10], Mass_plots[11], Mass_plots[12]);
#plot_vertical(Mass_plots[1], Mass_plots[2])
end



plot_all_channels_const_signal(BaseName, N, Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File)
xlims!(1550, 1980) #для 3ейй секции файла N
vline!([value_ll, value_rr])
plot!()

z1, ll, val_ll = Mean_value(left)
z2, rr, val_rr = Mean_value(right)
ll
rr
#plot_all_channels_const_signal(BaseName, N)
#xlims!(515, 800) #для 3ейй секции файла N
vline!([val_ll, val_rr])
plot!()



#= day 27.07 =#


BaseName = "CSE"
N = 1
Signal_copy, Frequency, _, _, Ref_File = 0, 0, 0, 0, 0
Signal_copy, Frequency, _, _, Ref_File = One_Case(BaseName, N)
signals_channel = Sign_Channel(Signal_copy) #12 каналов
start_qrs = floor(Int64, Ref_File.QRS_onset) #начало комплекса QRS (INT)
    end_qrs = floor(Int64, Ref_File.QRS_end) #конец комплекса QRS (INT) 
    Referents_by_File = _read_ref(N)
Ref_qrs = All_Ref_QRS(signals_channel[1], start_qrs, end_qrs, Referents_by_File.ibeg, Referents_by_File.iend)

Left, Right = Segment_left_right_P(Frequency, Ref_qrs, Referents_by_File.ibeg, Referents_by_File.iend)
All_left_right = [Left, Right]

Left
Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
Current_amp = Massiv_Amp_all_channels[Channel][Selection]
                Amp_extrem = Current_amp[1];
                Left_extrem = floor(Int64, Current_amp[2]);
                Right_extrem =  floor(Int64, Current_amp[3]);
#Massiv_Points_channel[Channel][Selection][Left_extrem]
#Massiv_Points_channel[Channel][Selection][Right_extrem]
                Current_points = Massiv_Points_channel[Channel][Selection]
                Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
Test2(Left)










function solve_y(Xa, Xb, Ya, Yb, X)
    Y = (X-Xa)/(Xb-Xa)*(Yb-Ya)+Ya
    return Y
end

solve_y(3, 8, 1, 2, 8)





greed(3, 8, 1, 2)
