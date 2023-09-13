include("Module_Get_Signal.jl")
import .Module_Get_Signal as mg
BaseName, N = "CSE", 1

#Correct = mg.Signal_12_channels(BaseName, N)

now = mg.Signal_all_channels(BaseName, N)

Correct == now