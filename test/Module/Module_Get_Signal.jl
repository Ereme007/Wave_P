module Module_Get_Signal
    using CSV, DataFrames, Dates
    include("../../src/readfiles.jl")
    include("env.jl")
    include("Functions_for_Module_Get_Signal.jl")


    #Сигналс характиристиками 
    #Вход: Наименование базы данных(BaseName), номер (N)
    #Выход: Имя, сигнал, частота, коефф, референтная разметка qrs, референтная разметка p
    function Signal_all_channels(BaseName, N)
        #Сигнал (имя, сигнал, частота, вся референтная рамзетка)
        Names_files, Signal_const, Frequency, Ref_File = One_Case(BaseName, N)
        
        #Дополнительные параметры
        koef  = 1000/Frequency
        Referents_by_File = _read_ref(N)
        start_qrs = floor(Int64, Ref_File.QRS_onset) #начало комплекса QRS (INT)
        end_qrs = floor(Int64, Ref_File.QRS_end)
        start_signal = floor(Int64, Referents_by_File.ibeg) #в Ref_File нет поля начала и конца сигнала(ibeg)
        end_signal = floor(Int64,  Referents_by_File.iend) #в Ref_File нет поля начала и конца сигнала(iend)


        #Сигнал в виде массива
        signals_channel = Sign_Channel(Signal_const)

        #Референтная разметка QRS
        Ref_qrs = All_Ref_QRS(signals_channel[1], start_qrs, end_qrs, start_signal, end_signal)

        #Референтная разетка P
        count_selections = length(Ref_qrs)
        Ref_P = Function_Ref_P(count_selections, Referents_by_File)

        return Names_files, signals_channel, Frequency, koef, Ref_qrs, Ref_P, start_signal, end_signal
    end

    export  Signal_all_channels
end