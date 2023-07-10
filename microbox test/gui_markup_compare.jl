# гуи для сравнение реф и тест разметок баз CSE и CTS_MA. тестовая разметка получена с помощью microbox
using CImGui
using CImGui: ImVec2, ImVec4
using ImPlot
using ImPlot.LibCImGui: ImGuiCond_Once, ImGuiCond_Always, ImPlotAxisFlags_NoGridLines, ImGuiKey_Space

include(joinpath(pathof(CImGui), "..", "..", "examples", "Renderer.jl"))
println(joinpath(pathof(CImGui), "..", "..", "examples", "Renderer.jl"))

using .Renderer

include("../src/readfiles.jl")
include("CompareUtils.jl")

# Директория с файлами базы (сигналы)
dir = "Y:\\Yuly\\ГОСТ51\\bin"  

# Директории с тестовой и референтной разметками
testdir = "microbox test\\test markup"
refpath = "Y:\\Yuly\\ГОСТ51\\ref"

function shiftpos!(obj::MarkupFields, shift)
    obj.P_onset += shift
    obj.P_end += shift
    obj.QRS_onset += shift
    obj.QRS_end += shift
    obj.T_end += shift
end

function calcstata(nameofbase::String)
    allref = read_all_ref("$refpath\\$nameofbase.csv")
    refnames = keys(allref) |> collect |> sort!

    ref = [allref[x] for x in refnames]
    test = [read_microbox_test("$testdir\\$nameofbase\\$x")[2] for x in refnames]

    # Двигаем реф разметку ко второму обнаруженному тесту (первый тестом не метится либо метится плохо))
    kshift = [0, 1, 2, 3, 4] # обычно второй обнаруженный в тесте смещён относительно первого референтного не дальше 4-х комплексов
    for i in 1:lastindex(ref)
        shift = 0
        lastd = Inf # Разность позиций начал QRS, по минимуму которой будемк сопостовлять тест и реф
        for shft in kshift
            if (d = abs(test[i].QRS_onset - (ref[i].QRS_onset + ref[i].shift*shft)); d < lastd)
                shift = ref[i].shift*shft
                lastd = d
            end
        end
        shiftpos!(ref[i], shift)
    end

    stata = compare_base_stata(ref, test)

    return ref, test, stata, refnames
end

mutable struct MenuWindowState
    bases::Vector{String}                       # Имена баз
    filenames::Vector{String}                   # Имена файлов выбранной базы
    stata::Vector{Dict{String, Float64}}        # Статистика по каждому файлу базы

    selectedbase::Int # Индекс выбранной базы
    selectedfile::Int # Индекс выбранного файла базы

    function MenuWindowState()
        _, _, stata, filenames = calcstata("CTS")
        new(["CTS", "CSE_MA"], filenames, stata, 1, 1)
    end
end

mutable struct PlotState
    leads::NamedTuple{(:I, :II, :III, :aVR, :aVL, :aVF, :V1, :V2, :V3, :V4, :V5, :V6), NTuple{12, Vector{Float64}}}
    ref_markup::Vector{MarkupFields}
    test_markup::Vector{MarkupFields}

    function PlotState()
        ref, test, _, filenames = calcstata("CTS")
        leads, _, _, _ = readbin("$dir\\CTS\\$(filenames[1])") 
        new(leads, ref, test)
    end
end

function change_plot_state!(obj::PlotState, nameofbase::String, fileid::Int)
    ref, test, _, filenames = calcstata("$nameofbase")
    leads, _, _, _ = readbin("$dir\\$nameofbase\\$(filenames[fileid])") 

    obj.leads = leads
    obj.ref_markup = ref
    obj.test_markup = test
end

# Комбо-бокс выбора базы
function SelectBase(state::MenuWindowState, plot_state::PlotState)
    CImGui.Text("База:") 
    if CImGui.BeginCombo("##type", state.bases[state.selectedbase])
        for i in 1:lastindex(state.bases)
            if CImGui.Selectable(string(state.bases[i]), i == state.selectedbase) 
                state.selectedbase = i 
                state.selectedfile = 1
                plot_state.ref_markup, plot_state.test_markup, state.stata, state.filenames = calcstata(state.bases[i])
                change_plot_state!(plot_state, state.bases[i], 1)
            end
        end
        CImGui.EndCombo()
    end
end

# Таблица с именами файлов базы и параметрами по каждому
function FilesTable(state::MenuWindowState, plot_state::PlotState)
    CImGui.NewLine()
    CImGui.Text("Файлы базы:") 

    # Имена столбцов таблицы
    CImGui.BeginChild("##header", ImVec2(CImGui.GetWindowContentRegionWidth(), CImGui.GetTextLineHeightWithSpacing()*1.3))
    filenames = state.filenames
    # colnames = keys(state.stata[1]) |> collect
    # colnames = vcat("Файл", colnames)
    # всё-таки хардкодим имена столбцов, чтобы были в нужном мне порядке (ключи словаря не сортированы)
    colnames = ["Файл", "dP_onset", "dQRS_onset", "dQRS_end", "dT_end", "dPQ_int", "dQRS_dur","dQT_int"] 
        CImGui.Columns(lastindex(colnames), "Заголовки")
            CImGui.Separator()
            for cname in colnames
                CImGui.TextColored(ImVec4(0.45, 0.7, 0.80, 1.00), cname)
                CImGui.NextColumn()
            end
        CImGui.Columns(1)
        CImGui.Separator()
    CImGui.EndChild()

    # Строки таблицы
    CImGui.BeginChild("##scrollingregion", (0, 600))
        CImGui.Columns(lastindex(colnames), "Строки")
        for filen in 1:lastindex(filenames)
            rowid = findfirst(x -> x == filenames[filen], filenames)
            if CImGui.Selectable(filenames[filen], rowid == state.selectedfile, CImGui.ImGuiSelectableFlags_SpanAllColumns)
                state.selectedfile = rowid
                change_plot_state!(plot_state, state.bases[state.selectedbase], rowid)
            end
            CImGui.NextColumn()
            for field in colnames[2:end]
                CImGui.Text("$(state.stata[filen][field])")
                CImGui.NextColumn()
            end
        end
        CImGui.Columns(1)
    CImGui.EndChild()
end

# Окно выбора базы и файла базы + отображение параметров по каждому файлу
function MenuWindow(state::MenuWindowState, plot_state::PlotState)
    CImGui.Begin("Меню")
        SelectBase(state, plot_state)
        FilesTable(state, plot_state)
    CImGui.End()
end

# Окно построения графиков всех каналов сигнала и наложения тестовой и референтной разметок
function PlotsWindow(menu_state::MenuWindowState, plot_state::PlotState)
    CImGui.Begin("Графики")

        # Разметки
        ref = plot_state.ref_markup[menu_state.selectedfile]
        test = plot_state.test_markup[menu_state.selectedfile]

        ImPlot.SetNextPlotLimitsX(maximum([ref.P_onset, test.P_onset]).-200, maximum([ref.T_end, test.T_end]).+200, ImGuiCond_Always)
        if ImPlot.BeginPlot("ЭКГ", C_NULL, C_NULL, ImVec2(CImGui.GetWindowContentRegionMax().x, CImGui.GetWindowContentRegionMax().y*0.95),
            x_flags = ImPlotAxisFlags_NoGridLines | ImPlotAxisFlags_NoDecorations, y_flags = ImPlotAxisFlags_NoGridLines | ImPlotAxisFlags_NoDecorations)
            
            # Строим все каналы
            shift = 0
            for sig in plot_state.leads
                ImPlot.PlotLine(sig.+shift)
                shift -= 2000
            end

            # Строим все разметки
            ImPlot.PlotVLines("ref", [ref.P_onset, ref.QRS_onset, ref.QRS_end, ref.T_end], 4)
            ImPlot.PlotVLines("test", [test.P_onset, test.QRS_onset, test.QRS_end, test.T_end], 4)

            ImPlot.EndPlot()
        end
    CImGui.End()
end

function ui(menu_state::MenuWindowState, plot_state::PlotState) # Главное окно программы (собирает всё вместе)
    MenuWindow(menu_state, plot_state)
    PlotsWindow(menu_state, plot_state)
end

function show_gui() # Main
    menu_state = MenuWindowState();
    plot_state = PlotState();
    Renderer.render(
        ()->ui(menu_state, plot_state),
        width = 2000,
        height = 1600,
        title = ""
    )
end

show_gui();