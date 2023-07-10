# сохранение картинок с выделителем по одному отведению 
using Plots
# plotly()

include("../src/detector_funcs.jl");
base_name = "CSE_MA"
# base_name = "CTS"

dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin"
listoffiles = readdir(joinpath(dir,base_name))

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

allbinfiles = allbinfiles[allbinfiles.!=nothing]
L = lastindex(allbinfiles)

# for fn = 1:5
    fname = allbinfiles[fn]
    signals, fs, timestart, units = readbin(joinpath(dir,base_name,fname));
    N_ch = lastindex(signals)
    for ch_num = 1:N_ch
        sig = signals[ch_num]

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
        maxpos, rng = findmax(integrated, 0.2, fs)
        # Поиск точек пересечения нуля дифференцированным сигналом
        #  We again apply a lowpass filter 
        # cutof frequency of 12Hz to ECGDER to reduce remaining noise
        DERFI = LFfilt(differed,fs, 40,2) # для P и T

        # проверить задержку!!
        zerocrosses = zerocross(differed)
        zc = map(x->x.pos, zerocrosses)
        # Идентификация QRS
        Q, R, S = qrs_points(filtered60,zerocrosses,maxpos,fs)
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
        posQRS = round.(Int,(Qb.+Se)./2)
        # Поиск T
        T, T_type = t_points(DERFI, posQRS, fs)
        # Поиск P
        P=p_points(DERFI, posQRS, Qb, T, zerocrosses, fs)


        # Определение границ волн
        Pb, Pe, Qb, Se, Tb, Te = findwavebounds(differed, DERFI, fs, P, Q, R, S, T)

        x1 = 4*fs; x2= 6*fs;
        fname = split(fname,'.')[1]
        plot(filtered60, label = "ECG,flt", title = "$fname; ch $ch_num")
        plot!(DERFI, label = "Diff,flt")
        scatter!(R[R.>0],filtered60[R[R.>0]], label = "R", color = "red")
        scatter!(T[T.>0],filtered60[T[T.>0]], label = "T", color = "green")
        scatter!(Tb[Tb.>0],filtered60[Tb[Tb.>0]], label = "Tb", color = "green")
        scatter!(Te[Te.>0],filtered60[Te[Te.>0]], label = "Te", color = "green")
        scatter!(P[P.>0],filtered60[P[P.>0]], label = "P", color = "purple")
        scatter!(Pb[Pb.>0],filtered60[Pb[Pb.>0]], label = "Pb", color = "purple")
        scatter!(Pe[Pe.>0],filtered60[Pe[Pe.>0]], label = "Pe", color = "purple")
        scatter!(S[S.>0],filtered60[S[S.>0]], label = "S",color = "red")
        scatter!(Q[Q.>0],filtered60[Q[Q.>0]], xlim=[x1,x2], label = "Q",color = "red")
        savefig("pics/$base_name-$fname-ch_$ch_num.png")
    end

# end



