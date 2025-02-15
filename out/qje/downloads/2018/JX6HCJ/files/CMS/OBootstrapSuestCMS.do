*Run in Stata 13 to get scores for xtmixed
*randomizing at treatment level because this is only way to construct consistent suest for all commands in a given table

****************************************
****************************************

capture program drop mycmd
program define mycmd
	syntax anything [if] [in] [, robust]
	tempvar touse e S
	gettoken testvars anything: anything, match(match)
	gettoken cmd anything: anything
	gettoken dep anything: anything
	unab anything: `anything'
	global k = wordcount("`testvars'")
	quietly `cmd' `dep' `anything' `if' `in', 
	quietly gen `touse' = e(sample)
	matrix b = e(b)
	global kk = colsof(b)
	quietly predict double `e' if `touse', resid
	matrix grad = J($ncluster,$kk,.)
	local anything = "`anything'" + " " + "constant"
	local i = 1
	foreach var in `anything' {
		quietly egen double `S' = sum(`e'*`var'), by($cluster)
		mkmat `S' if nn == 1, matrix(g)
		matrix grad[1,`i'] = g 
		local i = `i' + 1
		capture drop `S'
		}
	mkmat `anything' if `touse', matrix(X)
	matrix v = invsym(X'*X)

	mata b = st_matrix("b"); v = st_matrix("v"); grad = st_matrix("grad"); select = J(1,$kk,0); select[1,1..$k] = J(1,$k,1)
	if ($i == 1) {
		mata B = b; G = v*grad'; Select = select; dc = J(1,$ncluster,1)*grad; DC = dc*dc'
		}
	else {
		mata B = B, b; G = G \ (v*grad'); Select = Select, select; dc = J(1,$ncluster,1)*grad; DC = DC + dc*dc'
		}
global i = $i + 1
end

****************************************
****************************************

capture program drop mycmd1
program define mycmd1
	syntax anything [if] [in] [, re mle]
	tempvar touse xb e S1 S2 S3 S4 sum ssum Ti b c n
	gettoken testvars anything: anything, match(match)
	gettoken cmd anything: anything
	gettoken dep anything: anything
	unab anything: `anything'
	global k = wordcount("`testvars'")
	capture `cmd' `dep' `anything' `if' `in', `re' `mle'
	matrix b = e(b)
	if (_rc == 0 & colsof(b) == wordcount("`anything'") + 3) {
	gen `touse' = e(sample)
	bysort $cluster `touse' $panelvar: gen `n' = _n
	quietly egen `Ti' = count(`n') if `touse', by($panelvar)
	matrix v = e(V)
	global kk = colsof(b)
	global a = 1/(b[1,$kk]^2)
	quietly gen double `b' = (b[1,$kk-1]^2)/(`Ti'*b[1,$kk-1]^2+b[1,$kk]^2) if `touse'
	quietly gen double `c' = 1/(`Ti'*b[1,$kk-1]^2+b[1,$kk]^2) if `touse'
	quietly predict double `xb' if `touse', xb
	quietly gen double `e' = `dep' - `xb' if `touse'
	matrix grad = J($ncluster,$kk,.)
	local anything = "`anything'" + " " + "constant"
	local i = 1
	quietly egen double `S1' = sum(`e') if `touse', by($panelvar)
	quietly egen double `S4' = sum(`e'*`e') if  `touse', by($panelvar)
	foreach var in `anything' {
		quietly egen double `S2' = sum(`e'*`var') if `touse', by($panelvar)
		quietly egen double `S3' = sum(`var') if `touse', by($panelvar)
		quietly gen double `sum' = $a*(`S2' -`b'*`S1'*`S3') if `n' == 1 & `touse' == 1
		quietly replace `sum' = 0 if `touse' == 0 & `n' == 1
		quietly egen double `ssum' = sum(`sum'), by($cluster)
		mkmat `ssum' if nn == 1, matrix(g)
		matrix grad[1,`i'] = g 
		local i = `i' + 1
		capture drop `S2' `S3' `sum' `ssum'
		}
	quietly gen double `sum' = (`b'/b[1,$kk-1])*(`S1'*`S1'*`b'/(b[1,$kk-1]^2) - `Ti') if `n' == 1 & `touse' == 1
	quietly replace `sum' = 0 if `touse' == 0 & `n' == 1
	quietly egen double `ssum' = sum(`sum'), by($cluster)
	mkmat `ssum' if nn == 1, matrix(g)
	matrix grad[1,`i'] = g 
	local i = `i' + 1
	capture drop `sum' `ssum'

	quietly gen double `sum' = -(`Ti'-1)/b[1,$kk] - `c'*b[1,$kk] - `b'*`c'*`S1'*`S1'/b[1,$kk]+(`S4'-`b'*`S1'*`S1')/(b[1,$kk]^3) if `n' == 1 & `touse' == 1
	quietly replace `sum' = 0 if `touse' == 0 & `n' == 1
	quietly egen double `ssum' = sum(`sum'), by($cluster)
	mkmat `ssum' if nn == 1, matrix(g)
	matrix grad[1,`i'] = g 
	local i = `i' + 1
	capture drop `sum' `ssum'

	mata b = st_matrix("b"); v = st_matrix("v"); grad = st_matrix("grad"); select = J(1,$kk,0); select[1,1..$k] = J(1,$k,1)
	if ($i == 1) {
		mata B = b; G = v*grad'; Select = select; dc = J(1,$ncluster,1)*grad; DC = dc*dc'
		}
	else {
		mata B = B, b; G = G \ (v*grad'); Select = Select, select; dc = J(1,$ncluster,1)*grad; DC = DC + dc*dc'
		}
	global i = $i + 1
	}
	else {
		scalar t = scalar(t) + _rc + 5
	}
end

****************************************
****************************************

capture program drop mycmd2
program define mycmd2
	syntax anything [if] [in] [, iterate(string)]
	gettoken testvars anything: anything, match(match)
	gettoken cmd anything: anything
	gettoken dep anything: anything
	global k = wordcount("`testvars'")
	capture `cmd' `dep' `anything' `if' `in', iterate(`iterate')
	scalar t = scalar(t) + _rc
	if (_rc == 0) { 
	matrix v = e(V)
	matrix b = e(b)
	global kk = colsof(b)
	capture drop scores*
	quietly predict double scores1-scores23, scores
	mkmat scores1-scores23 if scores1 ~=., matrix(grad)
	mata b = st_matrix("b"); v = st_matrix("v"); grad = st_matrix("grad"); select = J(1,$kk,0); select[1,1..$k] = J(1,$k,1)
	if ($i == 1) {
		mata B = b; G = v*grad'; Select = select; dc = J(1,$ncluster,1)*grad; DC = dc*dc'
		}
	else {
		mata B = B, b; G = G \ (v*grad'); Select = Select, select; dc = J(1,$ncluster,1)*grad; DC = DC + dc*dc'
		}
	global i = $i + 1
	}
end

****************************************
****************************************

use DatCMS1, clear
generate constant = 1
rename session_id session
xtset session
global ncluster = 28
global cluster = "session"
bysort $cluster: gen nn = _n
global panelvar = "session"

*Table 2
global i = 1
scalar t = 0
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage, robust
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage male international_student risk_taker, robust
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage male international_student risk_taker expect_teammates_correctly_repor, robust
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage male international_student risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, robust
mycmd1 (tournament tournament_sabotage) xtreg qual_adj_output tournament tournament_sabotage male international_student risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, mle

mata gg = select(G,Select'); bb = select(B,Select); v = ($ncluster/($ncluster-1))*gg*gg'; v = invsym(v); test =  bb*v*bb',sum(rowsum(abs(v)):>0)
mata test = chi2tail(test[1,2],test[1,1]), cols(bb)-test[1,2], test[1,2], test[1,1], 2 ; st_matrix("test",test); st_matrix("dc",DC); b2 = bb
matrix F = test
matrix DC = dc

gen Order = _n
sort session Order
gen N = 1
gen Dif = (session ~= session[_n-1])
replace N = N[_n-1] + Dif if _n > 1
save aa, replace

drop if N == N[_n-1]
egen NN = max(N)
keep NN
generate obs = _n
save aaa, replace

mata ResF = J($reps,5,.); ResDC = J($reps,1,.)
forvalues c = 1/$reps {
	display "`c'"
	set seed `c'

	use aaa, clear
	quietly generate N = ceil(uniform()*NN)
	joinby N using aa
	drop session
	rename obs session

xtset session
sort session nn

*Table 2
global i = 1
scalar t = 0
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage, robust
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage male international_student risk_taker, robust
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage male international_student risk_taker expect_teammates_correctly_repor, robust
mycmd (tournament tournament_sabotage) reg qual_adj_output tournament tournament_sabotage male international_student risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, robust
mycmd1 (tournament tournament_sabotage) xtreg qual_adj_output tournament tournament_sabotage male international_student risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, mle

if (scalar(t) == 0) {
mata gg = select(G,Select'); bb = select(B,Select); v = ($ncluster/($ncluster-1))*gg*gg'; v = invsym(v); test =  (bb-b2)*v*(bb-b2)',sum(rowsum(abs(v)):>0)
mata test = chi2tail(test[1,2],test[1,1]), cols(bb)-test[1,2], test[1,2], test[1,1], 2 
mata ResF[`c',1..5] = test; ResDC[`c',1] = DC
}

}

drop _all
set obs $reps
forvalues i = 1/5 {
	quietly generate double ResF`i' = .
	}
quietly generate double ResDC1 = .
mata st_store(.,.,(ResF, ResDC))
svmat double F
svmat double DC
gen N = _n
sort N
save ip\OBootstrapSuestCMS1, replace

********************************************

use DatCMS2, clear
generate constant = 1

rename international_student ins
rename tournament_sabotage tsabot

global ncluster = 28
global cluster = "session"
bysort $cluster : gen nn = _n
global panelvar = "id_number"

*Table 3
global i = 1
scalar t = 0
mycmd1 (tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts) xtreg output_sabotage tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts diff_output pos_diff male ins risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, mle
*mycmd (tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts) xtmixed output_sabotage tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts pos_diff diff_output male ins risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know || session: || id_number:, iterate(20)
mycmd1 (tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts) xtreg quality_sabotage tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts diff_output pos_diff male ins risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, mle
mycmd2 (tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts) xtmixed quality_sabotage tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts diff_output pos_diff male ins risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know || session: || id_number:, iterate(20)
	
mata gg = select(G,Select'); bb = select(B,Select); v = ($ncluster/($ncluster-1))*gg*gg'; v = invsym(v); test =  bb*v*bb',sum(rowsum(abs(v)):>0)
mata test = chi2tail(test[1,2],test[1,1]), cols(bb)-test[1,2], test[1,2], test[1,1], 3 ; st_matrix("test",test); st_matrix("dc",DC); b3 = bb
matrix F = F \ test
matrix DC = DC \ dc
	
gen Order = _n
sort session Order
gen N = 1
gen Dif = (session ~= session[_n-1])
replace N = N[_n-1] + Dif if _n > 1
save bb, replace

mata ResF = J($reps,5,.); ResDC = J($reps,1,.)
forvalues c = 1/$reps {
	display "`c'"
	set seed `c'

	use aaa, clear
	quietly generate N = ceil(uniform()*NN)
	joinby N using bb
	drop session
	rename obs session

	egen newid = group(session id_number)
	replace id_number = newid
	drop newid

xtset id_number
sort session nn

*Table 3
global i = 1
scalar t = 0
mycmd1 (tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts) xtreg output_sabotage tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts diff_output pos_diff male ins risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, mle
mycmd1 (tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts) xtreg quality_sabotage tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts diff_output pos_diff male ins risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know, mle
mycmd2 (tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts) xtmixed quality_sabotage tournament tsabot diff_out_t diff_out_ts pos_diff_t pos_diff_ts diff_output pos_diff male ins risk_taker expect_teammates_correctly_repor gpa first_born num_siblings bathrooms_in_house car_on_campus work num_participants_know || session: || id_number:, iterate(20)

if (scalar(t) == 0) {	
mata gg = select(G,Select'); bb = select(B,Select); v = ($ncluster/($ncluster-1))*gg*gg'; v = invsym(v); test =  (bb-b3)*v*(bb-b3)',sum(rowsum(abs(v)):>0)
mata test = chi2tail(test[1,2],test[1,1]), cols(bb)-test[1,2], test[1,2], test[1,1], 3 ; st_matrix("test",test); st_matrix("dc",DC)
mata ResF[`c',1..5] = test; ResDC[`c',1] = DC
}
}

drop _all
set obs $reps
forvalues i = 6/10 {
	quietly generate double ResF`i' = .
	}
quietly generate double ResDC2 = .
mata st_store(.,.,(ResF, ResDC))
svmat double F
svmat double DC
gen N = _n
sort N
save ip\OBootstrapSuestCMS2, replace

*****************************************
*****************************************

use ip\OBootstrapSuestCMS1, clear
merge N using ip\OBootstrapSuestCMS2
drop _m 
sort N
drop F* DC*
svmat double F
svmat double DC
aorder
save results\OBootstrapSuestCMS, replace

erase aa.dta
erase bb.dta
erase aaa.dta




