global cluster = "clustercode"

*Controls from the fall 2007 survey;
global f07_child_controls "f07_heads_child_cnt f07_girl_cnt f07_age_cnt"
global f07_hh_controls "f07_duration_village_cnt f07_farsi_cnt f07_tajik_cnt f07_farmer_cnt f07_age_head_cnt f07_yrs_ed_head_cnt f07_num_ppl_hh_cnt f07_jeribs_cnt f07_num_sheep_cnt f07_nearest_scl" 
global f07_hh_controls_nodist "f07_duration_village_cnt f07_farsi_cnt f07_tajik_cnt f07_farmer_cnt f07_age_head_cnt f07_yrs_ed_head_cnt f07_num_ppl_hh_cnt f07_jeribs_cnt f07_num_sheep_cnt" 
*Controls from the spring 2008 survey;
global s08_child_controls "s08_heads_child_cnt s08_girls_cnt s08_age_cnt"
global s08_hh_controls "s08_duration_village_cnt s08_farsi_cnt s08_tajik_cnt s08_farmer_cnt s08_age_head_cnt s08_yrs_ed_head_cnt s08_num_ppl_hh_cnt s08_jeribs_cnt s08_num_sheep_cnt s08_nearest_scl" 
global s08_hh_controls_nodist "s08_duration_village_cnt s08_farsi_cnt s08_tajik_cnt s08_farmer_cnt s08_age_head_cnt s08_yrs_ed_head_cnt s08_num_ppl_hh_cnt s08_jeribs_cnt s08_num_sheep_cnt" 

*My code: some controls always dropped, so remove them from the globals
global f07_child_controls2 "f07_heads_child_cnt f07_age_cnt"
global s08_child_controls2 "s08_heads_child_cnt s08_age_cnt"

use DatBL, clear

global i = 1
global j = 1

*Table 4
mycmd (treatment) reg f07_formal_school treatment chagcharan if nonoutlier == 1 & f07_observed == 1 & f07_girl_cnt == 1, cluster(clustercode)
mycmd (treatment) reg f07_formal_school treatment $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_observed == 1 & f07_girl_cnt == 1, cluster(clustercode)
mycmd (treatment) reg f07_both_norma_total treatment chagcharan if nonoutlier == 1 & f07_test_observed == 1 & f07_girl_cnt == 1, cluster(clustercode)
mycmd (treatment) reg f07_both_norma_total treatment $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_test_observed == 1 & f07_girl_cnt == 1, cluster(clustercode)
mycmd (treatment) reg s08_both_norma_total treatment chagcharan if nonoutlier == 1 & s08_test_observed == 1 & s08_girls_cnt == 1, cluster(clustercode)
mycmd (treatment) reg s08_both_norma_total treatment $s08_child_controls2 $s08_hh_controls chagcharan if nonoutlier == 1 & s08_test_observed == 1 & s08_girls_cnt == 1, cluster(clustercode)
mycmd (treatment) reg f07_formal_school treatment chagcharan if nonoutlier == 1 & f07_observed == 1 & f07_girl_cnt == 0, cluster(clustercode)
mycmd (treatment) reg f07_formal_school treatment $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_observed == 1 & f07_girl_cnt == 0, cluster(clustercode)
mycmd (treatment) reg f07_both_norma_total treatment chagcharan if nonoutlier == 1 & f07_test_observed == 1 & f07_girl_cnt == 0, cluster(clustercode)
mycmd (treatment) reg f07_both_norma_total treatment $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_test_observed == 1 & f07_girl_cnt == 0, cluster(clustercode)
mycmd (treatment) reg s08_both_norma_total treatment chagcharan if nonoutlier == 1 & s08_test_observed == 1 & s08_girls_cnt == 0, cluster(clustercode)
mycmd (treatment) reg s08_both_norma_total treatment $s08_child_controls2 $s08_hh_controls chagcharan if nonoutlier == 1 & s08_test_observed == 1 & s08_girls_cnt == 0, cluster(clustercode)

*Table 5 
mycmd (treatment f07_treat_age)reg f07_formal_school treatment f07_treat_age $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_observed == 1 & f07_girl_cnt == 1, cluster(clustercode)
mycmd (treatment f07_treat_age) reg f07_formal_school treatment f07_treat_age $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_observed == 1 & f07_girl_cnt == 0, cluster(clustercode)
mycmd (treatment f07_treat_age) reg f07_both_norma_total treatment f07_treat_age $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_test_observed == 1 & f07_girl_cnt == 1, cluster(clustercode)
mycmd (treatment f07_treat_age) reg f07_both_norma_total treatment f07_treat_age $f07_child_controls2 $f07_hh_controls chagcharan if nonoutlier == 1 & f07_test_observed == 1 & f07_girl_cnt == 0, cluster(clustercode)

