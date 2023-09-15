module Module_Plot

using Plots
plotly()

function p()
    @info "function P"
end
export p
end