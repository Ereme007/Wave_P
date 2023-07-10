include("../src/detector_funcs.jl");

dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin\CTS"
dir = raw"C:\Yuly\!Code\Office\QualityTest_IEC_60601-2-51\data\bin\CSE_MA"
listoffiles = readdir(dir)

allbinfiles = map((x) -> (length(split(x,".")) != 1 ? 
                            (split(x,".")[2] == "bin" ? x : nothing) : nothing), listoffiles)

allbinfiles = allbinfiles[allbinfiles.!=nothing]

fn = 5
ch_num = 1

# fn = findfirst(allbinfiles.=="MA1_006.bin")
signals, fs, timestart, units = readbin(dir*"/"*allbinfiles[fn]);
sig = signals[ch_num]


# убираем дрейф
isoline = LFfilt(sig,fs, 1, 0)
# вычитаем дрейф из сигнала с учетом коэфф.усиления
sig_iso = sig - isoline./(fs^2)
# убираем ВЧ 
filtered60 = LFfilt(sig_iso,fs, 60)
# производная 
differed_original, delay_2 = fivepointdiff(filtered60, fs)
# differed = fixdelay(differed, delay_2)
differed_original = normalize(differed_original, fs, 2 )
# заменяем маленькие значения на 0
differed = set_small_to_zero(differed_original)
# интеграл квадрата производной в скользящем окне
sqred = differed.^2
integrated, delay_3 = movingaverage(sqred, 0.096, fs)
integrated = fixdelay(integrated, delay_3)

# Поиск всех реперных точек (изменение направления интегрированного сигнала с возрастания на убывание)
maxpos_fixed,maxpos_rng = findmax(integrated, 0.2, fs)

# Поиск точек пересечения нуля дифференцированным сигналом
#  We again apply a lowpass filter 
# cutof frequency of 12Hz to ECGDER to reduce remaining noise
DERFI = LFfilt(differed,fs, 40,2) # для P и T

# проверить задержку!!
zerocrosses = zerocross(differed)
zc = map(x->x.pos, zerocrosses)

rng = 1:5000
plot(filtered60[rng])
plot!(differed[rng])
plot!(integrated[rng])
scatter!(maxpos_fixed, integrated[maxpos_fixed])

plot!(abs.(differed[rng]))

differed_abs = abs.(differed[rng])
rds = round(Int, 80*fs/1000)  # радиус поиска фронтов в 20 мс 
L = length(differed_abs)
pos = maxpos_fixed[2]
dx = differed_abs[2:end] - differed_abs[1:end-1]
insert!(dx,1,0)
extr_all = Vector{Vector{Int}}()

for pos in maxpos_fixed
    N = lastindex(x)
    extr = Vector{Int}() # ищем точки перегиба в радиусе точки максимума интеграла
    for i= max(1, pos-rds):min(L, pos+rds)
        # интересуют только максимумы
        if dx[i+1]<0 && dx[i]>0  #|| dx[i+1]>0 && dx[i]<0 
            push!(extr,i)
        end
    end
    push!(extr_all,extr)
end
extr = extr_all[2]
qs_front = Vector{Vector{Int}}()
# идем по каждому комплексу и проверяем максимальные фронты
for extr in extr_all
    sorted_ampl_ind = sortperm(differed_abs[extr];rev=true)
    first_two = sorted_ampl_ind[1:2] # номера трех маскимальных фронтов по амплитуде
    if abs(first_two[1]-first_two[2]) <= 3 # влезает два фронта между максимумами
        push!(qs_front,sort(extr[first_two]))
    else
        push!(qs_front, [0,0])
    end
end
scatter!(extr_all[2], differed_abs[extr_all[2]])


# Поиск всех реперных точек
maxpos_diff = findmax(abs.(differed), 0.01, fs)
scatter!(maxpos_diff, abs.(differed[maxpos_diff]))


# plotly()