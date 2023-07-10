using Plots
plotly()

include("../src/detector_funcs.jl");

dir = "D:/INCART/QualityTest_IEC_60601-2-51/data/bin/CTS"
dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin\CTS"
dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin\CSE_MA"
listoffiles = readdir(dir)

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

allbinfiles = allbinfiles[allbinfiles.!=nothing]

fn = 5
fn = findfirst(allbinfiles.=="MA1_006.bin")
ch_num = 4
signals, fs, timestart, units = readbin(dir*"/"*allbinfiles[fn]);
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
maxpos, maxrng = findmax(integrated, 0.2, fs)

rng = 1:5000
plot(filtered60[rng])
plot!(differed[rng])
plot!(integrated)
scatter!(maxpos, integrated[maxpos])

# Поиск точек пересечения нуля дифференцированным сигналом
#  We again apply a lowpass filter 
# cutof frequency of 12Hz to ECGDER to reduce remaining noise
DERFI = LFfilt(differed,fs, 40,2) # для P и T

# проверить задержку!!
zerocrosses = zerocross(differed)
zc = map(x->x.pos, zerocrosses)
plot(differed)
scatter!(zc,differed[zc])

# Идентификация QRS
r, Q, R, S, r2 = qrs_detector_v2(maxrng, differed, fs, filtered60, zc)
# Q, R, S = qrs_points(filtered60,zerocrosses,maxpos,fs)
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


plot(filtered60)
scatter!(r[r.>0],filtered60[r[r.>0]])
scatter!(Q[Q.>0],filtered60[Q[Q.>0]])
scatter!(R[R.>0],filtered60[R[R.>0]])
scatter!(S[S.>0],filtered60[S[S.>0]])
scatter!(r2[r2.>0],filtered60[r2[r2.>0]])
scatter!(posQRS[posQRS.>0],filtered60[posQRS[posQRS.>0]])

# Поиск T
# Tud, Tdu, Tod, Tou = t_points(DERFI, R, fs);
# T = vcat(Tud, Tdu, Tod, Tou);
T, T_type = t_points(DERFI, posQRS, fs)

plot(DERFI)
plot!(filtered60)
scatter!(T[T.>0],DERFI[T[T.>0]])
scatter!(T[T.>0],filtered60[T[T.>0]])

# Поиск P
# подаем или Q, или T
P = p_points(DERFI, posQRS, Qb, T, zerocrosses, fs)
plot(DERFI)
plot!(filtered60)
scatter!(P[P.>0],filtered60[P[P.>0]])



# Определение границ волн
Pb, Pe, Qb, Se, Tb, Te = findwavebounds(differed, DERFI, fs, P, Q, R, S, T)

x1 = 3*fs; x2= 4*fs;
# plotly()
plot(filtered60, label = "ECG,flt")
plot!(DERFI, label = "Diff,flt")
scatter!(R[R.>0],filtered60[R[R.>0]], label = "R", color = "red")
scatter!(T[T.>0],filtered60[T[T.>0]], label = "T", color = "green")
scatter!(Tb[Tb.>0],filtered60[Tb[Tb.>0]], label = "Tb", color = "green")
scatter!(Te[Te.>0],filtered60[Te[Te.>0]], label = "Te", color = "green")
scatter!(P[P.>0],filtered60[P[P.>0]], label = "P", color = "purple")
scatter!(Pb[Pb.>0],filtered60[Pb[Pb.>0]], label = "Pb", color = "purple")
scatter!(Pe[Pe.>0],filtered60[Pe[Pe.>0]], label = "Pe", color = "purple")
scatter!(Se[Se.>0],filtered60[Se[Se.>0]], label = "S",color = "red")
scatter!(Qb[Qb.>0],filtered60[Qb[Qb.>0]], xlim=[x1,x2], label = "Q",color = "red")


maxpos, maxrng = findmax(integrated, 0.2, fs)
