
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Spillover Effects
*Country: Ecuador
*==============================================================================*

*--------------------------------------------
* Spillover-robust DID (Clarke, 2017)
*--------------------------------------------

* Clarke, D., 2017. Estimating difference-in-differences in the presence of spillovers.

clear all
set more off, perm

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Data\SBP_data\annual"
// global outputdir "$dir\Spillover-robust DID"
// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"
global outputdir "$dir\Results\Spillover-robust DID"

global control_groups			"never"
global control_groups_labels	`""Never-treated""'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'
global resolutions				"300 300"

global policy_bundles			`""sb" "sb+it" "sb+pa" "sb+it+pa""'
global policy_bundles_labels	`""SB only" "SB + IT" "SB + PA" "SB + IT + PA""'
global pbs						`""s" "si" "sp" "sip""'

global panels "a b c d"

// ssc install geodist
// ssc install geonear

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
				
				di "Estimating: `ttype_label' | `depvar_label' | `cgroup_label' | `policy_bundle_label'"
				if "`ttype'" == "ind" & "`policy_bundle'" == "pa & indigenous" {
					di in red "No treated units. Skipping."
					restore
					exit
				}
				
				use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
				duplicates drop pointid, force
				keep pointid y x _treated
				destring y x, replace force
				save "pointid_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", replace
				
				preserve
				keep if _treated == 1
				rename pointid pointid_treated
				rename y y_treated
				rename x x_treated
				save "pointid_treated_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", replace
				restore
				
				geonear pointid y x using "pointid_treated_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", neighbors(pointid_treated y_treated x_treated) nearcount(1) long
				save "km_to_nid_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", replace
				
				use "SBP_long_300_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
				merge m:1 pointid using "km_to_nid_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", keep(matched) nogen
				replace km_to_pointid_treated = 0 if _treated == 1
				replace km_to_pointid_treated = . if _treated == 0 & year < cohort_year
				
				xtset panel_id year
				
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				
				**# TWFE: areg
				egen cantonid_year = group(cantonid year), label
				* kfold
				cdifdif `depvar' post [fweight = _weight], distance(km_to_pointid_treated) maxdist(5) regtype(areg) absorb(pointid) cluster(cantonid) kfold(10) verbose plotrmse
				//graph save "$outputdir\rmse_kfold_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace
				* loocv
				//cdifdif `depvar' post [fweight = _weight], distance(km_to_pointid_treated) maxdist(5) regtype(areg) absorb(pointid) cluster(cantonid) loocv verbose plotrmse
				//graph save "$outputdir\rmse_loocv_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace
				
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}
