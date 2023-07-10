# сохранение картинок с выделителем по всем отведениям

using Plots
# plotly()

include("../src/detector_funcs.jl");
include("onelead.jl");

base_name = "CSE_MA"
base_name = "CTS"

dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin"
listoffiles = readdir(joinpath(dir,base_name))

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

allbinfiles = allbinfiles[allbinfiles.!=nothing]
L = lastindex(allbinfiles)
for fn = 1:15
    fname = allbinfiles[fn]
    all_plots = Vector()
    all_points = Vector{Vector}()

    signals, fs, timestart, units = readbin(joinpath(dir,base_name,fname));
    N_ch = lastindex(signals)

    pointsQ = []; pointsR = []; pointsS = []
    pointsPb = []; pointsP = []; pointsPe = []
    pointsTb = []; pointsT = []; pointsTe = []

    for ch_num = 1:N_ch
        sig = signals[ch_num]

        filtered60, Q, R, S, Pb, P, Pe, Tb, T, Te = all_point_on_lead(sig, fs)

        delta = round(Int, 0.1*fs)
        pointsQ = add_point(Q, pointsQ, delta)
        pointsR = add_point(R, pointsR, delta)
        pointsS = add_point(S, pointsS, delta)
        pointsPb = add_point(Pb, pointsPb, delta)
        pointsP = add_point(P, pointsP, delta)
        pointsPe = add_point(Pe, pointsPe, delta)
        pointsTb = add_point(Tb, pointsTb, delta)
        pointsT = add_point(T, pointsT, delta)
        pointsTe = add_point(Te, pointsTe, delta)


        filtered60 = filtered60 .- 15*(ch_num-1)
        x1 = 4*fs; x2= 7*fs;
        if ch_num==1
            plot(filtered60, label = "Ch $ch_num", title = "$fname; ch $ch_num")
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

    all_points = [pointsQ, pointsR ,pointsS,
    pointsPb , pointsP ,pointsPe ,
    pointsTb ,pointsT, pointsTe]
    # сведеные границы
    # удаляем отведения, где ничего не обнаружилось - а это те, где не было R
    has_R = map(x->~isempty(all_points[x][2]), 1:length(all_points))
    all_points = all_points[has_R]
    final_points = multileads_bounds(all_points,fs)
    for i in [1,3,4,6,7,9] 
        for k in 1:length(final_points[i])
            push!(all_plots, plot!(fill(final_points[i][k],150), collect(-150:-1), label = nothing))
        end
    end

    plot(all_plots[end], size = (500, 1000))

    # savefig("pics/$base_name-$fname.png")
end

cmpx_12 = [[963,12], [1775,12]]
cmpx_12 = cmpx_12.>0 

cmpx_12[1]