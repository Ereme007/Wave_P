include("Function_P.jl")
include("Markup_function_P.jl")
include("Function_dist.jl")
include("Test_P_5.jl")
BaseName = "CSE"
    N = 15
        Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
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
plot_all_channels_const_signal(BaseName, N)
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