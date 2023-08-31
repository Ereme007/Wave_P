#Возможно бесполезные проверки =(

#Область рассмотрения проекта
#Вход - имя базы данных ("CSE")
#Выход - кортеж имен для данной базы данных ; Путь к базе данных
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
    


