include("Test_P_5.jl")


n = 1
#сигнал детекции на 12 отведениях
plot_all_channels_points("CSE", n)

#исходный сигнал на 12 каналах
plot_all_channels_const_signal("CSE", n)
plot!()

all_the("CSE", 60)
plot!()
plot_const_signal("CSE", n, 9)
plot!(legend=false)
stop