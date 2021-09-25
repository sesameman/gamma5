using JLD2
using Plots
P2=Array{Float64}(undef,32,1)
F1k=Array{Float64}(undef,32,32)
@time for i=1:32
    local a, b
    global P2,F1k
    a,b=load("/Users/kjy/Desktop/program/julia/Gamma5/data/F1k_等间距/F1k$i.jld2","P2", "F1k")
    P2[i]=a
    F1k[i,:]=b
end #for i