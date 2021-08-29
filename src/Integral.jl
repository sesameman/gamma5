# using JSON3
# using Plots
# using FastGaussQuadrature
using LinearAlgebra
using Dierckx
using BenchmarkTools
using JLD2

include("/Users/kjy/Desktop/program/julia/module/GaussQuad/src/gaussQuad.jl")
include("/Users/kjy/Desktop/program/julia/module/GaussQuad/src/gaussmesh.jl")

P2=0.01
#常数区域
const τ=ℯ^2-1;
const Λ=0.234;
const ω=0.5;
const dd=(0.82)^3/ω;
const Nf=4;
const rm=12/(33 - 2*Nf);
const kstep=32
const zstep=16
const ystep=64
const cutup=10^4+0.
const cutdown=10^(-4)+0.
const mt=0.5
const dim=kstep*zstep

##导入原来的数据
function Inport()
    local A, B, k
    A, B,k=load("/Users/kjy/Desktop/program/julia/Gamma5/data/ABk512.jld2","A","B","k")
    global AA
    global BB
    AA=Spline1D(k,A)
    BB=Spline1D(k,B)
    return true
end

# 导入数据
Inport();

F(x::Float64)=((1-exp(-x/(4*mt)^2))/x)::Float64;
D(t::Float64)=(8*pi^2*(dd*exp(-t/(ω^2))/ω^4+rm*F(t)/log(τ+(1+t/Λ^2)^2)))::Float64;
branchfunction(x::Float64)=(x*AA(x)^2+BB(x)^2)::Float64
A(x)=AA(x)
B(x)=BB(x)
####################
##引入简写的动量k,角度z
getz(x::Int64)=((x-1)%zstep+1)::Int64
getk(x::Int64)=((x-1)÷zstep+1)::Int64


# 动量点和权重
meshk,weightk= gausslegendremesh(cutdown,cutup,kstep,2)
meshz,weightz=gausschebyshev(zstep,2);
##注意在kernel中，外动量为k指标为i，内动量q指标为j
##定义一系列变量
kfunction(x::Int64)=meshk[getk(x)]::Float64
zfunction(x::Int64)=mshz[getz(x)]::Float64
qPlus2function(j::Int64)=(P2/4+k[j]+sqrt(P2*k[j])*z[j])::Float64
qSubt2function(j::Int64)=(P2/4+k[j]-sqrt(P2*k[j])*z[j])::Float64
kdotpfunction(i::Int64)=sqrt(k[i]*P2)*z[i]::Float64
pdotqfunction(j::Int64)=sqrt(P2*k[j])*z[j]::Float64
A1function(j::Int64)=AA(qPlus2[j])::Float64
B1function(j::Int64)=BB(qPlus2[j])::Float64
A2function(j::Int64)=AA(qSubt2[j])::Float64
B2function(j::Int64)=BB(qSubt2[j])::Float64


##这里应该初始化下用到的量，转化为Table
k=Array{Float64}(undef,dim,1)
z=Array{Float64}(undef,dim,1)
qPlus2=Array{Float64}(undef,dim,1)
qSubt2=Array{Float64}(undef,dim,1)
kdotp=Array{Float64}(undef,dim,1)
pdotq=Array{Float64}(undef,dim,1)
A1=Array{Float64}(undef,dim,1)
B1=Array{Float64}(undef,dim,1)
A2=Array{Float64}(undef,dim,1)
B2=Array{Float64}(undef,dim,1)
branchplus=Array{Float64}(undef,dim,1)
branchsubt=Array{Float64}(undef,dim,1)
branch=Array{Float64}(undef,dim,1)
Threads.@threads for i=1:dim
    k[i]=kfunction(i)
    z[i]=zfunction(i)
    qPlus2[i]=qPlus2function(i)
    qSubt2[i]=qSubt2function(i)
    kdotp[i]=kdotpfunction(i)
    pdotq[i]=pdotqfunction(i)
    A1[i]=A1function(i)
    B1[i]=B1function(i)
    A2[i]=A2function(i)
    B2[i]=B2function(i)
    branchplus[i]=branchfunction(qPlus2[i])
    branchsubt[i]=branchfunction(qSubt2[i])
    branch[i]=branchplus[i]*branchsubt[i]
end


##分配kernel内存
kernel11=Array{Float64}(undef, dim, dim);
kernel12=Array{Float64}(undef, dim, dim);
kernel13=Array{Float64}(undef, dim, dim);
kernel14=Array{Float64}(undef, dim, dim);
kernel21=Array{Float64}(undef, dim, dim);
kernel22=Array{Float64}(undef, dim, dim);
kernel23=Array{Float64}(undef, dim, dim);
kernel24=Array{Float64}(undef, dim, dim);
kernel31=Array{Float64}(undef, dim, dim);
kernel32=Array{Float64}(undef, dim, dim);
kernel33=Array{Float64}(undef, dim, dim);
kernel34=Array{Float64}(undef, dim, dim);
kernel41=Array{Float64}(undef, dim, dim);
kernel42=Array{Float64}(undef, dim, dim);
kernel43=Array{Float64}(undef, dim, dim);
kernel44=Array{Float64}(undef, dim, dim);
