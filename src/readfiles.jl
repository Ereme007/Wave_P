using Dates, CSV, DataFrames, TOML #, FileUtils
include("templates.jl")

"""
словарь с кодировками типов, которые используются в hdr-файлах
"""
const string2datatype = Dict{String, DataType}(
    "int8"    => Int8,
    "uint8"   => UInt8,
    "int16"   => Int16,
    "uint16"  => UInt16,
    "int32"   => Int32,
    "uint32"  => UInt32,
    "int64"   => Int64,
    "uint64"  => UInt64,
    "float"   => Float32,
    "float32" => Float32,
    "double"  => Float64,
    "float64" => Float64,
    "string" => String
)

"""
чтение hdr-файла заголовка
"""
function readhdr(filepath::AbstractString)

    str = open(filepath, "r") do io
        len = stat(filepath).size
        bytes = Vector{UInt8}(undef, len)
        readbytes!(io, bytes, len)
        if bytes[1:3] == [0xEF, 0xBB, 0xBF] # проверка на UTF-8 BOM и пропуск
            bytes = bytes[4:end]
        end
        str = Array{Char}(bytes) |> x->String(x)
    end
    io = IOBuffer(str)
    lines = readlines(io) #, enc"windows-1251") # read and decode from windows-1251 to UTF-8 string

    lines = rstrip.(lines)

    delim = (' ', '\t')
    ln = split(lines[1], delim)
    num_ch, fs, lsb = parse(Int, ln[1]), parse(Float64, ln[2]), parse(Float64, ln[3])
    type = Int32
    # if (length(ln) > 3) # optional field
    #     type = string2datatype[ln[4]]
    # end

    ln = split(lines[2], delim)
    ibeg, iend = parse(Int, ln[1]), parse(Int, ln[2])
    timestart = parse(DateTime, ln[3])

    names = String.(split(lines[3], delim))
    lsbs = parse.(Float64, split(lines[4], delim))
    units = String.(split(lines[5], delim))

    if num_ch != length(names) # фикс, если в начале указано неверное кол-во каналов
        num_ch = length(names)
    end

    length(names) == length(lsbs) == length(units) || error("разное количество полей")

    return num_ch, fs, ibeg, iend, timestart, names, lsbs, units, type
end

"""
чтение bin-файла с каналами, рядом должен лежать hdr-файл
"""
function readbin(filepath::AbstractString, range::Union{Nothing, UnitRange{Int}} = nothing)
    # защита от дурака
    fpath, ext = splitext(filepath)
    hdrpath = fpath * ".hdr"
    binpath = fpath * ".bin"

    num_ch, fs, _, _, timestart, names, lsbs, units, type = readhdr(hdrpath)

    offset = (range !== nothing) ? range.start - 1 : 0

    elsize = num_ch * sizeof(type)
    byteoffset = offset * elsize # 0-based
    maxlen = (filesize(binpath) - byteoffset) ÷ elsize # 0-based
    len = (range !== nothing) ? min(maxlen, length(range)) : maxlen

    if len <= 0
        data = Matrix{type}(undef, num_ch, 0)
    else
        data = Matrix{type}(undef, num_ch, len)
        open(binpath, "r") do io
            seek(io, byteoffset)
            read!(io, data)
        end
    end

    channels = [data[ch, :] .* lsbs[ch] for ch in 1:num_ch] |> Tuple # matrix -> vector of channel vectors
    sym_names = Symbol.(names) |> Tuple # column names: String -> Symbol

    named_channels = NamedTuple{sym_names}(channels)
    return named_channels, fs, timestart, units
end

# чтение комбинированного текстового формата, состоящего из хедера и данных
function readevt(filepath::String)
    open(filepath, "r") do io
        # complex code to read some_data
        num_ch, fs, ibeg, iend, timestart, names, lsbs, units, type, types = readhdr(io)

        # будем читать строки до тех пор, пока не стречим разделитель хедера и данных
        while readline(io) !== "#"
        end
        #@show line = readline(io)
        #@show line !== "#"

        sym_names = Symbol.(names)
        #@show sym_names
        pairs = map(zip(sym_names, types)) do (k, v)
            k => v
        end

        data = CSV.File(io;
            header = sym_names,
            types = Dict(pairs),
            delim = '\t',
        ) |> columntable # named tuple of columns

        return data, fs, timestart, units
    end
end

# Читает реф разметку из таблицы (сведённые позиции и границы для каждого файла)
mutable struct MarkupFields
    P_onset::Float64     
    P_end::Float64
    QRS_onset::Float64
    QRS_end::Float64
    T_end::Float64
    P_dur::Float64
    PQ_interval::Float64
    QRS_dur::Float64
    QT_interval::Float64
    shift::Float64

    function MarkupFields()
        new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    end

    function MarkupFields(ponset, pend, qrsonset, qrsend, tend, pdur, pqint, qrsdur, qtint, shift)
        new(ponset, pend, qrsonset, qrsend, tend, pdur, pqint, qrsdur, qtint, shift)
    end
end

function read_all_ref(path::String)
    table = CSV.read(path, DataFrame, delim = ';')
    len = size(table)[1]
    refmarkup = Dict{String, MarkupFields}()
    for i in 1:len
        row = table[i,:]
        P_onset = try row["P-Onset"] catch e row["Ponset"] end
        P_end = try row["P-End"] catch e row["Pend"] end
        QRS_onset = try row["Qrs-Onset"] catch e row["QrsOn"] end
        QRS_end = try row["Qrs-End"] catch e row["QrsOff"] end
        T_end = try row["T-End"] catch e row["Tend"] end
        P_dur = try row["P-duration"]/2 catch e row["P_dur"] end
        PQ_interval = try row["PQ-interval"]/2 catch e row["PR"] end
        QRS_dur = try row["QRS-duration"]/2 catch e row["QRS"] end
        QT_interval = try row["QT-interval"]/2 catch e row["QT"] end
        shift = try row["End"] - row["Onset"] + 1 catch e 1000 end

        refmarkup[row["File"]] = MarkupFields(P_onset, P_end, QRS_onset, QRS_end, T_end, P_dur, PQ_interval, QRS_dur, QT_interval, shift)
    end

    return refmarkup
end

function read_microbox_test(path::String)
    table = readtable("$path\\StdEcgPars.bin")
    # table = formatdata(table)

    QRS_onset = table[:timeQ] |> collect
    QRS_offset = table[:timeS] |> collect
    P_onset = table[:timePstart] |> collect
    T_offset = table[:timeTendmax] |> collect

    QRS_dur = QRS_offset.-QRS_onset 
    PQ_dur = QRS_onset.-P_onset        
    QT_dur = T_offset.-QRS_onset      

    testmarkup = map((a,b,c,d,e,f,g) -> MarkupFields(a, 0, b, c, d, 0, e, f, g, 0), P_onset, QRS_onset, QRS_offset, T_offset, PQ_dur, QRS_dur, QT_dur)

    return testmarkup
end

# Зачитывает директорию dir и возвращает массив всех уникальных имён файлов без расширения (на каждую пару бинарь-хедер возвращается одно имя)
function getfileslist(dir::String)
    filelist = readdir(dir)
    allbinfiles = filter(x->endswith(lowercase(x), ".bin"), filelist)
    allbinfiles = map(x -> splitext(x)[1], allbinfiles)
    return allbinfiles
end

# Читаем темплейты из файла и преобразуем словарь в структуру темплейта
function gettemplates(path_toml::String)
    str = read(path_toml, String)
    dict = TOML.parse(str)
    tmpl_dict = template_dict(dict)

    return tmpl_dict
end