
*===========================================================================
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Group Heterogeneity
*Country: Ecuador
*===========================================================================

clear all
set more off, perm

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Data\SBP_data\annual"
// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"

*--------------------------------------------
* Group Heterogeneity
*--------------------------------------------

**# By status: always active & ever leaving

// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"
global dir_status "$dir\Results\Group Heterogeneity\Status"

global control_groups			"never"
global control_groups_labels	`""Never-treated"'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

// global treatment_types			"col ind"
// global treatment_types_labels	`""Collective" "Individual""'

global treatment_types			"col"
global treatment_types_labels	`""Collective""'

// global policy_bundles			`""sb" "sb+it" "sb+pa" "sb+it+pa""'
// global policy_bundles_labels	`""SB only" "SB + IT" "SB + PA" "SB + IT + PA""'
// global pbs						`""s" "si" "sp" "sip""'

global policy_bundles			`""sb+it""'
global policy_bundles_labels	`""SB + IT""'
global pbs						`""si""'

global panels "a b c d"

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				local panel: word `l' of ${panels}
				
				capture confirm file "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta"
				if _rc == 0 {
					use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
					xtset panel_id year
					
					levelsof sociobosque_status, local(status)
					foreach st of local status {
						use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
						
						keep if _treated == 1 & sociobosque_status == "`st'"
						if _N == 0 {
							continue
						}
						gen pairid = _n1 // Targeted control groups
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_`st'.dta", replace
					 
						keep pairid year cohort_year
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_targeted control id_year_`st'.dta", replace
						
						use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
						keep if _treated == 0
						gen pairid = _id // Control group candidates available for matching
						duplicates drop pairid year cohort_year, force
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_candidates_`st'.dta", replace

						use "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_targeted control id_year_`st'.dta", clear
						merge m:1 pairid year cohort_year using "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_candidates_`st'.dta", keep(matched) nogen
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_`st'.dta", replace

						append using "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_`st'.dta"
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_control_`st'.dta", replace
						duplicates drop panel_id year cohort_year, force
						
						* Generate post, did, and distyear
						gen post = (year >= treatment_year) if treatment_year != 9999
						replace post = 0 if treatment_year == 9999
						gen did = _treated * post
						gen distyear = year - sociobosque_year
						gen canton_id = cantonid
						gen post_pa = (year >= year_pa) if !missing(year_pa)
						gen fd_post_pa = D.post_pa
// 						gen post_il = (year >= year_il) if !missing(year_il)
// 						gen fd_post_il = D.post_il
// 						egen post_pail = group(post_pa post_il)
						local st1 = substr("`st'", 1, 1)
						
						di in red "==================== Estimating: `cgroup_label', `ttype_label', `policy_bundle_label', `s' ===================="
						if "`policy_bundle'" == "sb+pa" | "`policy_bundle'" == "sb+it+pa" {
							sum year_pa
							if r(max) < 1997 {
								levelsof cantonid, local(cantons)
								local n_clusters: word count `cantons'
								did_multiplegt_dyn `depvar' pointid year post, weight(_weight) effects(10) placebo(10) `= cond(`n_clusters'>1, "cluster(cantonid)", "")'
							}
							else {
								levelsof cantonid, local(cantons)
								local n_clusters: word count `cantons'
								levelsof year_pa if year_pa > 1997, local(years_pa)
								local n_years_pa: word count `years_pa'
								
								if `n_years_pa' == 1 {
									did_multiplegt_dyn `depvar' pointid year post, weight(_weight) effects(10) placebo(10) `= cond(`n_clusters'>1, "cluster(cantonid)", "")'
								}
								if `n_years_pa' >= 2 {
									did_multiplegt_old forestloss pointid year post, ///
										robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
										longdiff_placebo jointtestplacebo average_effect `= cond(`n_clusters'>1, "cluster(cantonid)", "")' ///
										if_first_diff(fd_post_pa==0) trends_nonparam(post_pa) always_trends_nonparam ///
										count_switchers_contr count_switchers_tot ///
										trends_lin(canton_id) ///
										breps(50) seed(111)
								}
							}
						}
						else {
							levelsof cantonid, local(cantons)
							local n_clusters : word count `cantons'
							did_multiplegt_dyn `depvar' pointid year post, weight(_weight) effects(10) placebo(10) `= cond(`n_clusters'>1, "cluster(cantonid)", "")'
						}
					}
				}
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

// Mannually copy data from windows to "$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta"

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				local panel: word `l' of ${panels}
				
				use "$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta", clear

				encode status, gen(statusid)
				levelsof statusid, local(yaxisid)
				foreach yaxis_label of local yaxisid {
					local current_label_text: label (statusid) `yaxis_label'
					local ylabels `"`ylabels' `yaxis_label' `"`current_label_text'"'"'
				}
				gen y_col = statusid - 0.15
				gen y_ind = statusid + 0.15

				twoway ///
					(scatter y_col estimate if type == "Collective", msymbol(Oh) mcolor(blue) msize(medium)) ///
					(rcap ub_ci lb_ci y_col if type == "Collective", horizontal lcolor(blue) lwidth(medium)) ///
					(scatter y_ind estimate if type == "Individual", msymbol(Dh) mcolor(green) msize(medium)) ///
					(rcap ub_ci lb_ci y_ind if type == "Individual", horizontal lcolor(green) lwidth(medium)) ///
					, ///
					ylabel(`ylabels', angle(0) labsize(small) noticks) ///
					ytitle("") ///
					yscale(reverse) ///
					xlabel(-0.15(0.05)0.10, format(%4.2f)) ///
					xtitle("Estimate of ATT and 95% Conf. Int.") ///
					xline(0, lpattern(dash) lcolor(black)) ///
					legend(order(1 "Collective" 3 "Individual")) ///
					graphregion(color(white)) ///
					title((`panel') `policy_bundle_label')
					graph save "$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.gph", replace
				
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
					
		grc1leg	"$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb.gph" ///
				"$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+it.gph" ///
				"$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+pa.gph" ///
				"$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+it+pa.gph", ///
				rows(1) cols(4) ///
				ycommon
		graph save "$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sociobosque.gph", replace
		graph export "$dir_status\Status Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sociobosque.png", as(png) replace width(6000) height(3000)
		
		local j = `j' + 1
	}
	local i = `i' + 1
}

**# By state

// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"
global dir_state "$dir\Results\Group Heterogeneity\State"

global control_groups			"never"
global control_groups_labels	`""Never-treated"'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'

global policy_bundles			`""sb" "sb+pa" "sb+it" "sb+it+pa""'
global policy_bundles_labels	`""SB" "SB + PA" "SB + IL" "SB + PA + IL""'
global pbs						`""s" "sp" "si" "spi""'

global panels "a b c d"

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				local panel: word `l' of ${panels}
				
				capture confirm file "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta"
				if _rc == 0 {
					use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
					xtset panel_id year
					
					levelsof state, local(states)

					foreach s of local states {
						use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
						keep if _treated == 1 & state == "`s'"
						if _N == 0 {
							continue
						}
						gen pairid = _n1 // Targeted control groups
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_`s'.dta", replace
						
						keep pairid year cohort_year
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_targeted control id_year_`s'.dta", replace
						
						use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
						keep if _treated == 0
						gen pairid = _id // Control group candidates available for matching
						duplicates drop pairid year cohort_year, force
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_candidates_`s'.dta", replace

						use "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_targeted control id_year_`s'.dta", clear
						merge m:1 pairid year cohort_year using "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_candidates_`s'.dta", keep(matched) nogen
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_`s'.dta", replace

						append using "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_`s'.dta"
						save "SBP_long_300_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_control_`s'.dta", replace
						duplicates drop panel_id year cohort_year, force
						xtset panel_id year
						
						* Generate post, did, and distyear
						gen post = (year >= treatment_year) if treatment_year != 9999
						replace post = 0 if treatment_year == 9999
						gen did = _treated * post
						gen distyear = year - sociobosque_year
						gen canton_id = cantonid
						gen post_pa = (year >= year_pa) if !missing(year_pa)
						gen fd_post_pa = D.post_pa
// 						gen post_il = (year >= year_il) if !missing(year_il)
// 						gen fd_post_il = D.post_il
// 						egen post_pail = group(post_pa post_il)
						local s1 = substr("`s'", 1, 1)

						
						di in red "==================== Estimating: `cgroup_label', `ttype_label', `policy_bundle_label', `s' ===================="
						if "`policy_bundle'" == "sb+pa" | "`policy_bundle'" == "sb+it+pa" {
							sum year_pa
							if r(max) < 1997 {
								levelsof cantonid, local(cantons)
								local n_clusters: word count `cantons'
								did_multiplegt_dyn `depvar' pointid year post, weight(_weight) effects(10) placebo(10) `= cond(`n_clusters'>1, "cluster(cantonid)", "")'
							}
							else {
								levelsof cantonid, local(cantons)
								local n_clusters: word count `cantons'
								levelsof year_pa if year_pa > 1997, local(years_pa)
								local n_years_pa: word count `years_pa'
								
								if `n_years_pa' == 1 {
									did_multiplegt_dyn `depvar' pointid year post, weight(_weight) effects(10) placebo(10) `= cond(`n_clusters'>1, "cluster(cantonid)", "")'
								}
								if `n_years_pa' >= 2 {
									did_multiplegt_old forestloss pointid year post, ///
										robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
										longdiff_placebo jointtestplacebo average_effect `= cond(`n_clusters'>1, "cluster(cantonid)", "")' ///
										if_first_diff(fd_post_pa==0) trends_nonparam(post_pa) always_trends_nonparam ///
										count_switchers_contr count_switchers_tot ///
										trends_lin(canton_id) ///
										breps(50) seed(111)
								}
							}
						}
						else {
							levelsof cantonid, local(cantons)
							local n_clusters : word count `cantons'
							did_multiplegt_dyn `depvar' pointid year post, weight(_weight) effects(10) placebo(10) `= cond(`n_clusters'>1, "cluster(cantonid)", "")'
						}
					}
				}
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

// Mannually copy data from windows to "$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta"

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				local panel: word `l' of ${panels}
				
				use "$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta", clear

				encode state, gen(stateid)
				levelsof stateid, local(yaxisid)
				foreach yaxis_label of local yaxisid {
					local current_label_text: label (stateid) `yaxis_label'
					local ylabels `"`ylabels' `yaxis_label' `"`current_label_text'"'"'
				}
				gen y_col = stateid - 0.15
				gen y_ind = stateid + 0.15

				twoway ///
					(scatter y_col estimate if type == "Collective", msymbol(Oh) mcolor(blue) msize(medium)) ///
					(rcap ub_ci lb_ci y_col if type == "Collective", horizontal lcolor(blue) lwidth(medium)) ///
					(scatter y_ind estimate if type == "Individual", msymbol(Dh) mcolor(green) msize(medium)) ///
					(rcap ub_ci lb_ci y_ind if type == "Individual", horizontal lcolor(green) lwidth(medium)) ///
					, ///
					ylabel(`ylabels', angle(0) labsize(small) noticks) ///
					ytitle("") ///
					yscale(reverse) ///
					xlabel(-0.15(0.05)0.10, format(%4.2f)) ///
					xtitle("Estimate of ATT and 95% Conf. Int.") ///
					xline(0, lpattern(dash) lcolor(black)) ///
					legend(order(1 "Collective" 3 "Individual")) ///
					graphregion(color(white)) ///
					title((`panel') `policy_bundle_label')
					graph save "$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.gph", replace
				
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		grc1leg	"$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb.gph" ///
				"$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+pa.gph" ///
				"$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+it.gph" ///
				"$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+it+pa.gph", ///
				rows(1) cols(4) ///
				ycommon
		graph save "$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sociobosque.gph", replace
		graph export "$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sociobosque.png", as(png) replace width(6000) height(3000)
		
		local j = `j' + 1
	}
	local i = `i' + 1
}

**# By cohort

// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"
global dir_cohort "$dir\Results\Group Heterogeneity\Cohort"

global control_groups			"never"
global control_groups_labels	`""Never-treated"'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'
// global treatment_types			"col"
// global treatment_types_labels	`""Collective""'
// global treatment_types			"ind"
// global treatment_types_labels	`""Individual""'

global policy_bundles			`""sb" "sb+it" "sb+pa" "sb+it+pa""'
global policy_bundles_labels	`""SB only" "SB + IT" "SB + PA" "SB + IT + PA""'
global pbs						`""s" "si" "sp" "sip" "p""'
// global policy_bundles			`""sb+it+pa""'
// global policy_bundles_labels	`""SB + IT + PA""'
// global pbs						`""sip""'
global panels "a b c d"

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				local panel: word `l' of ${panels}
				
				use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
				xtset panel_id year
				destring sociobosque_year, replace force
				levelsof sociobosque_year, local(cohorts)
				foreach cohort of local cohorts {
					use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
					xtset panel_id year
					* Generate post, did, and distyear
					gen post = (year >= treatment_year) if treatment_year != 9999
					replace post = 0 if treatment_year == 9999
					gen did = _treated * post
					gen distyear = year - sociobosque_year
					egen cantonid_year = group(cantonid year), label
					gen canton_id = cantonid
// 					gen post_il = (year >= year_il) if !missing(year_il)
// 					gen fd_post_il = D.post_il
// 					egen post_pail = group(post_pa post_il)
					replace `depvar' = 100 * `depvar'
					display "==================== Estimating: `cgroup_label' | `depvar_label' | `ttype_label' | `policy_bundle_label' | `cohort' ===================="
					did_multiplegt_dyn `depvar' pointid year post if cohort_year == `cohort', weight(_weight) effects(10) placebo(10) cluster(cantonid)
					
// 					keep if _treated == 1 & sociobosque_year == `cohort'
// 					if _N == 0 {
// 						continue
// 					}
// 					gen pairid = _n1 // Targeted control groups
// 					save "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_`cohort'.dta", replace
//				 
// 					keep pairid year cohort_year
// 					save "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_targeted control id_year_`cohort'.dta", replace
//					
// 					use "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
// 					keep if _treated == 0
// 					gen pairid = _id // Control group candidates available for matching
// 					save "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_candidates_`cohort'.dta", replace
//					
// 					use "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_targeted control id_year_`cohort'.dta", clear
// 					merge m:1 pairid year cohort_year using "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_candidates_`cohort'.dta", keep(matched) nogen
// 					save "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_control_`cohort'.dta", replace
//					
// 					append using "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_`cohort'.dta"
// 					save "SBP_long_did_mdm_`cgroup_label'_`ttype_label'_`policy_bundle'_treated_control_`cohort'.dta", replace
//					
// 					* Generate post, did, and distyear
// 					gen post = (year >= treatment_year) if treatment_year != 9999
// 					replace post = 0 if treatment_year == 9999
// 					gen did = _treated * post
// 					gen distyear = year - sociobosque_year
//					
// 					di in red "Estimating: `cgroup_label', `ttype_label', `policy_bundle_label', `cohort'"
// 					reghdfe `depvar' post [fweight = _weight], absorb(pointid cantonid#year) vce(cluster cantonid) noconstant
// 					estimates store state_`cgroup'_`ttype'_`j'_`pb'_`cohort'
// 					estadd local PixelFE "Yes"
// 					estadd local CantonYearFE "Yes"
				}
				
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

// Mannually copy data from windows to "$dir_state\State Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta"
// tostring cohort, replace force

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
				local panel: word `l' of ${panels}
				
				use "$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta", clear
				
				encode cohort, gen(cohortid)
				levelsof cohortid, local(yaxisid)
				foreach yaxis_label of local yaxisid {
					local current_label_text: label (cohortid) `yaxis_label'
					local ylabels `"`ylabels' `yaxis_label' `"`current_label_text'"'"'
				}
				gen y_col = cohortid - 0.1
				gen y_ind = cohortid + 0.1

				twoway ///
					(scatter y_col estimate if type == "Collective", msymbol(Oh) mcolor(blue) msize(medium)) ///
					(rcap ub_ci lb_ci y_col if type == "Collective", horizontal lcolor(blue) lwidth(medium)) ///
					(scatter y_ind estimate if type == "Individual", msymbol(Dh) mcolor(green) msize(medium)) ///
					(rcap ub_ci lb_ci y_ind if type == "Individual", horizontal lcolor(green) lwidth(medium)) ///
					, ///
					ylabel(`ylabels', angle(0) labsize(small) noticks) ///
					ytitle("") ///
					yscale(reverse) ///
					xlabel(-0.15(0.05)0.10, format(%4.2f)) ///
					xtitle("Estimate of ATT and 95% Conf. Int.") ///
					xline(0, lpattern(dash) lcolor(black)) ///
					legend(order(1 "Collective" 3 "Individual")) ///
					graphregion(color(white)) ///
					title((`panel') `policy_bundle_label')
				graph save "$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.gph", replace
				
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		grc1leg	"$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb.gph" ///
				"$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+pa.gph" ///
				"$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+it.gph" ///
				"$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sb+it+pa.gph", ///
				rows(1) cols(4) ///
				ycommon
		graph save "$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sociobosque.gph", replace
		graph export "$dir_cohort\Cohort Heterogeneity_mdm_`cgroup_label'_`depvar_label'_sociobosque.png", as(png) replace width(6000) height(3000)
		
		local j = `j' + 1
	}
	local i = `i' + 1
}

use "SBP_long_300_did_Individual_Collective_mdm_Never-treated_sb+it.dta" 
xtset panel_id year
gen post = (year >= treatment_year) if treatment_year != 9999
replace post = 0 if treatment_year == 9999
gen did = _treated * post
gen distyear = year - sociobosque_year
egen cantonid_year = group(cantonid year), label
gen canton_id = cantonid
replace forestloss = 100 * forestloss
did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
gen z = abs( -.1913089 /.1867252 )
gen p = 2 * (1 - normal(z))
levelsof p
graph save "$dir_cohort\Cohort Heterogeneity_mdm_Never-treated_Absolute forest loss_Individual_Collective_sociobosque_sb+it.gph", replace
did_multiplegt_dyn forestloss pointid year post if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
gen z2010 = abs( .0775281 /.1662583 )
gen p2010 = 2 * (1 - normal(z2010))
levelsof p2010
graph save "$dir_cohort\Cohort Heterogeneity_mdm_Never-treated_Absolute forest loss_Individual_Collective_sociobosque_sb+it_cohort2010.gph", replace
did_multiplegt_dyn forestloss pointid year post if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
gen z2011 = abs(-.3065574/ .6546702)
gen p2011 = 2 * (1 - normal(z2011))
levelsof p2011
graph save "$dir_cohort\Cohort Heterogeneity_mdm_Never-treated_Absolute forest loss_Individual_Collective_sociobosque_sb+it_cohort2011.gph", replace


use "SBP_long_300_did_Individual_Collective_mdm_Never-treated_sb+pa.dta" 
xtset panel_id year
gen post = (year >= treatment_year) if treatment_year != 9999
replace post = 0 if treatment_year == 9999
gen did = _treated * post
gen distyear = year - sociobosque_year
egen cantonid_year = group(cantonid year), label
gen canton_id = cantonid
replace forestloss = 100 * forestloss
did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
gen z = abs( -.1913089 /.1867252 )
gen p = 2 * (1 - normal(z))
levelsof p
graph save "$dir_cohort\Cohort Heterogeneity_mdm_Never-treated_Absolute forest loss_Individual_Collective_sociobosque_sb+pa.gph", replace
did_multiplegt_dyn forestloss pointid year post if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
gen z2010 = abs( .0775281 /.1662583 )
gen p2010 = 2 * (1 - normal(z2010))
levelsof p2010
graph save "$dir_cohort\Cohort Heterogeneity_mdm_Never-treated_Absolute forest loss_Individual_Collective_sociobosque_sb+pa_cohort2010.gph", replace
did_multiplegt_dyn forestloss pointid year post if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
gen z2011 = abs(-.3065574/ .6546702)
gen p2011 = 2 * (1 - normal(z2011))
levelsof p2011
graph save "$dir_cohort\Cohort Heterogeneity_mdm_Never-treated_Absolute forest loss_Individual_Collective_sociobosque_sb+pa_cohort2011.gph", replace