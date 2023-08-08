using Plots
plotly()
include("Markup_function_P.jl");
include("Function_P.jl");
include(".env");
include("../src/readfiles.jl");
include("../src/plots.jl");
include("Function_P_file.jl");
include("Plots_P.jl")
include("Create_Table.jl")


Names_files3, signals1, signal_without_qrs3, all_graph_butter3, all_graph_diff3, Ref_qrs3, Ref_P3, All_left_right3, Massiv_Amp_all_channels3, Massiv_Points_channel3, Referents_by_File3 = all_the("CSE", 1)

signals1

signal_const1 = Sign_Channel(signals1)
signal_const2 = []
for i in 1:12
    push!(signal_const2, signal_const1[i][1:300])
end
plot(signal_const1)
plot(signal_const2)


#delta = []
for i in 1:12
    del = (1600 - (i-1)*300) - signal_const1[i][1]
    signal_const2[i] = signal_const2[i] .+ del 
    #push!(delta, del)
end

delta
plot(signal_const1)
plot(signal_const2)

vline!(Ref_qrs3[1:2])
Ref_qrs3
vline!(Ref_P3[1])




Ref_P3
Massiv_Amp_all_channels3[1][1]
