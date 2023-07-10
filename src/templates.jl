
struct PointTemplate
    # шаблон состоит из таких точек:
        dist_rng # мин-макс расстояние до ближ. точни, отсчетов
        ampl_rng # диапазон по амплитуде
        name # имя
end
# шаблон - последовательность точек 
struct Template
    points::Vector{PointTemplate}
end

# преобразуем словарь в структуру темплейта
function template_dict(dict::Dict)
    tmpl_dict = Dict{String,Template}()
    for tmpl_name in keys(dict)
        tmpl = dict[tmpl_name]
        v = Vector{PointTemplate}()
        for i = 1:lastindex(tmpl["points"])
            ampl_rng = tmpl["ampl_rng"][i]
            dist_rng = tmpl["dist_rng"][i]
            push!(v, PointTemplate(dist_rng,ampl_rng, tmpl["points"][i]))
        end
        tmpl_dict[tmpl_name] = Template(v)
    end
    return tmpl_dict
end



# сравнение набора точек-экстремумов и темплейта
# points # точки из темлпейта
# id # номер zc начала сравнения
# zc - zero_crosses точки нулевой производной
# signal  #filtered60_norm фильтрованный НОРМИРОВАННЫЙ по амплитуде сигнал
# diff # производная
function compare2template(points::Vector{PointTemplate}, zc::Vector{Int64}, id::Int64, 
    signal::Vector{T}, diff::Vector,fs::Float64) where T

    nP = lastindex(points)
    nonzero_points = nP
    # nonzero_points = 0
    # for p in points
    #     if p.name !="z"
    #         nonzero_points+=1
    #     end
    # end

    good_num = 0 # счетчик совпавших точек
    # zero_lvl = signal[zc[id-1]] # от предыдущей точки отсчитываем уровень амплитуды внутри темплейта
    # by skv: пробуем в качестве нулевого уровня брать не амплитуду предыдущей точки, а средний уровень 30 мс сигнала в 30 мс точки наложения темплейта
    ibeg = maximum([1, zc[id] - 60])
    zero_lvl = mean(signal[ibeg:zc[id]-30])
    # sig_inside = signal[zc[j-i]:zc[j+n]]-zero_lvl # сигнал, соотв-й темлпейту

    # сравниваем точки темплейта
    boundleft, boundright = 1, lastindex(signal) # границы темплейта (левая граница ширины первого пика и правая - последнего)
    j = id # начинаем от первой точки
    L = lastindex(zc)
    for n=1:nP
        if j < L         
            ex_pos = zc[j] # позиция экстремума

            p = points[n] # точка темплейта

            # амплитуда относительно условного нуля
            ecg_ampl = signal[ex_pos] - zero_lvl 
            w_L, w_R = calc_width(ex_pos,signal.-zero_lvl, fs) # by skv: попытка расчёта ширины по относительной амплитуде
            dist =  (w_L+w_R)/fs # ширина в сек. по уровню 0,3

            # dist = (zc[j+1] - zc[j-1])/fs # ширина в секундах между двумя соседними экстремумами
            # # ДОБАВИТЬ еще одну более точную оценку ширины зубца
            # w_L, w_R = calc_width(ex_pos,signal.-zero_lvl, fs) # by skv: попытка расчёта ширины по относительной амплитуде
            # width =  (w_L+w_R)/fs # ширина в сек. по уровню 0,3
            # # if width < 0.7*dist # если по уровню уже сильнее чем на 30%, то подменяем одно другим
            # # if width > 0.7*dist # by skv: кажется, так логичнее
            # #     # чтобы избавиться от излишне узких зубцов
            # #     dist = width
            # # end
            # dist = width

            # println("$(p.name), ampl = $ecg_ampl, dist = $dist")
            # проверка параметров пика
            if (ecg_ampl>=minimum(p.ampl_rng)) && (ecg_ampl<=maximum(p.ampl_rng)) # направленность совпала
                # println("ampl: good")
                if p.name == "z"
                    good_num += 1
                else
                    if (dist>=minimum(p.dist_rng)) && (dist<=maximum(p.dist_rng))
                        # if p.name!="z" # нулевые точки не учитываем! или учитываем. Не знаю - изучить
                        #     good_num+=1
                        # end
                        good_num += 1
                    # println("dist: good")
                    end
                end
            end

            if      n == 1
                ind = maximum([0, j])
                boundleft = zc[ind]
            end # без elseif, т.к. есть темплейты из одной точки
            if  n == nP
                ind = minimum([lastindex(zc), j])
                boundright = zc[ind]
            end
        end
        j+=1
    end
    # как-то оцениваем сходство темлпейта и набора экстремумов
    similarity = good_num/nonzero_points 
    bounds = (left = boundleft, right = boundright)

    return similarity , bounds
end

# расчет ширины зубца
function calc_width(ex_pos,signal, fs; k_lvl = 0.3)
    signal_abs = abs.(signal)
    lvl = k_lvl*signal_abs[ex_pos] # уровень оценки ширины
    max_05width = round(0.25*fs) # зубец не шире 0,5 секунды
    w_L = 1; w_R = 1;
    fl_L = true; fl_R = true;

    L = lastindex(signal_abs)
    while fl_L && w_L < max_05width
        if ex_pos-w_L > 0 && signal_abs[ex_pos-w_L] > lvl
            w_L+=1
        else
            fl_L = false
        end
    end
    while fl_R && w_R < max_05width
        if ex_pos+w_R < L && signal_abs[ex_pos+w_R] > lvl
            w_R+=1
        else
            fl_R = false
        end
    end

    return w_L, w_R
end

# выбор темплейта из всех вариантов по значениям уровня
function select_template(tmpl_lvl::Dict, zc::Vector{Int64},
    integrated::Vector{Float64})

    tmplts = string.(keys(tmpl_lvl))

    pos_cmpx = Vector{Int64}()
    tmpl_name = Vector{String}()
    cmpx_area = copy(integrated)
    wind = round(Int64, 0.2*fs) # минимальное расстояние между комплексами
    N = lastindex(integrated)
    for i=2:L
        point = zc[i]
        # по интегралу понимаем, что тут есть комплекс
        if cmpx_area[point]>0.1
            # анализируем какие темплеты попали в текущую точку и соседние
            # lvls_L = map(x->tmpl_lvl[x][i-1], tmplts)
            lvls_i = map(x->tmpl_lvl[x][i], tmplts)
            lvls_R = map(x->tmpl_lvl[x][i+1], tmplts)
            if any(lvls.>0)
                # что-то точно попало
                is_one = lvls_i.==1
                one_tmpl = tmplts[lvls_i.==1]
                # если словил R, то это точно не QS
                if lastindex(one_tmpl)==0
                    if any(lvls_i.>0) # что-то вообще нашлось
                        if any(lvls_R.==1) # но впереди еще есть "единички"
                            continue
                        end
                        lvls_i_nonzero = lvls_i[lvls_i.>0]
                        lvls_i_nonzero_names = tmplts[lvls_i.>0]
                        ids = sortperm(lvls_i_nonzero, rev=true)
                        sorted_tmpl = lvls_i_nonzero[ids]
                        sorted_tmpl_names = lvls_i_nonzero_names[ids]

                        max_lvl = sorted_tmpl[1]
                        # может быть несколько темплейтов
                        max_tmpl_names =lvls_i_nonzero_names[lvls_i_nonzero.==max_lvl]
                        result  = join(max_tmpl_names, " | ")
                        push!(pos_cmpx, point)
                        push!(tmpl_name, result)
                        cmpx_area[point:min(N,point+wind)].=0 # заполняем нулями зону за детекцией, чтобы там ничего не ловилось!
                    end
                elseif lastindex(one_tmpl)==1
                    push!(pos_cmpx, point)
                    push!(tmpl_name, one_tmpl[1])
                    cmpx_area[point:min(N,point+wind)].=0 # заполняем нулями зону за детекцией, чтобы там ничего не ловилось!
                else
                    result  = join(one_tmpl, " || ")
                    push!(pos_cmpx, point)
                    push!(tmpl_name, result)
                    cmpx_area[point:min(N,point+wind)].=0 # заполняем нулями зону за детекцией, чтобы там ничего не ловилось!

                end
            end
        end
    end
    return pos_cmpx, tmpl_name
end

# находится ли точка в указанных границах
function isinbounds(point::Int, bounds::Vector{NamedTuple{(:left, :right), Tuple{Int64, Int64}}})
    for i in 1:lastindex(bounds)
        if (point > bounds[i].left) && (point < bounds[i].right)
            return true
        end
    end
    return false
end


# выбор темплейта из всех вариантов по значениям уровня
# версия с учетом интеграла , "поумнее"
function select_template2(tmpl_lvl::Dict, tmpl_bounds::Dict, tmpl_dict, zc::Vector{Int64},
    integrated::AbstractVector{Bool}, fs::Union{Int, Float64})

    tmplts = string.(keys(tmpl_lvl))

    pos_cmpx = Vector{Int64}()
    tmpl_name = Vector{String}()
    bounds = Vector{Vector{NamedTuple{(:left, :right), Tuple{Int64, Int64}}}}()
    cmpx_area = copy(integrated)
    wind = round(Int64, 0.2*fs) # минимальное расстояние между комплексами
    N = lastindex(integrated)
    L = lastindex(zc)
    thr = 0.05 # порог по интегралу
    for i=2:L
        # i=65
        point = zc[i]
        # по интегралу понимаем, что тут есть комплекс
        if cmpx_area[point]
            # ищем последнее значение zc, попавшее в зону интеграла
            i2 = point+findfirst(x->!x, cmpx_area[point:N])-1-1 # граница в отсчетах сигнала

            ids_zc_in = i:findlast(x->x<=i2, zc) # точки перегиба внутри интеграла
            ids_in = zc[ids_zc_in[1]]:zc[ids_zc_in[end]] # границы "окна интереса" в отсчетах сигнала

            # анализируем какие темплеты попали в окно интереса
            lvls_in = map(x->tmpl_lvl[x][ids_zc_in], tmplts)

            # println(typeof(max_tmpl_names), " ", length(max_tmpl_names))
            
            if any(sum.(lvls_in).>0) # что-то точно попало
                # Правило отбора: 
                # 1 Если значение сходства максимальное одно, то берем его.
                # 2. Из нескольких выбраем ту, у которого шире "зона" (или больше точек)
                # или брать самуый ранний, 

                max_val_tmplts = map(x->maximum(x),lvls_in)
                nz_ids = max_val_tmplts.>0
                max_val_tmplts_nz = max_val_tmplts[nz_ids]
                names_tmplts_nz = tmplts[nz_ids]
                lvls_in_nz = lvls_in[nz_ids]

                max_lvl =  maximum(max_val_tmplts_nz)  # макс. знач. среди всех
                max_lvl_ids = max_val_tmplts_nz.==max_lvl

                # может быть несколько темплейтов с таким уровнем
                max_tmpl_names = names_tmplts_nz[max_lvl_ids]
                lvls_in_nz_2 = lvls_in_nz[max_lvl_ids]

                if sum(max_lvl_ids) > 1 
                    # надо как-то выбрать самый "хорошо описывающий" вариант
                    # 1 по числу точек внутри темплейта 
                    # 2 по дистанции между левой и правой границей шиблона
                    # 3 по порядку появления в сигнале                 
                    # 4 Если все совпало у нескольких, то ставим все 

                    dot_num = map(x->length(tmpl_dict[x].points),max_tmpl_names)
                    max_dot_num = maximum(dot_num)
                    dot_num_max_id = dot_num.==max_dot_num
                    lvls_in_nz_3 = lvls_in_nz_2[dot_num_max_id]
                    max_tmpl_names_2= max_tmpl_names[dot_num_max_id]

                    if sum(dot_num_max_id)>1 # если не выбрали самый широкий так, то считаем дальше
                        tmpl_width = Vector{Float64}()
                        tmpl_start_zc_id = Vector{Int64}() # начало темплейта в индексах zc
                        for k = 1:lastindex(lvls_in_nz_3)
                            ind_start = findfirst(lvls_in_nz_3[k].==max_lvl) # откуда стартует шаблон в индексах окна
                            ind_zc = i+ind_start-1 # откуда стартует шаблон в индексах zc
                            ind = minimum([ind_zc+max_dot_num-1, lastindex(zc)]) # by skv: иначе иногда выходило за границы
                            push!(tmpl_width, zc[ind] - zc[ind_zc]) # считаем ширину в точках 
                            push!(tmpl_start_zc_id, ind_zc)
                        end
                        max_tmpl_width = maximum(tmpl_width)
                        max_tmpl_width_id = tmpl_width.==max_tmpl_width

                        max_tmpl_names_3 = max_tmpl_names_2[max_tmpl_width_id]
                        lvls_in_nz_4 = lvls_in_nz_3[max_tmpl_width_id]

                        if sum(max_tmpl_width_id)>1 # если не выбрали самый широкий так, то считаем дальше
                            tmpl_start_zc_id_3 = tmpl_start_zc_id[max_tmpl_width_id]

                            first_tmpl= minimum(tmpl_start_zc_id_3)
                            first_tmpl_id = tmpl_start_zc_id_3.==first_tmpl

                            # фиксируем результат! 
                            cmpx_zc_id = first_tmpl
                            result = max_tmpl_names_3[first_tmpl_id]

                            bounds_result = NamedTuple{(:left, :right), Tuple{Int64, Int64}}[]
                            if sum(first_tmpl_id) > 1 # ну все, все что могли проверили и выбрать не смогли
                                bounds_result = []
                                for i in 1:lastindex(result)
                                    push!(bounds_result, tmpl_bounds[result[i]][cmpx_zc_id])
                                end
                                result = join(result, "|")
                            else
                                result=result[1]
                                push!(bounds_result, tmpl_bounds[result][cmpx_zc_id])
                            end
                        else
                            lvl_in_ = lvls_in_nz_4[1] # берем его уровень
                            ind_start = findfirst(lvl_in_.==max_lvl) # ищем индекс внутри окна, где он был максимальный
                            # пока пропускаем вариант, что их несколько
                            cmpx_zc_id = i+ind_start-1
                            result = max_tmpl_names_3[1] # стринг или вектор? 
                            bounds_result = [tmpl_bounds[result][cmpx_zc_id]]
                        end
                    else
                        lvl_in_ = lvls_in_nz_3[1] # берем его уровень
                        ind_start = findfirst(lvl_in_.==max_lvl) # ищем индекс внутри окна, где он был максимальный
                        # пока пропускаем вариант, что их несколько
                        cmpx_zc_id = i+ind_start-1
                        result = max_tmpl_names_2[1] # вектор
                        bounds_result = [tmpl_bounds[result][cmpx_zc_id]]
                    end
                else # если максимальный темплейт был один 
                    lvl_in_ = lvls_in_nz_2[1] # берем его уровень
                    ind_start = findfirst(lvl_in_.==max_lvl) # ищем индекс внутри окна, где он был максимальный
                    # пока пропускаем вариант, что их несколько
                    cmpx_zc_id = i+ind_start-1
                    result = max_tmpl_names[1] #вектор
                    bounds_result = [tmpl_bounds[result][cmpx_zc_id]]
                end
                cmpx_zc_id = Int64(cmpx_zc_id)
                startpoint = cmpx_zc_id # -1 коррекция начала 
                push!(pos_cmpx, zc[startpoint]) 
                push!(tmpl_name, result)
                push!(bounds, bounds_result)

                cmpx_area[point:min(N,point+wind)].=false # заполняем нулями зону за детекцией, чтобы там ничего не ловилось!
            end
        end
    end
    return pos_cmpx, tmpl_name, bounds
end

# by skv: сбор статы по ширинам элементов приоритетного темплейта
# ПЛОХО ЧТО:
# 1. считает диапазоны для всех точек темплейта, хотя он мог быть выбран и с непрошедшими точками (но по CTS у всех приоритетных к-т похожести получился 1, поэтому пока так)
# 2. если алгоритм не смог выбрать темплейт, то его имя в формате QRS|RS|Q не будет воспринято (хотя их и не нужно рассматривать)
function getdiststata(pos_cmpx::Vector{Int64}, tmpl_name::Vector{String}, tmpl_dict, zc::Vector{Int64}, alldist::Dict{String, Dict{String, Vector{Int64}}}) # пока по дифференциалу только фильтрованного сигнала, но у q и s другие zc (по сигналу до ФНЧ)
    

    for i in 1:lastindex(pos_cmpx)  # идём по всем точкам, на каоторые был наложен приоритетный темплейт
        zc_ind = findfirst(x -> x == pos_cmpx[i], zc) # индекс позиции точки наложения комплекса в маттиве позиций экстремумов

        points = tmpl_dict[tmpl_name[i]].points
        for j in 1:lastindex(points) # идём по всем точкам темплейта
            ind = zc_ind + j - 1
            left = maximum([1, ind - 1])
            right = minimum([lastindex(zc), ind + 1])
            dist = zc[right] - zc[left]
            
            push!(alldist[tmpl_name[i]][points[j].name], dist)
        end

    end

    return alldist
end