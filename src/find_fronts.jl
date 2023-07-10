include("../src/find_localmax.jl")
include("../src/endpoint_segmentation.jl")

struct Point{T}
    pos::Int
    val::T
end

struct Front{T}
    ibeg::Int
    iend::Int # не включительно !
    pos::Int # max
    val::T # +/- ampl
    type::Int # 1 - возрастающий фронт, -1 - убывающий
end

"""
поиск фронтов на сигнале `x` с минимальной амплитудой не менее +/-delta
"""
function find_fronts(x::Vector{T}, delta::T = 0) where T
    mode = false
    mx = Point(1, typemin(T))
    mn = Point(1, typemax(T))
    up = 0
    dn = 0

    out = Front{T}[]

    for i in eachindex(x)
        if mode # (-) сигнал // ищем переход вверх
            if x[i] <= delta # идет (-) сигнал
                if (x[i] < 0) up = i end # всегда ищем последний переход через ноль
                if (x[i] < mn.val) mn = Point(i, x[i]) end # поиск минимума
            else # x[i] >= delta // ! найден переход вверх - записываем отрицательный пик
                push!(out, Front(dn + 1, up + 1, mn.pos, mn.val, -1))
                mode = false
                mx = Point(i, x[i])
                dn = i # сброс, переключение, и ловит пики шириной в 1 отсчет!
            end
        else # if (!mode) // (+) сигнал // ищем переход вниз
            if x[i] >= -delta # идет (+) сигнал
                if (x[i] > 0) dn = i end # всегда ищем последний переход через ноль
                if (x[i] > mx.val) mx = Point(i, x[i]) end # поиск максимума
            else # x[i] <= -delta // ! найден переход вниз - записываем положительный пик
                push!(out, Front(up + 1, dn + 1, mx.pos, mx.val, 1))
                mode = true
                mn = Point(i, x[i])
                up = i # сброс, переключение, и ловит пики шириной в 1 отсчет!
            end
        end
    end
    return out
end

# function split_front(xs, fr::Front)
#     # длина фронта выше окна производной * n - проверяем на асимметричный фронт / находим точку перелома
#     # endbeg = fr.ibeg + floor(Int, (fr.iend - fr.ibeg)/2)       # позиция разделяющей точки (пока просто посередине)
#     breakpoint, _ = findbreakpoint(xs[fr.pos:fr.iend]) 
#     endbeg = fr.pos + breakpoint - 1

#     mxpos_right = endbeg + findmax(xs[endbeg:fr.iend])[2] - 1  # позиция максимума нового фонта справа от разделителя

#     left = Front(fr.ibeg, endbeg, fr.pos, fr.val, fr.type)
#     right = Front(endbeg, fr.iend, mxpos_right, xs[mxpos_right], -fr.type)

#     return left, right
# end
# #

# function split_front(xs, prev::Front, fr::Front)
#     # длина фронта выше окна производной * n - проверяем на асимметричный фронт / находим точку перелома
    

#     return left, right
# end

function join_front(xs, prev::Front, next::Front)
    # длина фронта меньше окна производной * m 
    # ампилтуда фронта меньше опорного уровня / k
    # либо - совместное условие по площади фронта
    # это условие можно вынести позже - на этап после определения максимума по первичному детектору
end

# x = rand(-10:10, 100)

# fr = find_fronts(x, 2)

# plot(x)

# xx = [f.pos for f in fr]
# yy = [f.val for f in fr]
# scatter!(xx, yy)

# m = find_localmax(x, 10)
# scatter!(m, x[m], legend = :none)
