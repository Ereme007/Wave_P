using Plots
#plotly()

include("../src/readfiles.jl");
include("../src/plots.jl");
include("OneLeadQRS.jl");
include("../src/find_localmin.jl")
# 1. Функция чтения списка файлов
#dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS" # синтетические ЭКГ
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)   # Читаем все имена файлов базы

# ***Полученние имени файла по номеру
n = 3
fn = allbinfiles[n]

# 2. Функция чтения сигнала одной записи (12 каналов)
signals, fs, _, _ = readbin("$dir/$(fn)") # Зачитываем файл
ch_names = keys(signals)
#dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS"
# 3. Функция чтения референотной разметки (сведённых позиций границ)
#ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv")
ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv")
fn_ref = fn[1:2] == "MA" ? "MO" * fn[3:end] : fn
refrow = ref[fn_ref]

show_record(n)
#show_record2(n)


using StructArrays
using Tables


Bandpass


signals = StructVector(signals)

filtered_signals = map(Tables.columntable(signals)) do sig
    hpass = my_butter(sig, 2, (5, 20), fs, Bandpass)
end
filtered_signals = StructVector(filtered_signals)

diff_signals = map(Tables.columntable(filtered_signals)) do sig
    DiffFilt(sig, 1)
end

#diff_signals = StructVector(diff_signals)



ref = _read_ref_CTS(n)
ref.P_onset
typeof(ref.P_onset)
ref.T_end
ref.P_offset
r = ref.P_onset:ref.T_end+20



_show_signals_mark(signals[r], ref)
_show_signals_mark(filtered_signals[r], ref)
xlims!(1, 120)
#pls = plot_vertical(signals.I, signals.II, signals.aVR, signals.V1, signals.V2, signals.V3, signals.V4, signals.V5, signals.V6; label="")
pls = plot_vertical(filtered_signals.I, signals.I, diff_signals.I; label="")
xlims!(1,180)
vline!([ref.P_onset, ref.P_offset])

#l = signals.I[5] |> Int64







r = 1:130
plot(filtered_signals.I[r])

lk = find_localmin2(filtered_signals.I[r], 10)
lm = find_localmax(filtered_signals.I[r], 30)
scatter!(lk, filtered_signals.I[lk])
scatter!(lm, filtered_signals.I[lm])


plot(signals.I[r])
vline!([ref.P_onset, ref.P_offset])
lk2 = find_localmin2(signals.I[r], 10)
lm2 = find_localmax(signals.I[r], 30)
scatter!(lk2, signals.I[lk])
scatter!(lm2, signals.I[lm])


display()

## ??? Функция чтения темплейтов для алгоритма QRS
tmpl_dict = gettemplates("test/qrs_tmpl.toml")

# 4. Функция построения на графике всех каналов с реф. разметкой
#show_record(14)

# 5. Функция обработки одной записи
filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x = OneFileBounds(signals, fs, tmpl_dict) # Вывести информацию для графиков наружу + добавить функцию построения/сохранения

# 5.0 Функции построения графиков по всему файлу
#p = show_file_qrs_bounds(filtered60_norm, bounds_x, zc, pos_cmpx, tmpl_name, refrow)

#     5.1 Функция обаботки одного канала (QRS)
sig = signals[1]
filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x, integrated, tmpl_lvl = OneLeadQRS(sig, fs, tmpl_dict) # Получаем код, границы и инфу для графиков

Start_X = 20
End_X = 67
x = [Start_X, End_X]
y = filtered60_norm[x]

plot(filtered60_norm)
xlims!(0, 91)
scatter!(x, y)

function prois(x_0, x_1, y_0, y_1)
    res = (y_1 - y_0) / (x_1 - x_0)
    pos = x_0
    return res, pos
end

proisvod_all = Float64[]
points_pois = Float64[]
points_x = Int64[]
flag = true #+ это тру ; - это фолс
i = 1
shag = 8
start, posit = prois(i, i + shag, filtered60_norm[i], filtered60_norm[i+shag])
if (start < 0)
    flag = false
end


push!(proisvod_all, start)

for i in 1:(91-shag)
    now, position = prois(i, i + shag, filtered60_norm[i], filtered60_norm[i+shag])
    if (flag == false && now > 0)
        push!(points_pois, now)
        push!(points_x, position)
        flag = true
    elseif (flag == true && now < 0)
        push!(points_pois, now)
        push!(points_x, position)
        flag = false
    end
    push!(proisvod_all, now)
end

points_pois
points_x
y = filtered60_norm[points_x]
scatter!(points_x, filtered60_norm[points_x])

if (length(points_pois) == 3)
    resultats = Int64[]
    push!(resultats, abs(Start_X - points_x[1]))
    push!(resultats, abs(End_X - points_x[3]))
end

if (length(points_pois) == 2)
    for i in (points_x[2]+shag*2):(130-shag)
        if (abs(filtered60_norm[i] - filtered60_norm[i+1]) < 0.0024)
            push!(points_pois, proisvod_all[i])
            push!(points_x, i)
            break
        end
    end
end
points_x
#проверка близкий точек!
End_all = Int64[]
for i in 1:(length(poi)-1)
    if (!((poi[i+1] - poi[i]) < 20))
        push!(End_all, poi[i])
    end
end
End_all
if (poi[length(poi)] - poi[length(poi)-1] > 20)
    push!(End_all, poi[length(poi)])
end
End_all

if (length(End_all) == 2)
    for i in (End_all[2]+shag*2):(91-shag)
        if (abs(filtered60_norm[i] - filtered60_norm[i+1]) < 0.0024)
            push!(points_pois, proisvod_all[i])
            push!(End_all, i)
            break
        end
    end
end
End_all
abs(filtered60_norm[98] - filtered60_norm[99])
abs(filtered60_norm[76] - filtered60_norm[77])



#filtered60_norm, 1, 130, 9, 98
function PointsP(sign, Start, End, Ref_Start, Ref_End)
    shag = 6

    proisvod_all = Float64[]
    points_pois = Float64[]
    points_x = Int64[]
    flag = true #+ это тру ; - это фолс
    i = 1

    start, posit = prois(i, i + shag, sign[i], sign[i+shag])

    if (start < 0)
        flag = false
    end
    push!(proisvod_all, start)

    for i in Start:(End-shag)
        now, position = prois(i, i + shag, sign[i], sign[i+shag])
        if (flag == false && now > 0)
            push!(points_pois, now)
            push!(points_x, position)
            flag = true
        elseif (flag == true && now < 0)
            push!(points_pois, now)
            push!(points_x, position)
            flag = false
        end
        push!(proisvod_all, now)
    end

    # scatter!(points_x, sign[points_x])

    if (length(points_pois) == 2)
        for i in (points_x[2]+shag*2):(130-shag)
            if (abs(sign[i] - sign[i+1]) < 0.0024)
                push!(points_pois, proisvod_all[i])
                push!(points_x, i)
                break
            end
        end
    end

    if (length(points_pois) == 3)
        resultats = Int64[]
        push!(resultats, abs(Ref_Start - points_x[1]))
        push!(resultats, abs(Ref_End - points_x[3]))
    end
    return points_x
end



#dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS" # синтетические ЭКГ
dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CSE_MA" # синтетические ЭКГ
allbinfiles = getfileslist(dir)
n = 13
fn = allbinfiles[n]

signals, fs, _, _ = readbin("$dir/$(fn)") # Зачитываем файл
ch_names = keys(signals)
#dir = raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\bin\CTS"
#ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CTS\ref.csv")
ref = read_all_ref(raw"\\incart.local\FS\GUEST\Yuly\ГОСТ51\CSE\ref.csv")
sig = signals[6]
filtered60_norm, zc, pos_cmpx, tmpl_name, bounds_x, integrated, tmpl_lvl = OneLeadQRS(sig, fs, tmpl_dict) # Получаем код, границы и инфу для графиков

#function PointsP(sign, Start, End, Ref_Start, Ref_End)
StArT = 15
EnD = 130
Ref_1 = 27
Ref_2 = 87
poi = PointsP(filtered60_norm, StArT, EnD, 27, 87)
plot(filtered60_norm)
xlims!(StArT, EnD)
scatter!(poi, filtered60_norm[poi])
poi


#проверка близкий точек!
End_all = Int64[]
for i in 1:(length(poi)-1)
    if (!((poi[i+1] - poi[i]) < 20))
        push!(End_all, poi[i])
    end
end
End_all
if (poi[length(poi)] - poi[length(poi)-1] > 20)
    push!(End_all, poi[length(poi)])
end
End_all


#End_all[2]+shag*2
#123-shag
##fdsd
if (length(End_all) == 2)
    for i in (End_all[2]+shag*2):(EnD-shag)
        if (abs(filtered60_norm[i] - filtered60_norm[i+1]) < 0.0024)
            #  push!(points_pois, proisvod_all[i])
            push!(End_all, i)
            break
        end
    end
end
End_all


plot(filtered60_norm)
scatter!(End_all, filtered60_norm[End_all])
xlims!(1, EnD)
rr = [Ref_1, Ref_2]
scatter!(rr, filtered60_norm[rr])







using Printf

#####
#Функция всех локальных min и max с радиусом (=20)
#Определение крайней правой точки если не поределилась как одна их экстремумов
include("../src/find_localmin.jl");
l = find_localmin2(filtered60_norm, 10)
plot(filtered60_norm)
m = find_localmax(filtered60_norm[1:150], 10)
scatter!(l, filtered60_norm[l])
scatter!(m, filtered60_norm[m])
xlims!(1, 100)



#https://www.cyberforum.ru/c-beginners/thread357649.html

# #int main() где N = 10 это радиус
# {
#     int a[N], n_min, n_max, i, k;
#     for (i = 0; i < N; i++) заполнение массива, он у нас есть
#     {
#         a[i] = rand()%3;
#         printf("%d ", a[i]);
#     }
#     puts("\n");
#     n_min = n_max = 0;
#     if (a[0] < a[1]) ват
#        n_min++;
#     else if (a[0] > a[1])
#        n_max++;
#     k = i = 1;
#     while (i < N)
#     {
#         while (i < N && a[i-1] < a[i])
#         {
#            i++;
#            k++;
#         }
#         if (k > 1)
#         {
#            n_max++;
#            k = 1;
#         }
#         while (i < N && a[i-1] > a[i])
#         {
#            i++;
#            k++;
#         }
#         if (k > 1)
#         {
#            n_min++;
#            k = 1;
#         }
#         while (i < N && a[i-1] == a[i])
#            i++;
#     }
#     printf("n_min = %d n_max = %d\n", n_min, n_max); просто пишет количество, скорее всего не запоминает!
#     return 0;
#  }




StArT
EnD
inp = filtered60_norm[StArT:EnD]
radius = 20
min_amp = 0
mx = (pos=1, amp=-Inf) # состояния
out = Int[]
mx
mx.pos
2 - mx.pos >= radius
mx.amp >= min_amp

inp[2]
mx.amp
inp[2] >= mx.amp
mx = (pos=1, amp=inp[2])



mx = (pos=1, amp=-Inf) # состояния
out = Int[]
i = 1 + 20
length(inp) - radius
#Разборка чтобы сделать также только с минимумом
#for i in 1 + radius : length(inp) - radius ##от 21 до 96
is_max = true

i = 56
mx.pos
mx.amp
i - mx.pos
min_amp

# if i - mx.pos >= radius && mx.amp >= min_amp
is_max = true
# включить этот код, чтобы проверять область перед пиком Это прсто проверкаа...


for k = mx.pos-radius:mx.pos-1
    if inp[k] > mx.amp
        is_max = false
        break
    end
end
if is_max
    push!(out, mx.pos)
end
mx = (pos=i, amp=inp[i])
# end

inp[i]
inp[i-1]
mx.amp
if inp[i] >= mx.amp
    mx = (pos=i, amp=inp[i])
end
mx.pos
#end

function Funn(X)
    return (X - 1) * (X - 1) * (X - 1)
end

function Sec(X, H)
    return (Funn(X + H) - 2 * Funn(X) + Funn(X - H)) / (H * H)
end

Sec(1, 0.00001)
Sec(1.1, 0.00001)
Sec(0.9, 0.00001)







noee = plot_vertical(signals.II, filtered_signals.II, diff_signals.II; label="")

xlims!(1, 100)