using JuMP
import Gurobi
import GLPK
import HiGHS


BioenergyPrice = [81]
BiofuelPrice= [ 204, 200 ,  204,  210, 204, 200,  204,  210, 200, 210,  204,  210]
CFE = [15, 15, 15, 15, 15, 15,15, 15, 15, 15, 15, 15]
MaxDF= [3036.12, 3036.12, 3036120, 3036120, 3036120, 6072240, 6072240, 24288960, 24288960, 242889, 24288960, 24288960.8]
MaxDE=[ 100,  100  , 9800  , 9800  , 9800  , 9800  , 9800 , 9800 , 5488510  , 548850 ,548850 , 548840]
HoldingB = [0.0375, 0.0375, 0.0375, 0.0375, 0.0375]
HoldingF = [5.283]
AlfaFE = [2.776]
Cap=[ 15,  15,  15 ,  2,  2 ]
AlfaBF=[0.272         0.27          0.313          0        0;
        0.2584        0.2565        0.29735        0        0;
        0.2448        0.243         0.2817         0        0;
        0.2312        0.2295        0.26605        0        0;
        0.2176        0.216         0.2504         0        0;
        0.204         0.2025        0.23475        0        0;
        0.1904        0.189         0.2191         0        0;
        0.1768        0.1755        0.20345        0        0;
        0.1632        0.162         0.1878         0        0;
        0.1496        0.1485        0.17215        0        0;
        0.136         0.135         0.1565         0        0;
        0.1224        0.1215        0.14085        0        0]

AlfaBE=[0        0        0        0.956         0.895;
        0        0        0        0.9082        0.85025;
        0        0        0        0.8604        0.8055;
        0        0        0        0.8126        0.76075;
        0        0        0        0.7648        0.716;
        0        0        0        0.717         0.67125;
        0        0        0        0.6692        0.6265;
        0        0        0        0.6214        0.58175;
        0        0        0        0.5736        0.537;
        0        0        0        0.5258        0.49225;
        0        0        0        0.478         0.4475;
        0        0        0        0.4302        0.40275]


Yield=[44  44         44        44        44           44           44          44          44          44       44        44;
       35  35         35        35        35           35           35          35          35          35       35        35;
       35  35         35        35        35           35           35          35          35          35       35        35;
       55  55         55        55        55           55           55          55          55          55       55        55;
       35  35         35        35        35           35           35          35          35          35       35        35]


HoursN=[0    0          0         0         0            0            247.5       192.5       200         189      160       84;
        0    0          0         0         0            187          247.5       192.5       0           0        0         0;
        600  300        0         0         0            500          247.5       192.5       200         189      160       84;
        500  300        0         0         0            300          247.5       192.5       200         189      160       84;
        60   90         148.5     150       148.5        300          247.5       192.5       200         189      160       84]


CB = [               20 20 20 20 20 20 20 20 20 20 20 20; 
                     21 21 21 21 21 21 21 21 21 21 21 21;
                     26 26 26 26 26 26 26 26 26 26 26 26;
                     24 24 24 24 24 24 24 24 24 24 24 24; 
                     19 19 19 19 19 19 19 19 19 19 19 19]
                                          
CBF = [              21 21 21 21 21 21 21 21 21 21 21 21; 
                     21 21 21 21 21 21 21 21 21 21 21 21;
                     21 21 21 21 21 21 21 21 21 21 21 21;
                     0  0  0  0  0  0  0  0  0  0  0  0;
                     0  0  0  0  0  0  0  0  0  0  0  0]
                                        
CBE = [              0  0  0  0  0  0  0  0  0  0  0  0;                 
                     0  0  0  0  0  0  0  0  0  0  0  0;
                     0  0  0  0  0  0  0  0  0  0  0  0;
                     16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5; 
                     16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5  16.5]                                    



TP_biomass = length(HoldingB) # Tyep of biomass B
TypeOfBiomass=range(1,length=TP_biomass)
AG_biomass = length(MaxDE) # Age of biomass A
AgeOfBiomass=range(1,length=AG_biomass)
NB_periods = length(CFE) # Number of periods T
periods=range(1,length= NB_periods)


#SCP = Model(Gurobi.Optimizer)
SCP = Model(HiGHS.Optimizer)


@variable(SCP, PurchasedBiomass[1:TP_biomass, 1:AG_biomass, 1: NB_periods]>=0)
@variable(SCP, BiomassForBioenergy[1:TP_biomass, 1:AG_biomass, 1: NB_periods]>=0)
@variable(SCP, BioeneregyFromBiomass[ 1: NB_periods]>=0)
@variable(SCP, BiomassForBiofuel[1:TP_biomass, 1:AG_biomass, 1: NB_periods]>=0)
@variable(SCP, BiofuelFromBiomass[1:NB_periods]>=0)
@variable(SCP, BiofuelForC[ 1: NB_periods]>=0)
@variable(SCP, BiofuelForBioenergy[ 1: NB_periods]>=0)
@variable(SCP, BioenergyFromBiofuel[ 1: NB_periods]>=0)
@variable(SCP, IFF[ 0: NB_periods]>=0)
@variable(SCP, IB[ 1:TP_biomass, 1:AG_biomass, 0: NB_periods]>=0)





for b in 1:TP_biomass, t in 1:NB_periods
    @constraint(SCP, sum(PurchasedBiomass[b,a,t] for a in 1:AG_biomass if a==1 ) <= Cap[b]* Yield[b,t]* HoursN[b,t])
end




for b in 1:TP_biomass, a in 1:AG_biomass , t in 1:NB_periods
    if a==1  
        @constraint(SCP,  PurchasedBiomass[b,a,t] == IB[b,a,t] + BiomassForBiofuel[b,a,t]+ BiomassForBioenergy[b,a,t])
    end      
end



for b in 1:TP_biomass, a in 2:AG_biomass , t in 1:NB_periods
    @constraint(SCP,  IB[b,a-1,t-1] == IB[b,a,t] + BiomassForBiofuel[b,a,t]+ BiomassForBioenergy[b,a,t])     
end


for b in 1:TP_biomass, a in 1:AG_biomass , t in 0:NB_periods
    if t==0  
        @constraint(SCP,  IB[b,a,t]==0 )
    end   
       
end




for t in 1:NB_periods
    @constraint(SCP, sum(AlfaBF[a,b]*BiomassForBiofuel[b,a,t] for b in 1:TP_biomass, a in 1:AG_biomass )== BiofuelFromBiomass[t])
end



for t in 1:NB_periods
    @constraint(SCP, sum(AlfaBE[a,b]*BiomassForBioenergy[b,a,t] for b in 4:TP_biomass, a in 1:AG_biomass )== BioeneregyFromBiomass[t])
end

#



for t in 1:NB_periods
    @constraint(SCP, IFF[t-1]+BiofuelFromBiomass[t]== IFF[t]+BiofuelForC[t]+BiofuelForBioenergy[t]) 
end

for t in 0:NB_periods
    if t==0
        @constraint(SCP, IFF[t] ==0) 
    end      
end


for t in 1:NB_periods
    @constraint(SCP, AlfaFE[]*BiofuelForBioenergy[t] == BioenergyFromBiofuel[t])
end


for t in 1:NB_periods
    @constraint(SCP, BiofuelForC[t] <= MaxDF[t])
end



for t in 1:NB_periods
    @constraint(SCP, BioenergyFromBiofuel[t]+BioeneregyFromBiomass[t] <= MaxDE[t])
end


for t in 1:NB_periods
    @objective(SCP, Max,  (BiofuelPrice[t]*BiofuelForC[t]+BioenergyPrice[]*(BioenergyFromBiofuel[t]+BioeneregyFromBiomass[t])
            -sum(CB[b,t]*PurchasedBiomass[b,a,t] for b in 1:TP_biomass, a in 1:AG_biomass if a==1 )
            -sum(CBF[b,t]*BiomassForBiofuel[b,a,t] for b in 1:TP_biomass, a in 1:AG_biomass )
            -sum(CBE[b,t]*BiomassForBioenergy[b,a,t] for b in 1:TP_biomass, a in 1:AG_biomass )
            -CFE[t]*BiofuelForBioenergy[t]
            -sum(HoldingB[b]*IB[b,a,t] for b in 1:TP_biomass, a in 1:AG_biomass )- HoldingF[]*IFF[t]) )
end
    
    


optimize!(SCP)
println("Optimal value: ", objective_value(SCP))





value.(PurchasedBiomass)

value.(IB)

value.(BiomassForBiofuel) 

value.(BiomassForBioenergy) 

value.(BiofuelFromBiomass)

value.(BioeneregyFromBiomass)

value.(BioenergyFromBiofuel)

value.(IFF)

value.(BiofuelForC)




