module Module_Plots
    Low_Hight = 75

    using Plots
    plotly()
    include("../../src/plots.jl")
    Selection = 2
    
    #Главные функции
    function plot_my_and_ref_P(signal, my_edge, ref_p)
        plot(signal, legend = false)
        vline!(my_edge, color = :green)
        vline!(ref_p, color = :red)
        xlims!(ref_p[Selection][1] - 50, ref_p[Selection + 1][2] + 50)     
    end

    #Можно добавить график всех первичных границ по всем отведениям
    function plot_all_channels_const_signal(Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
        Mass_plots = []
    
        for Channel in 1:12
            poin = []
            
            for i in 1:length(Massiv_Points_channel[Channel][3])
                push!(poin, Signal_const[Channel][Massiv_Points_channel[Channel][3][i]])
            end  
    
            Hight = sort!(poin)[length(Massiv_Points_channel[Channel][3])] + Low_Hight
            Low = sort!(poin)[1] - Low_Hight
            co = 1
    
            plot_plot = (
                plot(Signal_const[Channel], ylim = [Low, Hight]);
                size_mass = length(Massiv_Amp_all_channels[Channel]);
                
                for Selection in 1:size_mass
                # Selection = 1;
                    #vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg) - 1, Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) - 1 ], lc=:red);
                    vline!(Ref_P[Selection], color = :red)
    #Left = Massiv_Amp_all_channels[Channel][Selection][2]
    #Right =  Massiv_Amp_all_channels[Channel][Selection][3]
    #scatter!([Left, Right], [Signal_const[Channel][Left], Signal_const[Channel][Right]])
                    
                    Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Channel][Selection], Massiv_Points_channel[Channel][Selection] )
    #=Current_amp = Massiv_Amp_all_channels[Channel][Selection]
                    Amp_extrem = Current_amp[1];
                    Left_extrem = floor(Int64, Current_amp[2]);
                    Right_extrem =  floor(Int64, Current_amp[3]);
    #Massiv_Points_channel[Channel][Selection][Left_extrem]
    #Massiv_Points_channel[Channel][Selection][Right_extrem]
                    Current_points = Massiv_Points_channel[Channel][Selection]
                    Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
    #Points_fronts.Left
    #Points_fronts.Right
    =#
                    scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[Channel][Points_fronts.Left], Signal_const[Channel][Points_fronts.Right]]);
                    
                    if (co == 1)
                   # @info "Amp_extrem[$Channel] = $(Points_fronts.Amp)";
                        co = 2
                    end
                end;
                
                plot!(title = "Отведение $Channel")#, legend=false)
            )
    
        push!(Mass_plots, plot_plot)
        end
    
        plot_vertical(Mass_plots[1], Mass_plots[2], Mass_plots[3], Mass_plots[4], Mass_plots[5], Mass_plots[6], Mass_plots[7], Mass_plots[8], Mass_plots[9], Mass_plots[10], Mass_plots[11], Mass_plots[12]);
        xlims!(Ref_P[Selection][1] - 50, Ref_P[Selection + 1][2] + 50)  
    end
    
    #Второстепенна функция
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
    
    #= Функция, которая переводит массив Massiv_Amp_all_channels в Amp Left Right (Points_fronts)=#
    #Вход: Массив амплитуд и массив точек
    #Выход: Структура, у которой поля Amp Left Right
    function Mark_Amp_Left_Right(massiv_amp_all_channels, massiv_points_channel)
        Current_amp = massiv_amp_all_channels
        Amp_extrem = Current_amp[1];
        Left_extrem = floor(Int64, Current_amp[2]);
        Right_extrem =  floor(Int64, Current_amp[3]);
        Current_points = massiv_points_channel
        Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
        
        return Points_fronts
    end
    
    export plot_my_and_ref_P, plot_all_channels_const_signal
end