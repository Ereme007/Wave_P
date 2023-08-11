#Отрисовка всяких графиков
include("Function_P_file.jl")
include("Markup_function_P.jl")
include("Function_dist.jl")
include(".env")

#Функция, строящая график исходного сигнала на 12 отведениях с реф разметкой и моей детекцией зубца Р.
#Вход - Имя базы данных (BaseName); номер файла (N)
#Выход - NULL
function plot_all_channels_const_signal(Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
    Mass_plots = []

    for Channel in 1:12
        poin = []
        
        for i in 1:length(Massiv_Points_channel[Channel][3])
            push!(poin, signal_const[Channel][Massiv_Points_channel[Channel][3][i]])
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
                vline!(Ref_P[Channel][Selection], color = "red")
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
    #plot_vertical(Mass_plots[1], Mass_plots[2])
end




#Функция, строящая график на дифференцированном сигнале, границы P из реферетного файла и найденные границы зубца Р
#Вход - имя базы данных (BaseName); номер файла (N), Сгнал (Signal_const), массив амплитуд (Massiv_Amp_all_channels), массив точек (Massiv_Points_channel), дифф сигнал (all_graph_diff), референтные значения для файла (Referents_by_File), референтные значения волны P (Ref_P)
#Выход - NULL
function plot_all_channels_points(Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Ref_P)
    #Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
    Mass_plots = []
    
    for Channel in 1:12 
        plot_plot = (
            plot(all_graph_diff[Channel]);
            size_mass = length(Massiv_Amp_all_channels[Channel]);
            
            for Selection in 1:size_mass
            # Selection = 1 ;
                vline!(Ref_P[Channel][Selection], color = "red")
                #vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Channel][Left], all_graph_diff[Channel][Right]])
                Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Channel][Selection], Massiv_Points_channel[Channel][Selection] )
#=
                Current_amp = Massiv_Amp_all_channels[Channel][Selection]
                Amp_extrem = Current_amp[1];
                Left_extrem = floor(Int64, Current_amp[2]);
                Right_extrem =  floor(Int64, Current_amp[3]);
#Massiv_Points_channel[Channel][Selection][Left_extrem]
#Massiv_Points_channel[Channel][Selection][Right_extrem]
                Current_points = Massiv_Points_channel[Channel][Selection]
                Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);=#
#Points_fronts.Left
#Points_fronts.Right
                scatter!([Points_fronts.Left, Points_fronts.Right], [all_graph_diff[Channel][Points_fronts.Left], all_graph_diff[Channel][Points_fronts.Right]]);
            end;
            plot!(title = "Отведение $Channel", legend=false)
        )

    push!(Mass_plots, plot_plot)
    end
    
    plot_vertical(Mass_plots[1], Mass_plots[2], Mass_plots[3], Mass_plots[4], Mass_plots[5], Mass_plots[6], Mass_plots[7], Mass_plots[8], Mass_plots[9], Mass_plots[10], Mass_plots[11], Mass_plots[12]);
#plot_vertical(Mass_plots[1], Mass_plots[2])
end




#Два графика. Сверху - исходный сигнал с референтной разметкой P и моей детекцией P; снизу - график с фильтрами, референтной разметкой P и всеми точками,если Charr = 'p' (который находит алгоритм. Те точки, которые отличаются по цвету, являются фронтами)
#Вход - Имя базы данных (BaseName); номер файла (N); текущее отведение (Current_channel); Символ-флаг, если р то рисуем все экстремумы (Charr) 
#Выход - NULL (значение амплитуды и файла - НЕТ) 
function plot_channel_points(Current_channel, Charr, Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Ref_P)
    #Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)    
#Current_channel = 1
    Mass_plots = []
    Out_AMP = 0
    #for Channel in 1:12
    Mass_plots_signal = []
    #@info "Mass_plots_signal = $Mass_plots_signal"
        #for Current_channel in 1:12
      #  Current_channel = 1
          
    plot_const_sug = (
        plot(Signal_const[Current_channel]);
        size_mass = length(Massiv_Amp_all_channels[Current_channel]);
        
        for Selection in 1:size_mass
   # Selection = 1 ;
            vline!(Ref_P[Current_channel][Selection], color = "red")         
   #vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Current_channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Current_channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Current_channel][Left], all_graph_diff[Current_channel][Right]])
            Mass_amp = Massiv_Amp_all_channels[Current_channel][Selection]
            Amp_extrem = Mass_amp[1];
            Left_extrem = floor(Int64, Mass_amp[2]);
            Right_extrem =  floor(Int64, Mass_amp[3]);
            
#Massiv_Points_channel[Current_channel][Selection][Left_extrem]
#Massiv_Points_channel[Current_channel][Selection][Right_extrem]
            Mass_points = Massiv_Points_channel[Current_channel][Selection]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Mass_points[Left_extrem], Mass_points[Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
            scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[Current_channel][Points_fronts.Left], Signal_const[Current_channel][Points_fronts.Right]]);
                
              #  if(Current_channel == 12)
              #  @info "Отведение(1) $Current_channel left = $(Signal_const[Current_channel][Points_fronts.Left]), Right = $(Signal_const[Current_channel][Points_fronts.Right])"
              #  end
              
        end;

        plot!(title = "Отведение $Current_channel", legend=false);    
    )
           # @info "Mass_plots_signal = $Mass_plots_signal"
    push!(Mass_plots_signal, plot_const_sug)
       # end
       #@info "Mass_plots_signal = $Mass_plots_signal"
    #end
    plot_front_sig = (
        plot(all_graph_diff[Current_channel]);
        size_mass = length(Massiv_Amp_all_channels[Current_channel]);
      #  @info "$(Ref_P[Current_channel])";
        vline!(Ref_P[Current_channel], lc=:red);
        
        for Selection in 1:size_mass
            if(Charr == 'p')
                poi = Massiv_Points_channel[Current_channel][Selection]
                #@info "points $poi"
                scatter!(poi, all_graph_diff[Current_channel][poi])
            end;
   # Selection = 1 ;
            count_selections = length(Massiv_Amp_all_channels[Current_channel]);
           # lik = Function_Ref_P(count_selections, Referents_by_File);
         #   vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red);
#Left = Massiv_Amp_all_channels[Current_channel][Selection][2]
#Right =  Massiv_Amp_all_channels[Current_channel][Selection][3]
#scatter!([Left, Right], [all_graph_diff[Current_channel][Left], all_graph_diff[Current_channel][Right]])
            Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_channel][Selection], Massiv_Points_channel[Current_channel][Selection])
#=
            Current_amp = Massiv_Amp_all_channels[Current_channel][Selection]
            Amp_extrem = Current_amp[1];
            Out_AMP = Amp_extrem;
            Left_extrem = floor(Int64, Current_amp[2]);
            Right_extrem =  floor(Int64, Current_amp[3]);
#Massiv_Points_channel[Current_channel][Selection][Left_extrem]
#Massiv_Points_channel[Current_channel][Selection][Right_extrem]
            Current_points = Massiv_Points_channel[Current_channel][Selection]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
#Points_fronts.Left
#Points_fronts.Right
=#
            scatter!([Points_fronts.Left, Points_fronts.Right], [all_graph_diff[Current_channel][Points_fronts.Left], all_graph_diff[Current_channel][Points_fronts.Right]]);
           # @info "Left = $(Points_fronts.Left)  Right = $(Points_fronts.Right)"
        end;

        plot!(title = "Отведение $Current_channel", legend=false)
    )

    push!(Mass_plots, plot_front_sig)

    #Current_channel = 1
    plot_vertical(Mass_plots_signal[1], Mass_plots[1])

    #plot!(title = "Отведение $Current_channel, файл $BaseName")
  # return Out_AMP
end



#Функция строит исходный сигнал на заданном отведении
#Вход - имя базы данных (BaseName); номер файла (N); Текущее отведение (Current_chanel), рефертная разметка P (Ref_P)
#Выход - NULL
function plot_const_signal(BaseName, Current_chanel, Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, Ref_P)
    #Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
    #plot(Signal_const[Current_chanel], label = "Исх сиг $BaseName отведение $Current_chanel")
    plot(Signal_const[Current_chanel], label = false);
    title!("Исходный сигнал $BaseName отведение $Current_chanel");
    size_mass = length(Massiv_Amp_all_channels[Current_chanel]);
    
    for Selection in 1:size_mass
        #vline!([Referents_by_File.P_onset + (Selection-1) * (Referents_by_File.iend - Referents_by_File.ibeg), Referents_by_File.P_offset + (Selection-1) *(Referents_by_File.iend - Referents_by_File.ibeg) ], lc=:red,  label=false);
        vline!(Ref_P[Current_chanel][Selection], color = "red")
        Points_fronts = Mark_Amp_Left_Right(Massiv_Amp_all_channels[Current_chanel][Selection],  Massiv_Points_channel[Current_chanel][Selection])
        scatter!([Points_fronts.Left, Points_fronts.Right], [Signal_const[Current_chanel][Points_fronts.Left], Signal_const[Current_chanel][Points_fronts.Right]], label=false);
    end
end