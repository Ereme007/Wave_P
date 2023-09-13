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
