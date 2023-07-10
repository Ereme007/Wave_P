# типовые сченарии запуска microbox

extremove(file) = splitext(file)[1]

"""
запуск обработки microbox
"""
function runfile(exefile::String, binfile::String, resultdir::String, 
    settingsdir::String = joinpath(dirname(exefile), "Settings")
)
    file = endswith(binfile, ".bin") ? extremove(binfile) : binfile # чтобы правильно называть файлы типа 06.06.bin
    command = `$exefile $file $resultdir $settingsdir StartupConfig_debug.toml`
    # @show command
    @time run(command)
end

"""
многопоточный запуск по списку файлов
"""
function runbatch(exefile::String, binfiles::Vector{String}, resultdirs::Vector{String},
    settingsdir::String = joinpath(dirname(exefile), "Settings")
)
    @time Threads.@threads for i in eachindex(binfiles)
        binfile = binfiles[i]
        resultdir = resultdirs[i]
        runfile(exefile, binfile, resultdir, settingsdir)
        println("File $i of $(length(binfiles)) finished.")
    end
end

function runbatch(exefile::String, binfiles::Vector{String}, outpath::String,
    settingsdir::String = joinpath(dirname(exefile), "Settings")
)
    resultdirs = map(binfiles) do binfile
        fname = basename(binfile)
        fname = endswith(fname, ".bin") ? extremove(fname) : fname # чтобы правильно называть файлы типа 06.06.bin
        joinpath(outpath, fname)
    end

    runbatch(exefile, binfiles, resultdirs, settingsdir)
end
