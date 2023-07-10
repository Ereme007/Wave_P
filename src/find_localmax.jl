function find_localmax(inp::AbstractVector, radius, min_amp = 0)
    mx = (pos = 1, amp = -Inf) # состояния
    out = Int[]
    
    for i in 1 + radius : length(inp) - radius
        is_max = true
    
        if i - mx.pos >= radius && mx.amp >= min_amp
            is_max = true
            # включить этот код, чтобы проверять область перед пиком
            for k = mx.pos - radius : mx.pos - 1
                if inp[k] > mx.amp
                    is_max = false
                    break
                end
            end
            if is_max
                push!(out, mx.pos)
            end
            mx = (pos = i, amp = inp[i])
        end
    
        if inp[i] >= mx.amp
            mx = (pos = i, amp = inp[i])
        end
    end
    return out
end

