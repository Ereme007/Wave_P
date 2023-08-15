using Match.jl

include("Function_dist.jl")

function comparison(Obj1, Obj2, Name_Data_Base, Number_File)
    channel = 1 #Здесь не имеет значение
    Names_files, signal_const, _, _, _, _, Ref_P, _, Massiv_Amp_all_channels, Massiv_Points_channel, _ = all_the(Name_Data_Base, Number_File)
    
    Selection = 3 #Здесь не имеет значение, но по итогу рассматриваем на 3ем отсеке (все отсеки между собой одинаковы, кроме первого)
    Selection_Edge = []
    Left_p = Ref_P[channel][Selection][1]
    Right_p = Ref_P[channel][Selection][2]

    for Current_chanel in 1:12
        Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
        #Тут Функцию по КАК РАЗ поканально в одной секции
        push!(Selection_Edge, Points_fronts)
    end

    default_result = 0
    
    Obj1 = (
    @match Obj1 begin
    "T1_MD" => Test1_MD(Selection_Edge)
    "T2_MD" => Test2_MD(Selection_Edge)
    "T1_Sq" => Test1_Square(Selection_Edge)
    "T2_Sq" => Test2_Square(Selection_Edge)
    _ => default_result
    end)
    Left1, Right1 = Delta(Left_p, Right_p, Obj1[1], Obj1[2])

    Obj2 = (
    @match Obj2 begin
    "T1_MD" => Test1_MD(Selection_Edge)
    "T2_MD" => Test2_MD(Selection_Edge)
    "T1_Sq" => Test1_Square(Selection_Edge)
    "T2_Sq" => Test2_Square(Selection_Edge)
    _ => default_result
    end)
    Left2, Right2 = Delta(Left_p, Right_p, Obj2[1], Obj2[2])

    return Left1, Right1, Left2, Right2
end

comparison("T1_Sq", "T2_Sq", "CSE", 2) #тут по X
