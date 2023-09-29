function _read_ref(nr, reffile::String = Raw_CSE_Ref_Incart )
    df = CSV.read(reffile, DataFrame, delim = ';')
    #@info df
    row = df[nr, :]

    # 0-индексы (?)
    filename = row["File"]
    ibeg = row["Onset"] + 1
    iend = row["End"] + 1
    P_onset = row["P-Onset"] + 1
    P_offset = row["P-End"] + 1
    Qrs_onset = row["Qrs-Onset"] + 1
    Qrs_end = row["Qrs-End"] + 1
    T_end = row["T-End"] + 1
    P_dur = row["P-duration"]
    PQ_int = row["PQ-interval"]
    Qrs_dur = row["QRS-duration"]
    QT_int = row["QT-interval"]
    return (;
        filename,
        ibeg,
        iend,
        P_onset,
        P_offset,
        Qrs_onset,
        Qrs_end,
        T_end,
        P_dur,
        PQ_int,
        Qrs_dur,
        QT_int,
    )
end


function _read_ref_CTS(nr, reffile::String = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv" )#reffile::String = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
    df = CSV.read(reffile, DataFrame, delim = ';')
    #@info df
    row = df[nr, :]

    # 0-индексы (?)
    filename = row["File"]
  #  ibeg = row["Onset"] + 1
  #  iend = row["End"] + 1
    P_onset = row["Ponset"] + 1
    P_offset = row["Pend"] + 1
    Qrs_onset = row["QrsOn"] + 1
    Qrs_end = row["QrsOff"] + 1
    T_end = row["Tend"] + 1
    P_dur = row["P_dur"]
    PQ_int = row["PR"]
    Qrs_dur = row["QRS"]
    QT_int = row["QT"]
    return (;
        filename,
     #   ibeg,
     #   iend,
        P_onset,
        P_offset,
        Qrs_onset,
        Qrs_end,
        T_end,
        P_dur,
        PQ_int,
        Qrs_dur,
        QT_int,
    )
end

function plot_vertical(channels...; label::String = "")
    pls = [] #pls = map(v_ecgs, colnames) do sig, name
        for i in 1:length(channels)
            sig = channels[i]
            p = plot(sig, label = :none);
            push!(pls, p)
        end
        p = plot(
            pls...,
            link= :x,
            legend=false,
            # frame=:none,
            layout = (length(channels), 1),
            title = label,
             margin=0*Plots.mm,
            # widen=false,
            # ticks = false,
            # frame=:none,
            # legend_position = :topright)
        )
        plot!(size = (1000, 600))
        return p
end



function plot_vertical_ref(line, channels...; label::String = "")
    pls = [] #pls = map(v_ecgs, colnames) do sig, name
        for i in 1:length(channels)
            sig = channels[i]
            p = plot(sig, label = :none);
            push!(pls, p)
            vline!([line])#, lc=:black)#, ls=:dot)
        end
        p = plot(
            pls...,
            link= :x,
            legend=false,
            # frame=:none,
            layout = (length(channels), 1),
            title = label,
            # margin=0*Plots.mm,
            # widen=false,
            # ticks = false,
            # frame=:none,
            # legend_position = :topright)
        )
       # vline!(line)
        plot!(size = (800, 500))
        return p
end

function _show_signals_mark(signals, ref)
    colnames = [Tables.schema(signals).names...]
	v_ecgs = [Tables.columntable(signals)...]

    cols = 4
    pls = [] #pls = map(v_ecgs, colnames) do sig, name
    for i in 1:length(colnames)
        sig, name = v_ecgs[i], colnames[i]
        p = plot(sig, label = string(name));
        vline!([ref.Qrs_onset, ref.Qrs_end], label = :none);
        vline!([ref.T_end], label = :none);
        xticks = mod1(length(colnames),3) == 0 ? :auto : :none
        vline!([ref.P_onset, ref.P_offset], label = :none,
            xticks = xticks,
            yticks = :none,
            widen=false);
            push!(pls, p)
    end
    pls = reshape(pls, :, cols) |> permutedims |> x->reshape(x, :) # reorder for plot
	plot(
        pls...,
        link= :x,
        legend=false,
        frame=:none
        # layout = (length(colnames) ÷ cols, cols),
        # margin=0*Plots.mm,
        # widen=false,
        # ticks = false,
        # frame=:none,
        # legend_position = :topright)
    )

    plot!(size = (800, 500))
end

# by gvg
function show_record(
    nr;
    binpath = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MO",
    reffile = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
    )

    ref = _read_ref(nr)

    signals, fs, _, _ = readbin(joinpath(binpath, ref.filename*".bin"), ref.ibeg:ref.iend+20)

	_show_signals_mark(signals, ref)
end



function show_record_CTS(
    nr;
    binpath = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS",
    reffile = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv"
    )

    ref = _read_ref_CTS(nr)

    signals, fs, _, _ = readbin(joinpath(binpath, ref.filename*".bin"), ref.P_onset:ref.T_end+20)

	_show_signals_mark(signals, ref)
end
# show_record(40)

# data = [500 .* randn(100) for _ in 1:6]
# plot(
#     data,
#     #layout = (3,2),
#     margin=1*Plots.mm, # not very helpful
#     widen=false,
#     ticks = false,
#     # frame=:none
#     link = :x, # error
#     # xticks = :none,
#     # yticks = :none
# )

# p1 = plot(500 .* rand(100), xticks = :none);
# p2 = plot(500 .* rand(100));
# plot(p1, p2, layout = (2,1), link = :x, margin=0*Plots.mm)

# by skv

# График для одного отведения: фильтрованный номированный сигнал с нанесёнными детектированными пиками и точками наложения темплейтов,
# имена темплейтов, графики с к-тами похожести для наиболие подходящих темплейтов
function show_lead_templates(filtered60_norm::Vector{Float64}, integrated::AbstractVector{Bool}, zc::Vector{Int}, pos_cmpx::Vector{Int}, tmpl_lvl, tmpl_name::Vector{String}, disp::Bool = true)
    # построение графика уровня совпадения с темплейтом
    plts = Vector()
    plot(filtered60_norm, label = "filtered, normed")
    scatter!(zc,filtered60_norm[zc], lael = "zerocrosses")
    scatter!(pos_cmpx, filtered60_norm[pos_cmpx],mc="green",ms=4,label="")
    i=-2
    for tmpl_name in keys(tmpl_lvl)
        if maximum(tmpl_lvl[tmpl_name]) >= 0.5 # те, у которых мало совпадения, не стоим
            push!(plts,plot!(zc[1:end],tmpl_lvl[tmpl_name].+i,label=tmpl_name))
            push!(plts,plot!(integrated.*0.9.+i,label="",color="black"))
            i-=1
        end
    end

    # текст с темплейтом
    scatter!(pos_cmpx, filtered60_norm[pos_cmpx].+0.5,series_annotations=tmpl_name, ms=0.01, label = "")

    p = plot(plts[end], size = (800, 500),xlim=(2000,3000))

    if disp display(p) end

    return p
end

# График для одного отведения: строит границы тестовые и референтные
function show_lead_bounds(filtered60_norm::Vector{Float64}, zc::Vector{Int}, pos_cmpx::Vector{Int}, tmpl_name::Vector{String}, bounds_x::Vector{Vector{Int}}, refrow, disp::Bool = true)
    if !isempty(filtered60_norm) # Если канал не был пустым
        p = plot(filtered60_norm, label = "filtered norm")
        scatter!(zc,filtered60_norm[zc], label = "zerocrosses")
        scatter!(pos_cmpx, filtered60_norm[pos_cmpx],mc="green",ms=4,label="")
        scatter!(pos_cmpx, filtered60_norm[pos_cmpx].+0.5,series_annotations=tmpl_name, ms=0.01, label = "")
        vline!(bounds_x[1], label = "test bounds")

        # Наносим реф разметку
        On = try refrow.QrsOn[1] catch e refrow[:,"Qrs-Onset"][1] end
        Off = try refrow.QrsOff[1] catch e refrow[:,"Qrs-End"][1] end
        vline!([On, Off], color = :red, linewidth = 2, label = "ref bounds")
        xlims!(0, 1000)
    else
        p = plot()
    end

    if disp display(p) end

    return p
end

# Строит все отведения файла с нанесеёнными тестовыми границами по каждому отведению и рефферентными - синхронно для всех отведений.
# Отображает все задетектированные пики, точки наложения приоритетного темплейта и имя приоритетного темплейта
function show_file_qrs_bounds(filtered60_norm::Vector{Vector{Float64}}, bounds_x::Vector{Vector{Vector{Int}}}, zc::Vector{Vector{Int}}, pos_cmpx::Vector{Vector{Int}}, tmpl_name::Vector{Vector{String}}, refrow, disp::Bool = true)
    # Костылим наборы для построения прямых - границ комплексов, потому что удобный vline не даёт ограничить амплитуду
    plts = Vector()
    shift = 0
    ch_num = 1
    # Костылим наборы для построения прямых - границ комплексов, потому что удобный vline не даёт ограничить амплитуду
    xlines = Vector{Vector{Int64}}[]
    for bnd in bounds_x[ch_num]
        push!(xlines, [[bnd[1], bnd[1]], [bnd[2], bnd[2]]])
    end
    plot(filtered60_norm[ch_num].+shift, label = "$(ch_names[ch_num])")
    push!(plts, scatter!(zc[ch_num],filtered60_norm[ch_num][zc[ch_num]].+shift, label = ""))
    push!(plts, scatter!(pos_cmpx[ch_num], filtered60_norm[ch_num][pos_cmpx[ch_num]].+shift,mc="green",ms=4,label=""))
    push!(plts, scatter!(pos_cmpx[ch_num], filtered60_norm[ch_num][pos_cmpx[ch_num]].+0.5.+shift,series_annotations=tmpl_name[ch_num], ms=0.01, label = ""))
    if !isempty(bounds_x[ch_num]) push!(plts, plot!(xlines, fill([-1, 1].+shift, length(xlines)), color = :black, label = "")) end
    for ch_num in 2:12
        shift -= 1.5
        push!(plts, plot!(filtered60_norm[ch_num].+shift, label = "$(ch_names[ch_num])"))
        push!(plts, scatter!(zc[ch_num],filtered60_norm[ch_num][zc[ch_num]].+shift, label = ""))
        push!(plts, scatter!(pos_cmpx[ch_num], filtered60_norm[ch_num][pos_cmpx[ch_num]].+shift,mc="green",ms=4, label = ""))
        push!(plts, scatter!(pos_cmpx[ch_num], filtered60_norm[ch_num][pos_cmpx[ch_num]].+0.5.+shift,series_annotations=tmpl_name[ch_num], ms=0.01, label = ""))
        xlines = Vector{Vector{Int64}}[]
        for bnd in bounds_x[ch_num]
            push!(xlines, [[bnd[1], bnd[1]], [bnd[2], bnd[2]]])
        end
        if !isempty(bounds_x[ch_num]) push!(plts, plot!(xlines, fill([-1, 1].+shift, length(xlines)), color = :black, label = "")) end
    end

    p = plot(plts[end], size = (1000, 1000))

    # Наносим реф разметку
    On = try refrow.QrsOn[1] catch e refrow[:,"Qrs-Onset"][1] end
    Off = try refrow.QrsOff[1] catch e refrow[:,"Qrs-End"][1] end
    vline!([On, Off], color = :red, linewidth = 2, label = "ref")
    xlims!(0, 1000)

    if disp display(p) end
end



function _read_ref_needed(nr, reffile::String)#reffile::String = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv"
    df = CSV.read(reffile, DataFrame, delim = ';')
    #@info df
    row = df[nr, :]

    # 0-индексы (?)
    filename = row["File"]
  #  ibeg = row["Onset"] + 1
  #  iend = row["End"] + 1
    P_onset = row["Ponset"] + 1
    P_offset = row["Pend"] + 1
    Qrs_onset = row["QrsOn"] + 1
    Qrs_end = row["QrsOff"] + 1
    T_end = row["Tend"] + 1
    P_dur = row["P_dur"]
    PQ_int = row["PR"]
    Qrs_dur = row["QRS"]
    QT_int = row["QT"]
    return (;
        filename,
     #   ibeg,
     #   iend,
        P_onset,
        P_offset,
        Qrs_onset,
        Qrs_end,
        T_end,
        P_dur,
        PQ_int,
        Qrs_dur,
        QT_int,
    )
end