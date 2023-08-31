module Module_Edge
    include("Module_Signal.jl")
    import .Module_Signal as ms

    include("env.jl")
    include("Function_dist.jl")
    include("Markup_function_P.jl")

    function all_the_amp1(Name_Data_Base, Number_File)
        Name, _, _, _, _, _, Ref_P, _, Mass_amp, Mass_points, _ = ms.all_the1(Name_Data_Base, Number_File)

        size = length(Mass_amp[1])
        mass_by_selection = []
    
        for Curr_Selection in 1:size    
            Selection_Edge, left_Mediana, right_Mediana = function_Points_fronts_new(Mass_amp, Mass_points, Curr_Selection)

            left_filtr, right_filtr = Test2_Mediana_new(Selection_Edge, left_Mediana, right_Mediana)
    #@info "length(left_filtr) = $(length(left_filtr))"
    #@info "length(right_filtr) = $(length(right_filtr))"
    
            left_Sq, right_Sq = Tester_Sq_Filtr( left_filtr, right_filtr)
            push!(mass_by_selection, [left_Sq, right_Sq])
        end

        return mass_by_selection, Name[Number_File], Ref_P[1]
    end


    function all_the_amp2(Name_Data_Base, Number_File)
        Name, _, _, _, _, _, Ref_P, _, Mass_amp, Mass_points, _ = ms.all_the2(Name_Data_Base, Number_File)
   
        size = length(Mass_amp[1])
        mass_by_selection = []
    
        for Curr_Selection in 1:size    
            Selection_Edge, left_Mediana, right_Mediana = function_Points_fronts_new(Mass_amp, Mass_points, Curr_Selection)

            left_filtr, right_filtr = Test2_Mediana_new(Selection_Edge, left_Mediana, right_Mediana)
    #@info "length(left_filtr) = $(length(left_filtr))"
    #@info "length(right_filtr) = $(length(right_filtr))"
    
            left_Sq, right_Sq = Tester_Sq_Filtr( left_filtr, right_filtr)
            push!(mass_by_selection, [left_Sq, right_Sq])
        end

        return mass_by_selection, Name[Number_File], Ref_P[1]
    end

    export all_the_amp1, all_the_amp2
end