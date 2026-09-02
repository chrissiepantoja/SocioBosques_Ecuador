
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Mechanism Analysis
*Country: Ecuador
*==============================================================================*

*--------------------------------------------
* Overall ATT/ATET
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
global dir "C:\Users\dz136\Box\Socio Bosque"
cd "$dir\data"

global control_groups			"never"
global control_groups_labels	`""Never-treated"'

global depvars			"farming"
global depvars_labels	`""Farming""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'

global policy_bundles			`""none" "indigenous" "pa" "pa & indigenous""'
global policy_bundles_labels	`""SB only" "SB + IT" "SB + PA" "SB + IT + PA""'
global pbs						`""n" "i" "p" "pi""'

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
				
				capture confirm file "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta"
				if _rc == 0 {
					use "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
					xtset panel_id year
					
					replace farming = 100 * farming
										
					* Generate post, did, and distyear
					gen post = (year >= treatment_year) if treatment_year != 9999
					replace post = 0 if treatment_year == 9999
					gen did = _treated * post
					gen distyear = year - sociobosque_year
					
					**# TWFE: reghdfe
						display "==================== Estimating: `cgroup_label' | `depvar_label' | `ttype_label' | `policy_bundle_label' ===================="
						* Without controls
						reghdfe `depvar' post [fweight = _weight], absorb(pointid cantonid#year) vce(cluster cantonid) noconstant resid
						estimates store reghdfe_`ttype'_`cgroup'_nocv_`j'_`pb'
						estadd local DepVar				"`depvar_label'"
						estadd local ControlGroup		"`cgroup_label'"
						estadd local Treatment			"`ttype_label'"
						estadd local Controls			"No"
						estadd local PixelFE			"Yes"
						estadd local CantonYearFE		"Yes"
						
/*
						* With controls
						reghdfe `depvar' post $cv [fweight = _weight], absorb(pointid cantonid#year) vce(cluster cantonid) noconstant resid
						estimates store reghdfe_`ttype'_`cgroup'_cv_`j'_`pb'
						estadd local DepVar				"`depvar_label'"
						estadd local ControlGroup		"`cgroup_label'"
						estadd local Treatment			"`ttype_label'"
						estadd local Controls			"Yes"
						estadd local PixelFE			"Yes"
						estadd local CantonYearFE		"Yes"
*/
				}
				else {
					display "File not found: SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta"
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

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}

		esttab	reghdfe_col_`cgroup'_nocv_`j'_n reghdfe_ind_`cgroup'_nocv_`j'_n reghdfe_col_`cgroup'_nocv_`j'_i reghdfe_ind_`cgroup'_nocv_`j'_i ///
				reghdfe_col_`cgroup'_nocv_`j'_p reghdfe_ind_`cgroup'_nocv_`j'_p reghdfe_col_`cgroup'_nocv_`j'_pi ///
				using "$dir\Results\Mechanism Analysis\Mechanism Analysis_mdm_`cgroup_label'_`depvar_label'.rtf", ///
				b(%8.4f) t(%6.4f) ///
				parentheses lines compress depvars ///
				scalars("PixelFE Pixel FE" "CantonYearFE Canton x Year FE" N r2 r2_a F) star(* 0.10 ** 0.05 *** 0.01) ///
				nogaps obslast replace ///
				title("TWFE: `depvar_label', `cgroup_label'")
		
		local j = `j' + 1
	}
	local i = `i' + 1
}