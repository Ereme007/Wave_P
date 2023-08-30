#export comparison
include("test/Stati/Stati.jl")

Name_Data_Base, Number_File = "CSE", 35

channel = 1
Selection = 5


import .Stati as st

import Stati: comparison

st.comparison("T1_Med", "T2_Med", Name_Data_Base, Number_File)