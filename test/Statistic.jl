using Match

include("Function_dist.jl")


#Функция, выдающее значение дельта относительно левой и правой границы для 2х разных фитльтров (рассматриваем на 3ей секции)
#Вход: Obj1, Obj2, Name_Data_Base, Number_File
#Выход: Левая и правая дельта для 1го и 2го фильтра (Left1/Left2 для Right1/Right2)
function comparison(Obj1, Obj2, Name_Data_Base, Number_File)
    channel = 1 #Здесь не имеет значение
    Names_files, _, _, _, _, _, Ref_P, _, Massiv_Amp_all_channels, Massiv_Points_channel, _ = all_the(Name_Data_Base, Number_File)
    
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
    "T1_Med" => Test1_Mediana(Selection_Edge)
    "T2_Med" => Test2_Mediana(Selection_Edge)
    _ => default_result
    end)

    Left1, Right1 = Delta(Left_p, Right_p, Obj1[1], Obj1[2])

    Obj2 = (
    @match Obj2 begin
    "T1_MD" => Test1_MD(Selection_Edge)
    "T2_MD" => Test2_MD(Selection_Edge)
    "T1_Sq" => Test1_Square(Selection_Edge)
    "T2_Sq" => Test2_Square(Selection_Edge)
    "T1_Med" => Test1_Mediana(Selection_Edge)
    "T2_Med" => Test2_Mediana(Selection_Edge)
    _ => default_result
    end)
    Left2, Right2 = Delta(Left_p, Right_p, Obj2[1], Obj2[2])

    return Left1, Right1, Left2, Right2
end




#Функция, выдающее значение дельта относительно левой и правой границы для 2х разных фитльтров (рассматриваем на 3ей секции)
#Вход: Obj1, Obj2, Name_Data_Base, Number_File
#Выход: Левая и правая дельта для 1го и 2го фильтра (Left1/Left2 для Right1/Right2)
function stat_all_test(Obj1, Obj2, Name_Data_Base, Number_File)
    channel = 1 #Здесь не имеет значение
    Names_files, _, _, _, _, _, Ref_P, _, Massiv_Amp_all_channels, Massiv_Points_channel, _ = all_the(Name_Data_Base, Number_File)
    Names_files2, _, _, _, _, _, Ref_P2, _, Massiv_Amp_all_channels2, Massiv_Points_channel2, _ = all_the2(Name_Data_Base, Number_File)
    
    Selection = 3 #Здесь не имеет значение, но по итогу рассматриваем на 3ем отсеке (все отсеки между собой одинаковы, кроме первого)
    Selection_Edge = []
    Left_p = Ref_P[channel][Selection][1]
    Right_p = Ref_P[channel][Selection][2]

    for Current_chanel in 1:12
        Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection], Massiv_Points_channel[Current_chanel][Selection])
        #Тут Функцию по КАК РАЗ поканально в одной секции
        push!(Selection_Edge, Points_fronts)
    end

    Selection_Edge2 = []
    Left_p2 = Ref_P2[channel][Selection][1]
    Right_p2 = Ref_P2[channel][Selection][2]

    for Current_chanel2 in 1:12
        Points_fronts2 = Mark_Amp_Left_Right(Massiv_Amp_all_channels2[Current_chanel2][Selection], Massiv_Points_channel2[Current_chanel2][Selection])
        #Тут Функцию по КАК РАЗ поканально в одной секции
        push!(Selection_Edge2, Points_fronts2)
    end

    default_result = 0
    
    Obj1 = (
    @match Obj1 begin
    "T1_MD" => Test1_MD(Selection_Edge)
    "T2_MD" => Test2_MD(Selection_Edge)
    "T1_Sq" => Test1_Square(Selection_Edge)
    "T2_Sq" => Test2_Square(Selection_Edge)
    "T1_Med" => Test1_Mediana(Selection_Edge)
    "T2_Med" => Test2_Mediana(Selection_Edge)
    _ => default_result
    end)

    Left1, Right1 = Delta(Left_p, Right_p, Obj1[1], Obj1[2])

    Obj2 = (
    @match Obj2 begin
    "T1_MD" => Test1_MD(Selection_Edge2)
    "T2_MD" => Test2_MD(Selection_Edge2)
    "T1_Sq" => Test1_Square(Selection_Edge2)
    "T2_Sq" => Test2_Square(Selection_Edge2)
    "T1_Med" => Test1_Mediana(Selection_Edge2)
    "T2_Med" => Test2_Mediana(Selection_Edge2)
    _ => default_result
    end)
    Left2, Right2 = Delta(Left_p2, Right_p2, Obj2[1], Obj2[2])

    return Left1, Right1, Left2, Right2
end


#Пример вызова
#comparison("T1_Med", "T2_Med", "CSE", 2) #тут по X