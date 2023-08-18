using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames
using Match

#Если хотим сохранить картинки - отключчаем ploty()
plotly()

include("Markup_function_P.jl");
include("Function_P.jl");
include(".env");
include("../src/readfiles.jl");
include("../src/plots.jl");
include("Function_P_file.jl");
include("Plots_P.jl")
include("Create_Table.jl")
include("Statistic.jl")



#====================================================================#

#Нахождение амплитуды и границ по одному каналу (последняя цифра - номер канала)
#Massiv_Points_channel = Sort_points_with_channel() - сортируем точки по возрастанию на всех каналах по своим промежуткам (т.е.  Sort_points_with_channel[1] - означает для 1го канала рассматриваются все области поиска, на которых в порядке возрастания расставлены локальные точки)

#Пояснение многомерного массива "Massiv_Points_channel"
#Massiv_Points_channel[channel] # на отведении channel столько отрезков (length)
#Massiv_Points_channel[channel][2] #облать имеющий номер 2
#Massiv_Points_channel[channel][2][1] #точка по X
#На вход: массив точек(Massiv_Points_channel), сигнал (singnal), коэффициент(koeff), канал(channel), радиус(RADIUS)
#На выход: AMP_START_END - структура, которая содержит амплитуду. индекс левой и правой границы фронта
function amp_one_channel_(Massiv_Points_channel, singnal, koeff, channel, RADIUS)
    #@info "Start amp_one_channel"
    #@info "length(Massiv_Points_channel[channel]) = $(length(Massiv_Points_channel[channel]))"
    f_index = first_index = 0
    l_index = last_index = 0
    #только 1ая облась
    AMP_START_END = []
    FINAL_amp = 0
    #   OBLAST_with_channel = []
    All_Amp = []
    All_Amp_by_channel = []
    for current_segment in 1:1#length(Massiv_Points_channel[channel]) # (цикл от 1 области зубца P, который возможен в сигнале до последней области - Amp_start_end)
         @info "current_segment = $((Massiv_Points_channel[channel][current_segment]))" 
        Max_amp = 0
        @info "сегмент = $current_segment" 
        for i in 1:length(Massiv_Points_channel[channel][current_segment])
             @info "счетчик = $i" 
            amp = 0

            for k in (i+1):(i+3)
                #  @info "значение K = $k" 
                
                if (((k + 1) <= length(Massiv_Points_channel[channel][current_segment])) && abs(Massiv_Points_channel[channel][current_segment][i] - Massiv_Points_channel[channel][current_segment][k]) < RADIUS / koeff) #тут вылезет!
                    #  @info "зашли внутрь" 
                    before = Massiv_Points_channel[channel][current_segment][k-1]
                    after = Massiv_Points_channel[channel][current_segment][k]
                    #  @info "wtf k! = $k"                 
                    amp = amp + abs(singnal[channel][before] - singnal[channel][after])
                    f_index = i
                    l_index = k
                    #@info "inside amp = $amp" 
                end
                push!(All_Amp, [amp, i, l_index])

                if (Max_amp < amp)
                    #  @info "Max_amp = $Max_amp and amp = $amp "
                    Max_amp = amp
                    first_index = i
                    #  @info "first index = $i"
                    last_index = l_index
                    # @info "last index = $l_index"
                end

            end
            # push!(AMP_START_END, [Max_amp, first_index, last_index])
            FINAL_amp = Max_amp
            @info "счетчик в конце = $i"

        end
        
        push!(AMP_START_END, [FINAL_amp, first_index, last_index])
        push!(All_Amp_by_channel, All_Amp)
        #  запоминаем, что на участке под номером OBL, амплитуду Max_amp, начало и конец first_index last_index
    end
    #push!(OBLAST_with_channel, AMP_START_END)

    return All_Amp_by_channel
end


#Сведение к 12 каналам
#На вход: массив точек(Massiv_Points_channel), сигнал(signal), коэффициент(koeff), радиус (RADIUS)
#На выход: массив из 12и отведений (Final_massiv)
function amp_all_cannel_(Massiv_Points_channel, signal, koeff, RADIUS)
    Final_massiv = []
    
    for channel in 1:1
        push!(Final_massiv, amp_one_channel_(Massiv_Points_channel, signal, koeff, channel, RADIUS))
    end
    
    return Final_massiv
end



#Наименование базы данных и номер файла ("CSE")
Name_Data_Base, Number_File = "CSE", 2
#Определённое отведение (channel)
channel = 4

#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
#Сигнал в виде массива для более удобного поканальной отрисовки
Massiv_Signal = Sign_Channel(signal_const)
Names_files, Signal_copy, Frequency, _, _, Ref_File = One_Case(Name_Data_Base, Number_File)
koef  = 1000/Frequency

Massiv_Amp_all_channels_test = amp_all_cannel_(Massiv_Points_channel, all_graph_diff, koef, RADIUS)

Massiv_Amp_all_channels_test[1][1][10:30]
current_segment = 2
length(Massiv_Points_channel[channel][current_segment])
Massiv_Points_channel[channel][current_segment]
length(Massiv_Points_channel[channel])
length(Massiv_Points_channel[channel][current_segment])
1:length(Massiv_Points_channel[channel][current_segment])