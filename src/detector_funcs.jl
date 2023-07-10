using DSP
using Statistics

include("../src/readfiles.jl")
include("../src/find_fronts.jl")

struct ZeroCross
    pos::Int64
    type::Int64
end

struct Wave
    b::Int64
    e::Int64
end

# получение из бинарника одного канала и частоты дискретизации
function sigdata(binfile)
    signals, fs, timestart, units = readbin(binfile);
    fs = Int(fs);

    return signals, fs
end



# Фильтр нижних частот от https://physionet.org/content/ecgpuwave/1.3.4/src/matlab/ecgpuwave-m/lynfilt.m 

# порядок равен Fs !! 
# нормализация по амплитуде
# Fpb - коэффициент, по сути частота, на которой АЧХ=0
# Amax - коэффициент, к которому приводим амплитуду. 0 - не нормализовывать
function LFfilt(sig::AbstractVector, fs, Fpb::Int = 1, Amax::Int = 10 )
    # Фильтр нижних частот
    # Filtro paso-bajo.
    mpb=round(Int, fs/Fpb)
    b=fill(0.0,2*mpb+1); b[1]=1; b[mpb+1]=-2; b[2*mpb+1]=1
    a=[1,-2,1]

    y = filt(b, a, sig)

    # Убираем задержку.
    y= fixdelay(y, mpb)

    # Нормализация по амплитуде
    # относительно размаха сигнала за первые 2 секунды
    return normalize(y, fs, Amax )

end

# Убираем задержку.
# Тупо смещает сигнал влево
function fixdelay(y::AbstractVector, T::Int)
    y[1:end-T]=y[T+1:end]
    y[end-T+1:end] = fill(0.0,T)
    return y
end

# Нормализация по амплитуде
# относительно размаха сигнала за первые 2 секунды
function normalize(y, fs, Amax )
    if Amax != 0
        rmax=maximum(abs.(y[1:round(Int,2*fs)]))
        if rmax==0 rmax=1; end
        y = Amax*y./rmax;
    end
    return y
end

# ФНЧ до 11 (15?) Гц
# y(nT) = 2y(nT - T) - y(nT - 2 T) + x(nT) - 2x(nT- 6T) + x(nT- 12T)
function my_lowpass(signal)

    fsignal = similar(signal)
    for i in 1:lastindex(signal)
        if i < 13
            fsignal[i] = signal[i]
        else
            fsignal[i] = 2*fsignal[i-1] - fsignal[i-2] + signal[i] - 2*signal[i-6] + signal[i-12]
        end
    end

    # aprox = range(fsignal[1], fsignal[length(fsignal)], length(fsignal))
    
    # fsignal = fsignal .- aprox

    delay = 6
    
    return fsignal, delay
end

# ФВЧ от 5 Гц
function my_highpass(signal)

    fsignal = similar(signal)
    for i in 1:lastindex(signal)
        if i < 33
            fsignal[i] = signal[i]
        else
            fsignal[i] = 32*signal[i-16] - (fsignal[i-1] + signal[i] - signal[i-32])
        end
    end

    delay = 16
    
    return fsignal, delay
end

# # Полосовой фильтр 5 - 11 (15?) Гц
# function lynn_filter(signal, type)

#     delay_low = 0; delay_high = 0;

#     if type == "low"
#         filtered, delay_low = my_lowpass(signal)
#     elseif type == "bandpass"
#         filtered_low, delay_low = my_lowpass(signal)
#         filtered, delay_high = my_highpass(filtered_low)
#     end

#     aprox = range(filtered[1], filtered[end], length(filtered))
#     filtered = filtered .- aprox

#     delay = delay_low + delay_high

#     return filtered, delay
# end

# Дифференцирующий ФНЧ (пятиточечная производная)
# Разностное уравнение: y(nT) = (1/8 T) [-x(nT - 2 T) - 2x(nT - T) + 2x(nT + T) +x(nT+ 2T)]
function fivepointdiff(filtered, fs)

    differed = fill(0.0, length(filtered))

    for i in 3:length(filtered)-2
        differed[i] = (1/8)*(fs)*(-filtered[i-2] - 2*filtered[i-1] + 2*filtered[i+1] + filtered[i+2])
    end

    # delay = 2

    delay = 1

    return differed, delay
end
# замена маленьких значений на 0.0
function set_small_to_zero(sig::Vector{Float64}, eps::Number = 0.015) #1.0e-12)
    for i in 1:lastindex(sig)
        if -eps<=sig[i]<=eps
            sig[i] = 0
        end        
    end
    return sig
end

# Фильтр скользящего среднего
function movingaverage(sqred, wsize, fs)

    w_size = ceil(wsize*fs) |> Int             # ширина окна в отсчетах
    window = sqred[1:w_size]             # (окно) массив w_size последних значений сигнала
    w_cnt = 1
    w_sum = sqred[1]*w_size              # сумма значений в окне

    integrated = fill(0.0, length(sqred))

    for i in 1:lastindex(sqred)

        last = window[w_cnt]              # самое старое значение в окне (будет выкинуто)
        window[w_cnt] = sqred[i]          # запись нового значения в окне (на место самого старого)

        w_sum = w_sum - last + sqred[i]   # сумма значений в окне
        if i>w_size/2 integrated[i] =  w_sum/w_size  end   # среднее в окне

        w_cnt += 1
        if w_cnt > w_size w_cnt = 1 end   # переключение счетчика при необходимости

    end

    delay = w_size/2 |> Int;

    return integrated, delay
end

# Поиск локальных максимумов
function fndmax(integrated, radius, fs)

    lastmaxpos = 0
    lastmaxamp = 0
    radius = radius*fs |> Int

    maxpos = Int[]

    SignalLevel1 = 0
    NoiseLevel1 = 0
    Threshold1 = 0

    init = Float64[]

    for i in 1:lastindex(integrated)

        # 2-секундная фаза обучения
        if i/fs < 2
            push!(init, integrated[i])
        elseif i/fs == 2
            push!(init, integrated[i])
            max = maximum(init);
            mn = mean(init);

            SignalLevel1 = 0.875*max;
            NoiseLevel1 = 0.875*mn;
        else
            # Подтверждение предыдущего предполагаемого максимума
            if i-lastmaxpos > radius && lastmaxpos>0

                if lastmaxamp < Threshold1
                    NoiseLevel1 = 0.125*lastmaxamp+0.875*NoiseLevel1;
                else
                    push!(maxpos, lastmaxpos)
                
                    lastmaxamp = integrated[i]
                    lastmaxpos = i
                end
            end

            if integrated[i] >= lastmaxamp
                lastmaxamp = integrated[i]
                lastmaxpos = i
            end

        end

        Threshold1 = NoiseLevel1 + 0.25(SignalLevel1 - NoiseLevel1);

    end
    # коррекция положения максимума в соответствии с серединой импульса
    maxpos_fixed = Vector{Int}()
    maxpos_rng = Vector{UnitRange}()
    for pos in maxpos
        mx_lvl = integrated[pos]
        thr = 0.3 * mx_lvl # высота, по которой считаем ширину импулься
        i1=pos-1
        while integrated[i1]>=thr; i1-=1; end
        i2=pos+1
        while integrated[i2]>=thr; i2+=1; end
        new_pos = round(Int, mean([i1,i2]))
        push!(maxpos_fixed, new_pos)
        push!(maxpos_rng, i1:i2)

    end
    
    return maxpos_fixed, maxpos_rng
end

# ищет точки пересечения уровня слева и справа от пика
function findbounds(peakpos::Vector{Int}, sig::Vector{Float64}, k_lvl::Float64)
    searchbounds = fill((left = 0, right = 0), lastindex(peakpos))
    for i in 1:lastindex(peakpos) # цикл по всем позициям максимумов
        searchLvl = k_lvl * sig[peakpos[i]] # уровень, только выше которого будет находится зона поиска для данного комплекса
        # ищем точки пересечения уровня слева и справа от пика
        maxR = round(Int, 0.25*fs) # максимальный радиус половины зубца

        left = peakpos[i] - maxR + 1
        for pos in peakpos[i]:-1:1
            if sig[pos] < searchLvl
                left = pos + 1
                break
            end
        end

        right = peakpos[i] + maxR - 1
        for pos in peakpos[i]:1:lastindex(sig)
            if sig[pos] < searchLvl
                right = pos - 1
                break
            end
        end

        searchbounds[i] = (left = left, right = right)
    end

    return searchbounds
end

function isallzero(vec::Vector)
    for v in vec
        if v != 0
            return false
        end
    end
    return true
end

# Поиск точек пересечения нуля
# используется для производной
# правка от 02/03/2023 - теперь выдаст точку на изолинии
function zerocross(x::AbstractVector)
    
    zerocrosses = ZeroCross[]

    lastpos = -Inf # позиция последней детекции

    zero_val = 0 # это уровень нуля
    for i in 2:lastindex(x)-1
        if x[i] >= -zero_val && x[i-1] < -zero_val   # отрицательный зубец
            push!(zerocrosses, ZeroCross(i,-1))
            lastpos = i
        elseif x[i] <= zero_val && x[i-1] > zero_val # положительный зубец
            push!(zerocrosses, ZeroCross(i,1))
            lastpos = i
        # by skv: чтобы детектировало только вход на изолинию и выход из неё
        elseif x[i] == zero_val  # детекция выхода из изолинии
            if x[i+1] > zero_val
                if (i - lastpos) > 20 # чтобы не детектировала по две точки на пологих вершинах пиков из-за предварительного приведения малых значений diff к 0
                    push!(zerocrosses, ZeroCross(i,0))
                    lastpos = i
                end
            elseif x[i+1] < zero_val
                if (i - lastpos) > 20
                    push!(zerocrosses, ZeroCross(i,0))
                    lastpos = i
                end
            end
        end
    end

    return zerocrosses
end

# коррекция позиций пересечения нуля: zerocrosses, найденные по дифференцированному сигналу,
# могут быть смещены относительно максимумов и минимумов сигнала, которому должны соответсвовать => 
# => ищем максимум или минимум (в зависимости от направленности фронта) нужного сигнала в окрестностях zerocross
# + если длина фронта превышает некоторый r, разделяем его на два фронта точкой, максимально отстоящей от прямой, соединяющей соседние пики на сигнале
function zcposcorrect(sig::Vector{T}, fronts::Vector{Front{T}}, sr::Int, maxr::Int) where T
    zcpos = [f.ibeg for f in fronts] # позиции пересечений нуля дифференциалом - пиков исходного сигнала
    type = [f.type for f in fronts]  # типы фронтов, НАЧАЛА которых описывают zcpos

    n = lastindex(zcpos)
    corrected = Int64[]

    lastpos = 0 # корректная позиция предыдущего пика

    # ищем минимумы или максимумы (в зависимости от направленности фронта) на нужном сигнале в окрестностях sr позиции предполагаемого пика
    # если новая позиция текущего пика отстает от новой позиции предыдущего более, чем на maxr - разбиваем его
    for i in 1:n
        leftbound = maximum([1, zcpos[i] - sr])
        rightbound = minimum([lastindex(sig), zcpos[i] + sr])
        if type[i] == -1 # => фронт отрицательный => ibeg соответствует максимуму
            _, ind0 = findmax(sig[leftbound:rightbound])
        else # type == 1 => фронт положительный => ibeg соответствует минимуму
            _, ind0 = findmin(sig[leftbound:rightbound])
        end
        newpos = leftbound + ind0 - 1 # корректная позиция пика

        if (newpos - lastpos) > maxr                              # слишком длинный фронт - разбиваем
            # breakpoint, _ = findbreakpoint(sig[lastpos:newpos]) # ищем точку, наиболее отстоящую от прямой, соединяюшей пики, формирующие слишклм длинный фронт
            # breakpos = lastpos + breakpoint - 1                 # корректная позиция разбивающей точки

            # бъём то тех пор, пока треугольники не станут вполовину меньше исходного
            breakpoints = segmentation(sig[lastpos:newpos], 0.5)
            breakpos = breakpoints .+ lastpos .- 1

            for bp in breakpos push!(corrected, bp) end
            # push!(corrected, breakpos)
        end

        push!(corrected, newpos)
        lastpos = newpos
    end


    return corrected
end

# Идентификация R, Q, S
function qrs_points(filtered, zerocrosses, maxpos, fs)

    R = Int[]; 
    Q = Int[]; 
    S = Int[];
    # Сильно упростила! надо брать во внимание полярность и амлитуду

    # zc = hcat(zerocrosses.pos, zerocrosses.type);
    pos_zc = map(x->x.pos, zerocrosses)
    for i in 1:lastindex(maxpos)
        # пересечения нуля в радиусе 0.25 с.  максимума интекгрированного сигнала
        # убрала ограничение, что пик всегда правее и поск ведется только слева
        ind = map(x -> x.pos > maxpos[i]-0.2*fs && x.pos < maxpos[i]+0.2*fs && x.pos > 1, zerocrosses);
        sample = zerocrosses[ind]
        pos_zc = map(x->x.pos, sample)

        n = length(sample) 
        # R - позиция максимума интегрированного сигнала - в нем должна быть уже компенсирована задержка!
        # ищем ближайшие пересечения нуля
        isq = false
        iss = false
        isr = false
        for j in 3:n
            if pos_zc[j] >= maxpos[i] # первый переваливший за maxpos 
                if filtered[pos_zc[j-1]]>0
                    push!(R, pos_zc[j-1]) # берем предыдущее пересечение

                    if filtered[pos_zc[j-2]]<0
                        push!(Q, pos_zc[j-2]) 
                    else
                        push!(Q, 0)
                    end

                    if filtered[pos_zc[j]]<0
                        push!(S, pos_zc[j]) 
                    else
                        push!(S, 0)
                    end
                    push!(S, pos_zc[j])                    
                else
                    if j==n
                        push!(S, 0)     
                    else
                        push!(S, pos_zc[j+1])     
                    end
                    if filtered[pos_zc[j-1]]<0
                        push!(Q, pos_zc[j-1]) 
                    else
                        push!(Q, 0)
                    end
                    if filtered[pos_zc[j]]<0
                        push!(R, pos_zc[j]) 
                    else
                        push!(R, 0)
                    end
                end
                # наивно предполагаем, что R по амплитуде больше S
                # if abs(filtered[pos_zc[j]]) < abs(filtered[pos_zc[j-1]]) 
                #     push!(Q, pos_zc[j-2]) # берем предыдущее пересечение
                #     push!(R, pos_zc[j-1]) # берем предыдущее пересечение
                #     push!(S, pos_zc[j])                    
                # else
                #     if j==n
                #         push!(S, 0)     
                #     else
                #         push!(S, pos_zc[j+1])     
                #     end
                #     push!(Q, pos_zc[j-1]) # берем предыдущее пересечение
                #     push!(R, pos_zc[j]) # берем предыдущее пересечение
                # end
                isq = true
                iss = true
                isr = true
                break
            end      
        end
        # # полярность R-зубца - может быть инвертирован! 
        # isq = false;
        # isr = false;
        # iss = false;

        # for j in n:-1:1
        #     if !isq || !isr || !iss
        #         # зубец типа как R и выше уровня по амплитуде
        #         if sample[j].type == 1 && abs(filtered[sample[j].pos]) > Lvl
        #             if !isr
        #                 push!(R, sample[j].pos) # точку перегиба не смещаем
        #                 isr = true
        #             end
        #         # зубец другого типа
        #         else
        #             if !iss && !isr # && abs(filtered[sample[j].pos])>100
        #                 push!(S, sample[j].pos)
        #                 iss = true
        #             elseif !isq && isr && iss
        #                 push!(Q, sample[j].pos)
        #                 isq = true
        #             end
        #         end
        #     end
        # end
    end

    return Q, R, S
end

function qrs_detector_v2(maxrng, differed, fs, filtered60, zc)
    # вторая производная 
    seconddiffered_original, delay_2 = fivepointdiff(differed, fs)
    seconddiffered_original = normalize(seconddiffered_original, fs, 2 )
    seconddiffered = set_small_to_zero(seconddiffered_original)
    secondzerocrosses = zerocross(seconddiffered)
    secondzc = map(x->x.pos, secondzerocrosses)

    N = lastindex(maxrng)
    r_vec=Vector{Int}(); Q_vec=Vector{Int}(); R_vec=Vector{Int}(); S_vec=Vector{Int}(); r2_vec=Vector{Int}();

    for i=1:N
        i1=maxrng[i].start
        i2=maxrng[i].stop
        # позиции экстремумов первой производной, попадающие внутрь пика интеграла
        zc_1 = findlast(i1.>=secondzc)+1
        zc_2 = findfirst(i2.<=secondzc)-1
        # значения экстремумов производной
        zc_on_cmpx = secondzc[zc_1:zc_2]
        diff_val = abs.(differed[zc_on_cmpx])
        
        diff_val_srt_ind = sortperm(diff_val)
        r = 0; Q = 0; R = 0; S = 0; r2 = 0;
        # между двумя макмимальными фронтами 2 и менее других фронта
        if abs(diff_val_srt_ind[end]-diff_val_srt_ind[end-1]) <=2 
            # позиция максимального фронта в точках исходного сигнала
            # max_front_ind = diff_val_srt_ind[end]
            # max_front_pos = zc_on_cmpx[max_front_ind]
            zc_L = findlast(zc.<=zc_on_cmpx[diff_val_srt_ind[1]])+1# первый экстремум СИГНАЛА слева
            zc_R = findfirst(zc.>=zc_on_cmpx[diff_val_srt_ind[end]]) #+1 # первый экстремум СИГНАЛА справа
            # погнали проверять разные морфологии комплекса
            # определяем амплитуды сигнала в точках перегиба
            zc1st_on_cmpx = zc[zc_L:zc_R]
            d_extr = filtered60[zc1st_on_cmpx]
            # определяем первую БОЛЬШЕ "нуля"
            minval = 0.7 # ПОДОБРАНО ВРУЧНУЮ ИЗ_ЗА СМЕЩЕНИЯ ОТ ФИЛЬТРА
            is_zero = abs.(d_extr).<minval
            d_extr[is_zero] .= 0        
            # проверяем по числу положительных волн r/R
            num_R = sum(d_extr.>0)
            if num_R == 0 # морфология QS, W
                num_invert = sum(d_extr.<0)
                if num_invert==1  #QS
                    Q = zc1st_on_cmpx[findfirst(d_extr.<0)]
                    S = Q
                elseif num_invert > 1
                    Q = zc1st_on_cmpx[findfirst(d_extr.<0)]
                    S = zc1st_on_cmpx[findlast(d_extr.<0)]
                # else # нет отрицательных значений
                #     Q = 0
                #     S = 0
                end
            elseif num_R == 1 # морфология rS, Rs, qR, QRs, qRs, Qr
                ind_R = findfirst(d_extr.>0)
                R = zc1st_on_cmpx[ind_R]
                # ищем Q 
                if ind_R == 1
                    Q=0
                else 
                    if d_extr[ind_R-1] < 0 # морфология qR, QRs, qRs, Qr
                        Q = zc1st_on_cmpx[ind_R-1]
                    # else # морфология rS, Rs
                    #     Q = 0
                    end
                end
                # ищем S 
                if ind_R == lastindex(zc1st_on_cmpx)
                    # S=0
                else
                    if d_extr[ind_R+1] < 0 # морфология rS, Rs, QRs, qRs
                        S = zc1st_on_cmpx[ind_R+1]
                    # else # морфология qR, Qr
                    #     S = 0
                    end
                end            
            elseif num_R ==2 # морфология rSR2, RsR', rSr' - надо изучать!!
                indR = findfirst(d_extr.>0)
                indR2 = findlast(d_extr.>0)
                r = zc1st_on_cmpx[indR] # в RsR2 r=R
                r2 = zc1st_on_cmpx[indR2] # то же что r' = R'
                # если м/д R и R2 несколько пиков, то берем максимальный
                indS = indR + sortperm(abs.(d_extr[indR+1:indR2-1]))[end] #sortperm дает индекс ОТ R, поэтому +R
                S = zc1st_on_cmpx[indS]
                # Q = 0     
            end
        end
        push!(r_vec,r)
        push!(Q_vec,Q)
        push!(R_vec,R)
        push!(S_vec,S)
        push!(r2_vec,r2)
    end
    return r_vec, Q_vec, R_vec, S_vec, r2_vec
end


# Поиск пика волны P
function p_points(DERFI, R, Q, T, zerocrosses, fs)
    # define a window of 155 ms starting
    # 225 ms before the R position

    # This window is shortened when the previous T or the next Q wave
    # is in it. 
    ws = round(Int, 0.155*fs)
    preR =  round(Int,0.225*fs)
    P = Int[];

    pos_zc = map(x->x.pos, zerocrosses)
    type_zc = map(x->x.type, zerocrosses)

    # In this window we search for the maximum and minimum value
    # If these values are bigger
    # than 2% of the maximum slope of the QRS complex, the algorithm assumes
    # that it has located a Pwave;otherwise, the algorithm assumes that the 
    # P wave cannot be located in the given lead.
    # The P wave peak is assumed to occur at the zero-crossing between 
    # the maximum and the minimum values in the window
    for k in 1:lastindex(R)
        posR = R[k]
        if R != 0
            if posR-preR > 0 
                b1 = posR-preR;
                b2 = posR-preR+ws;

                #первое пересечение нуля левее Q
                indP = findlast(pos_zc.<Q[k])
                if ~isnothing(indP) 
                    typeP = type_zc[indP] # тип P -инверсия или нет
                else # если Q=0
                    typeP = 1 # на шару ... 
                end

                # если левый край окна заехал на предыдущий комплекс
                # вдруг T не нашлось, то берем там Q
                Q_or_T = map((x,y)->max(x,y), Q,T)
                if k>1 && Q_or_T[k-1] != 0
                    # окно заканчиваем на Q+1 предыдущего комплекса
                    if b2 < Q_or_T[k-1] b2 = Q_or_T[k-1]+1 end
                end

                bend = b2
                # @show b1, b2
                # положительный зубец p
                if typeP == 1
                    # wmax = argmax(DERFI[b1:bend])
                    # for i in 1:(b2-b1)                        
                    #     if wmax+b1 == bend+1
                    #         bend = b2 - i
                    #     else
                    #         break
                    #     end
                    # end
                    # wmin = argmin(DERFI[wmax+b1:b2])

                    # индекс максимального остчета в окне
                    wmax = argmax(DERFI[b1:bend])
                    # добавить проверку уровня DERFI[b1+wmax-1] > 0.2*thr
                    # минимум ищется ПРАВЕЕ максимума
                    # насколько это корректно?
                    wmin = argmin(DERFI[b1+wmax-1:b2])

                    isinv = false
                    wbeg = b1 + wmax - 1
                    wend = b1 + wmin -1 + wmax-1
                else
                    # for i in 1:(b2-b1)
                    #     wmin = argmin(DERFI[b1:bend])
                    #     if wmin+b1 == bend+1
                    #         bend = b2 - i
                    #     else
                    #         break
                    #     end
                    # end
                    # wmax = argmax(DERFI[wmin+b1:b2])

                    # обратный порядок поиска
                    wmin = argmin(DERFI[b1:bend])
                    # максимум правее минимума
                    wmax = argmax(DERFI[b1+wmin-1:b2])
                    wbeg = b1 + wmin - 1
                    wend = b1 + wmin -1 + wmax-1
                    isinv = true
                end

                # if wend > length(DERFI) wend = length(DERFI) end
                # диффер. сигнал между мин-максами 
                wsign = DERFI[wbeg:wend]

                for j in 2:lastindex(wsign)
                              #  __
                    if isinv #__/
                        # пересекли 0
                        if wsign[j] >= 0 && wsign[j-1] < 0
                            push!(P, wbeg + j - 1)
                            break
                        end
                    else # __
                           # \__
                        if wsign[j] <= 0 && wsign[j-1] > 0
                            push!(P, wbeg + j - 1)
                            break
                        end
                    end
                end
            end
        end

        if length(P) < k push!(P, 0) end
    end

    return P
end

# Поиск пика волны Т
# из статьи https://sci-hub.ru/10.1007/BF02441680
# To detect the T wave, we define a search window in DERFI that is a function of the heart rate
# (2). The algorithm determines the type of T-wave (regular, inverted? biphasic +- or biphasic -+)
# according to the relative positions and values of the maximum and minimum values within the
# search window, using the CSE working party classifcation (9). The T wave peak is assumed to
# occur at the zero-crossing adjacent to the maximum or minimum value
function t_points(DERFI, R, fs)
    # Рассчет среднего значения R-R-интервалов
    sumRR = 0
    r = R[findall(x -> x!=0, R)]
    # если были дырки, RR найдется неправильно
    if length(r) == 1
        RRav = r[1]
    else
        for i in 2:lastindex(r) sumRR += r[i] - r[i-1] end
        RRav = abs(sumRR/(length(r)-1))
    end

    # Выбор границ окна поиска
    # при увеличении RR окно кменьшается, чтобы не словить P вместо T
    if RRav > 0.7*fs
        bwind = 0.14*fs |> Int64
        ewind = 0.5*fs  |> Int64
    else
        bwind = 0.1*fs |> Int64
        ewind = round(0.6*RRav)  |> Int64
    end

    # Tud = []
    # Tdu = []
    # Tod = []
    # Tou = []
    T = Int[]
    T_type = String[]
    for i in 1:lastindex(R)
        if R[i] != 0 && (R[i]) <= length(DERFI)-ewind

            window = R[i]+bwind:R[i]+ewind
            # кусочек сигнала, где ищем T-волну
            dw0 = DERFI[window]

            wmin = argmin(DERFI[window])
            wmax = argmax(DERFI[window])

            # кусок сигнала между пиками 
            wsig = dw0[min(wmin,wmax):max(wmin,wmax)]
            # точки пересечения нуля
            zc = zerocross(wsig)
            # позиции - в индексах внутри окна wmax:wmin
            zc = map(x -> x.pos, zc)
            # позиции внутри окна bwind:ewind
            zc_wind = zc.+min(wmin,wmax).-1

            # максимум левее минимума
            if wmax < wmin 
                if length(zc) != 0
                    # условие для only-upward T-волны 
                    if abs(dw0[wmax]) > 4*abs(dw0[wmin])
                        push!(T_type, "only-upward")
                    else # upward-downward
                        push!(T_type, "upward-downward")
                    end
                    # проверить, не надо ли -1 
                    push!(T, zc_wind[1]+bwind-1+R[i]-1)
                end
            else # максимум правее минимума
                if length(zc) != 0
                    # поиск минимума правее 
                    mina = minimum(dw0[wmax:length(dw0)])
                    # mina сравнима по абсолютной величине с max, мы снова рассматриваем форму вверх-вниз.
                    # границы сопоставимости я взяла от балды
                    # if 1.2>abs(dw0[wmax]/mina)>0.8
                    #     push!(T_type, "upward-downward/normal")
                    # else
                    #     # сравниваем min и max, и если они имеют схожие значения, считается Т вниз-вверх, 
                    #     # в противном случае предполагается Т только-вниз.
                    #     if 1.2>abs(dw0[wmax]/dw0[wmin])>0.8
                    #         push!(T_type, "downward-upward/inverted")
                    #     else    
                            #only-downward
                    #     end
                    # end
                    # работаем по второму варианту классификатора из статьм
                    if abs(dw0[wmax])<4*abs(mina)
                        push!(T_type, "up-down/normal")
                    else
                        if abs(dw0[wmin]) > 4*abs(dw0[wmax])
                            push!(T_type, "only-downward")
                        else
                            push!(T_type, "down-up/inverted")
                        end
                        # в алгоритме нет only-upward 
                    end
                    push!(T, zc_wind[1]+bwind-1+R[i]-1)
                end
            end
        end

        if length(T) < i push!(T, 0) end
        if length(T_type) < i push!(T_type, "none") end

    end

    T = map(x -> x > length(DERFI) ? length(DERFI) : x, T)
    return T,T_type
end

# Определение границ волн - параметры из статьи
# dermax - точка максимального наклога QRS-кривой
function bounds_coeff(DERFI::AbstractVector, pk::Int, dermax::Int, wavetype::String)
    if dermax == 0
        f=0
    else
        f = abs(DERFI[pk]*10/DERFI[dermax])
    end
    if wavetype == "P"
        return 1.35, 2.0
    elseif wavetype == "r"
        return 1.8, 1.0  # ОТ БАЛДЫ - потестить другие
    elseif wavetype == "Q"
        return 1.8, 1.0 # хотя конца тут нет
    elseif wavetype == "R"
        return 10.0, 10.0 # хотя конца тут нет
    elseif wavetype == "r2"
        return 1.8, 1.0 # ОТ БАЛДЫ - потестить другие
    elseif wavetype == "S"
        if f < 4.0
            ke = 3.0
        elseif f >= 4.0 && f < 4.75
            ke = 8.0
        elseif f >= 4.75 && f < 6.20
            ke = 9.0
        else
            ke = 12.0
        end
        return 1.0, ke # хотя начала тут нет
    elseif wavetype == "T"
        if f <= 0.13 
            ke = 4.0
        elseif f > 0.13 f < 0.20
            ke = 5.0
        elseif f >= 0.20 f < 0.41
            ke = 6.0
        else
            ke = 7.0
        end
        return 2.0, ke
    else
        error("Неизвестный тип волны $wavetype")
    end
end
# определение границ волн
function wavebounds(pos, DERFI, R, wavetype,fs)

    # НУЖНА ПРОВЕРКА СООТВЕТСТВИЯ pos и R!
    # пока отсутствие волны маркируется 0 и соответствие сохраняется
    dermax = find_dermax(DERFI, R)

    wind = round(Int,0.3*fs) # максимальное оно поиска границ волны - от балды взяла

    bounds = Wave[]
    for i in 1:lastindex(pos)
        pkb = Float64[]
        pke = Float64[]
        if pos[i] != 0 
            # по каждой волне смотрим инверсию тк в случае патологии может меняться
            fl_invert = isinv(DERFI, pos[i])
            # ищем точки максимального наклона волны

            # влево от метки до точки перегиба - начало
            for j in pos[i]-1:-1:pos[i]-1-wind
                if fl_invert
                    if DERFI[j-1] > DERFI[j]
                        pkb = j;
                        break
                    end
                else
                    if DERFI[j-1] < DERFI[j]
                        pkb = j;
                        break
                    end
                end
            end

            # вправо от метки - конец
            for j in pos[i]+1:pos[i]+1+wind
                if fl_invert
                    if DERFI[j] < DERFI[j-1]
                        pke = j-1;
                        break
                    end                    
                else
                    if DERFI[j] > DERFI[j-1]
                        pke = j-1;
                        break
                    end
                end
            end

            # рассчет границ
            if pkb != [] && pke != [] 
                # коэффициенты для этого типа зубца
                 # НУЖНА ПРОВЕРКА СООТВЕТСТВИЯ pos и R! для dermax
                # пока отсутствие волны маркируется 0 и соответствие сохраняется
                kb, ke = bounds_coeff(DERFI, pke, dermax[i], wavetype)

                THb = DERFI[pkb]/kb # пороговые значения амплитуды дифферинц.
                THe = DERFI[pke]/ke

                # идём влево от pkb
                wb = 0;
                for p in pkb:-1:max(0,pkb-1-wind)
                    if fl_invert
                        if DERFI[p-1] >= THb && DERFI[p] < THb
                            wb = p-1; # первая точка пересекающая границу
                            break
                        end
                    else
                        if DERFI[p-1] <= THb && DERFI[p] > THb
                            wb = p-1;
                            break
                        end
                    end
                end

                # идём вправо от pke
                we = 0;
                for p in pke+1:min(lastindex(DERFI),pke+1+wind)
                    if fl_invert
                        if DERFI[p] <= THe && DERFI[p-1] > THe
                            we = p;
                            break
                        end
                    else
                        if DERFI[p] >= THe && DERFI[p-1] < THe
                            we = p;
                            break
                        end
                    end
                end

                push!(bounds, Wave(wb, we))
            else # границ не найдено
                push!(bounds, Wave(-1, -1))
            end
        else
            # волны не было
            push!(bounds, Wave(-1, -1))
        end
    end

    return bounds
end

# поиск максимального наклона кривой QRS
function find_dermax(differed,R)
    dermax = Int[]
    k = 0

    for i in R
        k += 1
        for j in i:-1:2
            if differed[j-1] < differed[j]
                push!(dermax, j)
                break
            end
        end
        if length(dermax) < k push!(dermax, 0) end
    end

    return dermax
end


function plot_bounds(Pb,Pe,A)

    x = []
    y = []

    if Pe != []
        for i in 1:lastindex(Pb)
            push!(x, [Pb[i], Pb[i]])
            push!(x, [Pe[i], Pe[i]])
            push!(y, [-A, A])
            push!(y, [-A, A])
        end
    else
        for i in 1:lastindex(Pb)
            push!(x, [Pb[i], Pb[i]])
            push!(y, [-A, A])
        end
    end

    return x, y
end

# Поиск границ волн
function findwavebounds(differed, DERFI, fs, P, Q, R, S, T)

    Pwave = wavebounds(P, DERFI, R, "P", fs);
    Twave = wavebounds(T, DERFI, R, "T", fs);

    Qwave = wavebounds(Q, differed, R, "Q", fs);
    Swave = wavebounds(S, differed, R, "S", fs);
    Rwave = wavebounds(R, differed, R, "R", fs)
    L = lastindex(Qwave)
    Qb = Vector{Int}();  Se = Vector{Int}(); 
    for i = 1:L
        candidatesQ = [Qwave[i].b, Rwave[i].b]
        candidatesQ = candidatesQ[candidatesQ.>0] # убираем невалидные значения
        if isempty(candidatesQ)
            push!(Qb,0)
        else
            push!(Qb,minimum(candidatesQ))
        end
        candidatesS = [Swave[i].e, Rwave[i].e]
        candidatesS = candidatesS[candidatesS.>0] # убираем невалидные значения
        if isempty(candidatesS)
            push!(Se,0)
        else
            push!(Se,maximum(candidatesS))
        end
    end
    Pb = map((x) -> x.b, Pwave); Pe = map((x) -> x.e, Pwave)
    Tb = map((x) -> x.b, Twave); Te = map((x) -> x.e, Twave)
    # Qb = map((x) -> x.b, Qwave); Se = map((x) -> x.e, Swave)

    return Pb, Pe, Qb, Se, Tb, Te
end

# определение инвертированности волны по точке максимума
function isinv(diff, point_extr::Int)

    # point_extr - точка перегибa
    if diff[point_extr-1] >= 0 && diff[point_extr+1] <= 0
        return false
    elseif diff[point_extr-1] <= 0 && diff[point_extr+1] >= 0
        return true
    else
        println("Точка $point_extr не является перегибом!")
        return true
    end
end


## отбраковка максимум двух границ и поиск самых ранних onset и поздних end
## g = 6, 6, 6, 10, 12 для Pb, Pe, Qb, Se и Te соответственно
function multilead_bounds(bounds, g, type)
    if length(bounds) <= 2
        if type == "onset" bnd = minimum(bounds)
        elseif type == "end" bnd = maximum(bounds)
        end
    else
        bounds_sorted = sort(bounds)
        if type == "onset"
            min = bounds_sorted[1]
            rej = filter(x -> x < min + g, bounds_sorted)

            if !isempty(rej) && length(rej) <= 2
                ind = findall(x -> !(x in rej), bounds_sorted)
                bounds_sorted = bounds_sorted[ind]
            end

            bnd = minimum(bounds_sorted)

        elseif type == "end"
            max = bounds_sorted[end]
            rej = filter(x -> x > max - g, bounds_sorted)
            if !isempty(rej) && length(rej) <= 2
                ind = findall(x -> !(x in rej), bounds_sorted)
                bounds_sorted = bounds_sorted[ind]
            end

            bnd = maximum(bounds_sorted)
        end
    end

    return bnd
end



function multileads_bounds(all_points,Fs)
    # all_points вектор векторов
    # [Q, R, S, Pb, P, Pe, Tb, T, Te]
    final_points = []
    for w = 1:9
        # по каждой волне
        this_wave = []
        # по каждому комплексу на сигнале
        cmpx_12_all = all_points[w]
        for c = 1:length(cmpx_12_all)
            cmpx_12 = cmpx_12_all[c]
            cmpx_12 = cmpx_12[cmpx_12.>0]   
            if ~isempty(cmpx_12)
                cmpx_12_clear = outlier_ms(cmpx_12,Fs)
                if cmp in [1,4,7] # Q, Pb, Tb - самый левый край из всех отведений
                    cmpx = minimum(cmpx_12_clear)
                elseif cmp in [3,5,9] # # S, Pe, Te - самый правый край из всех отведений
                    cmpx = maximum(cmpx_12_clear)
                else
                    cmpx = mean(cmpx_12_clear)
                end            
                push!(this_wave, cmpx)
            end
        end

        push!(final_points, this_wave)
    end
    return final_points
end


# добавление точки к ранее известным позициям
# формируются наборы точек в одном окружении - типа от разных каналовв
function add_point(b::AbstractVector, a::AbstractVector, delta::Int)
    # b-вектор новых точек, a - куда добавлям
    # a = [[100],[1000],[2000]]
    # b = [900, 1001, 1100,3000]
    # delta = round(Int, 0.1*fs)
    insert_ind = 1
    for i=1:length(b)
        fl_find = false
        if ~isempty(a)
            for j=insert_ind:length(a)
                if median(a[j])-delta <= b[i] <= median(a[j])+delta
                    insert_ind = j
                    fl_find = true
                    continue
                end
            end
    
            if fl_find # если комплекс нашел место, то гуд
                push!(a[insert_ind], b[i])
            else # он или первый, или последний
                md_a = median.(a)
                ind = findfirst(b[i].<md_a)
                if ~isnothing(ind)
                    insert!(a, ind, [b[i]]) 
                else
                    push!(a, [b[i]])
                end
            end
        else
            push!(a, [b[i]])
            insert_ind+=1
        end
    end

    
    return a
end



