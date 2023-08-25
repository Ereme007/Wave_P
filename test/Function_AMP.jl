using Alert
#Функция, в которую передают массив точек, на выход - амплитуда (точек от 2 до 4)
#Если будет больше 4, то считает только первые четыре точки
#Если будет 2 , всё равботает
#Если одна точка - ошибка
function Amp_index(mass_points)
    size = length(mass_points)
    #  if (size == 1)
    #      alert("Одна точка")
    #  end
    count_amp = abs(mass_points[2] - mass_points[1])
    
    for i in 3:4
        if(i <= size)
            count_amp = count_amp + abs(mass_points[i] - mass_points[i-1])
        end
    end
    
    return count_amp
end
    
