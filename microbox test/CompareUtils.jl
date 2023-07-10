# Функции для сравнения реф и тест разметок 

# График с реф и тест разметками по одному сигналу
function compare_file_plot(leads::NamedTuple{(:I, :II, :III, :aVR, :aVL, :aVF, :V1, :V2, :V3, :V4, :V5, :V6), NTuple{12, Vector{Float64}}}, ref::MarkupFields, test::Vector{MarkupFields}, disp::Bool = true)
    leadnames = keys(leads)
    plts = Vector()
    shift = 0
    plot(leads[leadnames[1]], label = "$(leadnames[1])")
    for lead in leadnames
        shift -= 2000
        push!(plts, plot!(leads[lead].+shift, label = "$lead"))
    end

    p = plot!(plts[end], size = (800, 1000))

    # нанесение разметок

    # референтная
    vline!([ref.P_onset], linewidth = 2, color = :green, label = "ref P onset")
    vline!([ref.QRS_onset], linewidth = 2, color = :green, label = "ref QRS onset")
    vline!([ref.QRS_end], linewidth = 2, color = :green, label = "ref QRS end")
    vline!([ref.T_end], linewidth = 2, color = :green, label = "ref T end")
    
    # тестовая
    vline!([x.P_onset for x in test], linewidth = 2, color = :blue, label = "test P onset")
    vline!([x.QRS_onset for x in test], linewidth = 2, color = :blue, label = "test QRS onset")
    vline!([x.QRS_end for x in test], linewidth = 2, color = :blue, label = "test QRS end")
    vline!([x.T_end for x in test], linewidth = 2, color = :blue, label = "test T end")

    xlims!(0, maximum([ref.QRS_end, ref.T_end]) + 50)

    if disp display(p) end

    return p
end

# Стата сравнения позиций и длительностей (тест и реф) по одному файлу
function compare_file_stata(ref::MarkupFields, test::MarkupFields)
    # т.к. файлы состоят из дублирующихся представительных комплексов, и референтную разметку имеет только первый,
    # предполагаем, что первый элемент тестовой разметки относится к этому комплексу
    dP_onset = ref.P_onset - test.P_onset
    dQRS_onset = ref.QRS_onset - test.QRS_onset
    dQRS_end = ref.QRS_end - test.QRS_end
    dT_end = ref.T_end - test.T_end

    dPQ_int = ref.PQ_interval - test.PQ_interval
    dQRS_dur = ref.QRS_dur - test.QRS_dur
    dQT_int = ref.QT_interval - test.QT_interval

    return Dict("dP_onset" => -dP_onset, "dQRS_onset" => -dQRS_onset, "dQRS_end" => -dQRS_end, "dT_end" => -dT_end, 
                "dPQ_int" => -dPQ_int, "dQRS_dur" => -dQRS_dur, "dQT_int" => -dQT_int)
end

# Стата сравнения позиций и длительностей (тест и реф) по нескольким файлам
function compare_base_stata(ref::Vector{MarkupFields}, test::Vector{MarkupFields})
    n = length(ref)
    stata = fill(Dict{String, Float64}(), n)
    for i in 1:n
        stata[i] = compare_file_stata(ref[i], test[i])
    end

    return stata
end