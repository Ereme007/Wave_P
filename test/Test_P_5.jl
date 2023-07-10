using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido

plotly()
include("Function_P.jl")
include(".env")
include("../src/readfiles.jl");
include("../src/plots.jl");

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



#Область рассмотрения проекта
#Вход - имя базы данных ("CSE")
#Выход - кортеж имен для данной базы данных ; Путь к базе данных
function Position_Data_Base(Type_Data_base)
    if (Type_Data_base == "CSE")
        raw_base_data = Raw_CSE_MA_Data_Base_Incart # синтетические ЭКГ CSE_MA
        allbinfiles = getfileslist(raw_base_data) 
    elseif(Type_Data_base == "CTS")
        raw_base_data = Raw_CTS_Data_Base_Incart # синтетические ЭКГ CTS
        allbinfiles = getfileslist(raw_base_data) 
    else
        return false, false
    end
    return allbinfiles, raw_base_data 
end


#Референтная разметка для данной базы данных
#Вход - имя базы данных ("CSE") наименование файла ("MA1_001")
#Выход - Data_base (имя базы данных); ref_file (референтная разметка для данного файла); ref_all_file (референтная разметка для всех файлов); raw_ref (путь к референтной разметке)
function Referent_Data_Base(Data_base, filename)
    if (Data_base == "CSE" || Data_base == "CTS")
        if(Data_base == "CSE")
            raw_ref = Raw_CSE_Ref_Incart
        else
            raw_ref = Raw_CTS_Ref_Incart
        end

   #     @info "$Data_base" 
        ref_all_file = read_all_ref(raw_ref) 
        fn_ref = filename[1:2] == "MA" ? "MO" * filename[3:end] : filename
        
        ref_file = ref_all_file[fn_ref]
      #  @info "$ref_file"
    return Data_base, ref_file, ref_all_file, raw_ref
    else
        return false, false, false, false
    end
end


#Функция считывания сигнала
#Вход - Имя базы данных ("CSE"), номер файла (12)
#Выход - Сигнал, частота, дата(-), вектор "unit"(-) 
function One_Case(BaseName, N)
#проверка на ошибок для Базы данных
    Names_files, Raw_Base_Date = Position_Data_Base(BaseName)
    
    if (Raw_Base_Date == false)
        return "Ошибка: Неверное наименование (или путь) для Базы Данных"
    end

    File_Name = Names_files[N]
#проверка на ошибок в реферетной разметке (будет вылетать программа, если неверно)
    Data_Base_Name, Ref_File, Ref_All_File, Raw_Ref = Referent_Data_Base(BaseName, File_Name)
    
    if (Data_Base_Name == false)
        return "Ошибка: Неверное наименование (или путь) референтной разметки или номер файла"
    end

    #Считываем сигнал
    signals, fs, time, cor = readbin("$Raw_Base_Date/$(File_Name)") 
    return signals, fs, time, cor, Ref_File
end

#Описание
#Вход - Имя базы данных ("CSE"); номер файла (12)
#Выход - 
function all_the(BaseName, N)
    Signal_const, _, _, _, _ = One_Case(BaseName, N)
    Signal_copy, Frequency, _, _, Ref_File = One_Case(BaseName, N)
    koef  = 1000/Frequency

    Referents_by_File = _read_ref(N)
    start_qrs = floor(Int64, Ref_File.QRS_onset) #начало комплекса QRS (INT)
    end_qrs = floor(Int64, Ref_File.QRS_end) #конец комплекса QRS (INT) 
    #@info "start_qrs = $start_qrs"
    #@info "end_qrs = $end_qrs"


   # Copy_Sig = clone(Signal)
   # @info "Copy_Sig = $Signal"
    #Неизменный сигнал (массив)
    signal_const = Sign_Channel(Signal_const) #12 каналов
    #Сигнал для обработки (массив)
    signals_channel = Sign_Channel(Signal_copy) #12 каналов

#   Start_Sig = 1
#End_Sig = length(signals_channel[1])
#
    #return signals_const
    Ref_qrs = All_Ref_QRS(signals_channel[1], start_qrs, end_qrs, Referents_by_File.ibeg, Referents_by_File.iend)
   # @info "Ref_qrs = $Ref_qrs"
    #return start_qrs, end_qrs, Referents_by_File.ibeg, Referents_by_File.iend
#    return Ref_qrs

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
    plot_vertical_ref(All_left_right, signal_const[1], signal_without_qrs[1], all_graph_butter[1], all_graph_diff[1]) 
    

    All_Points_Min_Max = All_points_with_channels_max_min(All_left_right, all_graph_diff, RADIUS_LOCAL)[1]
    @info "все точки мин мах на всех отведениях и участках: $All_Points_Min_Max"
    Massiv_Points_channel = Sort_points_with_channel(All_points_with_channels_max_min(All_left_right, all_graph_diff, RADIUS_LOCAL))
    #@info "Massiv_Points_channel[1] = $(Massiv_Points_channel[1])"
    
    Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)
    @info "Massiv_Amp_all_channels[1] = $(Massiv_Amp_all_channels[1])"
    return Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel,  all_graph_diff, Referents_by_File
end


function plot_all_channels_points(BaseName, N)
    Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)

    @info "start"
    Mass_plots = []
    for Channel in 1:12 
        plot_plot = (
            plot(all_graph_diff[Channel]);
            for Selection in 1:length(Massiv_Amp_all_channels[Channel])
            # Selection = 1 ;
                vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Channel][Left], all_graph_diff[Channel][Right]])
                Amp_extrem = Massiv_Amp_all_channels[Channel][Selection][1];
                Left_extrem = floor(Int64, Massiv_Amp_all_channels[Channel][Selection][2]);
                Right_extrem =  floor(Int64, Massiv_Amp_all_channels[Channel][Selection][3]);
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
#plot_vertical(Mass_plots[1], Mass_plots[2])
end



#===================================================================================================
=#

function plot_channel_points(BaseName, N, Current_channel, Charr)
    Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)    
#Current_channel = 1
    Mass_plots = []
    #for Channel in 1:12
    plot_front_sig = (
        plot(all_graph_diff[Current_channel]);

        for Selection in 1:length(Massiv_Amp_all_channels[Current_channel])
            if(Charr == +)
                poi = Massiv_Points_channel[Current_channel][Selection]
                @info "points $poi"
                scatter!(poi, all_graph_diff[Current_channel][poi])
            end;
   # Selection = 1 ;
            vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Current_channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Current_channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Current_channel][Left], all_graph_diff[Current_channel][Right]])
            Amp_extrem = Massiv_Amp_all_channels[Current_channel][Selection][1];
            Left_extrem = floor(Int64, Massiv_Amp_all_channels[Current_channel][Selection][2]);
            Right_extrem =  floor(Int64, Massiv_Amp_all_channels[Current_channel][Selection][3]);
#Massiv_Points_channel[Current_channel][Selection][Left_extrem]
#Massiv_Points_channel[Current_channel][Selection][Right_extrem]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Massiv_Points_channel[Current_channel][Selection][Left_extrem], Massiv_Points_channel[Current_channel][Selection][Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
            scatter!([Points_fronts.Left, Points_fronts.Right], [all_graph_diff[Current_channel][Points_fronts.Left], all_graph_diff[Current_channel][Points_fronts.Right]]);
            @info "Left = $(Points_fronts.Left)  Right = $(Points_fronts.Right)"
        end;

        plot!(title = "Отведение $Current_channel", legend=false)
        )

    push!(Mass_plots, plot_front_sig)

    Mass_plots_signal = []
    @info "Mass_plots_signal = $Mass_plots_signal"
        #for Current_channel in 1:12
      #  Current_channel = 1    
    plot_const_sug = (
        plot(Signal_const[Current_channel]);

        for Selection in 1:length(Massiv_Amp_all_channels[Current_channel])
   # Selection = 1 ;
            vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Current_channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Current_channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Current_channel][Left], all_graph_diff[Current_channel][Right]])
            Amp_extrem = Massiv_Amp_all_channels[Current_channel][Selection][1];
            Left_extrem = floor(Int64, Massiv_Amp_all_channels[Current_channel][Selection][2]);
            Right_extrem =  floor(Int64, Massiv_Amp_all_channels[Current_channel][Selection][3]);
#Massiv_Points_channel[Current_channel][Selection][Left_extrem]
#Massiv_Points_channel[Current_channel][Selection][Right_extrem]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Massiv_Points_channel[Current_channel][Selection][Left_extrem], Massiv_Points_channel[Current_channel][Selection][Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
                scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[Current_channel][Points_fronts.Left], Signal_const[Current_channel][Points_fronts.Right]]);
                
              #  if(Current_channel == 12)
               # @info "Отведение(1) $Current_channel left = $(Signal_const[Current_channel][Points_fronts.Left]), Right = $(Signal_const[Current_channel][Points_fronts.Right])"
              #  end
              
        end;
        plot!(title = "Отведение $Current_channel", legend=false);
            
            
        )
           # @info "Mass_plots_signal = $Mass_plots_signal"
    push!(Mass_plots_signal, plot_const_sug)
       # end
       #@info "Mass_plots_signal = $Mass_plots_signal"
    #end
    
    #Current_channel = 1
    plot_vertical(Mass_plots_signal[1], Mass_plots[1])



    #plot!(title = "Отведение $Current_channel, файл $BaseName")
  # return plot_front_sig
end

    


function plot_const_signal(BaseName, N)
Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
plot(Signal_const[1])
end


#Проверка графиков
all_the("CSE", 1)
plot!()


all_the("CSE", 2)
plot_channel_points("CSE", 3, 6, +)


plot_const_signal("CSE", 1)

stop
