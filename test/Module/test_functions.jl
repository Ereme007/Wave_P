#Тестируем Module_Get_Signal
include("Module_Get_Signal.jl")
import .Module_Get_Signal as mg
BaseName, N = "CSE", 1

#Correct = mg.Signal_all_channels(BaseName, N)

now = mg.Signal_all_channels(BaseName, N)

Correct == now

#Тестируем Module_Fronts
BaseName, N = "CSE", 1
Names_files2, signals_channel2, Frequency2, koef2, Ref_qrs2, Ref_P2, start_signal2, end_signal2 = mg.Signal_all_channels(BaseName, N)

include("Module_Fronts.jl")
import .Module_Fronts as mf
Massiv_Amp_all_channels2, Massiv_Points_channel2 = mf.Defenition_Fronts(signals_channel2, Frequency2, koef2, Ref_qrs2, start_signal2, end_signal2)
Count_Selection = length(Massiv_Amp_all_channels2[1])

#Тестируем Module_Edge
include("Module_Edge.jl")
import .Module_Edge as me
left_right_one_selection2 = me.function_edge(Massiv_Amp_all_channels2, Massiv_Points_channel2)

#Проверка размерности
Count_Selection == (length(me.function_edge(Massiv_Amp_all_channels2, Massiv_Points_channel2)))

left_right_one_selection2[2]



#Сплошное тестирование:
include("Module_Get_Signal.jl")
import .Module_Get_Signal as m_get_signal

include("Module_Fronts.jl")
import .Module_Fronts as m_fronts

include("Module_Edge.jl")
import .Module_Edge as m_edge

BaseName3, N3 = "CSE", 3
Names_files3, signals_channel3, Frequency3, koef3, Ref_qrs3, Ref_P3, start_signal3, end_signal3 = m_get_signal.Signal_all_channels(BaseName3, N3)
Massiv_Amp_all_channels3, Massiv_Points_channel3 = m_fronts.Defenition_Fronts(signals_channel3, Frequency3, koef3, Ref_qrs3, start_signal3, end_signal3)
left_right_one_selection2 = m_edge.function_edge(Massiv_Amp_all_channels3, Massiv_Points_channel3)
