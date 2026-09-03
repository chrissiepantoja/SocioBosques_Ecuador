*==============================================================================*
* DUKE UNIVERSITY
* Topic: Sociobosques
* Title: Overall ATT/ATET - Nighttime lights
* Country: Ecuador
*==============================================================================*

clear all
set more off

global dir "G:\My Drive\socio bosque"
cd "$dir\data"

global results "$dir\Results\Event Study"
global ntl_results "$results\Nighttime lights"
capture mkdir "$results"
capture mkdir "$ntl_results"

capture program drop run_ntl_dcdh
program define run_ntl_dcdh
	syntax, FILE(string) TTYPE(string) PBUNDLE(string) PBLABEL(string) POSTH(string) ///
		[COHORTFILTER(string) CLUSTER]

	use year pointid panel_id treatment_year _treated _weight cohort_year cantonid sociobosque_year nighttime_lights using "`file'", clear
	xtset panel_id year

	capture confirm variable nighttime_lights
	if _rc {
		display as error "nighttime_lights not found in `file'. Run _merge_nighttime_lights.do first."
		exit 111
	}

	capture drop post did distyear
	gen byte post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen byte did = _treated * post
	gen distyear = year - sociobosque_year

	local sample_if ""
	local sample_label "All cohorts"
	if "`cohortfilter'" != "" {
		local sample_if "if `cohortfilter'"
		local sample_label "`cohortfilter'"
	}

	local clusteropt ""
	if "`cluster'" != "" local clusteropt "cluster(cantonid)"

	local graph_base "$ntl_results\eventstudy_dcdh_300_mdm_Never-treated_Nighttime lights_`ttype'_`pbundle'"
	local event_data "`graph_base'_data.dta"

	display as result "==================== did_multiplegt_dyn | `ttype' | `pblabel' | `sample_label' ===================="
	did_multiplegt_dyn nighttime_lights pointid year post `sample_if', ///
		weight(_weight) effects(10) placebo(10) `clusteropt' ///
		graph_off save_results("`event_data'")

	tempname att se level zcrit ci_l ci_u pval pre_mean pre_sd pre_n nobs
	scalar `att' = .
	capture scalar `att' = e(Av_tot_effect)
	if _rc capture scalar `att' = e(avg_total_effect)
	if _rc capture scalar `att' = e(ATT)
	if _rc {
		display as error "Could not find overall ATT in e(Av_tot_effect), e(avg_total_effect), or e(ATT)."
		exit 198
	}

	scalar `se' = .
	capture scalar `se' = e(se_avg_total_effect)
	if _rc capture scalar `se' = e(se_Av_tot_effect)
	if _rc capture scalar `se' = e(se_ATT)
	if _rc {
		display as error "Could not find overall ATT standard error in e(se_avg_total_effect), e(se_Av_tot_effect), or e(se_ATT)."
		exit 198
	}

	scalar `level' = 95
	capture confirm scalar e(level)
	if !_rc scalar `level' = e(level)
	scalar `zcrit' = invnormal(0.5 + `level' / 200)
	scalar `ci_l' = `att' - `zcrit' * `se'
	scalar `ci_u' = `att' + `zcrit' * `se'
	scalar `pval' = .
	if `se' > 0 scalar `pval' = 2 * normal(-abs(`att' / `se'))

	local precond "post == 0"
	if "`cohortfilter'" != "" local precond "`precond' & (`cohortfilter')"
	quietly summarize nighttime_lights if `precond'
	scalar `pre_mean' = r(mean)
	scalar `pre_sd' = r(sd)
	scalar `pre_n' = r(N)

	scalar `nobs' = .
	capture scalar `nobs' = e(N)

	preserve
		use "`event_data'", clear
		sort time_to_treat
		twoway ///
			(connected point_estimate time_to_treat, lcolor(navy) mcolor(navy) lpattern(solid)) ///
			(rcap up_CI_95 lb_CI_95 time_to_treat, lcolor(navy%60)), ///
			xlabel(-10(1)10, labsize(small)) ///
			xtitle("Relative time to last period before treatment changes (t=0)") ///
			ytitle("Effect on nighttime lights") ///
			yline(0, lpattern(dash) lcolor(gs8)) ///
			graphregion(color(white)) plotregion(color(white)) ///
			legend(off) ///
			title("`ttype' | `pblabel'", size(medium))
		graph save "`graph_base'.gph", replace
		graph export "`graph_base'.png", as(png) replace width(2400)
	restore

	post `posth' ///
		("did_multiplegt_dyn") ///
		("`ttype'") ///
		("`pbundle'") ///
		("`pblabel'") ///
		("`sample_label'") ///
		(`att') (`se') (`ci_l') (`ci_u') (`pval') ///
		(`pre_mean') (`pre_sd') (`pre_n') (`nobs') ///
		("`graph_base'.gph") ("`graph_base'.png")
end

tempname att_post
tempfile att_results
postfile `att_post' ///
	str24 estimator ///
	str12 treatment_type ///
	str12 policy_bundle ///
	str16 policy_bundle_label ///
	str32 sample ///
	double att se ci_lower ci_upper p_value pre_mean pre_sd pre_n nobs ///
	str244 graph_gph ///
	str244 graph_png ///
	using `att_results', replace

run_ntl_dcdh, ///
	file("SBP_long_300_did_Collective_mdm_Never-treated_sb.dta") ///
	ttype("Collective") pbundle("sb") pblabel("SB") ///
	cohortfilter("cohort_year == 2008") cluster posth(`att_post')

run_ntl_dcdh, ///
	file("SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta") ///
	ttype("Collective") pbundle("sb+it") pblabel("SB + IT") ///
	cluster posth(`att_post')

run_ntl_dcdh, ///
	file("SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta") ///
	ttype("Collective") pbundle("sb+pa") pblabel("SB + PA") ///
	cohortfilter("cohort_year == 2011") posth(`att_post')

run_ntl_dcdh, ///
	file("SBP_long_300_did_Collective_mdm_Never-treated_sb+it+pa.dta") ///
	ttype("Collective") pbundle("sb+it+pa") pblabel("SB + IT + PA") ///
	cohortfilter("cohort_year == 2010") posth(`att_post')

run_ntl_dcdh, ///
	file("SBP_long_300_did_Individual_mdm_Never-treated_sb.dta") ///
	ttype("Individual") pbundle("sb") pblabel("SB") ///
	cluster posth(`att_post')

run_ntl_dcdh, ///
	file("SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta") ///
	ttype("Individual") pbundle("sb+it") pblabel("SB + IT") ///
	posth(`att_post')

run_ntl_dcdh, ///
	file("SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta") ///
	ttype("Individual") pbundle("sb+pa") pblabel("SB + PA") ///
	posth(`att_post')

postclose `att_post'

use `att_results', clear
gen stars = ""
replace stars = "***" if p_value < 0.01
replace stars = "**" if p_value >= 0.01 & p_value < 0.05
replace stars = "*" if p_value >= 0.05 & p_value < 0.10
order estimator treatment_type policy_bundle policy_bundle_label sample att se ci_lower ci_upper p_value stars pre_mean pre_sd pre_n nobs graph_gph graph_png
label variable att "Overall ATT"
label variable se "Standard error"
label variable ci_lower "95% CI lower"
label variable ci_upper "95% CI upper"
label variable p_value "p-value"
label variable stars "Significance"
label variable pre_mean "Pre-treatment mean"
label variable pre_sd "Pre-treatment SD"
label variable pre_n "Pre-treatment N"
label variable nobs "Regression N"

save "$ntl_results\Overall ATT_did_multiplegt_dyn_Nighttime lights.dta", replace
export excel using "$ntl_results\Overall ATT_did_multiplegt_dyn_Nighttime lights.xlsx", firstrow(variables) replace
export delimited using "$ntl_results\Overall ATT_did_multiplegt_dyn_Nighttime lights.csv", replace

list treatment_type policy_bundle att se ci_lower ci_upper p_value stars, noobs abbreviate(20)
