using Plots, StructArrays, Tables, CSV#, PlotlyBase, PlotlyKaleido
#для толго чтобы видеть координаты на графиках
plotly()
include("Function_P.jl")

include("../src/readfiles.jl");
include("../src/plots.jl");
#include("OneLeadQRS.jl");
include("../src/find_localmin.jl")
include(".env")

mutable struct Markup_Left_Right_Range
    Left::Int     
    Right::Int

    function Markup_Left_Right_Range()
        new(0, 0)
    end

    function Markup_Left_Right_Range(left, right)
        new(left, right)
    end
end

markup_selection1 = Dict{String, Markup_Left_Right_Range}()


mutable struct Markup_Left_Right_Front_Wave_P
    Left::Int     
    Right::Int

    function Markup_Left_Right_Front_Wave_P()
        new(0, 0)
    end

    function Markup_Left_Right_Front_Wave_P(left, right)
        new(left, right)
    end
end

markup_front_wave_P = Dict{String, Markup_Left_Right_Front_Wave_P}()



mutable struct Markupref_Left_Right_P
    Left::Int     
    Right::Int

    function Markupref_Left_Right_P()
        new(0, 0)
    end

    function Markupref_Left_Right_P(left, right)
        new(left, right)
    end
end

markupref_P = Dict{String, Markupref_Left_Right_P}()


#markup_selection.Max




n = 2
channel = 1
Selection = 10
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
#dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS" # синтетические ЭКГ

allbinfiles = getfileslist(dir)  

@info "Selection = $Selection"

fn = allbinfiles[n]


referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
#referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv"

ref = read_all_ref(referent)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]

dir
fn
signals, fs, _, _ = readbin("$dir/$(fn)") 
signals = StructVector(signals)

@info "$signals"
signals_copy = copy(signals)
referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
ref = read_all_ref(referent)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]

ref = _read_ref(n)
start_qrs = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
end_qrs= floor(Int64, refrow.QRS_end) #конец комплекса QRS
dur_qrs= floor(Int64, refrow.QRS_dur)
signals_channel = Sign_Channel(signals_copy) #12 каналов
signals_start = Sign_Channel(signals) #12 каналов


@info "$start_qrs, $end_qrs, $(ref.ibeg), $(ref.iend)"
plot(signals_start[channel])
include("Function_P.jl")

Ref_qrs = All_Ref_QRS(start_qrs, end_qrs, ref.ibeg, ref.iend)

signal_without_qrs = Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)

plot_vertical_ref(Ref_qrs, signals_start[channel], signal_without_qrs[channel])

#function Wave_P()


#Изменяемые параметы - номер файла, канал, область рассмотрения (канал и область рассм. - для детального изучения)
#Главный итог - Massiv_Points_channel



#n = 5
#channel = 2
#Selection = 5 #Область в которой мы рассматриваем зубец Р
function Wave_P(n, channel, Selection)
#n = 2
#channel = 1
#Selection = 10
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)  

@info "Selection = $Selection"

fn = allbinfiles[n]

referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
ref = read_all_ref(referent)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
@info "start"

refrow = ref[fn_ref]
@info "refrow = $refrow"

signals, fs, _, _ = readbin("$dir/$(fn)") 
signals = StructVector(signals)
#@info "$signals"
signals_copy = copy(signals)
referent = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
ref = read_all_ref(referent)  #CSE
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]

ref = _read_ref(n)
start_qrs = floor(Int64, refrow.QRS_onset) #начало комплекса QRS 
end_qrs= floor(Int64, refrow.QRS_end) #конец комплекса QRS
dur_qrs= floor(Int64, refrow.QRS_dur)
signals_channel = Sign_Channel(signals_copy) #12 каналов
signals_start = Sign_Channel(signals) #12 каналов


@info "$start_qrs, $end_qrs, $(ref.ibeg), $(ref.iend)"
plot(signals_start[channel])

Ref_qrs = All_Ref_QRS(start_qrs, end_qrs, ref.ibeg, ref.iend)

signal_without_qrs = Zero_qrs(Ref_qrs, signals_channel, start_qrs, end_qrs)

#plot(signals_start[channel])
Left, Right = Segment_left_right_P(fs, Ref_qrs, ref.ibeg, ref.iend)
Place_found_P_Left_and_Right = [Left, Right]
Tester = Place_found_P_Left_and_Right
all_graph_butter = Graph_my_butter(signal_without_qrs)
koef  = 1000/fs


@info "$Place_found_P_Left_and_Right"


dist = floor(Int64, 20/koef)
all_graph_diff = Graph_diff(all_graph_butter, dist)
Massiv_Points_channel = Sort_points_with_channel(All_points_with_channels_max_min(Place_found_P_Left_and_Right, all_graph_diff, RADIUS))

amp_one_channel(Massiv_Points_channel, all_graph_diff, koef, channel, RADIUS)
Massiv_Amp_all_channels = amp_all_cannel(Massiv_Points_channel, all_graph_diff, koef, RADIUS)


One_channel = amp_one_channel(Massiv_Points_channel, all_graph_diff, koef, channel, RADIUS)





#Графики
#1 - amp, 2 - left, 3 - right
Start_test = floor(Int64, One_channel[Selection][2])
End_test = floor(Int64, One_channel[Selection][3])



Start_sig_p = Massiv_Points_channel[channel][Selection][Start_test]
End_sig_p = Massiv_Points_channel[channel][Selection][End_test]
ind1 = Second_Diff_Left_Right(all_graph_diff, channel,End_sig_p, Place_found_P_Left_and_Right[2][Selection])
ind2 = Second_Diff_Right_Left(all_graph_diff, channel,Start_sig_p, Place_found_P_Left_and_Right[1][Selection])


p1 = (plot(all_graph_diff[channel], label = "Отфильтрованный сигнал");
vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], label = "Реф разметка");
scatter!((Start_sig_p, all_graph_diff[channel][Start_sig_p]), label = "Левая граница");
scatter!((End_sig_p, all_graph_diff[channel][End_sig_p]), label = "Правая граница");
)


#p2 = (plot(all_graph_diff[channel], label = "Отфильтрованный сигнал");
#vline!([ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg), ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg) ], label = "Реф разметка");
#scatter!((Start_sig_p, all_graph_diff[channel][Start_sig_p]), label = "Левая граница");
#scatter!((End_sig_p, all_graph_diff[channel][End_sig_p]), label = "Правая граница");

#scatter!([ind1, ind2], [all_graph_diff[channel][ind1], all_graph_diff[channel][ind2]], label = "3я производаня");)


#Massiv_Points_channel[1]
#Selec = 7
#Start_sig_p = Massiv_Points_channel[channel][Selec][Start_test];
#Start_sig_p

#plot(signals_start[channel])

#plot_vertical_ref(Place_found_P_Left_and_Right, signals_start[channel], signal_without_qrs[channel], all_graph_butter[channel], p1)
#plot_vertical_ref(Place_found_P_Left_and_Right,signal_without_qrs[channel])

markup_selection = Markup_Left_Right_Range(Place_found_P_Left_and_Right[1][Selection], Place_found_P_Left_and_Right[2][Selection])


markup_front_wave_P = Markup_Left_Right_Front_Wave_P(Start_sig_p, End_sig_p)
##markupref_P.Left = Ref_qrs[Selection*2]
##markupref_P.Right = Ref_qrs[Selection*2 + 1]


Ref_Left = ref.P_onset + (Selection-1) * (ref.iend - ref.ibeg)
Ref_Right = ref.P_offset + (Selection-1) *(ref.iend - ref.ibeg)


size_selection = length(Massiv_Points_channel[1])


    return markup_selection, markup_front_wave_P, size_selection, Ref_Left, Ref_Right, Place_found_P_Left_and_Right, signals_start[channel], signal_without_qrs[channel], all_graph_butter[channel], p1
end

Filed = 2
Ch = 1
Sel = 10
#Ref_qrs
fs = 500
Place_found_P_Left_and_Right

markup_selection1, markup_front_wave_P, size_selection, Ref_Left, Ref_Right, Place_found_P_Left_and_Right, signals_start, signal_without_qrs, all_graph_butter, p1 = Wave_P(Filed, Ch, Sel)
plot_vertical_ref(Place_found_P_Left_and_Right, signals_start, signal_without_qrs, all_graph_butter, p1)



#markup_selection = Markup_Left_Right_Range(Place_found_P_Left_and_Right[1][Sel], Place_found_P_Left_and_Right[2][Sel])
markup_selection.Left
markup_selection.Right
markup_front_wave_P.Left
markup_front_wave_P.Right
Ref_Left
Ref_Right
#сделать для реф разметки



#
#check_all = []    
#for chan in 1:12
#    check = []
#for i in 1:size_selection
#    markup_selection, markup_front_wave_P = Wave_P(Filed, chan, i)
#        if (markup_selection.Left <= markup_front_wave_P.Left && markup_selection.Right >= markup_front_wave_P.Right)
#        push!(check, true)
#    else
#        push!(check, false)
#        @info "chan, i = $chan, $i"
#        break
#    end
#    push!(check_all, check)
#end

#check
#all = true
#for i in 1:length(check)
#    if (check[i] == false)
#        all = false
#        break
#    end
#end#

#end

#all

#plot_vertical_ref(Place_found_P_Left_and_Right, signals_start[channel], signal_without_qrs[channel], all_graph_butter[channel], p1)

