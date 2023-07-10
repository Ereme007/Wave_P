# сохранение картинок с выделителем по всем отведениям
using Plots
using XLSX
# plotly()

include("../src/detector_funcs.jl");
include("../src/qrs_cmpx.jl");
include("onelead.jl");
# расчет длительности интервалов
function get_intervals(cmpx::QRS)
    fs = cmpx.freq
    Pdur = round(Int(1000*(cmpx.points.Pe-cmpx.points.Pb)/fs)) #ms
    PQ = round(Int(1000*(cmpx.points.Q-cmpx.points.P)/fs)) #ms
    QS = round(Int(1000*(cmpx.points.S-cmpx.points.Q)/fs)) #ms
    QT = round(Int(1000*(cmpx.points.T-cmpx.points.Q)/fs)) #ms
    # Tdur = round(Int(1000*(cmpx.Te-cmpx.Tb)/fs)) #ms
    return [Pdur, PQ, QS, QT]
end

# амплитуды зубцов Р, Q, R, S, ST и Т 
function get_amplitudes(cmpx::QRS, s::Vector)
    all_amps = Vector()
    for w in [:r,:P,:Q,:R,:S,:r2,:T]
        pos = getproperty(cmpx.points,w)
        if pos>0
            push!(all_amps, s[pos])
        else
            push!(all_amps, 0)
        end
    end
    return all_amps

end

# расчет медианного значения позиции/амплитуды
# вектор векторов значений признаков по всем комплексам на сигнале
# тк комплекс везде один и тот же, то считаем типа самое частое значение по всем комплексам
function get_mdn(all_vals::Vector{Vector{T}}) where T
    # перегруппировываем интервалы 
    result=Vector{Int}()
    N = length(all_vals[1])
    for p=1:N
        # значения параметра на всех комлпексах
        this_wave = map(x->x[p], all_vals)
        mdn_val = round(Int, median(this_wave)) # надо улучшить и брать что-то типа моды
        push!(result,mdn_val)
    end
    return result
end

base_name = "CSE_MA"
base_name = "CTS"

dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin"
listoffiles = readdir(joinpath(dir,base_name))

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

allbinfiles = allbinfiles[allbinfiles.!=nothing]
L = lastindex(allbinfiles)
AMPLITUDES_all = Dict{String,Dict{String, Vector}}()
INTERVALS_ALL = Dict{String,Vector}()
# проверь наложение комплексов в 9, 14м,26,29, ///// 46, 52, 65  - нет детекций
# for fn = 1:L
    fn=4
    fname = allbinfiles[fn]
    fname_short = String(split(fname,".")[1])
    all_plots = Vector()
    all_points = Vector{Vector}()

    signals, fs, timestart, units = readbin(joinpath(dir,base_name,fname));
    N_ch = lastindex(signals)

    QRS_set = Vector{QRSMerged}()
    mdn_amps_ch = Vector() # для поканальных амплитуд зубцов
    mdn_amps = Vector{Vector}()
    for ch_num = 1:N_ch
        println(ch_num)
        sig = signals[ch_num]

        filtered60, cmpx_b, cmpx_e, Pb, P, Pe, r, Q, R, S, r2, Tb, T, Te = all_point_on_lead(sig, fs)
        pos = round.(Int,(cmpx_b.+cmpx_e)./2)
        # собираем в вектор структурок поканальной детекции
        # qrspoints_set= QRSPoints(fs, Q, R, S, Pb, P, Pe, Tb, T, Te)
        qrspoints_set= QRS(fs, pos, cmpx_b, cmpx_e, r, Q, R, S, r2, Pb, P, Pe, Tb, T, Te)
        # расчет амплитуд зубцов по этому отведению P,Q,R,S,T
        if ~isempty(qrspoints_set)
            all_amps = map(x->get_amplitudes(x, sig), qrspoints_set)
            push!(mdn_amps_ch, get_mdn(all_amps)) # Р, Q, R, S и Т 
        else
            push!(mdn_amps_ch, [0,0,0,0,0,0,0])
        end
        # для первого раза надо задать базовые детекции и систему отведений
        if isempty(QRS_set) && ~isempty(qrspoints_set)
            for qrspoints in qrspoints_set
                QRSMerged_new = QRSMerged(N_ch, qrspoints, ch_num)
                push!(QRS_set,QRSMerged_new)
            end
        end
        # добавляем в общий "котел" детекций
        # там всё само сольется с тем, чем надо
        for qrspoints in qrspoints_set
            push!(QRS_set,qrspoints,ch_num)
        end

        filtered60 = filtered60 .- 15*(ch_num-1)
        x1 = 4*fs; x2= 7*fs;
        if ch_num==1
            plot(filtered60, label = "Ch $ch_num", title = "$fname_short; ch $ch_num")
            # plot!(DERFI, label = "Diff,flt")
            display(scatter!(R[R.>0],filtered60[R[R.>0]], label = "R", color = "red"))
            scatter!(T[T.>0],filtered60[T[T.>0]], label = "T", color = "green")
            scatter!(Tb[Tb.>0],filtered60[Tb[Tb.>0]], label = "Tb", color = "green")
            scatter!(Te[Te.>0],filtered60[Te[Te.>0]], label = "Te", color = "green")
            scatter!(P[P.>0],filtered60[P[P.>0]], label = "P", color = "purple")
            scatter!(Pb[Pb.>0],filtered60[Pb[Pb.>0]], label = "Pb", color = "purple")
            scatter!(Pe[Pe.>0],filtered60[Pe[Pe.>0]], label = "Pe", color = "purple")
            scatter!(cmpx_e[cmpx_e.>0],filtered60[cmpx_e[cmpx_e.>0]], label = "cmpx_e",color = "red")
            scatter!(cmpx_b[cmpx_b.>0],filtered60[cmpx_b[cmpx_b.>0]], xlim=[x1,x2], label = "cmpx_b",color = "red")
        else
            plot!(filtered60, label = "Ch $ch_num")    
            scatter!(R[R.>0],filtered60[R[R.>0]], label = nothing, color = "red")
            scatter!(T[T.>0],filtered60[T[T.>0]], label = nothing, color = "green")
            scatter!(Tb[Tb.>0],filtered60[Tb[Tb.>0]], label = nothing, color = "green")
            scatter!(Te[Te.>0],filtered60[Te[Te.>0]], label = nothing, color = "green")
            scatter!(P[P.>0],filtered60[P[P.>0]], label = nothing, color = "purple")
            scatter!(Pb[Pb.>0],filtered60[Pb[Pb.>0]], label = nothing, color = "purple")
            scatter!(Pe[Pe.>0],filtered60[Pe[Pe.>0]], label = nothing, color = "purple")
            scatter!(cmpx_e[cmpx_e.>0],filtered60[cmpx_e[cmpx_e.>0]], label = nothing,color = "red")
            push!(all_plots, scatter!(cmpx_b[cmpx_b.>0],filtered60[cmpx_b[cmpx_b.>0]], xlim=[x1,x2], label = nothing,color = "red"))
        end
    end

    # расчет длительностей интервалов по всем найденным комплексам [Pdur, PQ, QS, QT]
    if ~isempty(QRS_set)
        all_intervals = map(x->get_intervals(x.merged), QRS_set)
        mdn_intervals = get_mdn(all_intervals)
    end
    colors = Dict(:S=>"red", :Q=>"red", :Pb=>"purple", :Pe=>"purple", :Tb=>"green", :Te=>"green")
    for point in [:S, :Q, :Pb, :Pe, :Tb, :Te] 
        for cmp in QRS_set
            value = getproperty(cmp.merged.points, point)
            push!(all_plots, plot!(fill(value,150), collect(-150:-1),color = colors[point], label = nothing))
        end
    end
    # собираем по файлам амплитуды Р, Q, R, S и Т 
    for (i,v) in enumerate(["P","Q","R","S","T"])
        if i==1
            AMPLITUDES_all[fname_short] = Dict{String,Vector}()
        end
        AMPLITUDES_all[fname_short][v]=map(x->x[i], mdn_amps_ch)
    end
    
    for (i,v) in enumerate(["Pdur","PQ","QS","QT"])
        INTERVALS_ALL[fname_short]= mdn_intervals
    end
    
    plot(all_plots[end], size = (500, 1000))

    savefig("pics/2_$base_name-$fname.png")
# end

using Statistics
# cmpM = QRS_set[5]
# x = map(x->x.Tb, cmpM.leads)
# mdn = median(x) # медиана
# in_range = (x.-mdn).< 5*fs/1000 
# x[in_range]
# remove_outliers!(all_detections, fs)
# merge_bounds!(cmpM)
cmpx = QRS_set[8].merged
Pdur, PQ, QS, QT = get_intervals(cmpx)
# расчет интервалов по всем найденным комплексам
all_intervals = map(x->get_intervals(x.merged), QRS_set)
mdn_intervals = get_mdn(all_intervals)

all_amps = map(x->get_amplitudes(x, sig), qrspoints_set)
mdn_amps = get_mdn(all_amps)


collect(all_intervals[1])
