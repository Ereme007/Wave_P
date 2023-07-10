# после прогона multileadplot_qrs.jl


AMPLITUDES_all
# в одну таблицу
# имя файла - значения абсолютных интервалов "Pdur","PQ","QS","QT"
INTERVALS_ALL

using DataFrames
df = INTERVALS_ALL|>DataFrame
df2 = DataFrame([[names(df)]; collect.(eachrow(df))], [:column; Symbol.(["Pdur","PQ","QS","QT"])])

names(df2)

XLSX.writetable("test_Durations.xlsx", df2; overwrite=true)
for w in ["P","Q","R","S","T"]
    files = []
    M = Vector()
    for key in keys(AMPLITUDES_all)
        push!(M, AMPLITUDES_all[key][w])
        push!(files, string(key))
    end
    dfA = DataFrame(M, files)
    dfA2 = DataFrame([[names(dfA)]; collect.(eachrow(dfA))], [:column; Symbol.(collect(1:12))])
    sort!(dfA2)
    XLSX.writetable("test-$w-amplitudes.xlsx", dfA2; overwrite=true)
end

#################
using CSV
dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\CTS\CTS Database\CS50132D_CTS_Database_delivery\CS50132D_CTS_Database_HES_Format\ECG_Data_CAL-ANE_Output"
dur_file = "ref-Durations.csv"

# удаляем наибольшее значение ошибки
remove_err(differ)=sort(abs.(differ))[1:end-2]

df_ref_dur = DataFrame(CSV.File(joinpath(dir,dur_file)))
df_test_dur = DataFrame(XLSX.readtable(raw"C:\Users\yzh\.julia\dev\GOST51_Sukhoverkhaya\test_Durations.xlsx", "Sheet1"))
dnames_ref = df_ref_dur[:,1]
dnames_test = df_test_dur[:,1]
dnames_ref==dnames_test
differ_clean=[]

for col=3
    ref = df_ref_dur[:,col]
    test = df_test_dur[:,col]
    differ = ref-test
    differ_clean = remove_err(differ)
    print(std(differ_clean))
    print("   ")
    println(mean(differ_clean))
end


