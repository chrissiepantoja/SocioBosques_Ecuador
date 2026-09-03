
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Robustness Check - Forest Cover
*Country: Ecuador
*==============================================================================*

*--------------------------------------------
* Robustness Check - Forest Cover
*--------------------------------------------

* TWFE: Biased when staggered adoption, heterogeneous treatment effects (ATT(g,t)); negative weights (using already treated units as controls); Treatment effect heterogeneity between groups biases the estimated pre-trends (Sun & Abraham, 2021).
* post can be replaced by did, same result
* Should not control for panel_id FE (panel_id varies with cohort_year; fake individuals; the inherent geographical features of pointid will not change based on which treated group it is assigned to)
* Should not control for cohort FE (already absorbed; highly correlated with year FE)
* Should not control for pointid × cohort FE (cohort: year of first treatment, invariant with year)
* reghdfe: Equivalent to xtdidregress!

clear all
set more off, perm

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Data\SBP_data\annual"
// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"

global control_groups			"never"
global control_groups_labels	`""Never-treated""'

global depvars			"forestcover farming"
global depvars_labels	`""Forest cover" "Agricultural expansion""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'

global policy_bundles			`""sb" "sb+it" "sb+pa" "sb+it+pa""'
global policy_bundles_labels	`""SB only" "SB + IT" "SB + PA" "SB + IT + PA""'
global pbs						`""s" "si" "sp" "sip""'

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb
	display in red "300_mdm_Never-treated_Collective_Absolute forest loss_sb"
	use "SBP_long_300_did_Collective_mdm_Never-treated_sb.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
	
	replace forestcover = 100 * forestcover
	replace farming = 100 * farming
	
	did_multiplegt_dyn forestcover pointid year post if cohort_year == 2008, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z1 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p1 = 2 * (1 - normal(z1))
	gen significance1 = ""
	replace significance1 = "***" if p1 < 0.01
	replace significance1 = "**"  if p1 >= 0.01 & p1 < 0.05
	replace significance1 = "*"   if p1 >= 0.05 & p1 < 0.1
	levelsof z1
	levelsof p1
	levelsof significance1
	
	did_multiplegt_dyn farming pointid year post if cohort_year == 2008, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z2 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p2 = 2 * (1 - normal(z2))
	gen significance2 = ""
	replace significance2 = "***" if p2 < 0.01
	replace significance2 = "**"  if p2 >= 0.01 & p2 < 0.05
	replace significance2 = "*"   if p2 >= 0.05 & p2 < 0.1
	levelsof z2
	levelsof p2
	levelsof significance2

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+it
	display in red "300_mdm_Never-treated_Collective_Absolute forest loss_sb+it"
	use "SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
// 	gen post_il = (year >= year_il) if !missing(year_il)
// 	gen fd_post_il = D.post_il
// 	egen post_pail = group(post_pa post_il)
	
	replace forestcover = 100 * forestcover
	replace farming = 100 * farming
	
	did_multiplegt_dyn forestcover pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z1 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p1 = 2 * (1 - normal(z1))
	gen significance1 = ""
	replace significance1 = "***" if p1 < 0.01
	replace significance1 = "**"  if p1 >= 0.01 & p1 < 0.05
	replace significance1 = "*"   if p1 >= 0.05 & p1 < 0.1
	levelsof z1
	levelsof p1
	levelsof significance1
	
	did_multiplegt_dyn farming pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z2 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p2 = 2 * (1 - normal(z2))
	gen significance2 = ""
	replace significance2 = "***" if p2 < 0.01
	replace significance2 = "**"  if p2 >= 0.01 & p2 < 0.05
	replace significance2 = "*"   if p2 >= 0.05 & p2 < 0.1
	levelsof z2
	levelsof p2
	levelsof significance2

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+pa
	display in red "300_mdm_Never-treated_Collective_Absolute forest loss_sb+pa"
	use "SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
	gen post_pa = (year >= year_pa) if !missing(year_pa)
	gen fd_post_pa = D.post_pa

	replace forestcover = 100 * forestcover
	replace farming = 100 * farming
	
 	did_multiplegt_dyn forestcover pointid year post if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z1 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p1 = 2 * (1 - normal(z1))
	gen significance1 = ""
	replace significance1 = "***" if p1 < 0.01
	replace significance1 = "**"  if p1 >= 0.01 & p1 < 0.05
	replace significance1 = "*"   if p1 >= 0.05 & p1 < 0.1
	levelsof z1
	levelsof p1
	levelsof significance1
	
 	did_multiplegt_dyn farming pointid year post if cohort_year == 2011, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z2 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p2 = 2 * (1 - normal(z2))
	gen significance2 = ""
	replace significance2 = "***" if p2 < 0.01
	replace significance2 = "**"  if p2 >= 0.01 & p2 < 0.05
	replace significance2 = "*"   if p2 >= 0.05 & p2 < 0.1
	levelsof z2
	levelsof p2
	levelsof significance2

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+it+pa
	display in red "300_mdm_Never-treated_Collective_Absolute forest loss_sb+it+pa"
	use "SBP_long_300_did_Collective_mdm_Never-treated_sb+it+pa.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
	gen post_pa = (year >= year_pa) if !missing(year_pa)
	gen fd_post_pa = D.post_pa
// 	gen post_il = (year >= year_il) if !missing(year_il)
// 	gen fd_post_il = D.post_il
// 	egen post_pail = group(post_pa post_il)

	replace forestcover = 100 * forestcover
	replace farming = 100 * farming
	
	levelsof year_pa if cohort_year == 2010 //1970 1979
	did_multiplegt_dyn forestcover pointid year post if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z1 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p1 = 2 * (1 - normal(z1))
	gen significance1 = ""
	replace significance1 = "***" if p1 < 0.01
	replace significance1 = "**"  if p1 >= 0.01 & p1 < 0.05
	replace significance1 = "*"   if p1 >= 0.05 & p1 < 0.1
	levelsof z1
	levelsof p1
	levelsof significance1
	
	did_multiplegt_dyn farming pointid year post if cohort_year == 2010, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z2 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p2 = 2 * (1 - normal(z2))
	gen significance2 = ""
	replace significance2 = "***" if p2 < 0.01
	replace significance2 = "**"  if p2 >= 0.01 & p2 < 0.05
	replace significance2 = "*"   if p2 >= 0.05 & p2 < 0.1
	levelsof z2
	levelsof p2
	levelsof significance2

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb
	display in red "300_mdm_Never-treated_Individual_Absolute forest loss_sb"
	use "SBP_long_300_did_Individual_mdm_Never-treated_sb.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	replace forestcover = 100 * forestcover
	replace farming = 100 * farming
	
	did_multiplegt_dyn forestcover pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z1 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p1 = 2 * (1 - normal(z1))
	gen significance1 = ""
	replace significance1 = "***" if p1 < 0.01
	replace significance1 = "**"  if p1 >= 0.01 & p1 < 0.05
	replace significance1 = "*"   if p1 >= 0.05 & p1 < 0.1
	levelsof z1
	levelsof p1
	levelsof significance1
	
	did_multiplegt_dyn farming pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z2 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p2 = 2 * (1 - normal(z2))
	gen significance2 = ""
	replace significance2 = "***" if p2 < 0.01
	replace significance2 = "**"  if p2 >= 0.01 & p2 < 0.05
	replace significance2 = "*"   if p2 >= 0.05 & p2 < 0.1
	levelsof z2
	levelsof p2
	levelsof significance2

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb+it
	display in red "300_mdm_Never-treated_Individual_Absolute forest loss_sb+it"
	use "SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
// 	gen post_il = (year >= year_il) if !missing(year_il)
// 	gen fd_post_il = D.post_il
// 	egen post_pail = group(post_pa post_il)

	replace forestcover = 100 * forestcover
	replace farming = 100 * farming
	
	did_multiplegt_dyn forestcover pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z1 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p1 = 2 * (1 - normal(z1))
	gen significance1 = ""
	replace significance1 = "***" if p1 < 0.01
	replace significance1 = "**"  if p1 >= 0.01 & p1 < 0.05
	replace significance1 = "*"   if p1 >= 0.05 & p1 < 0.1
	levelsof z1
	levelsof p1
	levelsof significance1
	
	did_multiplegt_dyn farming pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z2 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p2 = 2 * (1 - normal(z2))
	gen significance2 = ""
	replace significance2 = "***" if p2 < 0.01
	replace significance2 = "**"  if p2 >= 0.01 & p2 < 0.05
	replace significance2 = "*"   if p2 >= 0.05 & p2 < 0.1
	levelsof z2
	levelsof p2
	levelsof significance2

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb+pa
	display in red "300_mdm_Never-treated_Individual_Absolute forest loss_sb+pa"
	use "SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
	gen post_pa = (year >= year_pa) if !missing(year_pa)
	gen fd_post_pa = D.post_pa

	levelsof cohort_year
	
	did_multiplegt_dyn forestcover pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
	gen z1 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p1 = 2 * (1 - normal(z1))
	gen significance1 = ""
	replace significance1 = "***" if p1 < 0.01
	replace significance1 = "**"  if p1 >= 0.01 & p1 < 0.05
	replace significance1 = "*"   if p1 >= 0.05 & p1 < 0.1
	levelsof z1
	levelsof p1
	levelsof significance1
	
	did_multiplegt_dyn farming pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
// 	did_multiplegt_old farming pointid year post, ///
// 		robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
// 		longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
// 		if_first_diff(fd_post_pa==0) trends_nonparam(post_pa) always_trends_nonparam ///
// 		count_switchers_contr count_switchers_tot ///
// 		trends_lin(canton_id) ///
// 		breps(50) seed(111) // fd_post_pa not found r(111);
	gen z2 = abs(e(Av_tot_effect) / e(se_avg_total_effect))
	gen p2 = 2 * (1 - normal(z2))
	gen significance2 = ""
	replace significance2 = "***" if p2 < 0.01
	replace significance2 = "**"  if p2 >= 0.01 & p2 < 0.05
	replace significance2 = "*"   if p2 >= 0.05 & p2 < 0.1
	levelsof z2
	levelsof p2
	levelsof significance2


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
				
				capture confirm file "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta"
				if _rc == 0 {
					use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
					xtset panel_id year
					
					* Generate post, did, and distyear
					gen post = (year >= treatment_year) if treatment_year != 9999
					replace post = 0 if treatment_year == 9999
					gen did = _treated * post
					gen distyear = year - sociobosque_year
					gen canton_id = cantonid
					gen post_pa = (year >= year_pa) if !missing(year_pa)
					gen fd_post_pa = D.post_pa
// 					gen post_il = (year >= year_il) if !missing(year_il)
// 					gen fd_post_il = D.post_il
// 					egen post_pail = group(post_pa post_il)					
					
					display in red "==================== Estimating: `cgroup_label' | `depvar_label' | `ttype_label' | `policy_bundle_label' ===================="
						* Without controls
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
				else {
					display "File not found: SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta"
					continue
				}
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

// local i 1
// foreach cgroup of global control_groups {
// 	local cgroup_label: word `i' of ${control_groups_labels}
//	
// 	local j 1
// 	foreach depvar of global depvars {
// 		local depvar_label: word `j' of ${depvars_labels}
//
// 		esttab	reghdfe_col_`cgroup'_nocv_`j'_n reghdfe_ind_`cgroup'_nocv_`j'_n reghdfe_col_`cgroup'_nocv_`j'_i reghdfe_ind_`cgroup'_nocv_`j'_i ///
// 				reghdfe_col_`cgroup'_nocv_`j'_p reghdfe_ind_`cgroup'_nocv_`j'_p reghdfe_col_`cgroup'_nocv_`j'_pi ///
// 				using "$dir\Results\Robustness Check\Forest Cover\Robustness Check_mdm_`cgroup_label'_`depvar_label'.rtf", ///
// 				b(%8.4f) t(%6.4f) ///
// 				parentheses lines compress depvars ///
// 				scalars("PixelFE Pixel FE" "YearFE Year FE" N r2 r2_a F) star(* 0.10 ** 0.05 *** 0.01) ///
// 				nogaps obslast replace ///
// 				title("TWFE: `depvar_label', `cgroup_label'")
//
// 		local j = `j' + 1
// 	}
// 	local i = `i' + 1
// }