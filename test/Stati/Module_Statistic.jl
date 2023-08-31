module Module_Statistic
    include("Module_Edge.jl")
    import .Module_Edge as me

    include("Function_dist.jl")
    function Value_Table(Name_Data_Base, Number_File)
        Selection = 3
        
        mass_selection1, Name, Ref_P = me.all_the_amp1(Name_Data_Base, Number_File)
        mass_selection2, _, _ = me.all_the_amp2(Name_Data_Base, Number_File)
        
        left1 , right1 = mass_selection1[Selection]
        left2 , right2 = mass_selection2[Selection]
        
        P_left = Ref_P[Selection][1] 
        P_right = Ref_P[Selection][2]
        delta_left1, delta_right1 = Delta(P_left, P_right, left1, right1)
        delta_left2, delta_right2 = Delta(P_left, P_right, left2, right2)

        return Name, delta_left1, delta_right1, delta_left2, delta_right2
    end

    export Value_Table
end