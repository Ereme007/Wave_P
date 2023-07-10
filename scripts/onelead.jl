using Plots
using XLSX
using DataFrames

include("../src/detector_funcs.jl")

struct Markup
    P::Vector{Int}
    Pb::Vector{Int}
    Pe::Vector{Int}
    Q::Vector{Int}
    Qb::Vector{Int}
    R::Vector{Int}
    S::Vector{Int}
    Se::Vector{Int}
    T::Vector{Int}
    Tb::Vector{Int}
    Te::Vector{Int}
end

function save_plot(sig, P, Pb, Pe, Q, Qb, R, S, Se, T, Tb, Te, plotfilename)
    A = [minimum(sig),maximum(sig)]./2
    wPb,wPe = plot_bounds(Pb,Pe,A)
    wQb,wSe = plot_bounds(Qb,Se,A)
    wTb,wTe = plot_bounds(Tb,Te,A)

    p1 = plot(sig, legend = false)
    p2 = scatter!(P, sig[P], markersize=2)
    p3 = scatter!(Q, sig[Q], markersize=2)
    p4 = scatter!(R, sig[R], markersize=2)
    p5 = scatter!(S, sig[S], markersize=2)
    p6 = scatter!(T, sig[T], markersize=2)

    p7 = plot!(wPb,wPe,color = :red)
    p8 = plot!(wQb,wSe,color = :green)
    p9 = plot!(wTb,wTe,color = :purple)

    xlims!(2500,5000)

    savefig("debugging plots/$plotfilename.png")
end

#_______________________________________________________________________________________
# Если нужно отладиться на одном конкретном отведении из конкретного файла
    # binfile = "D:/INCART/QualityTest_IEC_60601-2-51/data/bin/CTS/CAL20200.bin"
    # signals, fs = sigdata(binfile);

    # leadnum = 1
    # sig = signals[keys(signals)[leadnum]];

#_______________________________________________________________________________________

function LeadMarkup(sig, fs)
    # определение полярности и инвертирование
    level = minimum(sig)+(maximum(sig)+abs(minimum(sig)))/2
    if level < 0 sig *= -1 end

    # Предподготовка (алгоритм Пана-Томпкинса)
    filtered, delay_1 = lynn_filter(sig, "bandpass")
    differed, delay_2 = fivepointdiff(filtered)

    # Интегрирование квадрата сигнала в скользящем окне шириной 95 мс (фильтр скользящего среднего)
    # Возведение в квадрат
    sqred = differed.^2
    integrated, delay_3 = movingaverage(sqred, 0.096, fs)

    # Поиск всех реперных точек (изменение направления интегрированного сигнала с возрастания на убывание)
    maxpos = findmax(integrated, 0.2, fs)

    # Поиск точек пересечения нуля дифференцированным сигналом
    zerocrosses = zerocross(differed)

    # Идентификация QRS
    Q, R, S = qrs_points(filtered,zerocrosses,maxpos,fs)

    # Поиск P
    DERFI, delay_3 = lynn_filter(differed, "low")
    P = p_points(DERFI, sig, R, Q, fs)

    # Поиск Т
    # Tud, Tdu, Tod, Tou = t_points(DERFI, R, fs);
    # T = vcat(Tud, Tdu, Tod, Tou);
    T = t_points(DERFI, R, fs)

    # Определение границ волн
    P, Pb, Pe, Q, Qb, R, S, Se, T, Tb, Te = findwavebounds(differed, DERFI, filtered, P, Q, R, S, T)

    # Коррекция позиций 
    P, Pb, Pe, Q, Qb, R, S, Se, T, Tb, Te = pos_correct(delay_1, delay_2, delay_3, P, Pb, Pe, Q, Qb, R, S, Se, T, Tb, Te)

    # Собираем результат  
    res = Markup(P, Pb, Pe, Q, Qb, R, S, Se, T, Tb, Te)

    # построение и сохранение графика в папке debugging plots
    # plotfilename = split(split(binfile,"/")[end],".")[end-1]
    # save_plot(sig, P, Pb, Pe, Q, Qb, R, S, Se, T, Tb, Te, plotfilename)

    return res
end

# расчет точек по одному сигналу
function all_point_on_lead(sig, fs)
     # убираем дрейф
     isoline = LFfilt(sig,fs, 1, 0)
     # вычитаем дрейф из сигнала с учетом коэфф.усиления
     sig_iso = sig - isoline./(fs^2)
     # убираем ВЧ 
     filtered60 = LFfilt(sig_iso,fs, 60)
     # производная 
     differed_original, delay_2 = fivepointdiff(filtered60, fs)
     # differed = fixdelay(differed, delay_2)
     differed_original = normalize(differed_original, fs, 2 )
     # заменяем маленькие значения на 0
     differed = set_small_to_zero(differed_original)
     # интеграл квадрата производной в скользящем окне
     sqred = differed.^2
     integrated, delay_3 = movingaverage(sqred, 0.096, fs)
     integrated = fixdelay(integrated, delay_3)

     # Поиск всех реперных точек (изменение направления интегрированного сигнала с возрастания на убывание)
     maxpos, maxrng = findmax(integrated, 0.2, fs)
     # Поиск точек пересечения нуля дифференцированным сигналом
     #  We again apply a lowpass filter 
     # cutof frequency of 12Hz to ECGDER to reduce remaining noise
     DERFI = LFfilt(differed,fs, 40,2) # для P и T

     # проверить задержку!!
     zerocrosses = zerocross(differed)
     zc = map(x->x.pos, zerocrosses)
     # Идентификация QRS
    #  Q, R, S = qrs_points(filtered60,zerocrosses,maxpos,fs)
     r, Q, R, S, r2  = qrs_detector_v2(maxrng, differed, fs, filtered60, zc)
     rwave = wavebounds(r, differed, R, "r", fs);
     Qwave = wavebounds(Q, differed, R, "Q", fs);
     Swave = wavebounds(S, differed, R, "S", fs);
     Rwave = wavebounds(R, differed, R, "R", fs)
     r2wave = wavebounds(r2, differed, R, "r2", fs);
     L = lastindex(Qwave)
     cmpx_b = Vector{Int}();  cmpx_e = Vector{Int}(); 
     for i = 1:L
         candidates_b = [Qwave[i].b, Rwave[i].b, rwave[i].b]
         candidates_b = candidates_b[candidates_b.>0] # убираем невалидные значения
         if isempty(candidates_b)
             push!(cmpx_b,0)
         else
             push!(cmpx_b,minimum(candidates_b))
         end
         candidates_e = [Swave[i].e, Rwave[i].e, r2wave[i].e]
         candidates_e = candidates_e[candidates_e.>0] # убираем невалидные значения
         if isempty(candidates_e)
             push!(cmpx_e,0)
         else
             push!(cmpx_e,maximum(candidates_e))
         end
     end
     posQRS = round.(Int,(cmpx_b.+cmpx_e)./2)
     # Поиск T
     T, T_type = t_points(DERFI, posQRS, fs)
     # Поиск P
     # maxpos поставила вмест R, тк R может и не быть=) - ПРОВЕРИТЬ 
     P=p_points(DERFI, maxpos, cmpx_b, T, zerocrosses, fs)


     # Определение границ волн T и P
     Pwave = wavebounds(P, DERFI, R, "P", fs);
     Twave = wavebounds(T, DERFI, R, "T", fs);
     Pb = map((x) -> x.b, Pwave); Pe = map((x) -> x.e, Pwave)
     Tb = map((x) -> x.b, Twave); Te = map((x) -> x.e, Twave)
    #  Pb, Pe, Qb, Se, Tb, Te = findwavebounds(differed, DERFI, fs, P, Q, R, S, T)


     return filtered60, cmpx_b, cmpx_e, Pb, P, Pe, r, Q, R, S, r2, Tb, T, Te
end