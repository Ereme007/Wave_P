# Сравнение тестовой (из микробокса) и референтной рзметок баз CTS и CSE
using Plots
plotly()

include("../src/readfiles.jl");
include("CompareUtils.jl")

# Имя базы
# nameofbase = "CTS"
nameofbase = "CSE_MA"

# Директории с тестовой и референтной разметками
testdir = "microbox test\\test markup\\$nameofbase"
refpath = "Y:\\Yuly/ГОСТ51\\ref\\$nameofbase.csv"

# Чтение имён файлов базы
dir = "Y:\\Yuly\\ГОСТ51\\bin\\$nameofbase"       
allfiles = getfileslist(dir)                        # Читаем все имена файлов базы (уникальные, без расширения)

# Чтение реф разметки (для всех файлов)
allref = read_all_ref(refpath)

# Работа по одному файлу
n = 10             # Номер файла
fn = allfiles[n]     # Имя файла

signals, fs, _, _ = readbin("$dir\\$(fn)") # Зачитываем файл
test = read_microbox_test("$testdir\\$fn") # Зачитываем тестовую разметку
ref = allref[fn]

# Нанесение разметок
p = compare_file_plot(signals, ref, test)

# Статистика

# Сравнение позиций и длительностей по одному файлу
stata = compare_file_stata(ref, test[1]) |> println

# Сравнение позиций и длительностей по базе
refnames = keys(allref) # потому что для CSE_MA файлов в реф разметке вдвое меньше, чем бинарников в базе (MА1_ не имеют реф разметки)
ref = [allref[x] for x in refnames]
test = [read_microbox_test("$testdir\\$x")[1] for x in refnames]
stata = compare_base_stata(ref, test)


table = readtable("microbox test\\test markup\\CSE_MA\\MA1_015\\Std12\\I\\ST.bin")
table = formatdata(table)