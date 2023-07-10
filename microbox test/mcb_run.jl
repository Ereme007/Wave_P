# прогон микробокса по CTS и CSE_MA

include("run_microbox.jl")
include("../src/readfiles.jl")

nameofbase = "CTS"   # синтетичечкие ЭКГ
# nameofbase = "CSE_MA"  # биологические ЭКГ

exefile = raw"Y:\#KTAuto\microbox\microbox.exe"

dir = raw"Y:/Yuly\ГОСТ51\bin"*"\\$nameofbase"       
allfiles = getfileslist(dir)                        # Читаем все имена файлов базы
binfiles = dir.*"\\".*allfiles

outpath = raw"D:\ИНКАРТ\GOST51_Sukhoverkhaya\microbox test\test markup"*"\\$nameofbase"

runbatch(exefile, binfiles, outpath)