#Функция, которая говорит расположение расположение той или иной базы данных
#Вход - имя базы данных (пример "CSE")
#Выход - кортеж имен для данной базы данных(allbinfiles), Путь к базе данных(raw_base_data)
function Position_Data_Base(Type_Data_base)
    if (Type_Data_base == "CSE")
        raw_base_data = Raw_CSE_MA_Data_Base_Incart # синтетические ЭКГ CSE_MA
        allbinfiles = getfileslist(raw_base_data) 
    elseif (Type_Data_base == "CTS")
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
            return false
        end

        ref_all_file = read_all_ref(raw_ref) 
        fn_ref = filename[1:2] == "MA" ? "MO" * filename[3:end] : filename
        
        ref_file = ref_all_file[fn_ref]

        return Data_base, ref_file, ref_all_file, raw_ref
    else
        return false, false, false, false
    
    end
end


#Функция считывания сигнала
#Вход - Имя базы данных BaseName (пример "CSE"), номер файла N(пример 12)
#Выход - имя файла, сигнал, частота, референтная
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

    return Names_files[N], signals, fs, Ref_File
end

#Функция записывает сигнал в 12 каналов
#Вход: Структура сигнала (Signal)
#Выход: Массив, в которм 12 ячеек
function Sign_Channel(Signal)
    return [Signal.I, Signal.II, Signal.III, Signal.aVR, Signal.aVL, Signal.aVF, Signal.V1, Signal.V2, Signal.V3, Signal.V4, Signal.V5, Signal.V6]
end


#Функция составления реферетной разметки для QRS
#На вход границы qrs и границы сигнала, на выход все рефенетнаые границы qrs 
#Верно только для искусственнного сигнала
function All_Ref_QRS(signals, start_qrs, end_qrs, start_sig, end_sig)
    Distance = end_sig - start_sig
    dur_qrs = end_qrs - start_qrs
    All_ref_qrs = Int64[]

    push!(All_ref_qrs, start_qrs)
    push!(All_ref_qrs, end_qrs)

    index = start_qrs + Distance

    while (index < length(signals))
        push!(All_ref_qrs, index)

        if (index + dur_qrs < length(signals))
            push!(All_ref_qrs, index + dur_qrs)
        end

        index = index + Distance + 1
    end
    
    return All_ref_qrs
end


#Функция составления реферетной разметки для волны Р
#Вход - количество областей поисак P
#Выход - Массив реферетных значений волны P на всём сигнале
function Function_Ref_P(ALL_SELECTION, Referents_by_File)
    Ref_P = []
    
    for Selection in 1:ALL_SELECTION
        k = ([Referents_by_File.P_onset - 1 + (Selection - 1) * (Referents_by_File.iend - Referents_by_File.ibeg + 1), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg + 1) - 1 ]);
        push!(Ref_P, k)
    end
    
    return Ref_P
end