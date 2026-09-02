
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Robustness Check - Honest DID
*Country: Ecuador
*==============================================================================*

*--------------------------------------------
* Honest DID
*--------------------------------------------
* Rambachan, A. and Roth, J., 2023. A more credible approach to parallel trends. Review of Economic Studies, 90(5), pp.2555-2591.
* https://github.com/mcaceresb/stata-honestdid
* https://github.com/asheshrambachan/HonestDiD/tree/master
* Sensitivity analysis using relative magnitudes restrictions: based on the relative magnitudes of deviations from parallel trends in pre-treatment periods.
* Sensitivity analysis using smoothness restrictions: allowing for violations of linear trends in pre-treatment periods.

clear all
set more off, perm

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Results\Placebo Test"
// global dir_data "$dir\Data\SBP_data\annual"

// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\Results\Placebo Test"
// global dir_data "$dir\data"

global dir "G:\My Drive\socio bosque"
cd "$dir\Results\Robustness Check\Placebo Test"
global dir_data "$dir\data"

global control_groups			"never notyet"
global control_groups_labels	`""Never-treated" "Not-yet-treated""'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'

global policy_bundles			`""sb" "sb+pa" "sb+it" "sb+it+pa""'
global policy_bundles_labels	`""SB" "SB + PA" "SB + IT" "SB + PA + IT""'
global pbs						`""s" "sp" "si" "spi""'

global panels1 "a b c d"
global panels2 "A B"

set maxvar 12000 // For did2s (Gardner, 2021)

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
			
				use "$dir_data\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'_aaa.dta", clear
				xtset panel_id year
			
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				
				**# TWFE: reghdfe
				gen pre_10 = (distyea r<= -10 & _treated==1)
				forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
					gen pre_`i'  = (distyear== -`i' & _treated==1) 
				}
				forv j = 0/10{
					gen post_`j' = (distyear == `j' & _treated==1)
				}
				replace post_10 = (distyear >= 10 & _treated==1)
				
				* Without controls
				reghdfe `depvar' pre_* post_* [fweight = _weight], nocons absorb(pointid year cantonid#year) vce(cluster cantonid)
				estimates store reghdfe_`ttype'_`cgroup'_nocv_`j'_`pb'
				
				* Sensitivity analysis using relative magnitudes restrictions
				honestdid, numpre(10) mvec(0.5(0.5)2) coefplot xtitle(Mbar) ytitle(95% Robust Conf. Int.)
				//honestdid, pre(2/10) post(12/22) mvec(0.5(0.5)2) coefplot xtitle(Mbar) ytitle(95% Robust Conf. Int.)
				
				*Sensitivity Analysis Using Smoothness Restrictions
				//honestdid, pre(2/10) post(12/22) mvec(0(0.01)0.05) delta(sd) coefplot xtitle(M) ytitle(95% Robust Conf. Int.)
				
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb
	use "$dir_data\SBP_long_300_did_Collective_mdm_Never-treated_sb.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid

	did_multiplegt (old) forestloss pointid year post if cohort_year == 2008, weight(_weight) robust_dynamic dynamic(10) placebo(10) breps(50) cluster(cantonid)
	honestdid, pre(10/11) post(12/15) vcov(e(V)) b(e(b)) mvec(0(0.1)1) coefplot xtitle(Mbar) ytitle(95% Robust Conf. Int.)
	honestdid, pre(1/11) post(12/21) vcov(didmgt_vcov) b(didmgt_results_no_avg) honestdid, pre(10/11) post(12/15) 
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
