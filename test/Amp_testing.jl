using Plots, StructArrays, Tables, CSV, Match#, PlotlyBase, PlotlyKaleido
using XLSX, DataFrames
using Alert

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
        count_points = length(Massiv_Points_channel[channel][current_segment])
        for left_points in 1:count_points
             @info "СЧЕТЧИК = $left_points" 
            amp = 0

            for right_points in (left_points + 1):(left_points + 3)
                  @info "значение K = $right_points" 
                
                if (((right_points + 1) <= count_points) && abs(Massiv_Points_channel[channel][current_segment][left_points] - Massiv_Points_channel[channel][current_segment][right_points]) < RADIUS / koeff) #тут вылезет!
                      @info "зашли внутрь" 
                    before = Massiv_Points_channel[channel][current_segment][right_points-1]
                    after = Massiv_Points_channel[channel][current_segment][right_points]
                    #  @info "wtf k! = $right_points"                 
                    amp = amp + abs(singnal[channel][before] - singnal[channel][after])
                    f_index = left_points
                    l_index = right_points
                    #@info "inside amp = $amp" 
                end
                push!(All_Amp, [amp, left_points, l_index])

                if (Max_amp < amp)
                    #  @info "Max_amp = $Max_amp and amp = $amp "
                    Max_amp = amp
                    first_index = left_points
                    #  @info "first index = $left_points"
                    last_index = l_index
                    # @info "last index = $l_index"
                end

            end
            # push!(AMP_START_END, [Max_amp, first_index, last_index])
            FINAL_amp = Max_amp
            @info "счетчик в конце = $left_points"

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
channel = 1
Selection = 1
#Сигнал
Names_files, signal_const, signal_without_qrs, all_graph_butter, all_graph_diff, Ref_qrs, Ref_P, Place_found_P_Left_and_Right, Massiv_Amp_all_channels, Massiv_Points_channel, Referents_by_File = all_the(Name_Data_Base, Number_File)
#Сигнал в виде массива для более удобного поканальной отрисовки
Massiv_Signal = Sign_Channel(signal_const)
Names_files, Signal_copy, Frequency, _, _, Ref_File = One_Case(Name_Data_Base, Number_File)
koef  = 1000/Frequency

Massiv_Amp_all_channels_test = amp_all_cannel_(Massiv_Points_channel, all_graph_diff, koef, RADIUS)

Massiv_Amp_all_channels_test[1][1][1:10]
current_segment = 2
length(Massiv_Points_channel[channel][current_segment])
Massiv_Points_channel[channel][current_segment]
length(Massiv_Points_channel[channel])
length(Massiv_Points_channel[channel][current_segment])
1:length(Massiv_Points_channel[channel][current_segment])
plot(signal_const.I)
amp_one_channel()

length(Massiv_Points_channel[channel][current_segment])




using Alert
function Amp_index(mass_points)
    size = length(mass_points)
  #  if (size == 1)
  #      alert("Одна точка")
  #  end
    count_amp = abs(mass_points[2] - mass_points[1])

    for i in 3:4
        if(i <= size)
            count_amp = count_amp + abs(mass_points[i] - mass_points[i-1])
        end
    end

    return count_amp
end



Amp_index([3, 2, 2])


#(mass_points[Left_index + 3][2] - mass_points[Left_index][2]) < Radiuse
function Massiv(mass_points)
    size = length(mass_points)
       # @info "size = $size"

    Sovok = []
    
    for Left_index in 1:(size-1)
        Mass_points = []
        
      #  @info "Here2  $Left_index"
        if (Left_index + 2 > size)
            end_index = 1
        elseif (Left_index + 3 > size)
            end_index = 2
        else
            end_index = 3 
        end

        @info "fir = $(mass_points[Left_index][1])"
        @info "sec = $(mass_points[Left_index + end_index][1])"
        dist = mass_points[Left_index + end_index][1] - mass_points[Left_index][1]
        @info "dist  $dist"
        while(dist > 6 && end_index != 1)
            @info "no!"
            @info "dist === $dist"
            end_index = end_index - 1
            dist = mass_points[Left_index + end_index][1] - mass_points[Left_index][1]
        end

        push!(Mass_points, mass_points[Left_index][2])#, Left_index, Left_index+1])
       
     #   @info "Mass_points = $Mass_points"
     #   @info "Left_index  = $Left_index"
      ##  if(Left_index == 6)
      #      @info "MAO"
      #  end
        
        for Right_index in (Left_index + 1) : (Left_index + end_index) 
           # @info "mass_points[Right_index][2] = $(mass_points[Right_index][2])"
            push!(Mass_points, mass_points[Right_index][2]) #, Left_index, Right_index])
        end

        push!(Sovok, Mass_points)
       end
       return Sovok
    end

function Link_mass_amp(massiv_po)
    massiv = Massiv(massiv_po)
    Mass = []
    size = length(massiv)
    for i in 1:size
        push!(Mass, Amp_index(massiv[i]))
    end

    return Mass
end



##po = [3, 5, -6, 1, 4, 7]
#Link_mass_amp(po)
#po3 = [3, 5, -6]
#Link_mass_amp(po3)
#po2 = [3, 5]
#Link_mass_amp(po2)

new_po3 = [[1, 3], [5, 5], [7, -6], [8, -7]]
Massiv(new_po3)
Link_mass_amp(new_po3)

Radiuse = 6
