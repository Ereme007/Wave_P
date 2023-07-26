x1 = 10
x2 = 33
y1 = 14
y2 = 22

(X - x1)/(x2-x1) = (Y-y1)/(y2-y1)


(y2-y1)/(x2-x1)
8/23

X = x1
Y = y1
b =  Y - X*(y2-y1)/(x2-x1) 
242/23

#определяем k потом b потом по точкам строим график прямой и это будет массив длинной qrs

k = (y2-y1)/(x2-x1)
b =  y1 - x1*(y2-y1)/(x2-x1) 
Mass_line = []
for i in (x1+1):(x2-1)
    push!(Mass_line, k*i + b)
end
Mass_line

plot(Mass_line)



include("Test_P_5.jl")
    BaseName = "CSE"
    N = 1
    Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
    size_mass = length(Massiv_Amp_all_channels[1]);
    Selection_Edge = []
    #for Selection in 1:size_mass
    Selection = 3   
        
        for Current_chanel in 1:12
            #Current_chanel = 1
            Current_amp = Massiv_Amp_all_channels[Current_chanel][Selection];
            Amp_extrem = Current_amp[1];
            Left_extrem = floor(Int64, Current_amp[2]);
            Right_extrem =  floor(Int64, Current_amp[3]);
            Current_points = Massiv_Points_channel[Current_chanel][Selection]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
            #Тут Функцию по КАК РАЗ поканально в одной секции
            push!(Selection_Edge, Points_fronts)

            
        end
        #push!(Selection_Edge, Points_fronts)
    #end
    #return Selection_Edge
    Selection_Edge
    
    left = []
    right = []
    for Selection in 1:12
        push!(left, Selection_Edge[Selection].Left)
        push!(right, Selection_Edge[Selection].Right)
    end
    x = 1:12

    plot(x, left)

    left
    size_left = length(left)
    #right

    Max = []
    Index = []
    for i in 1:size_left
        
        Now_point = left[i]
        @info "Now_point = $Now_point"
        Max_dist = 0
        j = 1
        while(j <= size_left)
            dist = abs(Now_point - left[j])
            @info "left[j] =  $(left[j])"
            if (dist > Max_dist)
                Max_dist = dist
            end
            j = j + 1
        end
        push!(Max, Max_dist)
        push!(Index, floor(Int64,j))
    end
    Max
    sort(Max)
    a = sort(Max)[1]


    plot(x, right)
    
    
    Max = []
    Index = []
    for i in 1:size_left
        
        Now_point = right[i]
        @info "Now_point = $Now_point"
        Max_dist = 0
        j = 1
        while(j <= size_left)
            dist = abs(Now_point - right[j])
            @info "right[j] =  $(right[j])"
            if (dist > Max_dist)
                Max_dist = dist
            end
            j = j + 1
        end
        push!(Max, Max_dist)
        push!(Index, floor(Int64,j))
    end
    Max
    sort(Max)
    a = sort(Max)[1]
    #return left, right 


    sums = 0
    for nn in 1:12
        sums = sums + right[nn]
    end
    sums
    Sred = sums/12

    DDist = []
    for nn in 1:12
        dd = abs(right[nn] - Sred)
        Index =  nn
        push!(DDist, [dd, Index])
    end
    DDist
    sort(DDist)


    sums = 0
    for nn in 1:12
        sums = sums + left[nn]
    end
    sums
    Sred = sums/12

    DDist = []
    for nn in 1:12
        dd = abs(left[nn] - Sred)
        Index =  nn
        push!(DDist, [dd, Index])
    end
    DDist
    sort(DDist)
    di = sort(DDist)[1][1]
    ini = floor(Int64, sort(DDist)[1][2])
#end

function Mean_value(Massiv_points)
    sums = 0
    size_Massiv_points = length(Massiv_points)
    for nn in 1:size_Massiv_points
        sums = sums + Massiv_points[nn]
    end
    sums
    Sred = sums/size_Massiv_points

    DDist = []
    for nn in 1:size_Massiv_points
        dd = abs(Massiv_points[nn] - Sred)
        Index =  nn
        value = Massiv_points[nn]
        push!(DDist, [dd, Index, value])
    end
    DDist
    sort(DDist)
    di = sort(DDist)[1][1]
    ini = floor(Int64, sort(DDist)[1][2])
    val = floor(Int64, sort(DDist)[1][3])
    return di, ini, val
end

function Min_dist_to_all_points(Massiv_Edge)
    size_left = length(Massiv_Edge)
    Max = []
    for i in 1:size_left
        Now_point = Massiv_Edge[i]
        #@info "Now_point = $Now_point"
        Max_dist = 0
        j = 1
        Index = 0
        Value = 0
        while(j <= size_left)
            dist = abs(Now_point - Massiv_Edge[j])
            #@info "Massiv_Edge[j] =  $(Massiv_Edge[j])"
            if (dist > Max_dist)
                Max_dist = dist
                Index = i
                Value = Now_point
            end
            j = j + 1
        end
        push!(Max, [Max_dist, Index, Value])
    end
    
    ma = sort(Max)[1]
    di = ma[1]
    ini = ma[2]
    val = ma[3]

    return di, ini, val
end

function Test1(Selection_Edge) 
    left = []
    right = []   
    for Selection in 1:12
        push!(left, Selection_Edge[Selection].Left)
        push!(right, Selection_Edge[Selection].Right)
    end
    return left, right
end


function Test2(Selection_Edge)
    left = []
    right = []
    Curr_Sel_left = 2
    Curr_Sel_right = 2
    push!(left, Selection_Edge[Selection].Left)
    push!(right, Selection_Edge[Selection].Right)
    for Selection in 2:12
        # @info "abs(left[Selection-1] - left[Selection]) = $(abs(left[Selection-1] - left[Selection-1]))"
        # @info "Sel = $(left[Selection-1])"
         if(abs(left[Curr_Sel_left-1] - Selection_Edge[Selection].Left) < 78)
         push!(left, Selection_Edge[Selection].Left)
         Curr_Sel_left = Curr_Sel_left + 1
         end
         if(abs(right[Curr_Sel_right-1] - Selection_Edge[Selection].Right) < 78)
         push!(right, Selection_Edge[Selection].Right)
         Curr_Sel_right = Curr_Sel_right + 1
         end
     end 
     return left, right
end

BaseName = "CSE"
    N = 15
        Signal_const, Massiv_Amp_all_channels, Massiv_Points_channel, all_graph_diff, Referents_by_File = all_the(BaseName, N)
        Referents_by_File
        size_mass = length(Massiv_Amp_all_channels[1]);
    Selection_Edge = []
    #for Selection in 1:size_mass
    Selection = 3   
        
        for Current_chanel in 1:12
            #Current_chanel = 1
            Current_amp = Massiv_Amp_all_channels[Current_chanel][Selection];
            Amp_extrem = Current_amp[1];
            Left_extrem = floor(Int64, Current_amp[2]);
            Right_extrem =  floor(Int64, Current_amp[3]);
            Current_points = Massiv_Points_channel[Current_chanel][Selection]
            Points_fronts = Markup_Left_Right_Front_Wave_P_amp_2(Amp_extrem, Current_points[Left_extrem], Current_points[Right_extrem]);
            #Тут Функцию по КАК РАЗ поканально в одной секции
            push!(Selection_Edge, Points_fronts)

            
        end
        #push!(Selection_Edge, Points_fronts)
    #end
    #return Selection_Edge
    Selection_Edge
    

    
    left, right = Test1(Selection_Edge)
    left 
    right
    x = 1:length(left)
    plot(x, left)

    left, right = Test2(Selection_Edge)
    left 
    right
    x = 1:length(left)
    plot(x, left)
    
 #=   for Selection in 2:12
       # @info "abs(left[Selection-1] - left[Selection]) = $(abs(left[Selection-1] - left[Selection-1]))"
       # @info "Sel = $(left[Selection-1])"
        if(abs(left[Selection-1] - Selection_Edge[Selection].Left) < 78)
        push!(left, Selection_Edge[Selection].Left)
        push!(right, Selection_Edge[Selection].Right)
        end
    end =#
#=
    for Selection in 1:12
        push!(left, Selection_Edge[Selection].Left)
        push!(right, Selection_Edge[Selection].Right)
    end=#



    
dist_ll, index_ll, value_ll = Min_dist_to_all_points(left)
x = 1:length(right)
plot(x, right)
dist_rr, index_rr, value_rr = Min_dist_to_all_points(right)
plot_all_channels_const_signal(BaseName, N)
xlims!(1550, 1980) #для 3ейй секции файла N
vline!([value_ll, value_rr])
plot!()

z1, ll, val_ll = Mean_value(left)
z2, rr, val_rr = Mean_value(right)
ll
rr
#plot_all_channels_const_signal(BaseName, N)
#xlims!(515, 800) #для 3ейй секции файла N
vline!([val_ll, val_rr])
plot!()