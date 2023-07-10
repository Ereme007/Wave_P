using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido

plotly()
include("Function_P.jl")
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
    #График с разметкой областью поиска P
    #plot_vertical_ref(All_left_right, signal_const[1], signal_without_qrs[1], all_graph_butter[1])
    
    
end

