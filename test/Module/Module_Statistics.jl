module Module_Statistics

    function Statistic(Left_Right_Edge, Left_Right_Ref_P)
        Left_Ref_P = Left_Right_Ref_P[1]
        Right_Ref_P = Left_Right_Ref_P[2]
        Left_Edge = Left_Right_Edge[1]
        Right_Edge = Left_Right_Edge[2]
        
        delta_left = Left_Edge - Left_Ref_P
        delta_right = Right_Ref_P - Right_Edge

        if (delta_left < 0 || delta_right < 0)
            In_Out = 0
        else
            In_Out = 1
        end

        return delta_left, delta_right, In_Out
    end

    export Statistic
end