# 总程序
P2=0.01
include("./integral.jl")

plist=gausslegendremesh(cutdown,cutup,32,2)[1]
lengthplist=length(plist)
for indexforp2=1:lengthplist
global P2
P2=plist[indexforp2]
include("./integral.jl")
include("./eva_kernel_new.jl")
include("kernel_full.jl")
jldsave("/Users/kjy/Desktop/program/julia/Gamma5/data/F1k_all/F1k$indexforp2.jld2";P2, F1k)
print("$P2 for $indexforp2/$lengthplist done\n")
end
# include("./eva_kernel_new.jl")
