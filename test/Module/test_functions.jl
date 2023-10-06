#Тестируем Module_Get_Signal
include("Module_Get_Signal.jl")
import .Module_Get_Signal as mg
NUMBER = 3
BaseName, N = "CSE", NUMBER

now = mg.Signal_all_channels(BaseName, N)


#Тестируем Module_Fronts
BaseName, N = "CSE", NUMBER
Names_files2, signals_channel2, const_signal2, Frequency2, koef2, Ref_qrs2, Ref_P2, start_signal2, end_signal2 = mg.Signal_all_channels(BaseName, N)

include("Module_Fronts.jl")
import .Module_Fronts as mf
Massiv_Amp_all_channels2, Massiv_Points_channel2 = mf.Defenition_Fronts(signals_channel2, Frequency2, koef2, Ref_qrs2, start_signal2, end_signal2)
Massiv_Amp_all_channels2[1]


Massiv_Amp_all_channels2[1][2]


#Тестируем Module_Edge
include("Module_Edge.jl")
import .Module_Edge as me
left_right_one_selection2 = me.function_edge(Massiv_Amp_all_channels2, Massiv_Points_channel2)

#Проверка размерности
Count_Selection == (length(me.function_edge(Massiv_Amp_all_channels2, Massiv_Points_channel2)))

left_right_one_selection2[2]

#Тестируем Module_Plot
include("Module_Plots.jl")
import .Module_Plots as m_p
m_p.plot_my_and_ref_P(const_signal2[1], left_right_one_selection2, Ref_P2)
Ref_P2

m_p.plot_all_channels_const_signal(const_signal2, Massiv_Amp_all_channels2, Massiv_Points_channel2, Ref_P2)

include("Module_Statistics.jl")
import .Module_Statistics as m_st
#Пусть рассматриваем кусок под номером 3
left_right_one_selection2[3][1] - Ref_P2[3][1]
Ref_P2[3][2] -left_right_one_selection2[3][2]
m_st.Statistic(left_right_one_selection2[3], Ref_P2[3])


include("Module_Statistics_CSV.jl")
import .Module_Statistics_CSV as m_st_csv
#m_st_csv.func()




#Сплошное тестирование:
include("Module_Get_Signal.jl")
import .Module_Get_Signal as m_get_signal

include("Module_Fronts.jl")
import .Module_Fronts as m_fronts

include("Module_Edge.jl")
import .Module_Edge as m_edge

include("Module_Plots.jl")
import .Module_Plots as m_plots

NUMBER = 3
BaseName3, N3 = "CSE", NUMBER
Names_files3, signals_channel3, const_signal3,  Frequency3, koef3, Ref_qrs3, Ref_P3, start_signal3, end_signal3 = m_get_signal.Signal_all_channels(BaseName3, N3)
Ref_qrs3
b=copy(Ref_qrs3[3:34])

Ref_P3
Massiv_Amp_all_channels3, Massiv_Points_channel3 = m_fronts.Defenition_Fronts(signals_channel3, Frequency3, Ref_qrs3)
left_right_one_selection3 = m_edge.function_edge(Massiv_Amp_all_channels3, Massiv_Points_channel3)
m_plots.plot_all_channels_const_signal(const_signal3, Massiv_Amp_all_channels3, Massiv_Points_channel3, Ref_P3)

Massiv_Amp_all_channelsThree, Massiv_Points_channelThree = m_fronts.Three(signals_channel3, Frequency3, Ref_qrs3)
left_right_one_selectionThree = m_edge.function_edge(Massiv_Amp_all_channelsThree, Massiv_Points_channelThree)
m_plots.plot_all_channels_const_signal(const_signal3, Massiv_Amp_all_channelsThree, Massiv_Points_channelThree, Ref_P3)

const_signal3 == signals_channel3

#plot(const_signal3[1])
m_plots.plot_my_and_ref_P(const_signal3[1], left_right_one_selection3, Ref_P3)
m_plots.plot_my_and_ref_P(const_signal3[1], left_right_one_selectionThree, Ref_P3)
m_plots.plot_all_channels_const_signal(const_signal3, Massiv_Amp_all_channels3, Massiv_Points_channel3, Ref_P3)

include("Module_Statistics.jl")
import .Module_Statistics as m_statistics
m_statistics.Statistic(left_right_one_selectionThree[3], Ref_P3[3])


include("Module_Statistics_CSV.jl")
import .Module_Statistics_CSV as m_statistics_csv
#m_statistics_csv.func(BaseName3, "test_Defenition_Fronts_edge")



include("Module_Amp_CSV.jl")
import .Module_Amp_CSV as m_amp_csv
#m_amp_csv.func(BaseName3, "test_THREE_amp")

#=====#
include("Module_Fronts.jl")
NUMBER = 1
BaseName3, N3 = "CSE", NUMBER
Names_files3, signals_channel3, const_signal3,  Frequency3, koef3, Ref_qrs3, Ref_P3, start_signal3, end_signal3 = m_get_signal.Signal_all_channels(BaseName3, N3)
Massiv_Amp_all_channels3, Massiv_Points_channel3, n = m_fronts.All_amp(signals_channel3, Frequency3, koef3, Ref_qrs3, start_signal3, end_signal3)
Massiv_Amp_all_channels3, Massiv_Points_channel3 = m_fronts.Defenition_Fronts(signals_channel3, Frequency3, koef3, Ref_qrs3, start_signal3, end_signal3)
n[12][2]
Massiv_Amp_all_channels3[12][2]
Massiv_Amp_all_channels3[12][2][1] - sort(n[12][2])[1][1]

plot(const_signal3[12])