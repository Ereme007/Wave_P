using Printf

function find_localmin(inp::AbstractVector, radius)
    mn = (pos = 1, amp = Inf) # состояния
    out = Int[]
    
    for i in 1 : radius
       if inp[i] < mn.amp
            mn = (pos = i, amp = inp[i])
        end
    end
    
    for i in 1 : length(inp)
        if inp[i] < mn.amp && i - mn.pos <= radius
            mn = (pos = i, amp = inp[i])
        end
    end
    # # mn = (pos = radius + 1, amp = Inf) 
    # for i in 1 + radius : length(inp) - radius
    #    # @info("Позиция $mn.pos, Значение ")
    #     is_min = true
    
    # if i - mn.pos >= radius && mn.amp <= min_amp
    #         is_min = true
    #         # включить этот код, чтобы проверять область перед пиком
    #         for k = mn.pos - radius : mn.pos - 1
    #             if inp[k] < mn.amp
    #                 is_min = false
    #                 break
    #             end
    #         end
    #         if is_min
    #             push!(out, mn.pos)
    #         end
    #         mn = (pos = i, amp = inp[i])
            
    #     end
        
    
    #     if inp[i] <= mn.amp
    #         mn = (pos = i, amp = inp[i])
    #     end

        
    # end
    return out
end

function find_localmin2(inp::AbstractVector, radius, min_amp = 0)
    mx = (pos = 1, amp = Inf) # состояния
    out = Int[]
    
    for i in 1 + radius : length(inp) - radius
        is_max = true
    
        if i - mx.pos >= radius && mx.amp <= min_amp
            is_max = true
            # включить этот код, чтобы проверять область перед пиком
            for k = mx.pos - radius : mx.pos - 1
                if inp[k] < mx.amp
                    is_max = false
                    break
                end
            end
            if is_max
                push!(out, mx.pos)
            end
            mx = (pos = i, amp = inp[i])
        end
    
        if inp[i] <= mx.amp
            mx = (pos = i, amp = inp[i])
        end
    end
    return out
end

