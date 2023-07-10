
dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin\CTS"
dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin\CSE_MA"
listoffiles = readdir(dir)

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

allbinfiles = allbinfiles[allbinfiles.!=nothing]

fn = 3
fn = findfirst(allbinfiles.=="MA1_006.bin")
signals, fs, timestart, units = readbin(dir*"/"*allbinfiles[fn]);
all_Q = Vector()
all_S = Vector()
for ch_num = 1:12
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
    maxpos = findmax(integrated, 0.2, fs)
    DERFI = LFfilt(differed,fs, 40,2) # для P и T
    # проверить задержку!!
    zerocrosses = zerocross(differed)
    # Идентификация QRS
    Q, R, S = qrs_points(filtered60,zerocrosses,maxpos,fs)
    push!(all_Q, Q)
    push!(all_S, S)
end

QSdata = Vector{Vector}()

isolineMS = 25; #длина изолинии перед Q ћс
isoline = round(Int32, (isolineMS*fs/1000));
TimeBegPoint = 0
qs_sig = []
for cmp = 2 # 1:length(all_Q[1])
    cmpxQ_12 = map(x->all_Q[x][cmp], collect(1:12))
    cmpxQ_12 = cmpxQ_12[cmpxQ_12.>0]
    Q_mean = round(Int32, mean(cmpxQ_12))

    cmpxS_12 = map(x->all_S[x][cmp], collect(1:12))
    cmpxS_12 = cmpxS_12[cmpxS_12.>0]
    S_mean = round(Int32, mean(cmpxS_12))

    qs_sig = map(x-> signals[x][Q_mean-isoline:S_mean], collect(1:12))
    TimeBegPoint = Q_mean-isoline

    append!(QSdata, qs_sig)
end
QSlen = length(qs_sig[1])

QSdata

Vamp,Vdam,Vdtn,Pdam,VampIN,NrmVct,MVA,MVDA,MVDT,Alpha = CalcQSVectI(fs,QSdata,isoline);
NrmVctChns = size(NrmVct,1);
NrmVctAv = zeros(NrmVctChns,10);
NrmVctInd = 0;

AIbeg = 15;             #ѕерва¤ точка расчета вывода в файл по интегралу
AIstep = 10;            #Ўаг точек расчета вывода в файл по интегралу
AIsize = AIstep/2;      #ширина осреднени¤ расчета вывода в файл по интегралу
AIend = 1000 - AIstep;  #ѕоследн¤¤ точка расчета вывода в файл по интегралу
PlotChan = 7;           #канал Ё √ дл¤ вывода на экран 1-8 I,II,V1,V2,V3,V4,V5,V6

QRSFid_all = Vector{Dict}()

for AIval = AIbeg:AIstep:AIend
    PlowP,PhighP = GetInterPoints(VampIN,AIval-AIsize,AIval+AIsize);
    NrmVctInd = NrmVctInd + 1;
    time = (((PhighP - PlowP)/2 + PlowP)-isoline)*1000/fs;

    QRSFid = Dict()
    QRSFid["TimeBegPoint"] = TimeBegPoint
    QRSFid["Type"] = Type    
    QRSFid["time"] = time
    QRSFid["MVA"] = MVA
    QRSFid["MVDA"] = MVDA
    QRSFid["MVDT"] = MVDT

    # Averval = CalcInterpolAverage(VampIN,PlowP,PhighP);
    QRSFid["AIval"] =AIval;
    Averval = CalcInterpolAverage(Vamp,PlowP,PhighP);
    QRSFid["Averval1"] =Averval
    Averval = CalcInterpolAverage(Vdam,PlowP,PhighP);
    QRSFid["Averval2"] =Averval
    Averval = CalcInterpolAverage(Vdtn,PlowP,PhighP);
    QRSFid["Averval3"] =Averval
    Averval = CalcInterpolAverage(Pdam,PlowP,PhighP);
    QRSFid["Averval4"] =Averval
    Averval = CalcInterpolAverage(Alpha,PlowP,PhighP);
    QRSFid["Averval5"] =Averval
    
    for k = 1:NrmVctChns
        Averval = CalcInterpolAverage(NrmVct[k,:],PlowP,PhighP);
        QRSFid["Averval6"] =Averval
        if NrmVctInd < 11
            NrmVctAv[k,NrmVctInd] = Averval;
        end
    end
    push!(QRSFid_all, QRSFid)
    
end



plot(1:QSlen,Vamp)
plot!(1:QSlen,Vdam)
plot!(1:QSlen,Vdtn)
plot!(1:QSlen,VampIN)
plot!(1:QSlen,Alpha)

plot(NrmVctAv[:,1:end])
AmpXY = zeros(1,QSlen);
for i= 1:QSlen
    AmpXY[i] = sqrt(NrmVct[1,i]*NrmVct[1,i] + 0.75 *NrmVct[2,i]*NrmVct[2,i]);
end

AlphaRad = (pi/180) *Alpha;

scatter(Alpha,AmpXY[1,1:end], proj = :polar)

all_points = []
all_plots = []
for ch_num = 1:12
    sig = signals[ch_num]

    filtered60, Q, R, S, Pb, P, Pe, Tb, T, Te = all_point_on_lead(sig, fs)
    push!(all_points,[Q, R, S, Pb, P, Pe, Tb, T, Te])

    filtered60 = filtered60 .- 15*(ch_num-1)
    x1 = 4*fs; x2= 6*fs;
    if ch_num==1
        plot(filtered60, label = "Ch $ch_num")
        # plot!(DERFI, label = "Diff,flt")
        display(scatter!(R[R.>0],filtered60[R[R.>0]], label = "R", color = "red"))
        scatter!(T[T.>0],filtered60[T[T.>0]], label = "T", color = "green")
        scatter!(Tb[Tb.>0],filtered60[Tb[Tb.>0]], label = "Tb", color = "green")
        scatter!(Te[Te.>0],filtered60[Te[Te.>0]], label = "Te", color = "green")
        scatter!(P[P.>0],filtered60[P[P.>0]], label = "P", color = "purple")
        scatter!(Pb[Pb.>0],filtered60[Pb[Pb.>0]], label = "Pb", color = "purple")
        scatter!(Pe[Pe.>0],filtered60[Pe[Pe.>0]], label = "Pe", color = "purple")
        scatter!(S[S.>0],filtered60[S[S.>0]], label = "S",color = "red")
        scatter!(Q[Q.>0],filtered60[Q[Q.>0]], xlim=[x1,x2], label = "Q",color = "red")
    else
        plot!(filtered60, label = "Ch $ch_num")    
        scatter!(R[R.>0],filtered60[R[R.>0]], label = nothing, color = "red")
        scatter!(T[T.>0],filtered60[T[T.>0]], label = nothing, color = "green")
        scatter!(Tb[Tb.>0],filtered60[Tb[Tb.>0]], label = nothing, color = "green")
        scatter!(Te[Te.>0],filtered60[Te[Te.>0]], label = nothing, color = "green")
        scatter!(P[P.>0],filtered60[P[P.>0]], label = nothing, color = "purple")
        scatter!(Pb[Pb.>0],filtered60[Pb[Pb.>0]], label = nothing, color = "purple")
        scatter!(Pe[Pe.>0],filtered60[Pe[Pe.>0]], label = nothing, color = "purple")
        scatter!(S[S.>0],filtered60[S[S.>0]], label = nothing,color = "red")
        push!(all_plots, scatter!(Q[Q.>0],filtered60[Q[Q.>0]], xlim=[x1,x2], label = nothing,color = "red"))
    end
end
plot(all_plots[end],  size = (500, 1000))

plot!(fill(Q_mean,150), collect(-150:-1))
plot!(fill(Q_mean+4,150), collect(-150:-1))

final_points = multileads_bounds(all_points,Fs)

for i in 1:9
    for k in 1:length(final_points[i])
        push!(all_plots, plot!(fill(final_points[i][k],150), collect(-150:-1)))
    end
end
