
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Robustness Check - Placebo Test
*Country: Ecuador
*==============================================================================*

*--------------------------------------------
* Placebo Test
*--------------------------------------------

clear all
set more off, perm

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Results\Placebo Test"
// global datadir "$dir\Data\SBP_data\annual"
// global dir "C:\Users\dz136\Box\Socio Bosque"
global dir "G:\My Drive\socio bosque"
cd "$dir\Results\Robustness Check\Placebo Test"
global datadir "$dir\data"

global control_groups			"never"
global control_groups_labels	`""Never-treated""'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'
global resolutions				"300 300"

global policy_bundles			`""sb" "sb+pa" "sb+it" "sb+pa+it""'
global policy_bundles_labels	`""SB only" "SB + PA" "SB + IT" "SB + PA + IT""'
global pbs						`""s" "sp" "si" "sip""'

global panels1 "a b c d"
global panels2 "A B"

local i 1
foreach depvar of global depvars {
	local depvar_label: word `i' of ${depvars_labels}
	
	local j 1
	foreach cgroup of global control_groups {
		local cgroup_label: word `j' of ${control_groups_labels}
			
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				
				di "Estimating: `ttype_label' | `depvar_label' | `cgroup_label' | `policy_bundle_label'"
				if "`ttype'" == "ind" & "`policy_bundle'" == "pa & indigenous" {
					di in red "No treated units. Skipping."
					restore
					exit
				}
			
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
				xtset panel_id year
				
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				
				**# TWFE: reghdfe
				reghdfe `depvar' post [fweight = _weight], absorb(pointid cantonid#year) vce(cluster cantonid)
				estimates store reghdfe_`ttype'_`cgroup'_cv_`i'
					
					* In-time placebo test with fake treatment time shifted back by 1-10 periods
					didplacebo reghdfe_`ttype'_`cgroup'_cv_`i', treatvar(post) pbotime(1(1)10) seed(1)
					graph save "reghdfe_pbotime_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace
					* In-space placebo test
					didplacebo reghdfe_`ttype'_`cgroup'_cv_`i', treatvar(post) pbounit seed(1)
					graph save "reghdfe_pbounit_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace
					* Free (unrestricted) version of mixed placebo test
					didplacebo reghdfe_`ttype'_`cgroup'_cv_`i', treatvar(post) pbotime(1(1)10) pbounit pbomix(2) seed(1)
					graph save "reghdfe_pbomix_unrestricted_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace
					* Restricted version of mixed placebo test
					didplacebo reghdfe_`ttype'_`cgroup'_cv_`i', treatvar(post) pbotime(1(1)10) pbounit pbomix(3) seed(1)
					graph save "reghdfe_pbomix_restricted_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace
					
/*
				**# did_imputation (Borusyak et al., 2021)
				did_imputation `depvar' $cv, i(pointid) t(year) g(first_treat) cluster(cantonid) `= cond("`cgroup'"=="notyet", "notyet", "")'
				estimates store didimp_`ttype'_`cgroup'_cv_`i'
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				display $tr_eff_`ttype'_`cgroup'_cv_`i'

				** In-Time Placebo test
				global K = 10
				matrix att_b = J(1, $K, 0)
				matrix att_V = J($K, $K, 0)

				forvalues i = 1(1)$K {
					cap drop first_treat_new
					qui gen first_treat_new = first_treat - `i'
					qui did_imputation `depvar' $cv if year < first_treat_new, i(pointid) t(year) g(first_treat_new) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
					matrix att_b[1, `i'] = e(b)[., "ATT"]
					matrix att_V[`i', `i'] = e(V)["ATT", "ATT"]
				}
				mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
				matrix colnames att_b = `names'
				matrix colnames att_V = `names'
				matrix rownames att_V = `names'
				ereturn post att_b att_V
				ereturn display
				coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) xtitle("Number of periods shifted back as fake treatment time") ytitle("Placebo effect") title("In-time Placebo Test") legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ciopts(recast(rcap)) addplot(line @b @at) coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3  L4.ATT=4 L5.ATT=5 L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) graphregion(color(white)) plotregion(color(white))
				graph save "didimputation_pbotime_`ttype_label'_mdm_`cgroup_label'_centroid.gph", replace

				** In-Space Placebo test
				capture drop first_treat_new
				capture program drop InSpacePlaceboTest
				program define InSpacePlaceboTest, rclass
					preserve
					xtshuffle first_treat, gen(first_treat_new)
					qui did_imputation `depvar' $cv, i(pointid) t(year) g(first_treat_new) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): InSpacePlaceboTest
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_InSpacePbo.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff) xtitle("distribution of placebo effect") ytitle("density") title("In-space Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(didimputation_pbounit_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (unrestricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset panel_id year

				did_imputation `depvar' $cv, i(pointid) t(year) g(first_treat) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]

				capture program drop MixedPlaceboTest2
				program define MixedPlaceboTest2, rclass
					preserve
					xtrantreat post, method(2) gen(post_new)
					tofirsttreat post_new, gen(first_treat_new)
					qui did_imputation `depvar' $cv, i(pointid) t(year) g(first_treat_new) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest2
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo2.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') xtitle("distribution of placebo effect") ytitle("density") title("Unrestricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(didimputation_pbomix_unrestricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (restricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset panel_id year

				did_imputation `depvar' $cv, i(pointid) t(year) g(first_treat) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]

				capture program drop MixedPlaceboTest3
				program define MixedPlaceboTest3, rclass
					preserve
					xtrantreat post, method(3) gen(post_new)
					tofirsttreat post_new, gen(first_treat_new)
					qui did_imputation `depvar' $cv, i(pointid) t(year) g(first_treat_new) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest3
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo3.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff) xtitle("distribution of placebo effect") ytitle("density") title("Restricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(didimputation_pbomix_restricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right
				
				**# did2s (Gardner, 2021)
				did2s `depvar' [fweight = _weight], first_stage(i.pointid i.year $cv) second_stage(i.post) treatment(post) cluster(canton_num)
				estimates store did2s_`ttype'_`cgroup'_cv_`i'
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[1.post]
				display $tr_eff_`ttype'_`cgroup'_cv_`i'

				** In-Time Placebo test
				global K = 10
				matrix att_b = J(1, $K, 0)
				matrix att_V = J($K, $K, 0)

				forvalues i = 1(1)$K {
					cap drop post_new
					qui gen post_new = (year >= (first_treat - `i')) & (first_treat != .)
					qui did2s `depvar' [fweight = _weight] if year < (first_treat - `i'), first_stage(i.pointid i.year $cv) second_stage(i.post_new) treatment(post_new) cluster(canton_num)
					matrix att_b[1, `i'] = e(b)[., "1.post_new"]
					matrix att_V[`i', `i'] = e(V)["1.post_new", "1.post_new"]
				}
				mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
				matrix colnames att_b = `names'
				matrix colnames att_V = `names'
				matrix rownames att_V = `names'
				ereturn post att_b att_V
				ereturn display
				coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) xtitle("Number of periods shifted back as fake treatment time") ytitle("Placebo effect") ///
					title("In-time Placebo Test") legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
					ciopts(recast(rcap)) addplot(line @b @at) ///
					coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
					graphregion(color(white)) plotregion(color(white))
				graph save "did2s_pbotime_`ttype_label'_mdm_`cgroup_label'_centroid.gph", replace

				** In-Space Placebo test
				capture drop post_new
				capture program drop InSpacePlaceboTest
				program define InSpacePlaceboTest, rclass
					preserve
					xtshuffle first_treat, gen(first_treat_new)
					gen post_new = (year >= first_treat_new) & (first_treat_new != .)
					qui did2s `depvar' [fweight = _weight], first_stage(i.pointid i.year $cv) second_stage(i.post_new) treatment(post_new) cluster(canton_num)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b["1.post_new"]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): InSpacePlaceboTest
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_InSpacePbo.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("In-space Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(did2s_pbounit_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (unrestricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset panel_id year

				did2s `depvar' [fweight = _weight], first_stage(i.pointid i.year $cv) second_stage(i.post) treatment(post) cluster(canton_num)
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b["1.post"]

				capture program drop MixedPlaceboTest2
				program define MixedPlaceboTest2, rclass
					preserve
					xtrantreat post, method(2) gen(post_new)
					qui did2s `depvar' [fweight = _weight], ///
						first_stage(i.pointid i.year $cv) second_stage(i.post_new) treatment(post_new) cluster(canton_num)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b["1.post_new"]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest2
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo2.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Unrestricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(did2s_pbomix_unrestricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (restricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset panel_id year

				did2s `depvar' [fweight = _weight], first_stage(i.pointid i.year $cv) second_stage(i.post) treatment(post) cluster(canton_num)
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b["1.post"]

				capture program drop MixedPlaceboTest3
				program define MixedPlaceboTest3, rclass
					preserve
					xtrantreat post, method(3) gen(post_new)
					qui did2s `depvar' [fweight = _weight], first_stage(i.pointid i.year $cv) second_stage(i.post_new) treatment(post_new) cluster(canton_num)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b["1.post_new"]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest3
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo3.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Restricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(did2s_pbomix_restricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right
							
				**# eventstudyinteract (Sun & Abraham, 2021)
				if `cgroup' == "never" {
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				}
				if `cgroup' == "notyet" {
					gen control_cohort = (sociobosque_year == r(max) if sociobosque_year != .) // Last-treated (not-yet-treated) unit as control cohort, exclude the time periods when the last cohort receives treatment
				}
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
				eventstudyinteract `depvar' F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster state_num) covariates($cv)
				estimates store eventstudy_`ttype'_`cgroup'_cv_`i'
				matrix eventstudy_`ttype'_`cgroup'_cv_`i'_b = e(b_iw)
				matrix eventstudy_`ttype'_`cgroup'_cv_`i'_v = e(V_iw)
				ereturn post eventstudy_`ttype'_`cgroup'_cv_`i'_b eventstudy_`ttype'_`cgroup'_cv_`i'_v
				lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/10
				global tr_eff_`ttype'_`cgroup'_cv_`i' = eventstudy_`ttype'_`cgroup'_cv_`i'_b[1,10] // L0 as ATT
				display $tr_eff_`ttype'_`cgroup'_cv_`i'

				** In-Time Placebo test
				global K = 10
				matrix att_b = J(1, $K, 0)
				matrix att_V = J($K, $K, 0)

				forvalues i = 1/$K {
					cap drop placebo_treat
					qui gen placebo_treat = sociobosque_year - `i'
					cap drop placebo_dist
					qui gen placebo_dist = year - placebo_treat
					
					* Recreate event dummies
					cap drop F*event L*event
					gen F10event = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)2 {
						gen F`j'event = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen L`j'event = (placebo_dist == `j' & _treated == 1)
					}
					replace L10event = (placebo_dist >= 10 & _treated == 1)
					
					qui eventstudyinteract `depvar' F*event L*event [fweight = _weight] if year < placebo_treat, ///
						cohort(placebo_treat) control_cohort(control_cohort) absorb(pointid year) vce(cluster state_num) covariates($cv)
					matrix att_b[1, `i'] = e(b_iw)[1,10] // Extract L0 coefficient
					matrix att_V[`i', `i'] = e(V_iw)[10,10]
				}

				mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
				matrix colnames att_b = `names'
				matrix colnames att_V = `names'
				matrix rownames att_V = `names'
				ereturn post att_b att_V
				ereturn display

				coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
					xtitle("Number of periods shifted back as fake treatment time") ///
					ytitle("Placebo effect") title("In-time Placebo Test") ///
					legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
					ciopts(recast(rcap)) addplot(line @b @at) ///
					coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
							   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
					graphregion(color(white)) plotregion(color(white))
				graph save "eventstudy_pbotime_`ttype_label'_mdm_`cgroup_label'_centroid.gph", replace

				** In-Space Placebo test
				capture drop placebo_treat
				capture program drop InSpacePlaceboTest
				program define InSpacePlaceboTest, rclass
					preserve
					xtshuffle sociobosque_year, gen(placebo_treat)
					
					* Recreate control cohort
					cap drop control_cohort
					if "`cgroup'" == "never" {
						gen control_cohort = (missing(placebo_treat))
					}
					if "`cgroup'" == "notyet" {
						gen control_cohort = (placebo_treat == r(max) if placebo_treat != .)
					}
					
					* Recreate event dummies
					cap drop F*event L*event
					gen placebo_dist = year - placebo_treat
					gen F10event = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)2 {
						gen F`j'event = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen L`j'event = (placebo_dist == `j' & _treated == 1)
					}
					replace L10event = (placebo_dist >= 10 & _treated == 1)
					
					qui eventstudyinteract `depvar' F*event L*event [fweight = _weight], cohort(placebo_treat) control_cohort(control_cohort) absorb(pointid year) vce(cluster state_num) covariates($cv)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = e(b_iw)[1,10]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): InSpacePlaceboTest
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_InSpacePbo.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') ///
							 (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("In-space Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(eventstudy_pbounit_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (unrestricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset pointid year

				capture program drop MixedPlaceboTest2
				program define MixedPlaceboTest2, rclass
					preserve
					xtrantreat sociobosque_year, method(2) gen(placebo_treat)
					
					* Recreate control cohort
					cap drop control_cohort
					if "`cgroup'" == "never" {
						gen control_cohort = (missing(placebo_treat))
					}
					if "`cgroup'" == "notyet" {
						gen control_cohort = (placebo_treat == r(max) if placebo_treat != .)
					}
					
					* Recreate event dummies
					cap drop F*event L*event
					gen placebo_dist = year - placebo_treat
					gen F10event = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)2 {
						gen F`j'event = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen L`j'event = (placebo_dist == `j' & _treated == 1)
					}
					replace L10event = (placebo_dist >= 10 & _treated == 1)
					
					qui eventstudyinteract `depvar' F*event L*event [fweight = _weight], cohort(placebo_treat) control_cohort(control_cohort) absorb(pointid year) vce(cluster state_num) covariates($cv)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = e(b_iw)[1,10]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest2
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo2.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') ///
							 (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Unrestricted Mixed Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(eventstudy_pbomix_unrestricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (restricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset pointid year

				capture program drop MixedPlaceboTest3
				program define MixedPlaceboTest3, rclass
					preserve
					xtrantreat sociobosque_year, method(3) gen(placebo_treat)
					
					* Recreate control cohort
					cap drop control_cohort
					if "`cgroup'" == "never" {
						gen control_cohort = (missing(placebo_treat))
					}
					if "`cgroup'" == "notyet" {
						gen control_cohort = (placebo_treat == r(max) if placebo_treat != .)
					}
					
					* Recreate event dummies
					cap drop F*event L*event
					gen placebo_dist = year - placebo_treat
					gen F10event = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)2 {
						gen F`j'event = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen L`j'event = (placebo_dist == `j' & _treated == 1)
					}
					replace L10event = (placebo_dist >= 10 & _treated == 1)
					
					qui eventstudyinteract `depvar' F*event L*event [fweight = _weight], cohort(placebo_treat) control_cohort(control_cohort) absorb(pointid year) vce(cluster state_num) covariates($cv)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = e(b_iw)[1,10]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest3
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo3.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') ///
							 (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Restricted Mixed Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(eventstudy_pbomix_restricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				**# stackedev (Cengiz et al., 2019)
				if `cgroup' == "never" {
					//gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
					gen P_10 = (distyear<= -10 & _treated == 1)
					forv i = 9(-1)1{ // Reference: pre_1 (normalize t=-1 to zero)
						gen P_`i'  = (distyear== -`i' & _treated == 1) 
					}
					forv j = 0/10{
						gen Q_`j' = (distyear == `j' & _treated == 1)
				}
				replace Q_10 = (distyear>= 10 & _treated == 1)
				rename P_1 ref
					
					stackedev `depvar' P_* Q_* ref, cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(state_num) covariates($cv)
					estimates store stackedev_`ttype'_never_cv_`i'
					matrix stackedev_`ttype'_never_cv_`i'_b = e(b)
					matrix stackedev_`ttype'_never_cv_`i'_v = e(V)
				}
				
				** In-Time Placebo test
				global K = 10
				matrix att_b = J(1, $K, 0)
				matrix att_V = J($K, $K, 0)

				forvalues i = 1/$K {
					cap drop placebo_treat
					qui gen placebo_treat = sociobosque_year - `i'
					cap drop placebo_dist
					qui gen placebo_dist = year - placebo_treat
					
					* Recreate event dummies
					cap drop P_* Q_* ref
					gen P_10 = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)1 {
						gen P_`j' = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen Q_`j' = (placebo_dist == `j' & _treated == 1)
					}
					replace Q_10 = (placebo_dist >= 10 & _treated == 1)
					rename P_1 ref
					
					qui stackedev `depvar' P_* Q_* ref if year < placebo_treat, cohort(placebo_treat) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(state_num) covariates($cv)
					matrix att_b[1, `i'] = e(b)[1,10] // Extract Q_0 coefficient
					matrix att_V[`i', `i'] = e(V)[10,10]
				}

				mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
				matrix colnames att_b = `names'
				matrix colnames att_V = `names'
				matrix rownames att_V = `names'
				ereturn post att_b att_V
				ereturn display

				coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
					xtitle("Number of periods shifted back as fake treatment time") ///
					ytitle("Placebo effect") title("In-time Placebo Test") ///
					legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
					ciopts(recast(rcap)) addplot(line @b @at) ///
					coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
							   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
					graphregion(color(white)) plotregion(color(white))
				graph save "stackedev_pbotime_`ttype_label'_mdm_never_centroid.gph", replace

				** In-Space Placebo test
				capture drop placebo_treat
				capture program drop InSpacePlaceboTest
				program define InSpacePlaceboTest, rclass
					preserve
					xtshuffle sociobosque_year, gen(placebo_treat)
					
					* Recreate event dummies
					cap drop P_* Q_* ref
					gen placebo_dist = year - placebo_treat
					gen P_10 = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)1 {
						gen P_`j' = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen Q_`j' = (placebo_dist == `j' & _treated == 1)
					}
					replace Q_10 = (placebo_dist >= 10 & _treated == 1)
					rename P_1 ref
					
					qui stackedev `depvar' P_* Q_* ref, cohort(placebo_treat) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(state_num) covariates($cv)
					return scalar pbo_eff_`ttype'_never_cv_`i' = e(b)[1,10]
				end

				simulate pbo_eff_`ttype'_never_cv_`i' = r(pbo_eff_`ttype'_never_cv_`i'), seed(1) reps(500): InSpacePlaceboTest
				save "SBP_long_did_`ttype_label'_mdm_never_centroid_InSpacePbo.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_never_cv_`i') ///
							 (histogram pbo_eff_`ttype'_never_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_never_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("In-space Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(stackedev_pbounit_`ttype_label'_mdm_never_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_never_cv_`i') >= abs($tr_eff_`ttype'_never_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_never_cv_`i' <= $tr_eff_`ttype'_never_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_never_cv_`i' >= $tr_eff_`ttype'_never_cv_`i')
				sum extreme_right

				** Mixed Placebo test (unrestricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_never_centroid.dta", clear
				xtset pointid year

				capture program drop MixedPlaceboTest2
				program define MixedPlaceboTest2, rclass
					preserve
					xtrantreat sociobosque_year, method(2) gen(placebo_treat)
					
					* Recreate event dummies
					cap drop P_* Q_* ref
					gen placebo_dist = year - placebo_treat
					gen P_10 = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)1 {
						gen P_`j' = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen Q_`j' = (placebo_dist == `j' & _treated == 1)
					}
					replace Q_10 = (placebo_dist >= 10 & _treated == 1)
					rename P_1 ref
					
					qui stackedev `depvar' P_* Q_* ref, cohort(placebo_treat) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(state_num) covariates($cv)
					return scalar pbo_eff_`ttype'_never_cv_`i' = e(b)[1,10]
				end

				simulate pbo_eff_`ttype'_never_cv_`i' = r(pbo_eff_`ttype'_never_cv_`i'), seed(1) reps(500): MixedPlaceboTest2
				save "SBP_long_did_`ttype_label'_mdm_never_centroid_MixedPbo2.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_never_cv_`i') ///
							 (histogram pbo_eff_`ttype'_never_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_never_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Unrestricted Mixed Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(stackedev_pbomix_unrestricted_`ttype_label'_mdm_never_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_never_cv_`i') >= abs($tr_eff_`ttype'_never_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_never_cv_`i' <= $tr_eff_`ttype'_never_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_never_cv_`i' >= $tr_eff_`ttype'_never_cv_`i')
				sum extreme_right

				** Mixed Placebo test (restricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_never_centroid.dta", clear
				xtset pointid year

				capture program drop MixedPlaceboTest3
				program define MixedPlaceboTest3, rclass
					preserve
					xtrantreat sociobosque_year, method(3) gen(placebo_treat)
					
					* Recreate event dummies
					cap drop P_* Q_* ref
					gen placebo_dist = year - placebo_treat
					gen P_10 = (placebo_dist <= -10 & _treated == 1)
					forvalues j = 9(-1)1 {
						gen P_`j' = (placebo_dist == -`j' & _treated == 1)
					}
					forvalues j = 0/10 {
						gen Q_`j' = (placebo_dist == `j' & _treated == 1)
					}
					replace Q_10 = (placebo_dist >= 10 & _treated == 1)
					rename P_1 ref
					
					qui stackedev `depvar' P_* Q_* ref, cohort(placebo_treat) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(state_num) covariates($cv)
					return scalar pbo_eff_`ttype'_never_cv_`i' = e(b)[1,10]
				end

				simulate pbo_eff_`ttype'_never_cv_`i' = r(pbo_eff_`ttype'_never_cv_`i'), seed(1) reps(500): MixedPlaceboTest3
				save "SBP_long_did_`ttype_label'_mdm_never_centroid_MixedPbo3.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_never_cv_`i') ///
							 (histogram pbo_eff_`ttype'_never_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_never_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Restricted Mixed Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(stackedev_pbomix_restricted_`ttype_label'_mdm_never_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_never_cv_`i') >= abs($tr_eff_`ttype'_never_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_never_cv_`i' <= $tr_eff_`ttype'_never_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_never_cv_`i' >= $tr_eff_`ttype'_never_cv_`i')
				sum extreme_right

				**# Heterogeneity-Robust TWFE (wooldid) (Wooldridge, 2021)
				expand _weight
				wooldid `depvar' treatment_year year sociobosque_year, att cluster(canton_num) subgroup(treatment_year) fe(pointid year) controls($cv) esfixedbaseperiod esrelativeto(-1) jointtests
				estimates store wooldid_`ttype'_`cgroup'_cv_`i'
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				display $tr_eff_`ttype'_`cgroup'_cv_`i'

				** In-Time Placebo test
				* Automatic implementation for 1-10 periods shifted back
				global K = 10
				matrix att_b = J(1, $K, 0)
				matrix att_V = J($K, $K, 0)

				forvalues i = 1(1)$K {
					cap drop treatment_year_new
					qui gen treatment_year_new = treatment_year - `i'
					qui wooldid `depvar' treatment_year_new year sociobosque_year if year < treatment_year_new, ///
						att cluster(canton_num) subgroup(treatment_year_new) ///
						fe(pointid year) controls($cv) ///
						esfixedbaseperiod esrelativeto(-1) jointtests
					matrix att_b[1, `i'] = e(b)[., "ATT"]
					matrix att_V[`i', `i'] = e(V)["ATT", "ATT"]
				}
				mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
				matrix colnames att_b = `names'
				matrix colnames att_V = `names'
				matrix rownames att_V = `names'
				ereturn post att_b att_V
				ereturn display
				coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) xtitle("Number of periods shifted back as fake treatment time") ytitle("Placebo effect") title("In-time Placebo Test") legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ciopts(recast(rcap)) addplot(line @b @at) coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) graphregion(color(white)) plotregion(color(white))
				graph save "wooldid_pbotime_`ttype_label'_mdm_`cgroup_label'_centroid.gph", replace

				** In-Space Placebo test
				capture drop treatment_year_new
				capture program drop InSpacePlaceboTest
				program define InSpacePlaceboTest, rclass
					preserve
					xtshuffle treatment_year, gen(treatment_year_new)
					qui wooldid `depvar' treatment_year_new year sociobosque_year, ///
						att cluster(canton_num) subgroup(treatment_year_new) ///
						fe(pointid year) controls($cv) ///
						esfixedbaseperiod esrelativeto(-1) jointtests
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): InSpacePlaceboTest
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_InSpacePbo.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') xtitle("distribution of placebo effect") ytitle("density") title("In-space Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(wooldid_pbounit_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				* Compute two-sided p-value
				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				* Compute left-sided p-value
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				* Compute right-sided p-value
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (unrestricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset panel_id year

				wooldid `depvar' treatment_year year sociobosque_year, att cluster(canton_num) subgroup(treatment_year) fe(pointid year) controls($cv) esfixedbaseperiod esrelativeto(-1) jointtests
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]

				capture program drop MixedPlaceboTest2
				program define MixedPlaceboTest2, rclass
					preserve
					xtrantreat post, method(2) gen(post_new)
					tofirsttreat post_new, gen(treatment_year_new)
					qui wooldid `depvar' treatment_year_new year sociobosque_year, ///
						att cluster(canton_num) subgroup(treatment_year_new) ///
						fe(pointid year) controls($cv) ///
						esfixedbaseperiod esrelativeto(-1) jointtests
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest2
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo2.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') xtitle("distribution of placebo effect") ytitle("density") title("Unrestricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(wooldid_pbomix_unrestricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				* Compute two-sided p-value
				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				* Compute left-sided p-value
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				* Compute right-sided p-value
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (restricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset panel_id year

				wooldid `depvar' treatment_year year sociobosque_year, att cluster(canton_num) subgroup(treatment_year) fe(pointid year) controls($cv) esfixedbaseperiod esrelativeto(-1) jointtests
				global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]

				capture program drop MixedPlaceboTest3
				program define MixedPlaceboTest3, rclass
					preserve
					xtrantreat post, method(3) gen(post_new)
					tofirsttreat post_new, gen(treatment_year_new)
					qui wooldid `depvar' treatment_year_new year sociobosque_year, ///
						att cluster(canton_num) subgroup(treatment_year_new) ///
						fe(pointid year) controls($cv) ///
						esfixedbaseperiod esrelativeto(-1) jointtests
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest3
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo3.dta", replace
				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') xtitle("distribution of placebo effect") ytitle("density") title("Restricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(wooldid_pbomix_restricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				* Compute two-sided p-value
				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				* Compute left-sided p-value
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				* Compute right-sided p-value
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right
								
				**# csdid (Callaway & Sant'Anna, 2021)
					csdid `depvar' $cv, i(pointid) t(year) gvar(first_treat) method(drimp) agg(simple) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
					estimates store csdid_`ttype'_`cgroup'_cv_`i'
					global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
					display $tr_eff_`ttype'_`cgroup'_cv_`i'

					** In-Time Placebo test
					* Automatic implementation for 1-10 periods shifted back
					global K = 10
					matrix att_b = J(1, $K, 0)
					matrix att_V = J($K, $K, 0)

					forvalues i = 1(1)$K {
						cap drop first_treat_new
						qui gen first_treat_new = first_treat - `i'
						qui csdid `depvar' $cv if year < first_treat_new, ivar(pointid) time(year) gvar(first_treat_new) method(drimp) agg(simple) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
						matrix att_b[1, `i'] = e(b)[., "ATT"]
						matrix att_V[`i', `i'] = e(V)["ATT", "ATT"]
					}
					mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
					matrix colnames att_b = `names'
					matrix colnames att_V = `names'
					matrix rownames att_V = `names'
					ereturn post att_b att_V
					ereturn display
					coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) xtitle("Number of periods shifted back as fake treatment time") ytitle("Placebo effect") title("In-time Placebo Test") legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ciopts(recast(rcap)) addplot(line @b @at) coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3  L4.ATT=4 L5.ATT=5 L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) graphregion(color(white)) plotregion(color(white))
					graph save "csdid_pbotime_`ttype_label'_mdm_`cgroup_label'_centroid.gph", replace
					
					** In-Space Placebo test
					capture drop first_treat_new
					capture program drop InSpacePlaceboTest
					program define InSpacePlaceboTest, rclass
						preserve
						xtshuffle first_treat, gen(first_treat_new)
						qui csdid `depvar' $cv, ivar(pointid) time(year) gvar(first_treat_new) method(drimp) agg(simple) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
						return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
					end

					simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): InSpacePlaceboTest
					save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_InSpacePbo.dta", replace
					graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff) xtitle("distribution of placebo effect") ytitle("density") title("In-space Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(csdid_pbounit_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

					* Compute two-sided p-value
					gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
					sum extreme_abs
					* Compute left-sided p-value
					gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
					sum extreme_left
					* Compute right-sided p-value
					gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
					sum extreme_right

					** Mixed Placebo test (unrestricted version)
					use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
					xtset panel_id year

					csdid `depvar' $cv, ivar(pointid) time(year) gvar(first_treat) method(drimp) agg(simple) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
					global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]

					capture program drop MixedPlaceboTest2
					program define MixedPlaceboTest2, rclass
						preserve
						xtrantreat post, method(2) gen(post_new)
						tofirsttreat post_new, gen(first_treat_new)
						qui csdid `depvar' $cv, ivar(pointid) time(year) gvar(first_treat_new) method(drimp) agg(simple) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
						return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
					end

					simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest2
					save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo2.dta", replace
					graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') xtitle("distribution of placebo effect") ytitle("density") title("Unrestricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(csdid_pbomix_unrestricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

					* Compute two-sided p-value
					gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
					sum extreme_abs
					* Compute left-sided p-value
					gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
					sum extreme_left
					* Compute right-sided p-value
					gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
					sum extreme_right
					
					** Mixed Placebo test (restricted version)
					use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
					xtset panel_id year
					csdid `depvar' $cv, ivar(pointid) time(year) gvar(first_treat) method(dripw) agg(simple) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
					global tr_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]

					capture program drop MixedPlaceboTest3
					program define MixedPlaceboTest3, rclass
						preserve
						xtrantreat post, method(3) gen(post_new)
						tofirsttreat post_new, gen(first_treat_new)
						qui csdid `depvar' $cv, ivar(pointid) time(year) gvar(first_treat_new) method(dripw) agg(simple) cluster(canton_num) `= cond("`cgroup'"=="notyet", "notyet", "")'
						return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = _b[ATT]
					end

					simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest3
					save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo3.dta", replace
					graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff) xtitle("distribution of placebo effect") ytitle("density") title("Restricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) graphregion(color(white)) plotregion(color(white)) name(csdid_pbomix_restricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

					* Compute two-sided p-value
					gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
					sum extreme_abs
					* Compute left-sided p-value
					gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
					sum extreme_left
					* Compute right-sided p-value
					gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
					sum extreme_right
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2024)
				did_multiplegt_dyn `depvar' pointid year post, effects(10) placebo(10) cluster(cantonid)
				estimates store dcdh_`ttype'_`cgroup'_cv_`i'
				matrix results = r(results)
				global tr_eff_`ttype'_`cgroup'_cv_`i' = results[1,1]
				display $tr_eff_`ttype'_`cgroup'_cv_`i'
				
				** In-Time Placebo test
				* Automatic implementation for 1-10 periods shifted back
				global K = 10
				matrix att_b = J(1, $K, 0)
				matrix att_V = J($K, $K, 0)

				forvalues i = 1/$K {
					matrix att_b[1, `i'] = results[`i',5]
					matrix att_V[`i', `i'] = results[`i',6]^2
				}
				mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
				matrix colnames att_b = `names'
				matrix colnames att_V = `names'
				matrix rownames att_V = `names'
				ereturn post att_b att_V
				ereturn display

				coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
					xtitle("Number of periods shifted back as fake treatment time") ///
					ytitle("Placebo effect") title("In-time Placebo Test") ///
					legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
					ciopts(recast(rcap)) addplot(line @b @at) ///
					coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
							   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
					graphregion(color(white)) plotregion(color(white))
				graph save "dcdh_pbotime_`ttype_label'_mdm_`cgroup_label'_centroid.gph", replace

				** In-Space Placebo test
				capture drop post_new
				capture program drop InSpacePlaceboTest
				program define InSpacePlaceboTest, rclass
					preserve
					xtshuffle post, gen(post_new)
					qui did_multiplegt_dyn `depvar' pointid year post_new, effects(10) placebo(10) cluster(canton_num) controls($cv)
					matrix results = r(results)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = results[1,1]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): InSpacePlaceboTest
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_InSpacePbo.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') ///
							 (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("In-space Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(dcdh_pbounit_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (unrestricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset pointid year

				capture program drop MixedPlaceboTest2
				program define MixedPlaceboTest2, rclass
					preserve
					xtrantreat post, method(2) gen(post_new)
					qui did_multiplegt_dyn `depvar' pointid year post_new, effects(1) cluster(canton_num) controls($cv)
					matrix results = r(results)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = results[1,1]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest2
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo2.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') ///
							 (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Unrestricted Mixed Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(dcdh_pbomix_unrestricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)

				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right

				** Mixed Placebo test (restricted version)
				use "$datadir\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid.dta", clear
				xtset pointid year

				capture program drop MixedPlaceboTest3
				program define MixedPlaceboTest3, rclass
					preserve
					xtrantreat post, method(3) gen(post_new)
					qui did_multiplegt_dyn `depvar' pointid year post_new, effects(1) cluster(canton_num) controls($cv)
					matrix results = r(results)
					return scalar pbo_eff_`ttype'_`cgroup'_cv_`i' = results[1,1]
				end

				simulate pbo_eff_`ttype'_`cgroup'_cv_`i' = r(pbo_eff_`ttype'_`cgroup'_cv_`i'), seed(1) reps(500): MixedPlaceboTest3
				save "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_centroid_MixedPbo3.dta", replace

				graph twoway (kdensity pbo_eff_`ttype'_`cgroup'_cv_`i') ///
							 (histogram pbo_eff_`ttype'_`cgroup'_cv_`i', fcolor(gs8%50) lcolor(white) lalign(center) below), ///
					xline(0, lp(dash)) xline($tr_eff_`ttype'_`cgroup'_cv_`i') ///
					xtitle("distribution of placebo effect") ytitle("density") ///
					title("Restricted Mixed Placebo Test") ///
					legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(dcdh_pbomix_restricted_`ttype_label'_mdm_`cgroup_label'_centroid, replace)


				gen extreme_abs = (abs(pbo_eff_`ttype'_`cgroup'_cv_`i') >= abs($tr_eff_`ttype'_`cgroup'_cv_`i'))
				sum extreme_abs
				gen extreme_left = (pbo_eff_`ttype'_`cgroup'_cv_`i' <= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_left
				gen extreme_right = (pbo_eff_`ttype'_`cgroup'_cv_`i' >= $tr_eff_`ttype'_`cgroup'_cv_`i')
				sum extreme_right			
				di "Completed: `depvar_label' | `cgroup_label' | `ttype_label'"
*/					
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}


**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt_dyn forestloss pointid year post if cohort_year == 2008, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	estimates store dcdh
	matrix results = r(results)
	global tr_eff = results[1,1]
	display $tr_eff

// 	** In-Time Placebo test
// 	* Automatic implementation for 1-10 periods shifted back
// 	global K = 10
// 	matrix att_b = J(1, $K, 0)
// 	matrix att_V = J($K, $K, 0)
//
// 	forvalues i = 1/$K {
// 		matrix att_b[1, `i'] = results[`i',5]
// 		matrix att_V[`i', `i'] = results[`i',6]^2
// 	}
// 	mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
// 	matrix colnames att_b = `names'
// 	matrix colnames att_V = `names'
// 	matrix rownames att_V = `names'
// 	ereturn post att_b att_V
// 	ereturn display
//
// 	coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
// 		xtitle("Number of periods shifted back as fake treatment time") ///
// 		ytitle("Placebo effect") title("In-time Placebo Test") ///
// 		legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
// 		ciopts(recast(rcap)) addplot(line @b @at) ///
// 		coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
// 				   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
// 		graphregion(color(white)) plotregion(color(white))
// 	graph save "dcdh_pbotime_Collective_mdm_Never-treated_sb.gph", replace

	** In-Space Placebo test
	capture drop post_new
	capture program drop InSpacePlaceboTest
	program define InSpacePlaceboTest, rclass
		preserve
		xtshuffle post, gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2008, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
	save "SBP_long_did_Collective_mdm_Never-treated_sb_InSpacePbo.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("In-space Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbounit_Collective_mdm_Never-treated_sb, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (unrestricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest2
	program define MixedPlaceboTest2, rclass
		preserve
		xtrantreat post, method(2) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2008, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb_MixedPbo2.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Unrestricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_unrestricted_Collective_mdm_Never-treated_sb, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (restricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest3
	program define MixedPlaceboTest3, rclass
		preserve
		xtrantreat post, method(3) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2008, effects(10) cluster(canton_num) controls($cv)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb_MixedPbo3.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Restricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_restricted_Collective_mdm_Never-treated_sb, replace)


	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+pa
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt_dyn forestloss pointid year post if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	estimates store dcdh
	matrix results = r(results)
	global tr_eff = results[1,1]
	display $tr_eff

// 	** In-Time Placebo test
// 	* Automatic implementation for 1-10 periods shifted back
// 	global K = 10
// 	matrix att_b = J(1, $K, 0)
// 	matrix att_V = J($K, $K, 0)
//
// 	forvalues i = 1/$K {
// 		matrix att_b[1, `i'] = results[`i',5]
// 		matrix att_V[`i', `i'] = results[`i',6]^2
// 	}
// 	mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
// 	matrix colnames att_b = `names'
// 	matrix colnames att_V = `names'
// 	matrix rownames att_V = `names'
// 	ereturn post att_b att_V
// 	ereturn display
//
// 	coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
// 		xtitle("Number of periods shifted back as fake treatment time") ///
// 		ytitle("Placebo effect") title("In-time Placebo Test") ///
// 		legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
// 		ciopts(recast(rcap)) addplot(line @b @at) ///
// 		coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
// 				   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
// 		graphregion(color(white)) plotregion(color(white))
// 	graph save "dcdh_pbotime_Collective_mdm_Never-treated_sb+pa.gph", replace

	** In-Space Placebo test
	capture drop post_new
	capture program drop InSpacePlaceboTest
	program define InSpacePlaceboTest, rclass
		preserve
		xtshuffle post, gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
	save "SBP_long_did_Collective_mdm_Never-treated_sb+pa_InSpacePbo.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("In-space Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbounit_Collective_mdm_Never-treated_sb+pa, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (unrestricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest2
	program define MixedPlaceboTest2, rclass
		preserve
		xtrantreat post, method(2) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb+pa_MixedPbo2.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Unrestricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_unrestricted_Collective_mdm_Never-treated_sb+pa, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (restricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest3
	program define MixedPlaceboTest3, rclass
		preserve
		xtrantreat post, method(3) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb+pa_MixedPbo3.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Restricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_restricted_Collective_mdm_Never-treated_sb+pa, replace)


	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+it
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	estimates store dcdh
	matrix results = r(results)
	global tr_eff = results[1,1]
	display $tr_eff

// 	** In-Time Placebo test
// 	* Automatic implementation for 1-10 periods shifted back
// 	global K = 10
// 	matrix att_b = J(1, $K, 0)
// 	matrix att_V = J($K, $K, 0)
//
// 	forvalues i = 1/$K {
// 		matrix att_b[1, `i'] = results[`i',5]
// 		matrix att_V[`i', `i'] = results[`i',6]^2
// 	}
// 	mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
// 	matrix colnames att_b = `names'
// 	matrix colnames att_V = `names'
// 	matrix rownames att_V = `names'
// 	ereturn post att_b att_V
// 	ereturn display
//
// 	coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
// 		xtitle("Number of periods shifted back as fake treatment time") ///
// 		ytitle("Placebo effect") title("In-time Placebo Test") ///
// 		legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
// 		ciopts(recast(rcap)) addplot(line @b @at) ///
// 		coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
// 				   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
// 		graphregion(color(white)) plotregion(color(white))
// 	graph save "dcdh_pbotime_Collective_mdm_Never-treated_sb+it.gph", replace

	** In-Space Placebo test
	capture drop post_new
	capture program drop InSpacePlaceboTest
	program define InSpacePlaceboTest, rclass
		preserve
		xtshuffle post, gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
	save "SBP_long_did_Collective_mdm_Never-treated_sb+it_InSpacePbo.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("In-space Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbounit_Collective_mdm_Never-treated_sb+it, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (unrestricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest2
	program define MixedPlaceboTest2, rclass
		preserve
		xtrantreat post, method(2) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb+it_MixedPbo2.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Unrestricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_unrestricted_Collective_mdm_Never-treated_sb+it, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (restricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest3
	program define MixedPlaceboTest3, rclass
		preserve
		xtrantreat post, method(3) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb+it_MixedPbo3.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Restricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_restricted_Collective_mdm_Never-treated_sb+it, replace)


	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+pa+it
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+pa+it.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt_dyn forestloss pointid year post if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	estimates store dcdh
	matrix results = r(results)
	global tr_eff = results[1,1]
	display $tr_eff

// 	** In-Time Placebo test
// 	* Automatic implementation for 1-10 periods shifted back
// 	global K = 10
// 	matrix att_b = J(1, $K, 0)
// 	matrix att_V = J($K, $K, 0)
//
// 	forvalues i = 1/$K {
// 		matrix att_b[1, `i'] = results[`i',5]
// 		matrix att_V[`i', `i'] = results[`i',6]^2
// 	}
// 	mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
// 	matrix colnames att_b = `names'
// 	matrix colnames att_V = `names'
// 	matrix rownames att_V = `names'
// 	ereturn post att_b att_V
// 	ereturn display
//
// 	coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
// 		xtitle("Number of periods shifted back as fake treatment time") ///
// 		ytitle("Placebo effect") title("In-time Placebo Test") ///
// 		legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
// 		ciopts(recast(rcap)) addplot(line @b @at) ///
// 		coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
// 				   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
// 		graphregion(color(white)) plotregion(color(white))
// 	graph save "dcdh_pbotime_Collective_mdm_Never-treated_sb+pa+it.gph", replace

	** In-Space Placebo test
	capture drop post_new
	capture program drop InSpacePlaceboTest
	program define InSpacePlaceboTest, rclass
		preserve
		xtshuffle post, gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
	save "SBP_long_did_Collective_mdm_Never-treated_sb+pa+it_InSpacePbo.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("In-space Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbounit_Collective_mdm_Never-treated_sb+pa+it, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (unrestricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+pa+it.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest2
	program define MixedPlaceboTest2, rclass
		preserve
		xtrantreat post, method(2) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb+pa+it_MixedPbo2.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Unrestricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_unrestricted_Collective_mdm_Never-treated_sb+pa+it, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (restricted version)
	use "$datadir\SBP_long_300_did_Collective_mdm_Never-treated_sb+pa+it.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest3
	program define MixedPlaceboTest3, rclass
		preserve
		xtrantreat post, method(3) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
	save "SBP_long_300_did_Collective_mdm_Never-treated_sb+pa+it_MixedPbo3.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Restricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_restricted_Collective_mdm_Never-treated_sb+pa+it, replace)


	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	estimates store dcdh
	matrix results = r(results)
	global tr_eff = results[1,1]
	display $tr_eff

// 	** In-Time Placebo test
// 	* Automatic implementation for 1-10 periods shifted back
// 	global K = 10
// 	matrix att_b = J(1, $K, 0)
// 	matrix att_V = J($K, $K, 0)
//
// 	forvalues i = 1/$K {
// 		matrix att_b[1, `i'] = results[`i',5]
// 		matrix att_V[`i', `i'] = results[`i',6]^2
// 	}
// 	mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
// 	matrix colnames att_b = `names'
// 	matrix colnames att_V = `names'
// 	matrix rownames att_V = `names'
// 	ereturn post att_b att_V
// 	ereturn display
//
// 	coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
// 		xtitle("Number of periods shifted back as fake treatment time") ///
// 		ytitle("Placebo effect") title("In-time Placebo Test") ///
// 		legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
// 		ciopts(recast(rcap)) addplot(line @b @at) ///
// 		coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
// 				   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
// 		graphregion(color(white)) plotregion(color(white))
// 	graph save "dcdh_pbotime_Individual_mdm_Never-treated_sb.gph", replace

	** In-Space Placebo test
	capture drop post_new
	capture program drop InSpacePlaceboTest
	program define InSpacePlaceboTest, rclass
		preserve
		xtshuffle post, gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
	save "SBP_long_did_Individual_mdm_Never-treated_sb_InSpacePbo.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("In-space Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbounit_Individual_mdm_Never-treated_sb, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (unrestricted version)
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest2
	program define MixedPlaceboTest2, rclass
		preserve
		xtrantreat post, method(2) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
	save "SBP_long_300_did_Individual_mdm_Never-treated_sb_MixedPbo2.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Unrestricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_unrestricted_Individual_mdm_Never-treated_sb, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (restricted version)
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest3
	program define MixedPlaceboTest3, rclass
		preserve
		xtrantreat post, method(3) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, effects(10) cluster(canton_num) controls($cv)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
	save "SBP_long_300_did_Individual_mdm_Never-treated_sb_MixedPbo3.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Restricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_restricted_Individual_mdm_Never-treated_sb, replace)


	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb+pa
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	estimates store dcdh
	matrix results = r(results)
	global tr_eff = results[1,1]
	display $tr_eff

// 	** In-Time Placebo test
// 	* Automatic implementation for 1-10 periods shifted back
// 	global K = 10
// 	matrix att_b = J(1, $K, 0)
// 	matrix att_V = J($K, $K, 0)
//
// 	forvalues i = 1/$K {
// 		matrix att_b[1, `i'] = results[`i',5]
// 		matrix att_V[`i', `i'] = results[`i',6]^2
// 	}
// 	mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
// 	matrix colnames att_b = `names'
// 	matrix colnames att_V = `names'
// 	matrix rownames att_V = `names'
// 	ereturn post att_b att_V
// 	ereturn display
//
// 	coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
// 		xtitle("Number of periods shifted back as fake treatment time") ///
// 		ytitle("Placebo effect") title("In-time Placebo Test") ///
// 		legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
// 		ciopts(recast(rcap)) addplot(line @b @at) ///
// 		coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
// 				   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
// 		graphregion(color(white)) plotregion(color(white))
// 	graph save "dcdh_pbotime_Individual_mdm_Never-treated_sb+pa.gph", replace

	** In-Space Placebo test
	capture drop post_new
	capture program drop InSpacePlaceboTest
	program define InSpacePlaceboTest, rclass
		preserve
		xtshuffle post, gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
	save "SBP_long_did_Individual_mdm_Never-treated_sb+pa_InSpacePbo.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("In-space Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbounit_Individual_mdm_Never-treated_sb+pa, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (unrestricted version)
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest2
	program define MixedPlaceboTest2, rclass
		preserve
		xtrantreat post, method(2) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
	save "SBP_long_300_did_Individual_mdm_Never-treated_sb+pa_MixedPbo2.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Unrestricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_unrestricted_Individual_mdm_Never-treated_sb+pa, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (restricted version)
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest3
	program define MixedPlaceboTest3, rclass
		preserve
		xtrantreat post, method(3) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
	save "SBP_long_300_did_Individual_mdm_Never-treated_sb+pa_MixedPbo3.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Restricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_restricted_Individual_mdm_Never-treated_sb+pa, replace)


	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb+it
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	estimates store dcdh
	matrix results = r(results)
	global tr_eff = results[1,1]
	display $tr_eff

// 	** In-Time Placebo test
// 	* Automatic implementation for 1-10 periods shifted back
// 	global K = 10
// 	matrix att_b = J(1, $K, 0)
// 	matrix att_V = J($K, $K, 0)
//
// 	forvalues i = 1/$K {
// 		matrix att_b[1, `i'] = results[`i',5]
// 		matrix att_V[`i', `i'] = results[`i',6]^2
// 	}
// 	mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
// 	matrix colnames att_b = `names'
// 	matrix colnames att_V = `names'
// 	matrix rownames att_V = `names'
// 	ereturn post att_b att_V
// 	ereturn display
//
// 	coefplot, vertical msymbol(smcircle_hollow) yline(0, lp(dash)) ///
// 		xtitle("Number of periods shifted back as fake treatment time") ///
// 		ytitle("Placebo effect") title("In-time Placebo Test") ///
// 		legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ///
// 		ciopts(recast(rcap)) addplot(line @b @at) ///
// 		coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3 L4.ATT=4 L5.ATT=5 ///
// 				   L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10) ///
// 		graphregion(color(white)) plotregion(color(white))
// 	graph save "dcdh_pbotime_Individual_mdm_Never-treated_sb+it.gph", replace

	** In-Space Placebo test
	capture drop post_new
	capture program drop InSpacePlaceboTest
	program define InSpacePlaceboTest, rclass
		preserve
		xtshuffle post, gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
	save "SBP_long_did_Individual_mdm_Never-treated_sb+it_InSpacePbo.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("In-space Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbounit_Individual_mdm_Never-treated_sb+it, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (unrestricted version)
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest2
	program define MixedPlaceboTest2, rclass
		preserve
		xtrantreat post, method(2) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
	save "SBP_long_300_did_Individual_mdm_Never-treated_sb+it_MixedPbo2.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Unrestricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_unrestricted_Individual_mdm_Never-treated_sb+it, replace)

	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

	** Mixed Placebo test (restricted version)
	use "$datadir\SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta", clear
	xtset pointid year

	capture program drop MixedPlaceboTest3
	program define MixedPlaceboTest3, rclass
		preserve
		xtrantreat post, method(3) gen(post_new)
		qui did_multiplegt_dyn forestloss pointid year post_new, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		matrix results = r(results)
		return scalar pbo_eff = results[1,1]
	end

	simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
	save "SBP_long_300_did_Individual_mdm_Never-treated_sb+it_MixedPbo3.dta", replace

	graph twoway (kdensity pbo_eff) ///
				 (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), ///
		xline(0, lp(dash)) xline($tr_eff) ///
		xtitle("distribution of placebo effect") ytitle("density") ///
		title("Restricted Mixed Placebo Test") ///
		legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		name(dcdh_pbomix_restricted_Individual_mdm_Never-treated_sb+it, replace)


	gen extreme_abs = (abs(pbo_eff) >= abs($tr_eff))
	sum extreme_abs
	gen extreme_left = (pbo_eff <= $tr_eff)
	sum extreme_left
	gen extreme_right = (pbo_eff >= $tr_eff)
	sum extreme_right

local i 1
foreach depvar of global depvars {
	local depvar_label: word `i' of ${depvars_labels}
	
	local j 1
	foreach cgroup of global control_groups {
		local cgroup_label: word `j' of ${control_groups_labels}
			
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				local panel: word `l' of ${panels}
				
				grc1leg "dcdh_pbounit_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph" ///
						"dcdh_pbomix_unrestricted_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph" ///
						"dcdh_pbomix_restricted_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", ///
						rows(1) cols(3) title("(`panel') `policy_bundle_label'", size(medium) pos(11))
				graph save "Placebo Test_dcdh_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace
				graph export "Placebo Test_dcdh_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.png", as(png) replace width(6000) height(3000)
				
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}