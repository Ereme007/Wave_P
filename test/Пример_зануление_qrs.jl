x1 = 10
x2 = 33
y1 = 14
y2 = 22

(X - x1)/(x2-x1) = (Y-y1)/(y2-y1)


(y2-y1)/(x2-x1)
8/23

X = x1
Y = y1
b =  Y - X*(y2-y1)/(x2-x1) 
242/23

#определяем k потом b потом по точкам строим график прямой и это будет массив длинной qrs

k = (y2-y1)/(x2-x1)
b =  y1 - x1*(y2-y1)/(x2-x1) 
Mass_line = []
for i in (x1+1):(x2-1)
    push!(Mass_line, k*i + b)
end
Mass_line

plot(Mass_line)