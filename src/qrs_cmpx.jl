# тупо позиции точек комплекса (амплитуды нужны??)
mutable struct Points
    # cmpx_b, cmpx_e, Pb, P, Pe, r, Q, R, S, r2, Tb, T, Te
    r::Int
    Q::Int 
    R::Int
    S::Int
    r2::Int
    Pb::Int
    P::Int
    Pe::Int
    Tb::Int
    T::Int 
    Te::Int
    # чтобы определить комплекс надо подать хотя бы R
    function Points(;r::Int = 0, Q::Int = 0,R::Int=0,S::Int=0,r2::Int = 0,Pb::Int=0,
        P::Int=0,Pe::Int=0,Tb::Int=0,T::Int=0,Te::Int=0)
        return new(r, Q, R, S,r2, Pb, P, Pe, Tb, T, Te)
    end
end
# более полны сведения о комплексе
mutable struct QRS
    freq::Union{Int, Float64}
    pos::Int
    c_beg::Int
    c_end::Int
    points::Points
    # чтобы определить комплекс надо подать хотя бы R
    function QRS(freq; pos::Int=0, c_beg::Int = 0, c_end::Int = 0, points::Points = Points(;))
        return new(freq, pos, c_beg, c_end, points)
    end
end
# определяющая комплекс позиция
get_pos(cmp::QRS)= cmp.pos #или cmp.R
get_freq(cmp::QRS)= cmp.freq
 
# создание набора поканальных детекций на основе векторов
function QRS(freq, pos::Vector{T}, vc_beg::Vector{T}, vc_end::Vector{T}, rvec::Vector{T}, Qvec::Vector{T}, Rvec::Vector{T}, Svec::Vector{T}, r2vec::Vector{T},
    Pbvec::Vector{T}, Pvec::Vector{T}, Pevec::Vector{T}, Tbvec::Vector{T}, Tvec::Vector{T}, Tevec::Vector{T}) where T
    N = lastindex(Rvec)
    qrspoints_set = Vector{QRS}()
    for i = 1:N
        points = Points(r=rvec[i], Q=Qvec[i], R=Rvec[i], S=Svec[i], r2=r2vec[i],
        Pb=Pbvec[i], P=Pvec[i], Pe=Pevec[i], Tb=Tbvec[i], T=Tvec[i], Te=Tevec[i])

        push!(qrspoints_set, QRS(freq; pos=pos[i], c_beg=vc_beg[i], c_end=vc_end[i], points))
    end
    return qrspoints_set
end
# комплекс описывается как сведеными грацицами (merged)
# так и поканальными (leads)
mutable struct QRSMerged
    ch_num::Int # число каналов (3/8/12...)
    merged::QRS
    leads::Vector{Union{Nothing,QRS}}

    function QRSMerged(ch_num::Int, cmp::QRS, ch::Int)
        # Инициализируем все каналы - жесткая фиксация канальных детекций
        all_leads = Vector{Union{Nothing,QRS}}(nothing, ch_num)
        all_leads[ch] = cmp
        return new(ch_num, cmp, all_leads)
    end
end

get_pos(cmp::QRSMerged)= get_pos(cmp.merged)
get_freq(cmp::QRSMerged)= get_freq(cmp.merged)
get_ch_num(cmp::QRSMerged) = cmp.ch_num
# добавление поканальных границ в канале с номером ch_ind
function Base.push!(qrs_all::QRSMerged, new_lead_qrs::QRS, ch_ind::Int)
    is_one_cmpx = check_cmplx_dist(qrs_all.merged,new_lead_qrs )

    if ~is_one_cmpx
        println("Комплекс не добавлен, т.к. порог дистанци между R превышен")
        return qrs_all
    end
    # обновляем детекцию в канале
    qrs_all.leads[ch_ind] = new_lead_qrs
    return qrs_all
end

# упорядочивание комплексов по R
function Base.sort!(cmp_set::Vector{QRSMerged})
    r_pos = map(x->x.merged.R, cmp_set)
    ind = sortperm(r_pos) 
    cmp_set = cmp_set[ind] 
end

# проверка совпадения комплексов по расстоянию между r
# если расстояние больше порога вернет false- это разные комплексы
function check_cmplx_dist(cmp1::Union{QRS,QRSMerged}, cmp2::Union{QRS,QRSMerged}; dist_ms::Int=200)
    pos1 = get_pos(cmp1); pos2 = get_pos(cmp2);
    thr = round(Int, dist_ms*get_freq(cmp1)/1000)
    check_cmplx_dist(pos1, pos2, thr)
end

# сравнеие расстояний между R
function check_cmplx_dist(pos1, pos2, thr)
    if pos1>0 && pos2>0
        delta = abs(pos1-pos2)
        return delta < thr
    else
        println("Значение R равно 0")
        return true
    end
end


# расчет сведеных границ
function merge_bounds!(cmpM::QRSMerged)
    points_names = propertynames(cmpM.merged.points)
    fs = cmpM.merged.freq
    # оставляем только валидные детекции
    valid_leads = cmpM.leads[.~isnothing.(cmpM.leads)]
    # первое - это Fs, пропускаем
    for point in points_names[2:end]
        all_detections = map(x->getproperty(x.points,point), valid_leads)
        all_detections = all_detections[all_detections.>0]
        all_detections = remove_outliers(all_detections, fs)

        if ~isempty(all_detections)
            if point in [:R, :P, :T]
                point_val = round(Int, mean(all_detections))
            elseif point in [:Q, :Pb, :Tb]
                point_val = minimum(all_detections)
            else
                point_val = maximum(all_detections)
            end
            setproperty!(cmpM.merged.points,point,point_val)
        end
    end
    # чтобы P и T не налезли на QS
    fix_bounds!(cmpM)
end
# коррекция границ волн P И T, если они налезли QS
# по хорошему, надо шестрить поканальные и убирать более
# жестко аутлаеры
function fix_bounds!(cmpM::QRSMerged)
    # надо переделать
    cmp = cmpM.merged.points
    if cmp.Q < cmp.Pe
        cmp.Pe = cmp.Q-1
    end
    if cmp.Pe < cmp.P
        cmp.P = 0 # вообще сбрасываем пик волны
    end
    if cmp.S > cmp.Tb
        cmp.Tb = cmp.S + 1
    end

    if cmp.Tb > cmp.T
        cmp.T = 0
    end
end
# поиск далеко расположенных точек
function remove_outliers(x::Vector, fs, thr_ms::Int=5)
    if isempty(x)
        return x
    end
    mdn = median(x) # медиана
    in_range = abs.(x.-mdn).< thr_ms*fs/1000 # точка дальше N-секунд медианы типа выброс. цифра с потолка!
    return x[in_range]
end

# добавление комплекса к ранее детекрированным
# ищется пара из QRSMerged и пушится туда
# если пары не было - создается новый QRSMerged и сет упорядочивается по R
# ch_ind - номер канала, где была детекция
function Base.push!(cmp_set::Vector{QRSMerged}, new_cmp::QRS, ch_ind::Int)
    # поиск по растсоянию м/д R
    fl_done = false
    for old_cmp in cmp_set
        if check_cmplx_dist(old_cmp, new_cmp)
            # а если там детекция уже была - перетрется \-0-/
            push!(old_cmp, new_cmp, ch_ind)
            merge_bounds!(old_cmp)
            fl_done = true
            # println("Добавляю новую поканальную детекцию ранее найденному комплексу, обновляю границы")
            break
        end
    end
    if fl_done
        return cmp_set
    else
        # println("Добавляю новый комплекс в набор")
        # число отведений берем из первого элемента так что проверка на пустоту
        if isempty(cmp_set)
            error("Не могу добавить новый комплекс в пустой массив! Надо задать число отведений")
        end
        new_cmp_m = QRSMerged(get_ch_num(cmp_set[1]), new_cmp, ch_ind)
        insert!(cmp_set, lastindex(cmp_set)+1, new_cmp_m)
        # @show cmp_set
        return sort!(cmp_set)
    end
end

