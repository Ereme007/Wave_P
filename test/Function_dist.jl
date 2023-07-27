
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