using DataStructures

function distantion(x1, x2, y1, y2)
    a = x1 - x2
    b = y1 - y2
    return sqrt(a * a + b * b);
end

# площадь треугольника по координатам
function triangle_surf(x1, x2, x3, y1, y2, y3)
    0.5 * abs((x2-x1)*(y3-y1) - (x3-x1)*(y2-y1))
end

# найти точку разделения отрезка на две части
# площадь макс. треугольника, или макс. отклонение от прямой, соединяющей крайние точки
function findbreakpoint(vec::AbstractVector{T}) where T

    len = length(vec)
    len < 2 && return (len, 0)

    y0 = vec[1]
    k = (vec[end] - vec[1]) / (len-1)

    dmax, imax = 0, 1
    for i = 2:len-1
        y0 += k
        dist = abs(vec[i] - y0)
        if (dist > dmax)
            dmax = dist
            imax = i
        end
    end

    s = triangle_surf(1, imax, len, vec[1], vec[imax], vec[len])
    return imax, s
end


"""
Делит участок до тех пор, пока площадь всех треугольников 
не уменьшится до `coef` от начальной
"""
function segmentation(vec::AbstractVector{T}, coef) where T
    i, s0 = findbreakpoint(vec)
    thr = s0 * coef
    s = s0
    len = length(vec)
    p = PriorityQueue(Base.Order.Reverse, (1, i, len) => s0)

    k_debug = 0
    while s > thr && k_debug < 1000
        k_debug += 1

        (ifirst, itop, ilast), s_ = peek(p)

        i1, s1 = findbreakpoint(@view vec[ifirst:itop])
        i2, s2 = findbreakpoint(@view vec[itop:ilast])
        i1 += ifirst-1
        i2 += itop-1

        dequeue!(p)
        push!(p, (ifirst, i1, itop) => s1)
        push!(p, (itop, i2, ilast) => s2)
        s -= s_
        s += s1 + s2
    end

    edges = zeros(Int, length(p))
    i = 1
    for ((ifirst, itop, ilast), s) in p
        edges[i] = ilast
        i += 1
    end
    sort!(edges)
    return edges
end