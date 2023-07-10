using Plots
using XLSX
using Statistics

include("../src/readfiles.jl")

# Чтение длительностей интервалов из файла с рефферетной разметкой 
xref = XLSX.readxlsx("D:/INCART/QualityTest_IEC_60601-2-51/data/CTS/ref.xlsx");
xref = xref[1]

filenames = xref["A"][2:end]
P_dur = xref["B"][2:end]
QRS = xref["C"][2:end]
PR =  xref["D"][2:end]
QT = xref["E"][2:end]
HR = xref["F"][2:end]

# Чтение рзультатов разметки алгоритма и расчет интервалов
dir = "D:/INCART/GOST51_Sukhoverkhaya/res"
resfiles = readdir(dir)

dP_dur = Float64[]
dPR = Float64[]
dQRS = Float64[]
dQT = Float64[]

for i in resfiles

    xres = XLSX.readxlsx(dir*"/"*i);
    xres = xres[1]
    P_onset = xres["A"][2:end]
    P_end = xres["B"][2:end]
    Q_onset = xres["C"][2:end]
    S_end = xres["D"][2:end]
    T_onset = xres["E"][2:end]
    T_end = xres["F"][2:end]

    Pdur_res = P_end - P_onset
    PQ_res = Q_onset - P_onset
    QRS_res = S_end - Q_onset
    QT_res = T_onset - Q_onset

    Pdur_res = map((x,y) -> x == 0 || y == 0 ? 0 : x-y, P_end, P_onset)
    Pdur_res = Pdur_res[findall(x -> x!=0, Pdur_res)]
    PQ_res = map((x,y) -> x == 0 || y == 0 ? 0 : x-y, Q_onset, P_onset)
    PQ_res = PQ_res[findall(x -> x!=0, PQ_res)]
    QRS_res = map((x,y) -> x == 0 || y == 0 ? 0 : x-y, S_end, Q_onset)
    QRS_res = QRS_res[findall(x -> x!=0, QRS_res)]
    QT_res = map((x,y) -> x == 0 || y == 0 ? 0 : x-y, T_onset, Q_onset)
    QT_res = QT_res[findall(x -> x!=0, QT_res )]

    fname = split(i,"_")[1]
    for i in 1:lastindex(filenames)
        if fname == filenames[i]
            if !isempty(Pdur_res) push!(dP_dur, P_dur[i] - mean(Pdur_res)) end
            if !isempty(PQ_res) push!(dPR, PR[i] - mean(PQ_res)) end
            if !isempty(QRS_res) push!(dQRS, QRS[i] - mean(QRS_res)) end
            if !isempty(QT_res) push!(dQT, QT[i] - mean(QT_res)) end

        end
    end
end

MEAN_dP_dur = mean(dP_dur)
MEAN_dPR = mean(dPR)
MEAN_dQRS = mean(dQRS)
MEAN_dQT = mean(dQT)

STD_dP_dur = std(dP_dur)
STD_dPR = std(dPR)
STD_dQRS = std(dQRS)
STD_dQT = std(dQT)

#############################################
scatter(dP_dur[1:end-1], dP_dur[2:end])
scatter(dPR[1:end-1], dPR[2:end])
scatter(dQRS[1:end-1], dQRS[2:end])
scatter(dQT[1:end-1], dQT[2:end])