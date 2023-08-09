using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames
plotly()
include("Function_P.jl")
include("Markup_function_P.jl")
include(".env")
include("../src/readfiles.jl");
include("../src/plots.jl");


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
#Referent_Data_Base("CSE", a[1])
function Referent_Data_Base(Data_base, filename)
    if (Data_base == "CSE" || Data_base == "CTS")
        if(Data_base == "CSE")
            raw_ref = Raw_CSE_Ref_Incart
        elseif(Data_base == "CTS")
            raw_ref = Raw_CTS_Ref_Incart
        else
            return false;
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
    signals, fs, time, cor = readbin("$(Raw_Base_Date)/$(File_Name)") 
    return signals, fs, time, cor, Ref_File
end

#Описание
#Вход - Имя базы данных ("CSE"); номер файла (12)
#Выход - Изначальный сигнал (Signal_const); массив амплитуды, левой и правой границы зубца Р (Massiv_Amp_all_channels);
        #массив всех экстремумов (Massiv_Points_channel); дифференцированный сигнал (all_graph_diff); 
        #референтные для текущего файла (Referents_by_File)
      #=  cc = 4
        Signal_const_CTS, _, _, _, Ref_File = One_Case("CTS", cc)
        signal_const_CTS = Sign_Channel(Signal_const_CTS)
        plot(signal_const_CTS[1])
        Referents_by_File = _read_ref(cc)
        start_qrs = floor(Int64, Ref_File.QRS_onset)
        all_the("CTS", cc)
     =# 
      
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
    Place_found_P_Left_and_Right = [Left, Right]

    all_graph_butter = Graph_my_butter(signal_without_qrs, Frequency)
    
    #Проверка графиков
    #График Исходного сигнала, Сигнал без QRS, Отфильтрованный сигнал (1 отведение)
    #plot_vertical(signal_const[1], signal_without_qrs[1], all_graph_butter[1])
    #График с разметкой областью поиска P, график Исходного сигнала, Сигнал без QRS, Отфильтрованный сигнал (1 отведение)
    #plot_vertical_ref(Place_found_P_Left_and_Right, signal_const[1], signal_without_qrs[1], all_graph_butter[1])
    
    
    dist = floor(Int64, Dsit_Diff/koef)
    all_graph_diff = Graph_diff(all_graph_butter, dist)
    #Проверка графика
    #График с разметкой областью поиска P, график Исходного сигнала, Сигнал без QRS, Отфильтрованный сигнал, Дифференц сигнал (1 отведение)
   # plot_vertical_ref(Place_found_P_Left_and_Right, signal_const[Ch], signal_without_qrs[Ch], all_graph_butter[Ch], all_graph_diff[Ch]) 
    

    All_Points_Min_Max = All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS_LOCAL)
    @info "все точки мин мах на всех отведениях и участках: $(All_Points_Min_Max[1])"
    Massiv_Points_channel = Sort_points_with_channel(All_Points_Min_Max)
    #@info "Massiv_Points_channel[1] = $(Massiv_Points_channel[1])"
    
    Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)
    #@info "Massiv_Amp_all_channels[1] = $(Massiv_Amp_all_channels[1])"
    @info "Ref_qrs = $(Ref_qrs)"
    return Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel,  all_graph_diff, Referents_by_File
end



#Функция, строящая график на дифференцированном сигнале, границы P из реферетного файла и найденные границы зубца Р
#Вход - имя базы данных (BaseName); номер файла (N)
#Выход - NO
function plot_all_channels_points(BaseName, N)
    Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)

    Mass_plots = []
    for Channel in 1:12 
        plot_plot = (
            plot(all_graph_diff[Channel]);
            size_mass = length(Massiv_Amp_all_channels[Channel]);
            for Selection in 1:size_mass
            # Selection = 1 ;
                vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Channel][Left], all_graph_diff[Channel][Right]])
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
                scatter!([Points_fronts.Left, Points_fronts.Right], [all_graph_diff[Channel][Points_fronts.Left], all_graph_diff[Channel][Points_fronts.Right]]);
            end;
            plot!(title = "Отведение $Channel", legend=false)
        )

    push!(Mass_plots, plot_plot)
end
plot_vertical(Mass_plots[1], Mass_plots[2], Mass_plots[3], Mass_plots[4], Mass_plots[5], Mass_plots[6], Mass_plots[7], Mass_plots[8], Mass_plots[9], Mass_plots[10], Mass_plots[11], Mass_plots[12]);
#plot_vertical(Mass_plots[1], Mass_plots[2])
end


#Функция, строящая график исходного сигнала на 12 отведениях с реф разметкой и моей детекцией зубца Р.
#Вход - Имя базы данных (BaseName); номер файла (N)
#Выход - график исходного сигнала на 12 отведениях с реф разметок Р и моим определением границ зубца Р
function plot_all_channels_const_signal(BaseName, N)
    Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)

    #@info "start"
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
                @info "Amp_extrem[$Channel] = $(Points_fronts.Amp)";
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
plot_all_channels_const_signal("CSE", 1)
xlims!(938, 1085)
#=
Функция построение графика одного основного сигнала по определённому каналу
Вход: Наименование базы данных (BaseName); Порядковый номер сигнала (N); Отведение (CH) 
Выход: NULL (функция построение графика)
P.S. После запуска функции необходимо написать plot!()
=#
function plot_one_channels_const_signal(BaseName, N, CH)
    Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)

    #@info "start"
    Mass_plots = []
    #for Channel in 1:12 
        plot_plot = (
            plot(Signal_const[CH]);
            size_mass = length(Massiv_Amp_all_channels[CH]);
            for Selection in 1:size_mass
            # Selection = 1;
                vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[CH][Selection][2]
#Right =  Massiv_Amp_all_channels[CH][Selection][3]
#scatter!([Left, Right], [Signal_const[CH][Left], Signal_const[Channel][Right]])

Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[CH][Selection], Massiv_Points_channel[CH][Selection])
              #=  Current_amp = Massiv_Amp_all_channels[CH][Selection]
                Amp_extrem = Current_amp[1];
                Left_extrem = floor(Int64, Current_amp[2]);
                Right_extrem =  floor(Int64, Current_amp[3]);
#Massiv_Points_channel[CH][Selection][Left_extrem]
#Massiv_Points_channel[CH][Selection][Right_extrem]
                Current_points = Massiv_Points_channel[CH][Selection]
                Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
=#
                scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[CH][Points_fronts.Left], Signal_const[CH][Points_fronts.Right]]);
            end;
            plot!(title = "Отведение $CH", legend=false)
        )

    push!(Mass_plots, plot_plot)
end

plot_one_channels_const_signal("CSE", 1, 1)
plot!()

#plot_vertical(Mass_plots[1], Mass_plots[2], Mass_plots[3], Mass_plots[4], Mass_plots[5], Mass_plots[6], Mass_plots[7], Mass_plots[8], Mass_plots[9], Mass_plots[10], Mass_plots[11], Mass_plots[12]);
#plot_vertical(Mass_plots[1], Mass_plots[2])
#end


#===================================================================================================
=#


#Функция
#Вход - Имя базы данных (BaseName); номер файла (N); текущее отведение (Current_channel); Символ-флаг, если р то рисуем все экстремумы (Charr) 
#Выход - (сейчас!) значение амплитуды и файла 
function plot_channel_points(BaseName, N, Current_channel, Charr)
    Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)    
#Current_channel = 1
    Mass_plots = []
    Out_AMP = 0
    #for Channel in 1:12
    plot_front_sig = (
        plot(all_graph_diff[Current_channel]);
        size_mass = length(Massiv_Amp_all_channels[Current_channel]);
        for Selection in 1:size_mass
            if(Charr == 'p')
                poi = Massiv_Points_channel[Current_channel][Selection]
                #@info "points $poi"
                scatter!(poi, all_graph_diff[Current_channel][poi])
            end;
   # Selection = 1 ;
            vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Current_channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Current_channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Current_channel][Left], all_graph_diff[Current_channel][Right]])
Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_channel][Selection], Massiv_Points_channel[Current_channel][Selection])
#=
            Current_amp = Massiv_Amp_all_channels[Current_channel][Selection]
            Amp_extrem = Current_amp[1];
            Out_AMP = Amp_extrem;
            Left_extrem = floor(Int64, Current_amp[2]);
            Right_extrem =  floor(Int64, Current_amp[3]);
#Massiv_Points_channel[Current_channel][Selection][Left_extrem]
#Massiv_Points_channel[Current_channel][Selection][Right_extrem]
            Current_points = Massiv_Points_channel[Current_channel][Selection]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
=#
            scatter!([Points_fronts.Left, Points_fronts.Right], [all_graph_diff[Current_channel][Points_fronts.Left], all_graph_diff[Current_channel][Points_fronts.Right]]);
           # @info "Left = $(Points_fronts.Left)  Right = $(Points_fronts.Right)"
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
        size_mass = length(Massiv_Amp_all_channels[Current_channel]);
        for Selection in 1:size_mass
   # Selection = 1 ;
            vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Current_channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Current_channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Current_channel][Left], all_graph_diff[Current_channel][Right]])
            Mass_amp = Massiv_Amp_all_channels[Current_channel][Selection]
            Amp_extrem = Mass_amp[1];
            Left_extrem = floor(Int64, Mass_amp[2]);
            Right_extrem =  floor(Int64, Mass_amp[3]);
            
#Massiv_Points_channel[Current_channel][Selection][Left_extrem]
#Massiv_Points_channel[Current_channel][Selection][Right_extrem]
            Mass_points = Massiv_Points_channel[Current_channel][Selection]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Mass_points[Left_extrem], Mass_points[Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
                scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[Current_channel][Points_fronts.Left], Signal_const[Current_channel][Points_fronts.Right]]);
                
              #  if(Current_channel == 12)
              #  @info "Отведение(1) $Current_channel left = $(Signal_const[Current_channel][Points_fronts.Left]), Right = $(Signal_const[Current_channel][Points_fronts.Right])"
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
   return Out_AMP
end

    

#Функция строит исходный сигнал на заданном отведении
#Вход - имя базы данных (BaseName); номер файла (N); Текущее отведение (Current_chanel)
#Выход - NO
function plot_const_signal(BaseName, N, Current_chanel)
Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
plot(Signal_const[Current_chanel], label = "Исх сиг $BaseName отведение $Current_chanel")
size_mass = length(Massiv_Amp_all_channels[Current_chanel]);
for Selection in 1:size_mass
vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
Current_amp = Massiv_Amp_all_channels[Current_chanel][Selection];
Amp_extrem = Current_amp[1];
Left_extrem = floor(Int64, Current_amp[2]);
Right_extrem =  floor(Int64, Current_amp[3]);
Current_points = Massiv_Points_channel[Current_chanel][Selection]
Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[Current_chanel][Points_fronts.Left], Signal_const[Current_chanel][Points_fronts.Right]]);
end
end


#Проверка графиков и сохранение

BD = "CSE" #(base data)
n = 1

AAmmpp = []
#for n in 1:125 #База данных CSE имеет 125 файлов
if ((n == 70) || (n == 67))#(number file)
    n = n + 1
end
CC = 3 #(Current channel)
NF, RBD = Position_Data_Base(BD) #(name file); (raw base data)
#выскок на 23 инт 57 
# тут лажааа 67 70
#График исходного сигнала и сигнала "детекции"
aa = plot_channel_points("CSE", n, CC, 'p')
plot!()
push!(AAmmpp, [n, aa])
title!("CSE $(NF[n])")
#savefig("pictures_by_channel_CSE/$(NF[n])-$CC.png")
@info "end $n"
#end


Signal_const1, Massiv_Amp_all_channels1, Massiv_Points_channel1, all_graph_diff1, Referents_by_File1 = all_the("CSE", 1)
Signal_const1
Massiv_Amp_all_channels1
Massiv_Points_channel1
plot(all_graph_diff1[1])
Referents_by_File1


n = 1

#сигнал детекции на 12 отведениях
plot_all_channels_points("CSE", n)

#исходный сигнал на 12 каналах
plot_all_channels_const_signal("CSE", n)
plot!()

all_the("CSE", 20)
plot!()
plot_const_signal("CSE", n, 9)
plot!(legend=false)
#stop


#Надо бы сделать проверочку... =(
#Надо сделать сохранение картинок =(
#Надо сделать файл, в котором говориться попадает или нет =(



