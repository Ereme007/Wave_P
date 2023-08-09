

using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
#для толго чтобы видеть координаты на графиках
plotly()
include("Function_P.jl")
include(".env")
include("../src/readfiles.jl");
include("../src/plots.jl");



mutable struct Markup_Left_Right_Range
    Left::Int     
    Right::Int

    function Markup_Left_Right_Range()
        new(0, 0)
    end

    function Markup_Left_Right_Range(left, right)
        new(left, right)
    end
end

markup_selection = Dict{String, Markup_Left_Right_Range}()


mutable struct Markup_Left_Right_Front_Wave_P_amp_2
    Amp::Float64
    Left::Int     
    Right::Int


    function Markup_Left_Right_Front_Wave_P_amp_2()
        new(0, 0, 0)
    end

    function Markup_Left_Right_Front_Wave_P_amp_2(amp, left, right)
        new(amp, left, right)
    end
end

markup_front_wave_P_amp = Dict{String, Markup_Left_Right_Front_Wave_P_amp_2}()



mutable struct Markupref_Left_Right_P
    Left::Int     
    Right::Int

    function Markupref_Left_Right_P()
        new(0, 0)
    end

    function Markupref_Left_Right_P(left, right)
        new(left, right)
    end
end

markupref_P = Dict{String, Markupref_Left_Right_P}()





mutable struct Channel_Points
    I::Int     
    II::Int
    III::Int     
    IV::Int
    V::Int     
    VI::Int
    VII::Int     
    VIII::Int
    IX::Int     
    X::Int
    XI::Int     
    XII::Int

    function Channel_Points()
        new(0, 0,0, 0,0, 0,0, 0,0, 0,0, 0)
    end

    function Channel_Points(I, II, III, IV, V, VI, VII, VIII, IX, X, XI, XII)
        new(I, II, III, IV, V, VI, VII, VIII, IX, X, XI, XII)
    end
end

channel_points = Dict{String, Channel_Points}()









dir = 0

#Область рассмотрения проекта
function Position_Data_Base(Type_Data_base)
    if (Type_Data_base == "CSE")
        dir = Raw_CSE_MA_Data_Base_Incart # синтетические ЭКГ CSE_MA
        allbinfiles = getfileslist(dir) 
    elseif(Type_Data_base == "CTS")
        dir = Raw_CTS_Data_Base_Incart # синтетические ЭКГ CTS
        allbinfiles = getfileslist(dir) 
    else
        return false
    end
    return allbinfiles, dir 
end


tt1, tt2 = Position_Data_Base("CSE")
#t1
#t2


#Область рассмотрения референтной разметки проекта
function Referent_Data_Base(Data_base, filename)
    if (Data_base == "CSE" || Data_base == "CTS")
        if(Data_base == "CSE")
            referent = Raw_CSE_Ref_Incart
        else
            referent = Raw_CTS_Ref_Incart
        end

   #     @info "$Data_base" 
        ref = read_all_ref(referent) 
        fn_ref = filename[1:2] == "MA" ? "MO" * filename[3:end] : filename
        
        refrow = ref[fn_ref]
      #  @info "$refrow"
    return Data_base, refrow, ref, referent
    else
        return false
    end
end

t1, t2, t3, t4 = Referent_Data_Base("CSE", tt1[1])
#t2
#t3
#t

#Делаем функцию на вход: Тип анализа (CSE или другое) 
#нормер проекта 

function One_Case(Base_name, n)

    Data_Base_Position, dir = Position_Data_Base(Base_name)
    if (Data_Base_Position == false)
       return "Ошибка: Неверное наименование (или путь) для Базы Данных"
   end

  # n = 1
    fn = Data_Base_Position[n]
  #  lol = fn[n]
    Data_Base_Name, refrow, ref = Referent_Data_Base(Base_name, fn)
  #  @info "Data_Base_Position[n] $fn"
 #   @info "$lol"
  #  refrow = Data_Base_Name
    if (Data_Base_Name == false)
        return "Ошибка: Неверное наименование (или путь) референтной разметки для Базы Данных"
    end

    #@info "MAMA $dir"
    raw = 1
    signals, fs, _, _ = readbin("$dir/$(fn)") 
        return fn, Data_Base_Name, refrow, dir, signals
end

m1, m2, m3, m4, m5 = One_Case("CSE", 1)

#m1
##m2
##m3
#m4
#m5








#One_Case("CSE", 1)

#Data_Base_Position, dir = Position_Data_Base("CSE")
#Data_Base_Position[1]
#pp = Raw_CSE_MA_Data_Base_Incart
#fn = Data_Base_Position[1]
#signals, fs, _, _ = readbin("$pp/$(fn)") 


#a, b = Referent_Data_Base("CSE", "MA1_001")
#Data_Base_Position = Position_Data_Base("CSE")
#Raw_CSE_MA_Data_Base_Incart
#fn = Data_Base_Position[n]
#readbin("$Raw_CSE_MA_Data_Base_Incart/$fn") 

#@info "$(One_Case("CSE", 5))"


#One_Case("CSE", 1)
#fn, Data_Base_Name, refrow , dir, signals = One_Case("CSE", 1)




#referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
#ref = read_all_ref(referent)  #CSE


function all_the(Base_name, n)
    fn, Data_Base_Name, refrow , dir, signals = One_Case(Base_name, n)


    ref = _read_ref(n)

    @info "fn = $fn"

    start_qrs = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
    end_qrs= floor(Int64, refrow.QRS_end) #конец комплекса QRS
    dur_qrs= floor(Int64, refrow.QRS_dur)
    #signals_copy = copy(signals)
    signals_channel = Sign_Channel(signals) #12 каналов
    signals_start = Sign_Channel(signals) #12 каналов


    Ref_qrs = All_Ref_QRS(start_qrs, end_qrs, ref.ibeg, ref.iend)
    signal_without_qrs = Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)
    
    Left, Right = Segment_left_right_P(fs, Ref_qrs, ref.ibeg, ref.iend)
Place_found_P_Left_and_Right = [Left, Right]
Tester = Place_found_P_Left_and_Right
all_graph_butter = Graph_my_butter(signal_without_qrs)
koef  = 1000/fs


#@info "$Place_found_P_Left_and_Right"


dist = floor(Int64, 20/koef)
all_graph_diff = Graph_diff(all_graph_butter, dist)

Tst = All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS_LOCAL)[1]
@info "все точки мин мах: $Tst"

Massiv_Points_channel = Sort_points_with_channel(All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS_LOCAL))

#amp_one_channel(Massiv_Points_channel, all_graph_diff, koef, channel)
Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)


#One_channel = amp_one_channel(Massiv_Points_channel, all_graph_diff, koef, channel)

return signals_start, Massiv_Amp_all_channels, Massiv_Points_channel,  all_graph_diff

end


signals_start1, Massiv_Amp_all_channels1, Massiv_Points_channel1,  all_graph_diff1 = all_the("CSE", 1)
#signals_start1
#Massiv_Amp_all_channels1
#Massiv_Points_channel1
plot(all_graph_diff1[1])



function plot_all_channels_points(Base_name, n)#("CSE", 1)
signals_start, New_massiv, Massiv_Points_channel, all_graph_diff = all_the(Base_name, n)

#Massiv_Points_channel[12][1][3]
#New_massiv[канал][область][1 или 2 или 3] где 1 - Amp, 2 - левая, 3 - правая граница 
#New_massiv[1][1]
#New_massiv[2]
#New_massiv[12]

ref = _read_ref(n)

Mass_plots = []
for Channel in 1:12
plot_plot = (
    plot(all_graph_diff[Channel]);

    for Selection in 1:length(New_massiv[Channel])
   # Selection = 1 ;
    vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], lc=:black);
#Left = New_massiv[Channel][Selection][2]
#Right =  New_massiv[Channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Channel][Left], all_graph_diff[Channel][Right]])
        Amp_extrem = New_massiv[Channel][Selection][1];
        Left_extrem = floor(Int64, New_massiv[Channel][Selection][2]);
        Right_extrem =  floor(Int64, New_massiv[Channel][Selection][3]);
#Massiv_Points_channel[Channel][Selection][Left_extrem]
#Massiv_Points_channel[Channel][Selection][Right_extrem]
        Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Massiv_Points_channel[Channel][Selection][Left_extrem], Massiv_Points_channel[Channel][Selection][Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
        scatter!([Points_fronts.Left, Points_fronts.Right], [all_graph_diff[Channel][Points_fronts.Left], all_graph_diff[Channel][Points_fronts.Right]]);
    end;
    plot!(title = "Отведение $Channel", legend=false)
    )

    push!(Mass_plots, plot_plot)
end


plot_vertical(Mass_plots[1], Mass_plots[2], Mass_plots[3], Mass_plots[4], Mass_plots[5], Mass_plots[6], Mass_plots[7], Mass_plots[8], Mass_plots[9], Mass_plots[10], Mass_plots[11], Mass_plots[12]);
#plot!(title = "$Base_name, файл $fn")
end






plot_all_channels_points("CSE", 1)

Massiv_Points_channel[1][1]


function plot_channel_points(Base_name, n, Current_channel, Charr)
    signals_start, New_massiv, Massiv_Points_channel, all_graph_diff = all_the(Base_name, n)



    ref = _read_ref(n) 

    
    
#Current_channel = 1
    Mass_plots = []
    for Channel in 1:12
        plot_plot1 = (
        plot(all_graph_diff[Channel]);




        for Selection in 1:length(New_massiv[Channel])
            if(Charr == '+')
                poi = Massiv_Points_channel[Channel][Selection]
                @info "points $poi"
                scatter!(poi, all_graph_diff[Channel][poi])
            end;
   # Selection = 1 ;
            vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], lc=:black);
#Left = New_massiv[Channel][Selection][2]
#Right =  New_massiv[Channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Channel][Left], all_graph_diff[Channel][Right]])
            Amp_extrem = New_massiv[Channel][Selection][1];
            Left_extrem = floor(Int64, New_massiv[Channel][Selection][2]);
            Right_extrem =  floor(Int64, New_massiv[Channel][Selection][3]);
#Massiv_Points_channel[Channel][Selection][Left_extrem]
#Massiv_Points_channel[Channel][Selection][Right_extrem]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Massiv_Points_channel[Channel][Selection][Left_extrem], Massiv_Points_channel[Channel][Selection][Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
            #scatter!([Points_fronts.Left, Points_fronts.Right], [all_graph_diff[Channel][Points_fronts.Left], all_graph_diff[Channel][Points_fronts.Right]]);
            @info "Left = $(Points_fronts.Left)  Right = $(Points_fronts.Right)"
        end;
        plot!(title = "Отведение $Channel", legend=false)
        )

        push!(Mass_plots, plot_plot1)

        Mass_plots_signal = []
        @info "Mass_plots_signal = $Mass_plots_signal"
        #for Channel in 1:12
        Channel = 1    
        plot_plot = (
            plot(signals_start[Channel]);

            for Selection in 1:length(New_massiv[Channel])
   # Selection = 1 ;
              vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], lc=:black);
#Left = New_massiv[Channel][Selection][2]
#Right =  New_massiv[Channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Channel][Left], all_graph_diff[Channel][Right]])
                Amp_extrem = New_massiv[Channel][Selection][1];
                Left_extrem = floor(Int64, New_massiv[Channel][Selection][2]);
                Right_extrem =  floor(Int64, New_massiv[Channel][Selection][3]);
#Massiv_Points_channel[Channel][Selection][Left_extrem]
#Massiv_Points_channel[Channel][Selection][Right_extrem]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Massiv_Points_channel[Channel][Selection][Left_extrem], Massiv_Points_channel[Channel][Selection][Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
                #scatter!([Points_fronts.Left, Points_fronts.Right], [signals_start[Channel][Points_fronts.Left], signals_start[Channel][Points_fronts.Right]]);
                
                if(Channel == 12)
               # @info "Отведение(1) $Channel left = $(signals_start[Channel][Points_fronts.Left]), Right = $(signals_start[Channel][Points_fronts.Right])"
                end
            end;
            plot!(title = "Отведение $Channel", legend=false)
            )
            
          #  push!(Mass_plots_signal, plot_plot)
       # end
    end
    #Current_channel = 1
    #plot_vertical(Mass_plots_signal[Current_channel], Mass_plots[Current_channel])



   # plot!(title = "Отведение $Current_channel, файл $fn")
    return plot_plot
end

include("Function_P.jl")
include(".env")

b = plot_channel_points("CSE", 4, 12, '-')

plot_all_channels_points("CSE", 4)
plot_channel_points("CSE", 4, 12, '-')
sropr








New_massiv[1][1][1]
New_massiv[1][2][1]
New_massiv[1][3][1]



