***Table 4 District-level Turnout Analysis (All States)***
reg turnout2 tlness challenged lcr2 mmd regd straight iuse2 squire ranney income2 diversity3 preselec redistrict year, cluster(id)
***Calculating p-values from one tailed signifance tests for directional hypotheses***
test _b[tlness]=0
local sign_tlness = sign(_b[tlness])
display "one-tailed p-value = " ttail(r(df_r),`sign_tlness'*sqrt(r(F)))
test _b[challenged]=0
local sign_challenged = sign(_b[challenged])
display "one-tailed p-value = " ttail(r(df_r),`sign_challenged'*sqrt(r(F)))
test _b[lcr2]=0
local sign_lcr2 = sign(_b[lcr2])
display "one-tailed p-value = " ttail(r(df_r),`sign_lcr2'*sqrt(r(F)))
test _b[mmd]=0
local sign_mmd = sign(_b[mmd])
display "one-tailed p-value = " 1-ttail(r(df_r),`sign_mmd'*sqrt(r(F)))
test _b[regd]=0
local sign_regd = sign(_b[regd])
display "one-tailed p-value = " 1-ttail(r(df_r),`sign_regd'*sqrt(r(F)))
test _b[straight]=0
local sign_straight = sign(_b[straight])
display "one-tailed p-value = " ttail(r(df_r),`sign_straight'*sqrt(r(F)))
test _b[iuse2]=0
local sign_iuse2 = sign(_b[iuse2])
display "one-tailed p-value = " ttail(r(df_r),`sign_iuse2'*sqrt(r(F)))
test _b[squire]=0
local sign_squire = sign(_b[squire])
display "one-tailed p-value = " ttail(r(df_r),`sign_squire'*sqrt(r(F)))
test _b[ranney]=0
local sign_ranney = sign(_b[ranney])
display "one-tailed p-value = " ttail(r(df_r),`sign_ranney'*sqrt(r(F)))
test _b[income2]=0
local sign_income2 = sign(_b[income2])
display "one-tailed p-value = " ttail(r(df_r),`sign_income2'*sqrt(r(F)))
test _b[diversity3]=0
local sign_diversity3 = sign(_b[diversity3])
display "one-tailed p-value = " 1-ttail(r(df_r),`sign_diversity3'*sqrt(r(F)))
test _b[preselec]=0
local sign_preselec = sign(_b[preselec])
display "one-tailed p-value = " ttail(r(df_r),`sign_preselec'*sqrt(r(F)))
test _b[redistrict]=0
local sign_redistrict = sign(_b[redistrict])
display "one-tailed p-value = " ttail(r(df_r),`sign_redistrict'*sqrt(r(F)))
***Table 4 District-level Turnout Analysis (TL States)***
reg turnout2 tlness challenged lcr2 mmd regd straight iuse2 squire ranney income2 diversity3 preselec redistrict year if tlstate==1, cluster(id)
***Calculating p-values from one tailed signifance tests for directional hypotheses***
test _b[tlness]=0
local sign_tlness = sign(_b[tlness])
display "one-tailed p-value = " ttail(r(df_r),`sign_tlness'*sqrt(r(F)))
test _b[challenged]=0
local sign_challenged = sign(_b[challenged])
display "one-tailed p-value = " ttail(r(df_r),`sign_challenged'*sqrt(r(F)))
test _b[lcr2]=0
local sign_lcr2 = sign(_b[lcr2])
display "one-tailed p-value = " ttail(r(df_r),`sign_lcr2'*sqrt(r(F)))
test _b[mmd]=0
local sign_mmd = sign(_b[mmd])
display "one-tailed p-value = " 1-ttail(r(df_r),`sign_mmd'*sqrt(r(F)))
test _b[regd]=0
local sign_regd = sign(_b[regd])
display "one-tailed p-value = " 1-ttail(r(df_r),`sign_regd'*sqrt(r(F)))
test _b[straight]=0
local sign_straight = sign(_b[straight])
display "one-tailed p-value = " ttail(r(df_r),`sign_straight'*sqrt(r(F)))
test _b[iuse2]=0
local sign_iuse2 = sign(_b[iuse2])
display "one-tailed p-value = " ttail(r(df_r),`sign_iuse2'*sqrt(r(F)))
test _b[squire]=0
local sign_squire = sign(_b[squire])
display "one-tailed p-value = " ttail(r(df_r),`sign_squire'*sqrt(r(F)))
test _b[ranney]=0
local sign_ranney = sign(_b[ranney])
display "one-tailed p-value = " ttail(r(df_r),`sign_ranney'*sqrt(r(F)))
test _b[income2]=0
local sign_income2 = sign(_b[income2])
display "one-tailed p-value = " ttail(r(df_r),`sign_income2'*sqrt(r(F)))
test _b[diversity3]=0
local sign_diversity3 = sign(_b[diversity3])
display "one-tailed p-value = " 1-ttail(r(df_r),`sign_diversity3'*sqrt(r(F)))
test _b[preselec]=0
local sign_preselec = sign(_b[preselec])
display "one-tailed p-value = " ttail(r(df_r),`sign_preselec'*sqrt(r(F)))
test _b[redistrict]=0
local sign_redistrict = sign(_b[redistrict])
display "one-tailed p-value = " ttail(r(df_r),`sign_redistrict'*sqrt(r(F)))
