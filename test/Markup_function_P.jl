mutable struct Markup_Left_Right_Front_Wave_P_amp_2
    Amp::Float64
    Left::Int     
    Right::Int


    function Markup_Left_Right_Front_Wave_P_amp_2()
        new(0, 0, 0)
    end

    function Markup_Left_Right_Front_Wave_P_amp_2(amp, left, right)
        new(amp, left, right)
    end
end

markup_front_wave_P_amp = Dict{String, Markup_Left_Right_Front_Wave_P_amp_2}()

#= Функция. которая переводит массив Massiv_Amp_all_channels в Amp Left Right (Points_fronts)=#

function Mark_Amp_Left_Right(massiv_amp_all_channels, massiv_points_channel)
    Current_amp = massiv_amp_all_channels
    Amp_extrem = Current_amp[1];
    Left_extrem = floor(Int64, Current_amp[2]);
    Right_extrem =  floor(Int64, Current_amp[3]);
    Current_points = massiv_points_channel
    Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
    return Points_fronts
end
    
