using LinearAlgebra
using Dierckx
using JSON3
using FastGaussQuadrature
#using Plots
using BenchmarkTools
using JLD2

P2=0.01
#常数区域
const τ=ℯ^2-1;
const Λ=0.234;
const dd=0.93;
const Nf=4;
const rm=12/(33 - 2*Nf);
const ω=0.5;
const kstep=32
const zstep=16
const ystep=64
const cutup=10^4+0.
const cutdown=10^(-4)+0.
const mt=0.5
const dim=kstep*zstep


# ##给出高斯积分的点和权重
# function gauss_quad(n)
#     β = @. .5/sqrt(1-(2*(1:n-1))^(-2.))
#     T = SymTridiagonal(zeros(n), β)
#     D, V = eigen(T)
#     i = sortperm(D); x = D[i]
#     w = 2*view(V, 1, i).^2
#     x, w
# end


##导入原来的数据
function Inport()
    open("/Users/kjy/Desktop/program/julia/Gamma5/A.json","r") do a
       AAA=JSON3.read(a)
        open("/Users/kjy/Desktop/program/julia/Gamma5/B.json","r") do b
            BBB=JSON3.read(b)
            open("/Users/kjy/Desktop/program/julia/Gamma5/X.json","r") do x
                X=JSON3.read(x)
                global AA
                global BB
                AA=Spline1D(X,AAA)
                BB=Spline1D(X,BBB)
            end
        end
    end
end

#之前多项式拟合的测试
# function log_quad(cutdown,cutup,n)
#     x=[10^(log10(cutdown)+i/(n-1)*(log10(cutup)-log10(cutdown))) for i= 0:n-1]
#     V(x) = [x[j]^(i-1) for i in eachindex(x), j in eachindex(x)]
#     w=V(x)\[(cutup^i-cutdown^i)/i for i=1:n]
#     x, w
# end
# x,w=log_quad(0.1,100,100)

#之前梯形法的点和权重
# #暂时用这个给出点和权重
# function mesh(cutdown,cutup,n)
#     x=[10^(log10(cutdown)+i/(n-1)*(log10(cutup)-log10(cutdown))) for i= 0:n-1]::Array{Float64}
#     w=Array{Float64}(undef,n)
#     for i in 1:n
#         if i==1
#             w[1]=x[2]-x[1]
#         elseif i==n
#             w[n]=x[i]-x[i-1]
#         else
#             w[i]=x[i+1]-x[i-1]
#         end
#     end
#     x,w
# end
# ####################

#之后用高斯拉格朗日法给出动量k2的点和权重
function  GaussLegendreK(down,up,n)
    s,w=gausslegendre(n)
    down=sqrt(down)
    up=sqrt(up)
    x=down*up*(up/down).^s
    w[i]*=x[i]*(log(up)-log(down))
    x,w
end

####################
####################
####################
Inport()
stepfunction(x)= x>0;
delta(x,y)= ==(x,y);
F(x::Float64)=((1-exp(-x/(4*mt)^2))/x)::Float64;
D(t::Float64)=(8*pi^2*(dd*exp(-t/(ω^2))/ω^4+rm*F(t)/log(τ+(1+t/Λ^2)^2)))::Float64;
branchfunction(x::Float64)=(x*AA(x)^2+BB(x)^2)::Float64
A(x)=AA(x)
B(x)=BB(x)
####################
##引入简写的动量k,角度z
getz(x::Int64)=((x-1)%zstep+1)::Int64
getk(x::Int64)=((x-1)÷zstep+1)::Int64
##高斯积分
# function GaussChebyshevIntegral2(f,n)
#     x,w=gausschebyshev(n::Int64,2)
#     out=dot(w,[f(x[i]) for i=1:n])
#     out::Float64
# end
# function GaussChebyshevIntegral128(f)

#     x,w=([-0.9997034698451394, -0.998814055240823, -0.9973322836635516, -0.9952590338932358, -0.9925955354920264, -0.9893433680751103, -0.9855044603739027, -0.9810810890921943, -0.9760758775559271, -0.9704917941574053, -0.9643321505948586, -0.9576005999084058, -0.9503011343135824, -0.9424380828337144, -0.9340161087325479, -0.925040206748652, -0.915515700133237, -0.9054482374931466, -0.8948437894408918, -0.883708645053719, -0.8720494081438075, -0.8598729933418101, -0.8471866219960603, -0.833997817889878, -0.8203144027795111, -0.8061444917553627, -0.791496488429254, -0.7763790799505741, -0.7608012318542781, -0.7447721827437818, -0.7283014388119159, -0.7113987682031776, -0.694074195220634, -0.6763379943809028, -0.6582006843207482, -0.639673021558891, -0.6207659941167485, -0.6014908150018703, -0.5818589155579527, -0.5618819386853605, -0.5415717319361841, -0.5209403404879301, -0.4999999999999998, -0.4787631293572092, -0.4572423233046385, -0.4354503449781915, -0.4134001183352828, -0.3911047204901559, -0.3685773739583617, -0.3458314388150115, -0.3228804047714462, -0.29973788317502437, -0.2764175989367712, -0.25293338239168056, -0.22929916109648993, -0.20552895156980036, -0.18163685097943635, -0.1576370287819737, -0.13354371831939785, -0.10937120837787441, -0.08513383471363578, -0.06084597155101392, -0.036522023057658726, -0.012176414801997309, 0.012176414801997652, 0.03652202305765885, 0.060845971551014046, 0.08513383471363568, 0.10937120837787452, 0.13354371831939799, 0.1576370287819736, 0.1816368509794365, 0.2055289515698007, 0.22929916109649004, 0.2529333823916809, 0.27641759893677154, 0.29973788317502426, 0.3228804047714463, 0.34583143881501144, 0.3685773739583618, 0.391104720490156, 0.4134001183352829, 0.43545034497819124, 0.4572423233046386, 0.4787631293572093, 0.5000000000000001, 0.5209403404879303, 0.5415717319361846, 0.5618819386853604, 0.5818589155579529, 0.6014908150018705, 0.6207659941167485, 0.6396730215588913, 0.6582006843207481, 0.6763379943809028, 0.694074195220634, 0.7113987682031779, 0.728301438811916, 0.7447721827437819, 0.760801231854278, 0.7763790799505744, 0.7914964884292541, 0.8061444917553627, 0.820314402779511, 0.8339978178898779, 0.8471866219960603, 0.8598729933418101, 0.8720494081438076, 0.8837086450537192, 0.8948437894408919, 0.9054482374931466, 0.9155157001332371, 0.9250402067486521, 0.934016108732548, 0.9424380828337144, 0.9503011343135824, 0.957600599908406, 0.9643321505948587, 0.9704917941574053, 0.9760758775559272, 0.9810810890921943, 0.9855044603739027, 0.9893433680751103, 0.9925955354920264, 0.9952590338932358, 0.9973322836635516, 0.998814055240823, 0.9997034698451394], [1.4440912182146153e-5, 5.772939648034401e-5, 0.00012976277739242128, 0.00023037019969721886, 0.00035931303370430453, 0.0005162854412572331, 0.0007009151011478568, 0.0009127640922211042, 0.0011513299320755743, 0.0014160467688962791, 0.0017062867235926266, 0.0020213613790582754, 0.0023605234130204163, 0.002722968370605682, 0.0031078365724181924, 0.003514215153604118, 0.003941140229066261, 0.0043875991796930025, 0.004852533054178993, 0.005334839080740601, 0.005833373282768781, 0.006346953192215214, 0.0068743606542758405, 0.0074143447167194995, 0.00796562459700839, 0.008526892720172794, 0.009096817820234386, 0.00967404809782208, 0.01025721442649078, 0.010844933600138081, 0.01143581161381626, 0.012028446970158053, 0.012621434003573528, 0.013213366214333638, 0.013802839604632092, 0.014388456008713087, 0.014968826409166002, 0.01554257423152126, 0.016108338609332824, 0.016664777612003096, 0.01721057142769407, 0.0177444254937751, 0.01826507356738252, 0.0187712807288078, 0.01926184631059063, 0.019735606745369515, 0.020191438325735, 0.020628259869539478, 0.0210450352843418, 0.0214407760249041, 0.021814543437911848, 0.022165450988355827, 0.022492666362295223, 0.022795413441014364, 0.02307297414189051, 0.023324690121606536, 0.023549964337668573, 0.02374826246452477, 0.02391911416092654, 0.024062114185525982, 0.02417692335806364, 0.024263269363866545, 0.024320947399748598, 0.02434982065978104, 0.02434982065978104, 0.024320947399748598, 0.024263269363866552, 0.02417692335806364, 0.024062114185525982, 0.023919114160926534, 0.02374826246452477, 0.023549964337668566, 0.023324690121606536, 0.02307297414189051, 0.022795413441014368, 0.022492666362295223, 0.022165450988355827, 0.021814543437911844, 0.021440776024904098, 0.0210450352843418, 0.02062825986953947, 0.020191438325734994, 0.019735606745369512, 0.019261846310590622, 0.018771280728807797, 0.018265073567382516, 0.017744425493775095, 0.01721057142769407, 0.016664777612003103, 0.016108338609332817, 0.01554257423152126, 0.014968826409166002, 0.014388456008713078, 0.013802839604632088, 0.013213366214333638, 0.012621434003573535, 0.012028446970158046, 0.011435811613816257, 0.010844933600138076, 0.010257214426490783, 0.009674048097822073, 0.009096817820234382, 0.008526892720172794, 0.007965624597008393, 0.0074143447167194934, 0.006874360654275837, 0.006346953192215214, 0.005833373282768782, 0.0053348390807405974, 0.004852533054178992, 0.0043875991796930025, 0.0039411402290662565, 0.0035142151536041136, 0.00310783657241819, 0.002722968370605682, 0.002360523413020418, 0.002021361379058273, 0.0017062867235926257, 0.0014160467688962746, 0.0011513299320755714, 0.0009127640922211027, 0.0007009151011478563, 0.0005162854412572335, 0.0003593130337043056, 0.00023037019969721816, 0.00012976277739241962, 5.7729396480343174e-5, 1.4440912182145865e-5])
#     out=0.
#     for i=1:64
#         out+=(f(x[i]::Float64)*w[i]::Float64)
#     end
#     return out::Float64
# end
function GaussChebyshevIntegral64(f)
    x,w=([-0.9993050417357722, -0.9963401167719553, -0.9910133714767443, -0.983336253884626, -0.973326827789911, -0.9610087996520538, -0.9464113748584028, -0.9295691721319396, -0.9105221370785028, -0.8893154459951141, -0.8659993981540929, -0.8406292962525803, -0.8132653151227975, -0.7839723589433414, -0.7528199072605318, -0.7198818501716109, -0.6852363130542332, -0.6489654712546573, -0.6111553551723933, -0.571895646202634, -0.5312794640198947, -0.4894031457070531, -0.4463660172534642, -0.4022701579639918, -0.35722015833766824, -0.31132287199021125, -0.26468716220876765, -0.21742364374000725, -0.1696444204239929, -0.12146281929612088, -0.07299312178779943, -0.024350292663424446, 0.024350292663424446, 0.07299312178779943, 0.12146281929612088, 0.1696444204239929, 0.21742364374000725, 0.26468716220876765, 0.31132287199021125, 0.35722015833766824, 0.4022701579639918, 0.4463660172534642, 0.4894031457070531, 0.5312794640198947, 0.571895646202634, 0.6111553551723933, 0.6489654712546573, 0.6852363130542332, 0.7198818501716109, 0.7528199072605318, 0.7839723589433414, 0.8132653151227975, 0.8406292962525803, 0.8659993981540929, 0.8893154459951141, 0.9105221370785028, 0.9295691721319396, 0.9464113748584028, 0.9610087996520538, 0.973326827789911, 0.983336253884626, 0.9910133714767443, 0.9963401167719553, 0.9993050417357722], [0.0017832807216964326, 0.004147033260562467, 0.006504457968978363, 0.008846759826363949, 0.011168139460131126, 0.013463047896718644, 0.01572603047602472, 0.01795171577569734, 0.020134823153530212, 0.02227017380838325, 0.024352702568710864, 0.026377469715054655, 0.028339672614259476, 0.030234657072402478, 0.03205792835485155, 0.03380516183714161, 0.035472213256882386, 0.03705512854024003, 0.03855015317861562, 0.039953741132720336, 0.04126256324262353, 0.04247351512365358, 0.043583724529323443, 0.044590558163756545, 0.04549162792741815, 0.0462847965813144, 0.04696818281620999, 0.0475401657148303, 0.047999388596458276, 0.04834476223480293, 0.04857546744150339, 0.04869095700913967, 0.04869095700913967, 0.04857546744150339, 0.04834476223480293, 0.047999388596458276, 0.0475401657148303, 0.04696818281620999, 0.0462847965813144, 0.04549162792741815, 0.044590558163756545, 0.043583724529323443, 0.04247351512365358, 0.04126256324262353, 0.039953741132720336, 0.03855015317861562, 0.03705512854024003, 0.035472213256882386, 0.03380516183714161, 0.03205792835485155, 0.030234657072402478, 0.028339672614259476, 0.026377469715054655, 0.024352702568710864, 0.02227017380838325, 0.020134823153530212, 0.01795171577569734, 0.01572603047602472, 0.013463047896718644, 0.011168139460131126, 0.008846759826363949, 0.006504457968978363, 0.004147033260562467, 0.0017832807216964326])
    out::Float64=0.
    for i=1:64
        out+=(f(x[i]::Float64)*w[i]::Float64)
    end
    return out::Float64
end
# meshy,weighty=gausschebyshev(ystep,2)
# function GaussChebyshevIntegral(f)

#     out::Float64=0.
#     for i=1:64
#         out+=(f(x[i]::Float64)*w[i]::Float64)
#     end
#     return out::Float64
# end
####################
####################
####################
####################

# function main()
#     kernel(x)=[1,x]
# end



meshk,weightk=GaussLegendreK(cutdown,cutup,kstep)
#meshq,weightq=mesh(cutdown,cutup,kstep)
meshz,weightz=gausschebyshev(zstep,2);
##注意在kernel中，外动量为k指标为i，内动量q指标为j
##定义一系列变量
kfunction(x::Int64)=meshk[getk(x)]::Float64
zfunction(x::Int64)=meshz[getz(x)]::Float64
qPlus2function(j::Int64)=(P2/4+k[j]+sqrt(P2*k[j])*z[j])::Float64
qSubt2function(j::Int64)=(P2/4+k[j]-sqrt(P2*k[j])*z[j])::Float64
kdotpfunction(i::Int64)=sqrt(k[i]*P2)*z[i]::Float64
pdotqfunction(j::Int64)=sqrt(P2*k[j])*z[j]::Float64
A1function(j::Int64)=AA(qPlus2[j])::Float64
B1function(j::Int64)=BB(qPlus2[j])::Float64
A2function(j::Int64)=AA(qSubt2[j])::Float64
B2function(j::Int64)=BB(qSubt2[j])::Float64

# kdotqfunction(i::Int64,j::Int64,y::Float64)=sqrt(k[i]*k[j])*(z[i]*z[j]+y*sqrt((1-z[i]^2)*(1-z[j]^2)))::Float64
# ksubq2function(i::Int64,j::Int64,y::Float64)=(k[i]+k[j]-2*kdotqfunction(i,j,y))::Float64

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

# kdotq=Array{Float64}(undef,dim,dim)
# ksubq2=Array{Float64}(undef,dim,dim)
# for i=1:dim ,j=1:dim
#     a=sqrt(k[i]*k[j])
#     b=z[i]*z[j]
#     c=sqrt((1-z[i]^2)*(1-z[j]^2))
#     kdotq[i,j](y)=a*(b+c*y)
#     #ksubq2(y)[i,j]=ksubq2function(i,j,y)
# end


##计算kernel
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