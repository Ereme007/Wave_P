using Statistics
# тестируем структуру Комплекса
include("../src/qrs_cmpx.jl");
# один и тот же комплекс, в двух отведениях
fs=500
cmp1_1 = QRSPoints(fs;Q=963, R= 991, S = 1029, Pb = -1, P = 0, Pe=-1,Tb=1108, T=1172, Te=1214)
cmp1_2 = QRSPoints(fs;Q=964, R= 993, S = 1033, Pb = -1, P = 0, Pe=-1,Tb=1127, T=1178, Te=1241)
# следующий комплекс
cmp2_1 = QRSPoints(fs;Q=1771, R= 1799, S = 0, Pb = 1722, P = 1727, Pe=1771,Tb=1916, T=1980, Te=2022)

# проверка, один и тот же это комплекс или нет
check_cmplx_dist(cmp1_1,cmp2_1) == false
check_cmplx_dist(cmp1_1,cmp1_2) == true

# создаем комплекс с несколькими отведениями
cmp_multilead = QRSMerged(12, cmp1_1, 1)
push!(cmp_multilead,cmp1_2, 2) #добавляем второе отведение
merge_bounds!(cmp_multilead) # сводим границы (мб делать это внутри push-а?)

# второй комплекс
cmp_multilead_2 = QRSMerged(12,cmp2_1,1)

# Делаем "сет" из комплексов 
cmp_set= [cmp_multilead_2] 
# и добавляем туда новые обнаруженные  границы
push!(cmp_set,cmp1_1,1) # внутри проверится, новый это комплекс или нет.
length(cmp_set) == 2 # тк. новый, размер сета увеличился
length(cmp_set[2].leads) == 1

push!(cmp_set,cmp1_1,1)
length(cmp_set) == 2  # повторное добавление не увеличило сет
length(cmp_set[2].leads) == 2 # но записало в поканальные границы еще один набор точек

push!(cmp_set,cmp1_1,8) # типа детекция в 8м канале
~isnothing(cmp_set[2].leads[8]) == true
