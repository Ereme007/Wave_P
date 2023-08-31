#export comparison
include("Stati.jl")
import .Stati as st

include("Module_Signal.jl")
import .Module_Signal as m_si

include("Module_Edge.jl")
import .Module_Edge as m_ed

include("Module_Statistic.jl")
import .Module_Statistic as m_st

Name_Data_Base, Number_File = "CSE", 2

channel = 1
Selection = 5

#import Stati: comparison

st.comparison1("T1_Med", "T2_Med", Name_Data_Base, Number_File)
st.comparison2("T1_Med", "T2_Med", Name_Data_Base, Number_File)

_, _, _, _, _, _, _, _, mass_amp1, mass_points1, _ = m_si.all_the1(Name_Data_Base, Number_File)
_, _, _, _, _, _, _, _, mass_amp2, mass_points2, _ = m_si.all_the2(Name_Data_Base, Number_File)

name, del_left1, del_right1, del_left2, del_right2 = m_st.Value_Table(Name_Data_Base, Number_File)


le, name, p = m_ed.all_the_amp1(Name_Data_Base, Number_File)
le
name
p

l, r = le[3]
l

rig
m_ed.all_the_amp2(Name_Data_Base, Number_File)
