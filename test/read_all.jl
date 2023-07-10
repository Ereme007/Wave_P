# чтение всех комлпексов из выборки, чтобы понять, какие у нас вообще есть
using XLSX, DataFrames
using Plots
include("../src/readfiles.jl");
include("../src/detector_funcs.jl");
# уже бинари.
binpath = raw"Y:\Yuly\ГОСТ51\bin"
bases = ["CSE_MA", "CTS"]
refpaths = [raw"Y:\Yuly\ГОСТ51\CSE\ref.xlsx",raw"Y:\Yuly\ГОСТ51\CTS\ref.xlsx"]
cmp_collection = Dict()
for b = 1:lastindex(bases)
    base = bases[b]
    refpath = refpaths[b]
    dir = joinpath(binpath,base)
    listoffiles = readdir(dir)
    allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                                (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

    filenames= allbinfiles[allbinfiles.!=nothing]
    
    cmp_collection[base] = Dict()
    # чтение референтной
    if base=="CSE_MA"
        ref = XLSX.readtable(refpath,"MRESULTS & Intervals")|>DataFrame
        ref.File = map(x->replace(x, "O"=>"A"), ref.File) # замена MO на MA 
        ref.Len = ref.End .- ref.Onset.+1
        ref.QrsOn = ceil.(Int32, getproperty(ref,Symbol("Qrs-Onset")))
        ref.QrsOff = ceil.(Int32,getproperty(ref,Symbol("Qrs-End")))
    else
        ref = XLSX.readtable(refpath,"Sheet1")|>DataFrame
        # тут будет приведение референтной к общему виду
    end

    for fname in filenames
        # fname = filenames[5]
        fname_short = split(fname,".")[1]
        cmpxs = Vector()
        signals, fs, timestart, units = readbin(joinpath(dir, fname))
        id = findfirst(ref.File.==fname_short)
        if isnothing(id)
            println("Не найден файл $fname_short")
            continue
        end
        ref_file = ref[id:id,:] # опорная разметк для этого файла
        chnames = propertynames(signals)
        for ch in chnames
            # ch=chnames[1]
            # rng = 1:ref_file.Len[1] # если весь комплекс брать
            delta = ceil(Int32,0.2*fs)
            rng = max(1,ref_file.QrsOn[1]-delta):ref_file.QrsOff[1]+delta
            if rng==0:0
                continue
            end
            ecg = getproperty(signals, ch)
            # убираем дрейф
            isoline = LFfilt(ecg,fs, 1, 0)
            # вычитаем дрейф из сигнала с учетом коэфф.усиления
            sig_iso = ecg - isoline./(fs^2)
            # убираем ВЧ 
            filtered60 = LFfilt(sig_iso,fs, 60)
            # ecg = filtered60
            max_ampl = maximum(abs.(ecg))
            sign_norm = ecg[rng]./max_ampl 
            sign_norm = sign_norm.-sign_norm[1]
            push!(cmpxs, sign_norm)
        end
        cmp_collection[base][fname_short] = cmpxs
        tscale = 0:1/fs:fs
        plot(cmpxs,size = (500, 1000), title = "$fname_short")
        xlims!(-fs/20,fs)
        savefig("pics_cmpx/normal/$base-$fname_short.png")
    end
#  отдельно-тк разные разметки

end


using TOML
str = read("test/qrs_tmpl.toml", String)
dict = TOML.parse(str)
dict["rSR2"]

