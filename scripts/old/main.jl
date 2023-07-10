include("../scripts/onelead.jl")

# функция построения и сохранения графиков (вызывается по умолчанию из цикла обработки всех файлов директории)
function makensaveplots(signals, shownlead, filename, dbase, Pb, Pe, Qb, Se, Tb, Te)

    n = shownlead

    sig = signals[keys(signals)[n]]

    plot(sig, label = string(keys(signals)[n]))

    # scatter!(P, sig[P], label = "P", markersize = 2)
    # scatter!(Q, sig[Q], label = "Q", markersize = 2)
    # scatter!(R, sig[R], label = "R", markersize = 2)
    # scatter!(S, sig[S], label = "S", markersize = 2)
    # scatter!(T, sig[T], label = "T", markersize = 2)

    A = [-600,300]

    xlims!(2000,3000)

    wPb = map((x) -> [x, x], Pb)
    wPe = map((x) -> [x, x], Pe)
    wQb = map((x) -> [x, x], Qb)
    wSe = map((x) -> [x, x], Se)
    wTb = map((x) -> [x, x], Tb)
    wTe = map((x) -> [x, x], Te)

    plot!(wPb, fill(A, length(wPb)), linecolor = :red)
    plot!(wPe, fill(A, length(wPe)), linecolor = :red)
    plot!(wQb, fill(A, length(wQb)), linecolor = :green)
    plot!(wSe, fill(A, length(wSe)), linecolor = :green)
    plot!(wTb, fill(A, length(wTb)), linecolor = :blue)
    plot!(wTe, fill(A, length(wTe)), linecolor = :blue, legend = false, fmt = :png)
    title!(filename)

    # savefig("plots/"*split(allbinfiles[f],".")[1]*"_plot")
    savefig("plots "*dbase*"/"*filename*"_plot")
end

# Указать только директорию, где лежит база
dir = "D:/INCART/QualityTest_IEC_60601-2-51/data/bin/CTS"
listoffiles = readdir(dir)

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

allbinfiles = allbinfiles[allbinfiles.!=nothing]

for f in 1:lastindex(allbinfiles)
    # f = 52
    # begin
    binfile = dir*"/"*allbinfiles[f]

    signals, fs = sigdata(binfile);

    res = Markup[];
    for L in keys(signals)
        sig = signals[L]
        if L == :aVR sig = - sig end
        if mean(sig) == 0 break end
        markup = LeadMarkup(sig, fs)
        push!(res, markup)
    end

    P = Int[]; Pb = Int[]; Pe = Int[]; Q = Int[]; Qb = Int[];
    R = Int[]; S = Int[]; Se = Int[]; T = Int[]; Tb = Int[]; Te = Int[];

    ns = map(x -> length(x.R), res)
    N = minimum(ns)

    for i in 1:N   # По каждому комплексу
        p = Int[]; pb = Int[]; pe = Int[]; q = Int[]; qb = Int[];
        r = Int[]; s = Int[]; se = Int[]; t = Int[]; tb = Int[]; te = Int[];

        for j in 1:lastindex(res)  # В каждом отведении
            if !(res[j].P == res[j].Pb == res[j].Pe == res[j].Q
                == res[j].Qb == res[j].R == res[j].S == res[j].Se
                == res[j].T == res[j].Tb == res[j].Te == [1])
                if res[j].P[i] != 1 push!(p, res[j].P[i]) end
                if res[j].Pb[i] != 1 push!(pb, res[j].Pb[i]) end
                if res[j].Pe[i] != 1 push!(pe, res[j].Pe[i]) end
                if res[j].Q[i] != 1 push!(q, res[j].Q[i]) end
                if res[j].Qb[i] != 1 push!(qb, res[j].Qb[i]) end
                if res[j].R[i] != 1 push!(r, res[j].R[i]) end
                if res[j].S[i] != 1 push!(s, res[j].S[i]) end
                if res[j].Se[i] != 1 push!(se, res[j].Se[i]) end
                if res[j].T[i] != 1 push!(t, res[j].T[i]) end
                if res[j].Tb[i] != 1 push!(tb, res[j].Tb[i]) end
                if res[j].Te[i] != 1 push!(te, res[j].Te[i]) end
            end
        end

        if !isempty(pb) bnd = multilead_bounds(pb, 6, "onset"); push!(Pb, bnd) 
        else push!(Pb, 0) end
        if !isempty(pe) bnd = multilead_bounds(pe, 6, "end"); push!(Pe, bnd) 
        else push!(Pe, 0) end
        if !isempty(qb) bnd = multilead_bounds(qb, 6, "onset"); push!(Qb, bnd) 
        else push!(Qb, 0) end
        if !isempty(se) bnd = multilead_bounds(se, 10, "end"); push!(Se, bnd) 
        else push!(Se, 0) end
        if !isempty(tb) bnd = multilead_bounds(tb, 12, "onset"); push!(Tb, bnd) 
        else push!(Tb, 0) end
        if !isempty(te) bnd = multilead_bounds(te, 12, "end"); push!(Te, bnd)
        else push!(Te, 0) end

    end

    # # сохранение разметки (пишем только позиции границ)
    df = DataFrame(P_onset = Pb,  P_end = Pe, 
                    Q_onset = Qb, S_end = Se,
                    T_onest = Tb, T_end = Te);

    XLSX.writetable("res/"*split(allbinfiles[f],".")[1]*"_markup_res.xlsx", Markup=(eachcol(df), names(df)));

    makensaveplots(signals, 1, split(allbinfiles[f],".")[1], split(dir,"/")[end],
                    Pb, Pe, Qb, Se, Tb, Te)
end
