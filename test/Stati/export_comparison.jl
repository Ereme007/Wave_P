#export comparison
include("Stati.jl")
import .Stati as st

include("Module_Signal.jl")
import .Module_Signal as m_si

include("Module_Edge.jl")
import .Module_Edge as m_ed

include("Module_Statistic.jl")
import .Module_Statistic as m_st

Name_Data_Base, Number_File = "CSE", 112

channel = 1
selection = 5
charr = 'p'
#import Stati: comparison

st.comparison1("T1_Med", "T2_Med", Name_Data_Base, Number_File)
st.comparison2("T1_Med", "T2_Med", Name_Data_Base, Number_File)

_, signal_const, _, signal_diff, _, _, Ref_P, _, mass_amp1, mass_points1, _ = m_si.all_the1(Name_Data_Base, Number_File)
_, _, _, _, _, _, _, _, mass_amp2, mass_points2, _ = m_si.all_the2(Name_Data_Base, Number_File)

name, del_left1, del_right1, del_left2, del_right2 = m_st.Value_Table(Name_Data_Base, Number_File)


le, name, p = m_ed.all_the_amp1(Name_Data_Base, Number_File)
le
name
p

m_ed.all_the_amp2(Name_Data_Base, Number_File)


include("Module_Plot.jl")
import .Module_Plot as m_pl
#(Current_channel, Charr, First_signal, Massiv_Amp_all_channels, Massiv_Points_channel, Second_signal, Ref_P)
m_pl.p()
include("Plots_P.jl")
using Plots
include("Markup_function_P.jl")
include("../../src/plots.jl")
#plot_channel_points(channel, Charr, signal_const, mass_amp1, mass_points1, signal_diff, Ref_P, mass_amp2, mass_points2)
#xlims!(Ref_P[Selection*2]-50, Ref_P[Selection*2+1]+50)

plot_all_channels_const_signal(signal_const, mass_amp1, mass_points1, Ref_P)

plot_all_channels_points(mass_amp1, mass_points1, signal_diff, Ref_P)
Ref_P[channel][selection]

plot_channel_points(channel, charr, mass_amp1, mass_points1, signal_diff, Ref_P, mass_amp2, mass_points2)
xlims!(Ref_P[channel][selection][1]-30, Ref_P[channel][selection][2]+30)
