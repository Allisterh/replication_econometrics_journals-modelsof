/* Barjamovic-Chaney-Cosar-Hortacsu, QJE */
clear
capture log close _all

cd "/Users/ke.3747/Dropbox/Research/BCH_AssyrianTrade_local/BCCH_replication_package/figures_tables" // Change path to local, keeping at the end the extension 'BCCH_replication_package/figures_tables'
capture erase temp_main.dta
capture erase temp_main2.dta
/**************************************************************/
// ancient L*T^1/theta estimates
qui do "do_ancientTs.do"                     // Baseline
*qui do "do_ancientTs_Barjamovic_coordinates" // Use this to replicate Appendix Table V (Barjamovic coordinates instead of inverse gravity estimates, see line 210 below), together with corresponding changes in other do files (top of do_match_ancient_modern_cities and do_ancient_city_characteristics.do) 
save temp_main.dta,replace

// Matching of ancient sites with modern districts
qui do "do_match_ancient_modern_cities.do" 
merge 1:1 anccity using temp_main // all should merge!!
drop _merge
save temp_main.dta,replace

// Adding the geographic controls
qui do "do_ancient_city_characteristics.do"
merge 1:1 anccity using temp_main.dta
drop _merge
save temp_main.dta,replace
/**************************************************************/
// Prelims
// If an ancient city has no modern town within the set radius, winsorize its modern population to the smallest population in the dataset:
gsort -modernpop2
replace modernpop2 = modernpop2[_n-1] if modernpop2==. // winsorize at the smallest population level. robust to skipping this line and dropping the two cities without a modern town within the set radius

gsort -modernpop3
replace modernpop3 = modernpop3[_n-1] if modernpop3==. // winsorize at the smallest population level. robust to skipping this line and dropping the two cities without a modern town within the set radius

gen lnTa     = ln(T_anc)
gen lnpop1   = ln(modernpop1)  // Modern population levels generated by 3 different methods in do_ancient_city_characteristics_qje_1stRound.do
gen lnpop2   = ln(modernpop2) 
gen lnpop3   = ln(modernpop3) 
gen lnLight  = ln(lights)

qui reg  lnpop1 lnTa if anccity != "Purushaddum",robust // Corresponds to modern day Ankara, and thus a explicable outlier.
estimates store mPop1
qui reg  lnpop2 lnTa if anccity != "Purushaddum",robust
estimates store mPop2
qui reg  lnpop3 lnTa if anccity != "Purushaddum",robust
estimates store mPop3
qui reg lnLight lnTa if anccity != "Purushaddum", robust
estimates store mLight

// Report results
noi esttab mPop1 mPop2 mPop3 mLight, compress label width(1\hsize) noconstant p star(* 0.10 ** 0.05 *** 0.01) s(N r2)

// Choose the preferred measure for modern population match
gen lnPop   = lnpop2 // Baseline is method 2 (modernpop2): sum of urban populations of all towns within 30 kms
					 // method 1 (modernpop1): urban population of closest district town (Appendix Table V, Panel D)
                     // method 3 (modernpop3): largest modern Turkish district within the set radius (Appendix Table V, Panel C)

// Persistence summary: population and lights 
qui reg lnPop lnTa, robust
estimates store mPop
qui reg lnLight lnTa, robust
estimates store mLight

noi esttab mPop mLight, compress label width(1\hsize) noconstant p star(* 0.10 ** 0.05 *** 0.01) s(N r2)

drop lnpop*
save temp_main2,replace
/**************************************************************/
// Figure 11: Ancient and modern city sizes
* Population
qui reg  lnPop lnTa if anccity != "Purushaddum", robust
local coefpop : di %7.3f _b[lnTa]
local sepop : di %7.3f _se[lnTa]
local R2pop : di %7.3f e(r2)
   
twoway (scatter  lnPop lnTa if anccity != "Purushaddum",msymbol(circle_hollow) msize(large)) ///
     (lfit lnPop lnTa if anccity != "Purushaddum", lcolor(black)  ///
	 legend(row(3) order(- "Slope: `coefpop'" - "St.Err.:`sepop'" - "R-sq:   `R2pop'") size(3) ring(0) pos(11)) ///
	 plotregion(fcolor(white)) graphregion(fcolor(white)) ///
	 ytitle("ln(Modern City Population)", size(4) margin(0 4 0 0)) ///
	 xtitle("ln(Ancient City Size)", size(4) margin(0 4 0 0)) ///
	 ylabel(5(2)15) xlabel(-10(2)6))

graph export "figure11a_ancientTs_vs_modernPop.eps", as(eps) preview(off) replace
graph close

* Lights
use temp_main2,clear
	  
qui reg  lnLight lnTa if anccity != "Purushaddum", robust
local coefpop : di %7.3f _b[lnTa]
local sepop : di %7.3f _se[lnTa]
local R2pop : di %7.3f e(r2)

twoway (scatter  lnLight lnTa if anccity != "Purushaddum", msymbol(circle_hollow) msize(large)) ///
     (lfit lnLight lnTa if anccity != "Purushaddum", lcolor(black)  ///
	 legend(row(3) order(- "Slope: `coefpop'" - "St.Err.:`sepop'" - "R-sq:   `R2pop'") size(3) ring(0) pos(11)) ///
	 plotregion(fcolor(white)) graphregion(fcolor(white)) ///
	 ytitle("ln(Night Lights)", size(4) margin(0 4 0 0)) ///
	 xtitle("ln(Ancient City Size)", size(4) margin(0 4 0 0)) ///
	 ylabel(5(1)11) xlabel(-10(2)6))

graph export "figure11b_ancientTs_vs_lights.eps", as(eps) preview(off) replace
graph close

/****************************************************/
/* Figure 12: Ranking of city sizes and Zipf's law */
use temp_main,clear

// Transformation using the persistence estimation coefficient (table 5, column 1), fitted relative ancient population estimate.
gen lnPopAnc   = 0.23 * ln(T_anc) // 0.23 is the estimate from the regression above (qui reg  lnPop lnTa, robust), which 

gsort -lnPopAnc
gen rank = _n
gen lnrank = ln(rank - 1/2)

drop rank T_anc

* Population
reg lnrank lnPopAnc, robust
local coefpop : di %7.3f _b[lnPopAnc]
local sepop : di %7.3f _se[lnPopAnc]
local R2pop : di %7.3f e(r2)
   
twoway (scatter  lnrank lnPopAnc,msymbol(circle_hollow) msize(large)) ///
     (lfit lnrank lnPopAnc, lcolor(black)  ///
	 legend(row(3) order(- "Slope: `coefpop'" - "St.Err.:`sepop'" - "R-sq:   `R2pop'") size(3) ring(0) pos(1)) ///
	 plotregion(fcolor(white)) graphregion(fcolor(white)) ///
	 ytitle("ln(Rank-1/2)", size(4) margin(0 4 0 0)) ///
	 xtitle("ln(Population)", size(4) margin(0 4 0 0)) ///
	 ylabel(-1(0.5)3.5) xlabel(-2(0.5)1.5))

graph export "figure12_zipf.eps", as(eps) preview(off) replace
graph close

/************************/
// Geographic controls
use temp_main2,clear

gen lnRugged     = ln(TRI)
gen lnCrop       = ln(cropsuit)
gen lnRomanRoad  = ln(DFcrossings1)  // Roman roads, measure 1 and 2, robust to using measure 2 (DFcrossings1). See data prep file do_ancient_city_characteristics.do
gen lnRoadw      = ln(wcrossings) // natural road scores

save temp_main, replace

/****************/
/* Regressions  */
/****************/
qui{
*keep if validity == 1 | anccity == "Mamma" // for known cities only, includes Mamma (Appendix Table V, Panel B)

// Table IV: determinants of ancient size
qui reg  lnTa  lnRoadw, robust 
estimates store m1
qui reg  lnTa  lnRomanRoad, robust
estimates store m2
qui reg  lnTa  lnRugged, robust 
estimates store m3
qui reg  lnTa  lnRoadw lnRugged, robust 
estimates store m4
qui reg  lnTa  lnRomanRoad lnRugged, robust 
estimates store m5

label var lnRugged "\$\log\left(Ruggedness\right)\$" 
label var lnRoadw "\$\log\left(Natural Roads\right)\$" 
label var lnRomanRoad "\$\log\left(Roman Roads\right)\$" 

noi esttab m1 m2 m3 m4 m5, compress noconstant  p starlevels(* 0.10 ** 0.05 *** 0.01)  stats(N r2,fmt(%9.0g %9.3f))

* Save to .tex file
estout m1 m2 m3 m4 m5 ///
  using "TableIV_determinants.tex", replace style(tex) ///
  keep(lnRoadw lnRomanRoad lnRugged) order(lnRoadw lnRomanRoad lnRugged) ///
  ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) p(par)) ///
  stats(N r2,fmt(%9.0g %9.3f) labels("\hline \$N\$" "\$R^2\$")) ///
  starlevels(* 0.10 ** 0.05 *** 0.01) label 

// Table V: Persistence of Economic Activity across 4000 Year
qui reg  lnPop lnTa if anccity != "Purushaddum", robust
estimates store m1
qui reg  lnPop   lnCrop if anccity != "Purushaddum", robust 
estimates store m2
qui reg  lnPop  lnTa lnCrop if anccity != "Purushaddum", robust 
estimates store m3
qui reg  lnLight lnTa if anccity != "Purushaddum", robust
estimates store m4
qui reg  lnLight   lnCrop if anccity != "Purushaddum", robust 
estimates store m5
qui reg  lnLight  lnTa lnCrop if anccity != "Purushaddum", robust 
estimates store m6
/*
// Appendix Table V: Persistence of Economic Activity across 4000 Year using Barjamovic (2011) locations. Purushaddum is not predicted to be near Ankara by Barjamovic.
qui reg  lnPop lnTa, robust
estimates store m1
qui reg  lnPop   lnCrop, robust 
estimates store m2
qui reg  lnPop  lnTa lnCrop, robust 
estimates store m3
qui reg  lnLight lnTa, robust
estimates store m4
qui reg  lnLight   lnCrop , robust 
estimates store m5
qui reg  lnLight  lnTa lnCrop, robust 
estimates store m6
*/
label var lnTa "\$\log\left(Pop T^{1/\theta}|_{ancient} \right)\$" 
label var lnCrop "\$\log\left( (Crop Yield \right)\$" 

noi esttab m1 m2 m3 m4 m5 m6, compress noconstant  p starlevels(* 0.10 ** 0.05 *** 0.01)  stats(N r2,fmt(%9.0g %9.3f))

* Save to .tex file
estout m1 m2 m3 m4 m5 m6 ///
  using "TableV_persistence.tex", replace style(tex) ///
  keep(lnTa lnCrop) order(lnTa lnCrop) ///
  ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) p(par)) ///
  stats(N r2,fmt(%9.0g %9.3f) labels("\hline \$N\$" "\$R^2\$")) ///
  starlevels(* 0.10 ** 0.05 *** 0.01) label 

}

/***/
erase temp_main.dta
erase temp_main2.dta
capture erase exportmention.dta
capture erase importmention.dta
/***/



