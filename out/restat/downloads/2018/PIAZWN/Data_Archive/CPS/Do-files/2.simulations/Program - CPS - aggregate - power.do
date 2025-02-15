********************************************************************************
**Using the data generated by the program "Generate dataset.do", this code 
**produces the results used to construc some graphs in figure 4.
********************************************************************************
clear *
set mem 2000m
********************************************************************************
prog define Simulation, rclass
args Y Range B power
 {
 
set more off
set matsize 5000
clear *

set seed 1


cap cd "XXXX define path to folders XXXX/CPS/"

use "Final Dataset/CPS.dta", clear

merge m:1 state year using "Final Dataset/M_bin.dta"

egen S=group(state) 

keep if `Y'!=.

egen P_jt=sum(weight), by(S year)  

gen omega2=weight^2



collapse  (mean)  employed l_wage  M_bin* P_jt (rawsum) omega2 [pw= weight], by(S year)


mat R=J(5000,15,.)


local row=1

forvalues s=1(1)51 {

	local end=2015-`Range'

	forvalues year=1979(1)`end' {

	preserve

	* Keep only range+1 years
	keep if inrange(year,`year',`year'+`Range')

	* Generate DID dummy
	gen T=year>=`year'+`Range'/2
	gen D=(S==`s')
	gen DD=(S==`s' & T==1)
	
	replace M_bin2=. if year!=`year'
		
	mat R[`row',8]=`year'
	mat R[`row',9]=`s'


	* Create treatment effect
	replace `Y' = `Y'+`power'/100 if DD==1


	* Generate residuals with H_0 imposed
	
	areg `Y' i.year [pw=P_jt], ab(S) 
	predict eta_jt, residual

	areg `Y' DD i.year [pw=P_jt], ab(S) 
	mat R[`row',1]=_b[DD]

	* Define parameters to estimate linear combination Wj. This will be based on the linear combination of the treated unit.

	egen P_post=sum(P_jt) if D==1&T==1 	
	egen P_pre=sum(P_jt) if D==1&T==0

	gen temp=(P_jt/P_post) if D==1&T==1 
	replace temp=(P_jt/P_pre) if D==1&T==0

	egen a_1t=mean(temp), by(year)
	drop temp P_post P_pre

	* This variable will generate the linear combination Wj when we summ it for each j
	gen W=a_1t*eta_jt  if T==1
	replace W=-a_1t*eta_jt  if T==0

	* Generates the variable to estimate the var(W|M) function.
	gen q=(a_1t^2)*omega2/(P_jt)^2


	collapse (mean) D M_bin* (sum) W q P_jt, by(S)
	
	summ W [aw=P_jt], detail
	local mean=r(mean)
	
	gen W2 = (W-`mean')^2
		
	reg W2 q [pw=P_jt] 
	predict var_M
	
	mat R[`row',10]=_b[q]
	mat R[`row',11]=_b[_cons]

	summ var_M 
	local min=r(min)

	gen test=var_M<0
	summ test
	mat R[`row',12]=r(mean)	

	summ test if D==1
	mat R[`row',13]=r(mean)	

	replace var_M=1 if `min'<0 & R[`s',10]<0
	replace var_M=q if `min'<0 & R[`s',11]<0
	
	gen W_normalized = W/sqrt(var_M)


	summ W if D==1
	local  treated=r(mean)
	
	summ W if D==0 [aw=P_jt]
	local control=r(mean)


	* Keep information on M
	
	
	summ M_bin2 if S==`s'
	mat R[`row',6]=r(mean)	
	
	*summ M_bin10 if S==`s' 
	*mat R[`row',7]=r(mean)	



	mat B=J(`B',3,.)
	
	summ S
	local N=r(N)

	
	* Run bootstrap with and without correction
	forvalues Round=1(1)`B' {     

	qui {
		gen h1=uniform()  
		gen h2=1 + int((`N'-1+1)*h1)

		gen W_tilde = W[h2] 
			
		
		gen W_tilde_corrected = W_normalized[h2] * sqrt(var_M) 	
		
			

		summ W_tilde if D==1
		local  treated=r(mean)
	
		summ W_tilde if D==0 [aw=P_jt]
		local control=r(mean)

		mat B[`Round',1]=`treated' - `control'
		
		
		summ W_tilde_corrected if D==1
		local treated=r(mean)
	
		summ W_tilde_corrected if D==0 [aw=P_jt]
		local control=r(mean)
		
		mat B[`Round',2]=`treated' - `control'


		drop h1 h2 *tilde* 
	}
	
	}


	set more off
	clear 
	svmat B
	
	** Without correction
		
	gen p_without=B1^2>R[`row',1]^2  if B1!=.  & R[`row',1]!=.


	summ p_without
	mat R[`row',2] = r(mean)

	
	** Correction, unknown variance
		
	gen p_FP=B2^2>R[`row',1]^2 if B2!=. & R[`row',1]!=.

	summ p_FP
	mat R[`row',3] = r(mean)


	*
	*
	display `s'
	display `s'
	*
	*
	
	local ++row
	
	restore
	
	}
	
}

set more off	
clear
svmat R

ren R2 p_without
ren R3 p_FP
ren R1 alpha_hat

foreach x in 5 {  // Generate rejection rates

	gen reject_without_`x' = p_without<=`x'/100 if p_without!=.
	gen reject_FP_`x' = p_FP<=`x'/100 if p_FP!=.

		
}

ren R6 M_bin2
ren R8 year
ren R9 S
ren R10 B
ren R11 A
gen above=M_bin2==2 if M_bin2!=.
gen below=1-above if M_bin2!=.

gen Y="`Y'"

summ rej*

gen Range=`Range'

gen Power=`power'

saveold "Results/Power/CPS_Bootstrap_`Y'_`Range'_`power'_`B'.dta", replace


}
end
****************************



foreach Range in 1 3 5 7  {

forvalues power=0(1)30  {

Simulation l_wage `Range' 500 `power'

}
}
