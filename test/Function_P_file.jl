#Возможно бесполезные проврки =(

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
        
        return Names_files, signals, fs, time, cor, Ref_File
end
    


#Определение сигнала
#Вход: Имя базы данных(BaseName), порядковый номер (N)
#Выход: Список файлов (Names_files), Первоначальный сигнал (Signal_const), Сигнал без QRS (signal_without_qrs), Сигнал my_butter (all_graph_butter), Сигнал дифференцированный (all_graph_diff), 
#Реферетная разметка QRS (Ref_qrs), Рефертеная разметка Р (Ref_P), Область поиска P (All_left_right), 
#Массив амплитуд (Massiv_Amp_all_channels), массив точек (Massiv_Points_channel), референтные значения для данного файла (Referents_by_File)
function all_the(BaseName, N)
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

    signal_without_qrs = Line_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)
    
    Left, Right = Segment_left_right_P(Frequency, Ref_qrs, Referents_by_File.ibeg, Referents_by_File.iend)
    All_left_right = [Left, Right]

    all_graph_butter = Graph_my_butter(signal_without_qrs, Frequency)    
    
    dist = floor(Int64, Dsit_Diff/koef)
    all_graph_diff = Graph_diff(all_graph_butter, dist)    

    All_Points_Min_Max = All_points_with_channels_max_min(All_left_right, all_graph_diff, RADIUS_LOCAL)
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

    return Names_files, Signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, All_left_right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File
end