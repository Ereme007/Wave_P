using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames
using Match
using Dates
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
    flag = false
    le = length(Massiv_Points_channel[channel][1])
    @info "le = $(le)"    
    for current_segment in 1:1#length(Massiv_Points_channel[channel]) # (цикл от 1 области зубца P, который возможен в сигнале до последней области - Amp_start_end)
         @info "current_segment = $((Massiv_Points_channel[channel][current_segment]))" 
        Max_amp = 0
        @info "сегмент = $current_segment"

        for i in 1:(length(Massiv_Points_channel[channel][current_segment])-2)
            flag = 0
             @info "счетчик = $i" 
            amp = 0

            for k in (i+1):(i+3)
                #  @info "значение K = $k" 
                edge_value = false
                if (((k + 1) <= length(Massiv_Points_channel[channel][current_segment]) + 1) && abs(Massiv_Points_channel[channel][current_segment][i] - Massiv_Points_channel[channel][current_segment][k]) < RADIUS / koeff && (flag == false)) #тут вылезет!
                    before = Massiv_Points_channel[channel][current_segment][k-1]
                    after = Massiv_Points_channel[channel][current_segment][k]
                    #  @info "wtf k! = $k"                 
                    amp = amp + abs(singnal[channel][before] - singnal[channel][after])
                    f_index = i
                    l_index = k
                    @info "flag = $(flag)"
                   if(k == length(Massiv_Points_channel[channel][current_segment]))
                        flag = true
                   end
                end
                if(flag == false)
                    @info "AMP = $amp, $i, $l_index, where flag = $(flag)"
                    push!(All_Amp, [amp, i, l_index])
                end
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
Name_Data_Base, Number_File = "CSE", 107
#Определённое отведение (channel)
channel = 4

#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
#Сигнал в виде массива для более удобного поканальной отрисовки
Massiv_Signal = Sign_Channel(signal_const)
Names_files, Signal_copy, Frequency, _, _, Ref_File = One_Case(Name_Data_Base, Number_File)
koef  = 1000/Frequency

Massiv_Amp_all_channels_test = amp_all_cannel_(Massiv_Points_channel, all_graph_diff, koef, RADIUS)

Massiv_Amp_all_channels_test[1][1]
current_segment = 2
length(Massiv_Points_channel[channel][current_segment])
Massiv_Points_channel[channel][current_segment]
length(Massiv_Points_channel[channel])
length(Massiv_Points_channel[channel][current_segment])
1:length(Massiv_Points_channel[channel][current_segment])




#====================================================================#

#Нахождение амплитуды и границ по одному каналу (последняя цифра - номер канала)
#Massiv_Points_channel = Sort_points_with_channel() - сортируем точки по возрастанию на всех каналах по своим промежуткам (т.е.  Sort_points_with_channel[1] - означает для 1го канала рассматриваются все области поиска, на которых в порядке возрастания расставлены локальные точки)

#Пояснение многомерного массива "Massiv_Points_channel"
#Massiv_Points_channel[channel] # на отведении channel столько отрезков (length)
#Massiv_Points_channel[channel][2] #облать имеющий номер 2
#Massiv_Points_channel[channel][2][1] #точка по X
#На вход: массив точек(Massiv_Points_channel), сигнал (singnal), коэффициент(koeff), канал(channel), радиус(RADIUS)
#На выход: AMP_START_END - структура, которая содержит амплитуду. индекс левой и правой границы фронта
function func_1(Massiv_Points_channel, singnal, koeff, channel, RADIUS)
    f_index = first_index_2 = first_index_1 = 0
    l_index = last_index_2 = last_index_1 = 0
    #только 1ая облась
    AMP_START_END = []
    Test_Fin = []
    FINAL_amp = 0
    #   OBLAST_with_channel = []
    All_Amp = []
    All_Amp_by_channel = []
    Count_segments = length(Massiv_Points_channel[channel])
    @info "1-Count_segments = $(Count_segments)" 

    for current_segment in 1:Count_segments # (цикл от 1 области зубца P, который возможен в сигнале до последней области - Amp_start_end)
        Max_amp = 0
        Max_amp_2 = 0
        Count_extrems = length(Massiv_Points_channel[channel][current_segment])
        @info "2-current_segment = $current_segment"
        @info "Count_extrems = $Count_extrems"
        for i in 1:(Count_extrems - 1)
            amp = 0
            for j in (i+1 : i+3)
                if(j > Count_extrems)
                    break
                end
                if(abs(Massiv_Points_channel[channel][current_segment][i] - Massiv_Points_channel[channel][current_segment][j]) < RADIUS / koeff)
                    before = Massiv_Points_channel[channel][current_segment][j-1]
                    after = Massiv_Points_channel[channel][current_segment][j]              
                    amp = amp + abs(singnal[channel][before] - singnal[channel][after])
                    f_index = i
                    l_index = j
                else
                    break
                end
               @info "[i, j] = [$i, $j]" 
               push!(All_Amp, [amp, i, l_index])
            end
            if(Max_amp_2 < amp)
            if (Max_amp < amp)
                Max_amp_2 = Max_amp
                #  @info "Max_amp = $Max_amp and amp = $amp "
                Max_amp = amp
                first_index_2 = first_index_1
                first_index_1 = i
                #  @info "first index = $i"
                last_index_2 = last_index_1
                last_index_1 = l_index
                # @info "last index = $l_index"
            else
                Max_amp_2 = amp
                first_index_2 = i
                #  @info "first index = $i"
                last_index_2 = l_index
            end
        end
            FINAL_amp = [Max_amp, Max_amp_2]
        end
        push!(AMP_START_END, [FINAL_amp[1], first_index_1, last_index_1, FINAL_amp[2], first_index_2, last_index_2])
      #  push!(All_Amp_by_channel, All_Amp) 
        if(first_index_1 < first_index_2 &&  abs(FINAL_amp[1] - FINAL_amp[2]) < 130)
            Fin_amp = FINAL_amp[2]
            Fin_first_index = first_index_2
            Fin_last_index = last_index_2
        else
            Fin_amp = FINAL_amp[1]
            Fin_first_index = first_index_1
            Fin_last_index = last_index_1
        end
        push!(Test_Fin, [Fin_amp, Fin_first_index, Fin_last_index])
    end 
    return Test_Fin
end

#Сведение к 12 каналам
#На вход: массив точек(Massiv_Points_channel), сигнал(signal), коэффициент(koeff), радиус (RADIUS)
#На выход: массив из 12и отведений (Final_massiv)
function func_union(Massiv_Points_channel, signal, koeff, RADIUS)
    Final_massiv = []
    
    for channel in 1:12
        push!(Final_massiv, func_1(Massiv_Points_channel, signal, koeff, channel, RADIUS))
    end
    
    return Final_massiv
end

Massiv_Points_channel[1]

Massiv_Amp_all_channels_test = func_union(Massiv_Points_channel, all_graph_diff, koef, RADIUS)

include("Module/Module_Plots.jl")
import .Module_Plots as m_plots

NUMBER = 2
Names_files, signal_const, signal_without_qrs, all_graph_butter,all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, NUMBER)
#Сигнал в виде массива для более удобного поканальной отрисовки
Massiv_Signal = Sign_Channel(signal_const)
Names_files, Signal_copy, Frequency, _, _, Ref_File = One_Case(Name_Data_Base, Number_File)
koef  = 1000/Frequency
Massiv_Amp_all_channels_test = func_union(Massiv_Points_channel, all_graph_diff, koef, RADIUS)


BaseName3, N3 = "CSE", NUMBER
Names_files3, signals_channel3, const_signal3,  Frequency3, koef3, Ref_qrs3, Ref_P3, start_signal3, end_signal3 = m_get_signal.Signal_all_channels(BaseName3, N3)
Massiv_Amp_all_channels3, Massiv_Points_channel3 = m_fronts.Defenition_Fronts(signals_channel3, Frequency3, koef3, Ref_qrs3, start_signal3, end_signal3)

left_right_one_selection3 = m_edge.function_edge(Massiv_Amp_all_channels_test, Massiv_Points_channel3)
#m_plots.plot_my_and_ref_P(const_signal3[1], left_right_one_selection3, Ref_P3)
m_plots.plot_all_channels_const_signal(const_signal3, Massiv_Amp_all_channels_test, Massiv_Points_channel3, Ref_P3)


left_right_one_selection3 = m_edge.function_edge(Massiv_Amp_all_channels3, Massiv_Points_channel3)
#m_plots.plot_my_and_ref_P(const_signal3[1], left_right_one_selection3, Ref_P3)
m_plots.plot_all_channels_const_signal(const_signal3, Massiv_Amp_all_channels3, Massiv_Points_channel3, Ref_P3)


Massiv_Amp_all_channels_test[1]
#Описание номер канала, номер отведения