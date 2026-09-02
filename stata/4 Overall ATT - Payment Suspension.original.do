
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Overall ATT/ATET
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

* xthdidregress (cannot estimate aggregated ATT(g,t)!)
* https://www.stata.com/manuals/causalxthdidregress.pdf
* https://www.stata.com/manuals/causalteffectsintro.pdf#causalteffectsintro
* xtdidregress: https://www.stata.com/manuals/causaldidregress.pdf#causaldidregress
* Extended TWFE: Wooldridge (2021); RA, IPW, and AIPW: Callaway and Sant'Anna (2021)
* default: controlgroup(never), hettype(timecohort)
* "invalid group specification r(198)" error: https://www.stata.com/support/faqs/statistics/invalid-group-specification/
* Automatically control for year FE & unit FE

* Heterogeneity-Robust TWFE (Wooldridge, 2021; Correia, 2017): allowing for a flexible specification of the $/theta_{g,t}$ avoids the problem of bad controls and negative weights that have been identified in the literature as potential problems in the estimation of DID models using traditional TWFE estimators.
* Wooldridge, J.M., 2021. Two-way fixed effects, the two-way mundlak regression, and difference-in-differences estimators. Working paper, Department of Economics, Michigan State University, East Lansing, MI. https://doi.org/10.2139/ssrn.3906345.
* with full saturated interactions (i.cohort##c.year)

	* wooldid: Estimation of Difference-in-Differences Treatment Effects with Staggered Treatment Onset Using Heterogeneity-Robust Two-Way Fixed Effects Regressions
	* https://github.com/thegland/wooldid
	* https://www.statalist.org/forums/forum/general-stata-discussion/general/1725042-wooldid-estimation-of-diff-in-diff-treatment-effects-with-staggered-treatment-onset-using-heterogeneity-robust-twfe-regressions
	* Automatically control for cohort FE & year FE: In step 1, wooldid estimates the underlying two-way fixed effects regression, which consists of (at baseline) a regression of the outcome variable on cohort fixed effects, time fixed effects, and a set of indicator variables used to flexibly capture the effect of treatment. Each indicator variable is 1 in a specific cohort-period (i-t) cell, and 0 otherwise. The slate of indicator variables spans all cohort-periods for which treatment effects are to be estimated. In step 2, wooldid completes a set of calculations using the margins command that convert the large slate of coefficients on the treatment indicator variables from the underlying regression in step 1 into treatment effects of interest.
	* Fixed reference periods offer the virtue of transparency: all treated cohorts are compared to one reference period, which is the same for all cohorts in relative time terms. By contrast, pooled reference periods can be more opaque, with different cohorts having reference periods that contain varying numbers of time periods. In exchange for reduced transparency, pooled reference periods offer the possibility of greater precision in treatment effect estimates, owing to the fact that they pool together more data and thus have greater opportunity to average out idiosyncratic variation in outcomes within the reference period. With respect to which type of reference period should be used, fixed reference periods offer the virtue of transparency: all treated cohorts are compared to one reference period, which is the same for all cohorts in relative time terms. By contrast, pooled reference periods can be more opaque, with different cohorts having reference periods that contain varying numbers of time periods. In exchange for reduced transparency, pooled reference periods offer the possibility of greater precision in treatment effect estimates, owing to the fact that they pool together more data and thus have greater opportunity to average out idiosyncratic variation in outcomes within the reference period.

	* jwdid
	* https://friosavila.github.io/app_metrics/app_metrics11.html
	* jwdid is a command that implements the estimation approach proposed by Wooldridge (2021), based on the Mundlak approach. The main idea of JWDID is that consistent estimations for ATT's can be obtained by allowing for full cohort and timing heterogeneity, by simply adding cohort/year interactions in them main model. One advantage over other estimators is that it can also be applied using methods other than linear regression, including count models (poisson) or binomial models (logit). Aggregations are obtained using margins.

* https://journal.r-project.org/articles/RJ-2022-048/

* did_imputation (Borusyak et al., 2024)
* Borusyak, K., Jaravel, X. and Spiess, J., 2024. Revisiting event-study designs: robust and efficient estimation. Review of Economic Studies, 91(6), pp.3253-3285.
* Estimation proceeds in three steps:
	* 1. Estimate a model for non-treated potential outcomes using the non-treated (i.e. never-treated or not-yet-treated) observations only. The benchmark model for diff-in-diff designs is a two-way fixed effect (FE) model: Y_it = a_i + b_t + eps_it, but other FEs, controls, etc., are also allowed.
	* 2. Extrapolate the model from Step 1 to treated observations, imputing non-treated potential outcomes Y_it(0), and obtain an estimate of the treatment effect tau_it = Y_it - Y_it(0) for each treated observation. (See What if imputation is not possible)

	* 3. Take averages of estimated treatment effects corresponding to the estimand of interest.

* did2s (Gardner, 2021)
* Gardner, J., 2021. Two-stage differences in differences. arXiv preprint arXiv:2207.05943.
* https://github.com/kylebutts/did2s_stata

* csdid (Callaway & Sant'Anna, 2021)
* Callaway, B. and Sant'Anna, P.H., 2021. Difference-in-differences with multiple time periods. Journal of econometrics, 225(2), pp.200-230.
* csdid: https://www.lianxh.cn/details/1071.html; https://www.stata.com/meeting/us21/slides/US21_SantAnna.pdf; https://www.stata.com/symposiums/economics21/slides/Econ21_Rios-Avila.pdf
* Base period
	* From the perspective of the treated observations, all ATTGT's are estimated using the last not treated period as "base-period", and using current period as the post period.
	* For ATT's before the treatment took place, the command uses T-1 as the base period (or Pre-period), and T as the post-period. This corresponds to the {cmd short} pre-treatment gap.
	* When long gaps are requested, the ATT's before treatment took place uses T-1 as base period, and G-1 as the post period. where G is the first period a unit received treatment. One can also use {cmd long2}, which provides the same estimates pped sign. This is the closest to standard event study effects. The usually ommited parameter (T-1) is not calculated with csdid.
	* For ATT's after the treatment took place, the command uses G-1 as the base period (pre-treatment period) and T as the post-period.

* eventstudyinteract (Sun & Abraham, 2021)
* Sun, L. and Abraham, S., 2021. Estimating dynamic treatment effects in event studies with heterogeneous treatment effects. Journal of Econometrics, 225(2), pp.175-199.
* First, estimate the interacted regression with reghdfe, where the interactions are between relative time indicators and cohort indicators. Second, estimate the cohort shares underlying each relative time. Third, take the weighted average of estimates from the first step, with weights set to the estimated cohort shares.

* staggered (Roth and Sant'Anna, 2023)
* Roth, J., Sant'Anna, P.H., 2023. Efficient Estimation for Staggered Rollout Designs. https://arxiv.org/pdf/2102.01291
* https://github.com/mcaceresb/stata-staggered
* https://github.com/jonathandroth/staggered

* did_multiplegt (de Chaisemartin and d'Haultfœuille, 2023b)
* de Chaisemartin, C. and d'Haultfœuille, X., 2020. Two-way fixed effects estimators with heterogeneous treatment effects. American Economic Review, 110(9), pp.2964-2996.
* de Chaisemartin, C. and d'Haultfœuille, X., 2023a. Two-way fixed effects and differences-in-differences with heterogeneous treatment effects: A survey. The Econometrics Journal, 26(3), pp.C1-C30.
* De Chaisemartin, C. and D'haultfœuille, X., 2023b. Two-way fixed effects and differences-in-differences estimators with several treatments. Journal of Econometrics, 236(2), p.105480.
* de Chaisemartin, C. and d'Haultfœuille, X., 2024. Difference-in-differences estimators of intertemporal treatment effects. Review of Economics and Statistics, pp.1-45.
* https://cran.r-project.org/web/packages/DIDmultiplegtDYN/DIDmultiplegtDYN.pdf
* Jia, W., Xie, R., Ma, C., Gong, Z. and Wang, H., 2024. Environmental regulation and firms' emission reduction–The policy of eliminating backward production capacity as a quasi-natural experiment. Energy Economics, 130, p.107271.
* normalized normalized_weights: continuous/multi-level treatment

* stackedev (Cengiz et al., 2019)
* Cengiz, D., Dube, A., Lindner, A. and Zipperer, B., 2019. The effect of minimum wages on low-wage jobs. The Quarterly Journal of Economics, 134(3), pp.1405-1454.
* Appends together individual datasets or stacks. Each stack includes all observations from a cohort o that receive treatment in the same time period and all units that never received treatment. Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units. That approach avoids erroneous compari late to early implementing units that may bias Two-Way Fixed Effects (TWFE) estimates if effects vary across treated cohorts (Goodman-Bacon, 2021).
capture program drop dcdh_effect_export_rate
program define dcdh_effect_export_rate
	// Usage:
	//	dcdh_effect_export_rate, DEPVAR(forestloss) POSTVAR(post) [SAMPLEVAR(es)]
	//	- DEPVAR: level outcome in percentage points (not logged)
	//	- POSTVAR: 0/1, where 0 = pre (used for baseline mean/SD)
	//	- SAMPLEVAR (optional): restrict baseline to SAMPLEVAR==1

	syntax, DEPVAR(name) POSTVAR(name) [SAMPLEVAR(name)]

	// 0) Pre-period condition
	local precond "(`postvar'==0)"
	if "`samplevar'" != "" {
		local precond "(`postvar'==0 & `samplevar'==1)"
	}

	// 1) Baseline stats (pre period)
	quietly summarize `depvar' if `precond'
	scalar mean_pre = r(mean)
	scalar sd_pre   = r(sd)

	estadd scalar PreMean = mean_pre, replace
	estadd scalar PreSD   = sd_pre,   replace

	// 2) Read DCDH average total effect and SE (pp)
	tempname b se
	scalar `b'  = .
	scalar `se' = .

	capture scalar `b'  = e(Av_tot_effect)
	if _rc capture scalar `b'  = e(avg_total_effect)
	if _rc capture scalar `b'  = e(ATT)
	if _rc {
		di as error ">>> Could not find e(Av_tot_effect)/e(avg_total_effect)/e(ATT)."
		exit 198
	}

	capture scalar `se' = e(se_avg_total_effect)
	if _rc capture scalar `se' = e(se_Av_tot_effect)
	if _rc capture scalar `se' = e(se_ATT)
	if _rc {
		di as error ">>> Could not find e(se_avg_total_effect)/e(se_Av_tot_effect)/e(se_ATT)."
		exit 198
	}

	// 3) Absolute effect (pp) and CI
	scalar level = 95
	capture confirm scalar e(level)
	if !_rc scalar level = e(level)
	scalar zcrit = invnormal(0.5 + level/200)

	scalar abs_b = `b'
	scalar abs_se = `se'
	scalar abs_l = abs_b - zcrit*abs_se
	scalar abs_h = abs_b + zcrit*abs_se

	estadd scalar PctPointEffect = abs_b, replace
	estadd scalar PctPointSE     = abs_se, replace
	estadd scalar PctPointLow    = abs_l, replace
	estadd scalar PctPointHigh   = abs_h, replace

	// stars for absolute effect
	scalar abs_z = .
	if abs_se>0 scalar abs_z = abs_b/abs_se
	scalar abs_p = 2*normal(-abs(abs_z))
	local  PctPoint_stars = cond(abs_p<0.01,"***", cond(abs_p<0.05,"**", cond(abs_p<0.10,"*","")))
	local  PctPoint_num : display %9.4f abs_b
	local  PctPoint_fmt `"`PctPoint_num'`PctPoint_stars'"'
	estadd local PctPoint_stars "`PctPoint_stars'", replace
	estadd local PctPoint_fmt   "`PctPoint_fmt'",   replace

	// 4) Relative effect (%) with analytic SE: 100*beta/mean_pre ; SE = 100*SE_beta/mean_pre
	if mean_pre!=. & mean_pre!=0 {
		scalar rel_b  = 100 * abs_b / mean_pre
		scalar rel_se = 100 * abs_se / mean_pre
		scalar rel_l  = rel_b - zcrit*rel_se
		scalar rel_h  = rel_b + zcrit*rel_se

		estadd scalar RelPctEffect = rel_b,  replace
		estadd scalar RelPctSE     = rel_se, replace
		estadd scalar RelPctLow    = rel_l,  replace
		estadd scalar RelPctHigh   = rel_h,  replace

		// stars for relative effect
		scalar rel_z = .
		if rel_se>0 scalar rel_z = rel_b/rel_se
		scalar rel_p = 2*normal(-abs(rel_z))
		local  RelPct_stars = cond(rel_p<0.01,"***", cond(rel_p<0.05,"**", cond(rel_p<0.10,"*","")))
		local  RelPct_num : display %9.4f rel_b
		local  RelPct_fmt `"`RelPct_num'`RelPct_stars'"'
		estadd local RelPct_stars "`RelPct_stars'", replace
		estadd local RelPct_fmt   "`RelPct_fmt'",   replace
	}
	else {
		di as error ">>> mean_pre is zero or missing; skipped relative-percent effect."
	}

	// 5) Standardized effect (in pre SDs): beta / sd_pre
	if sd_pre!=. & sd_pre>0 {
		scalar std_eff = abs_b / sd_pre
		estadd scalar StdEffectSD = std_eff, replace
	}
	else {
		di as error ">>> sd_pre is zero or missing; skipped standardized effect."
	}

	// 6) Console summary (avoid +cond() concat)
	local restr ""
	if "`samplevar'" != "" local restr "; restricted to SAMPLEVAR==1"
	di as text "----------------------------------------------"
	di as text "Baseline (pre-treatment`restr'):"
	di as result "  Mean = " %9.4f mean_pre "   SD = " %9.4f sd_pre "   (units: percentage points)"
	di as text "Estimated effect (DCDH average total effect):"
	di as result "  Abs = " %9.4f abs_b " pp   (SE " %9.4f abs_se "),  " ///
		"`=string(level, "%2.0f")'% CI: [" %9.4f abs_l ", " %9.4f abs_h "]"
	if mean_pre!=. & mean_pre!=0 {
		di as result "  Rel = " %9.4f rel_b " %   (SE " %9.4f rel_se ")  CI: [" %9.4f rel_l ", " %9.4f rel_h "]"
	}
	if sd_pre!=. & sd_pre>0 {
		di as result "  Std = " %9.4f std_eff " SDs"
	}
	di as text "----------------------------------------------"
end


clear all
set more off, perm

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Data\SBP_data\annual"

// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"

// global results "$dir\Results"
global results "$dir\Results\Event Study"

global dir_estimators "$dir\Results\Robustness Check\Estimators"

global control_groups			"never"
global control_groups_labels	`""Never-treated""'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'
global resolutions				"300 300"

global policy_bundles			`""sb" "sb+pa" "sb+it" "sb+it+pa""'
global policy_bundles_labels	`""SB" "SB + PA" "SB + IT" "SB + PA + IT""'
global pbs						`""s" "sp" "si" "spi""'

global panels1 "a b c d"
global panels2 "A B"

//set maxvar 120000 // For did2s (Gardner, 2021)

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb
	use "SBP_long_300_did_Collective_mdm_Never-treated_sb.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
	
	**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023)
	* Group and time fixed effects are automatically controlled for.
	display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023) ===================="
		* Without controls
		did_multiplegt_dyn forestloss pointid year post if cohort_year == 2008, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		gen byte es = (cohort_year == 2008)
		dcdh_effect_export_rate, depvar(forestloss) postvar(post) samplevar(es)
		estimates store dcdh_col_1_i
		matrix dcdh_col_1_n_b = e(b)
		matrix dcdh_col_1_n_v = e(V)
		graph save "$results\eventstudy_dcdh_300_mdm_Never-treated_Absolute forest loss_Collective_sb.gph", replace


// 		did_multiplegt_old forestloss pointid year post, ///
// 				robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
// 				longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
// 				count_switchers_contr count_switchers_tot ///
// 				trends_lin(canton_id) ///
// 				breps(50) seed(111) ///
// 				save_results("$results\Baseline\Baseline_dcdh_300_mdm_Never-treated_Collective_Absolute forest loss_sb.dta")
// 		matrix dcdh_col_1_n_b = e(didmgt_estimates)
// 		matrix dcdh_col_1_n_v = e(didmgt_variances)
// 		ereturn list
	**# did_imputation (Borusyak et al., 2024)
	* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
	* Only aw or iw are allowed; all weight types (aw\iw\fw\expand _weight) produce identical results.
	* Cohort identifiers: missing = never-treated.
	display "==================== did_imputation (Borusyak et al., 2024) ===================="
		* Without controls
		did_imputation forestloss pointid year sociobosque_year if cohort_year == 2008 [aweight = _weight], autosample fe(pointid year) cluster(cantonid)

	**# csdid (Callaway & Sant'Anna, 2021)
	* Only de jure iweights (de facto pweights) allowed.
	* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
	* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
	* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
	* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
	display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
		* Without controls
		csdid forestloss if cohort_year == 2008 [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
		estat event, window(-10 10) estore(cs_col_1_n)

	**# eventstudyinteract (Sun & Abraham, 2021)
	* The Absolute time indicators should take the value of zero for never treated units.
	* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
	* Cohort identifiers should be set to be missing for never treated units.
	display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
	gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
	gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
	forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
		gen F`i'event = (distyear == -`i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	forvalues i = 0/10 {
		gen L`i'event = (distyear == `i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
		
		* Without controls
		eventstudyinteract forestloss F*event L*event if cohort_year == 2008 [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster cantonid)
		estimates store sa_col_1_n
		matrix sa_col_1_n_b = e(b_iw)
		matrix sa_col_1_n_v = e(V_iw)
		ereturn post sa_col_1_n_b sa_col_1_n_v
		lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
		test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
		
	**# stackedev (Cengiz et al., 2019)
	* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
	* Cohort identifiers must be missing for never treated units.
	display "==================== stackedev (Cengiz et al., 2019) ===================="
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
		
		* Without controls
		stackedev forestloss P_* Q_* ref if cohort_year == 2008 [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(cantonid)
		estimates store stack_col_1_n
		matrix stack_col_1_n_b = e(b)	
		matrix stack_col_1_n_v = e(V)
		ereturn post stack_col_1_n_b stack_col_1_n_v
		lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
		test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

	**# TWFE: reghdfe
	display "==================== TWFE: reghdfe ===================="
	
	gen pre_10 = (distyear<= -10 & _treated==1)
	forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
		gen pre_`i'  = (distyear== -`i' & _treated==1) 
	}
	forv j = 0/10{
		gen post_`j' = (distyear == `j' & _treated==1)
	}
	replace post_10 = (distyear >= 10 & _treated==1)
	
		* Without controls
		reghdfe forestloss post if cohort_year == 2008 [fweight = _weight], nocons absorb(pointid year) vce(cluster cantonid)

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+it
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

	**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023)
	* Group and time fixed effects are automatically controlled for.
	display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023) ===================="
		* Without controls
		did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		dcdh_effect_export_rate, depvar(forestloss) postvar(post)
		estimates store dcdh_col_1_i
		matrix dcdh_col_1_i_b = e(b)
		matrix dcdh_col_1_i_v = e(V)
		graph save "$results\eventstudy_dcdh_300_mdm_Never-treated_Absolute forest loss_Collective_sb+it.gph", replace

// 		did_multiplegt_old forestloss pointid year post, ///
// 				robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
// 				longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
// 				count_switchers_contr count_switchers_tot ///
// 				trends_lin(canton_id) ///
// 				breps(50) seed(111) ///
// 				save_results("$results\Baseline\Baseline_dcdh_300_mdm_Never-treated_Collective_Absolute forest loss_sb+it.dta")
// 		matrix dcdh_col_1_i_b = e(didmgt_estimates)
// 		matrix dcdh_col_1_i_v = e(didmgt_variances)
// 		ereturn list
		
	**# did_imputation (Borusyak et al., 2024)
	* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
	* Only aw or iw are allowed; all weight types (aw\iw\fw\expand _weight) produce identical results.
	* Cohort identifiers: missing = never-treated.
	display "==================== did_imputation (Borusyak et al., 2024) ===================="
		* Without controls
		did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid year) cluster(cantonid)

	**# csdid (Callaway & Sant'Anna, 2021)
	* Only de jure iweights (de facto pweights) allowed.
	* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
	* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
	* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
	* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
	display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
		* Without controls
		csdid forestloss [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
		estat event, window(-10 10) estore(cs_col_1_i)

	**# eventstudyinteract (Sun & Abraham, 2021)
	* The Absolute time indicators should take the value of zero for never treated units.
	* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
	* Cohort identifiers should be set to be missing for never treated units.
	display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
	gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
	gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
	forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
		gen F`i'event = (distyear == -`i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	forvalues i = 0/10 {
		gen L`i'event = (distyear == `i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
		
		* Without controls
		eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster cantonid)
		estimates store sa_col_1_i
		matrix sa_col_1_i_b = e(b_iw)
		matrix sa_col_1_i_v = e(V_iw)
		ereturn post sa_col_1_i_b sa_col_1_i_v
		lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
		test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
		
	**# stackedev (Cengiz et al., 2019)
	* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
	* Cohort identifiers must be missing for never treated units.
	display "==================== stackedev (Cengiz et al., 2019) ===================="
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
		
		* Without controls
		stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(cantonid)
		estimates store stack_col_1_i
		matrix stack_col_1_i_b = e(b)	
		matrix stack_col_1_i_v = e(V)
		ereturn post stack_col_1_i_b stack_col_1_i_v
		lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
		test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

	**# TWFE: reghdfe
	display "==================== TWFE: reghdfe ===================="
	
	gen pre_10 = (distyear<= -10 & _treated==1)
	forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
		gen pre_`i'  = (distyear== -`i' & _treated==1) 
	}
	forv j = 0/10{
		gen post_`j' = (distyear == `j' & _treated==1)
	}
	replace post_10 = (distyear >= 10 & _treated==1)
	
		* Without controls
		reghdfe forestloss post [fweight = _weight], nocons absorb(pointid year) vce(cluster cantonid)
		

**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+pa
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
	
	**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023)
	* Group and time fixed effects are automatically controlled for.
	display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023) ===================="
		* Without controls
 		did_multiplegt_dyn forestloss pointid year post if cohort_year == 2011, weight(_weight) effects(10) placebo(10)
		gen byte es = (cohort_year == 2011)
		dcdh_effect_export_rate, depvar(forestloss) postvar(post) samplevar(es)
		graph save "$results\eventstudy_dcdh_300_mdm_Never-treated_Absolute forest loss_Collective_sb+pa.gph", replace
		
// 		did_multiplegt_old forestloss pointid year post if cohort_year == 2011, ///
// 				robust_dynamic weight(_weight) dynamic(9) placebo(9) ///
// 				longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
// 				if_first_diff(fd_post_pa==0) trends_nonparam(post_pa) always_trends_nonparam ///
// 				count_switchers_contr count_switchers_tot ///
// 				trends_lin(canton_id) ///
// 				breps(50) seed(111) ///
// 				save_results("$results\Baseline_dcdh_300_mdm_Never-treated_Collective_Absolute forest loss_sb+pa.dta")
	**# did_imputation (Borusyak et al., 2024)
	* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
	* Only aw or iw are allowed; all weight types (aw\iw\fw\expand _weight) produce identical results.
	* Cohort identifiers: missing = never-treated.
	display "==================== did_imputation (Borusyak et al., 2024) ===================="
		* Without controls
		did_imputation forestloss pointid year sociobosque_year if cohort_year == 2011 [aweight = _weight], autosample fe(pointid year) cluster(cantonid)

	**# csdid (Callaway & Sant'Anna, 2021)
	* Only de jure iweights (de facto pweights) allowed.
	* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
	* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
	* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
	* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
	display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
		* Without controls
		csdid forestloss if cohort_year == 2011 [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
		estat event, window(-10 10) estore(cs_col_1_p)

	**# eventstudyinteract (Sun & Abraham, 2021)
	* The Absolute time indicators should take the value of zero for never treated units.
	* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
	* Cohort identifiers should be set to be missing for never treated units.
	display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
	gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
	gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
	forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
		gen F`i'event = (distyear == -`i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	forvalues i = 0/10 {
		gen L`i'event = (distyear == `i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
		
		* Without controls
		eventstudyinteract forestloss F*event L*event if cohort_year == 2011 [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster cantonid)
		estimates store sa_col_1_p
		matrix sa_col_1_p_b = e(b_iw)
		matrix sa_col_1_p_v = e(V_iw)
		ereturn post sa_col_1_p_b sa_col_1_p_v
		lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
		test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
		
	**# stackedev (Cengiz et al., 2019)
	* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
	* Cohort identifiers must be missing for never treated units.
	display "==================== stackedev (Cengiz et al., 2019) ===================="
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
		
		* Without controls
		stackedev forestloss P_* Q_* ref if cohort_year == 2011 [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(cantonid)
		estimates store stack_col_1_p
		matrix stack_col_1_p_b = e(b)	
		matrix stack_col_1_p_v = e(V)
		ereturn post stack_col_1_p_b stack_col_1_p_v
		lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
		test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

	**# TWFE: reghdfe
	display "==================== TWFE: reghdfe ===================="
	
	gen pre_10 = (distyear<= -10 & _treated==1)
	forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
		gen pre_`i'  = (distyear== -`i' & _treated==1) 
	}
	forv j = 0/10{
		gen post_`j' = (distyear == `j' & _treated==1)
	}
	replace post_10 = (distyear >= 10 & _treated==1)
	
		* Without controls
		reghdfe forestloss post if cohort_year == 2011 [fweight = _weight], nocons absorb(pointid year) vce(cluster cantonid)

		
**# 300_mdm_Never-treated_Collective_Absolute forest loss_sb+it+pa
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
	
	**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023)
	* Group and time fixed effects are automatically controlled for.
	display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023) ===================="
		* Without controls
		levelsof year_pa if cohort_year == 2010 //1970 1979
		did_multiplegt_dyn forestloss pointid year post if cohort_year == 2010, weight(_weight) effects(10) placebo(10)
		gen byte es = (cohort_year == 2010)
		dcdh_effect_export_rate, depvar(forestloss) postvar(post) samplevar(es)
		graph save "$results\eventstudy_dcdh_300_mdm_Never-treated_Absolute forest loss_Collective_sb+it+pa.gph", replace
		
// 		did_multiplegt_old forestloss pointid year post if cohort_year == 2010, ///
// 				robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
// 				longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
// 				count_switchers_contr count_switchers_tot ///
// 				trends_lin(canton_id) ///
// 				breps(50) seed(111) ///
// 				save_results("$results\Baseline_dcdh_300_mdm_Never-treated_Collective_Absolute forest loss_sb+it+pa.dta")

	**# did_imputation (Borusyak et al., 2024)
	* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
	* Only aw or iw are allowed; all weight types (aw\iw\fw\expand _weight) produce identical results.
	* Cohort identifiers: missing = never-treated.
	display "==================== did_imputation (Borusyak et al., 2024) ===================="
		* Without controls
		did_imputation forestloss pointid year sociobosque_year if cohort_year == 2010 [aweight = _weight], autosample fe(pointid year) cluster(cantonid)

	**# csdid (Callaway & Sant'Anna, 2021)
	* Only de jure iweights (de facto pweights) allowed.
	* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
	* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
	* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
	* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
	display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
		* Without controls
		csdid forestloss if cohort_year == 2010 [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
		estat event, window(-10 10) estore(cs_col_1_pi)
		
	**# eventstudyinteract (Sun & Abraham, 2021)
	* The Absolute time indicators should take the value of zero for never treated units.
	* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
	* Cohort identifiers should be set to be missing for never treated units.
	display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
	gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
	gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
	forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
		gen F`i'event = (distyear == -`i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	forvalues i = 0/10 {
		gen L`i'event = (distyear == `i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
		
		* Without controls
		eventstudyinteract forestloss F*event L*event if cohort_year == 2010 [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster cantonid)
		estimates store sa_col_1_pi
		matrix sa_col_1_pi_b = e(b_iw)
		matrix sa_col_1_pi_v = e(V_iw)
		ereturn post sa_col_1_pi_b sa_col_1_pi_v
		lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
		test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
		
	**# stackedev (Cengiz et al., 2019)
	* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
	* Cohort identifiers must be missing for never treated units.
	display "==================== stackedev (Cengiz et al., 2019) ===================="
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
	
		* Without controls
		stackedev forestloss P_* Q_* ref if cohort_year == 2010 [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(cantonid)
		estimates store stack_col_1_pi
		matrix stack_col_1_pi_b = e(b)	
		matrix stack_col_1_pi_v = e(V)
		ereturn post stack_col_1_pi_b stack_col_1_pi_v
		lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
		test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

	**# TWFE: reghdfe
	display "==================== TWFE: reghdfe ===================="
	
	gen pre_10 = (distyear<= -10 & _treated==1)
	forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
		gen pre_`i'  = (distyear== -`i' & _treated==1) 
	}
	forv j = 0/10{
		gen post_`j' = (distyear == `j' & _treated==1)
	}
	replace post_10 = (distyear >= 10 & _treated==1)
	
		* Without controls
		reghdfe forestloss post if cohort_year == 2010 [fweight = _weight], nocons absorb(pointid year) vce(cluster cantonid)

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb
	use "SBP_long_300_did_Individual_mdm_Never-treated_sb.dta", clear
	xtset panel_id year
	* Generate post, did, and distyear
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	gen did = _treated * post
	gen distyear = year - sociobosque_year
	egen cantonid_year = group(cantonid year), label
	gen canton_id = cantonid
	
	**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023)
	* Group and time fixed effects are automatically controlled for.
	display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023) ===================="
		* Without controls
		did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10) cluster(cantonid)
		dcdh_effect_export_rate, depvar(forestloss) postvar(post)
		graph save "$results\eventstudy_dcdh_300_mdm_Never-treated_Absolute forest loss_Individual_sb.gph", replace
// 		did_multiplegt_old forestloss pointid year post, ///
// 				robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
// 				longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
// 				count_switchers_contr count_switchers_tot ///
// 				trends_lin(canton_id) ///
// 				breps(50) seed(111) ///
// 				save_results("$results\Baseline\Baseline_dcdh_300_mdm_Never-treated_Individual_Absolute forest loss_sb.dta")
// 		matrix dcdh_ind_1_n_b = e(didmgt_estimates)
// 		matrix dcdh_ind_1_n_v = e(didmgt_variances)
// 		ereturn list
		
	**# did_imputation (Borusyak et al., 2024)
	* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
	* Only aw or iw are allowed; all weight types (aw\iw\fw\expand _weight) produce identical results.
	* Cohort identifiers: missing = never-treated.
	display "==================== did_imputation (Borusyak et al., 2024) ===================="
		* Without controls
		did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid year) cluster(cantonid)

	**# csdid (Callaway & Sant'Anna, 2021)
	* Only de jure iweights (de facto pweights) allowed.
	* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
	* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
	* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
	* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
	display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
		* Without controls
		csdid forestloss [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
		estat event, window(-10 10) estore(cs_ind_1_n)

	**# eventstudyinteract (Sun & Abraham, 2021)
	* The Absolute time indicators should take the value of zero for never treated units.
	* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
	* Cohort identifiers should be set to be missing for never treated units.
	display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
	gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
	gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
	forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
		gen F`i'event = (distyear == -`i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	forvalues i = 0/10 {
		gen L`i'event = (distyear == `i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
		
		* Without controls
		eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster cantonid)
		estimates store sa_ind_1_n
		matrix sa_ind_1_n_b = e(b_iw)
		matrix sa_ind_1_n_v = e(V_iw)
		ereturn post sa_ind_1_n_b sa_ind_1_n_v
		lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
		test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
		
	**# stackedev (Cengiz et al., 2019)
	* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
	* Cohort identifiers must be missing for never treated units.
	display "==================== stackedev (Cengiz et al., 2019) ===================="
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
		
		* Without controls
		stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(cantonid)
		estimates store stack_ind_1_n
		matrix stack_ind_1_n_b = e(b)	
		matrix stack_ind_1_n_v = e(V)
		ereturn post stack_ind_1_n_b stack_ind_1_n_v
		lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
		test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

	**# TWFE: reghdfe
	display "==================== TWFE: reghdfe ===================="
	
	gen pre_10 = (distyear<= -10 & _treated==1)
	forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
		gen pre_`i'  = (distyear== -`i' & _treated==1) 
	}
	forv j = 0/10{
		gen post_`j' = (distyear == `j' & _treated==1)
	}
	replace post_10 = (distyear >= 10 & _treated==1)
	
		* Without controls
		reghdfe forestloss post [fweight = _weight], nocons absorb(pointid year) vce(cluster cantonid)

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb+it
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
	
	**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023)
	* Group and time fixed effects are automatically controlled for.
	display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023) ===================="
		* Without controls
		did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10)
		dcdh_effect_export_rate, depvar(forestloss) postvar(post)
		graph save "$results\eventstudy_dcdh_300_mdm_Never-treated_Absolute forest loss_Individual_sb+it.gph", replace
// 		did_multiplegt_old forestloss pointid year post, ///
// 				robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
// 				longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
// 				count_switchers_contr count_switchers_tot ///
// 				trends_lin(canton_id) ///
// 				breps(50) seed(111) ///
// 				save_results("$results\Baseline\Baseline_dcdh_300_mdm_Never-treated_Individual_Absolute forest loss_sb+it.dta")
// 		matrix dcdh_ind_1_i_b = e(didmgt_estimates)
// 		matrix dcdh_ind_1_i_v = e(didmgt_variances)
// 		ereturn list
		
	**# did_imputation (Borusyak et al., 2024)
	* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
	* Only aw or iw are allowed; all weight types (aw\iw\fw\expand _weight) produce identical results.
	* Cohort identifiers: missing = never-treated.
	display "==================== did_imputation (Borusyak et al., 2024) ===================="
		* Without controls
		did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid year) cluster(cantonid)

	**# csdid (Callaway & Sant'Anna, 2021)
	* Only de jure iweights (de facto pweights) allowed.
	* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
	* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
	* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
	* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
	display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
		* Without controls
		csdid forestloss [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
		estat event, window(-10 10) estore(cs_ind_1_i)

	**# eventstudyinteract (Sun & Abraham, 2021)
	* The Absolute time indicators should take the value of zero for never treated units.
	* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
	* Cohort identifiers should be set to be missing for never treated units.
	display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
	gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
	gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
	forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
		gen F`i'event = (distyear == -`i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	forvalues i = 0/10 {
		gen L`i'event = (distyear == `i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
		
		* Without controls
		eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster cantonid)
		estimates store sa_ind_1_i
		matrix sa_ind_1_i_b = e(b_iw)
		matrix sa_ind_1_i_v = e(V_iw)
		ereturn post sa_ind_1_i_b sa_ind_1_i_v
		lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
		test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
		
	**# stackedev (Cengiz et al., 2019)
	* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
	* Cohort identifiers must be missing for never treated units.
	display "==================== stackedev (Cengiz et al., 2019) ===================="
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
		
		* Without controls
		stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(cantonid)
		estimates store stack_ind_1_i
		matrix stack_ind_1_i_b = e(b)	
		matrix stack_ind_1_i_v = e(V)
		ereturn post stack_ind_1_i_b stack_ind_1_i_v
		lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
		test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

	**# TWFE: reghdfe
	display "==================== TWFE: reghdfe ===================="
	
	gen pre_10 = (distyear<= -10 & _treated==1)
	forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
		gen pre_`i'  = (distyear== -`i' & _treated==1) 
	}
	forv j = 0/10{
		gen post_`j' = (distyear == `j' & _treated==1)
	}
	replace post_10 = (distyear >= 10 & _treated==1)
	
		* Without controls
		reghdfe forestloss post [fweight = _weight], nocons absorb(pointid year) vce(cluster cantonid)

**# 300_mdm_Never-treated_Individual_Absolute forest loss_sb+pa
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
	
	**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023)
	* Group and time fixed effects are automatically controlled for.
	display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2023) ===================="
		* Without controls
		levelsof cohort_year
		did_multiplegt_dyn forestloss pointid year post, weight(_weight) effects(10) placebo(10)
		dcdh_effect_export_rate, depvar(forestloss) postvar(post)
		graph save "$results\eventstudy_dcdh_300_mdm_Never-treated_Absolute forest loss_Individual_sb+pa.gph", replace
		did_multiplegt_old forestloss pointid year post, ///
				robust_dynamic weight(_weight) dynamic(10) placebo(9) ///
				longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
				count_switchers_contr count_switchers_tot ///
				trends_lin(canton_id) ///
				breps(50) seed(111) ///
				if_first_diff(fd_post_pa==0) trends_nonparam(post_pa) always_trends_nonparam ///
				save_results("$results\Baseline_dcdh_300_mdm_Never-treated_Individual_Absolute forest loss_sb+pa.dta") // fd_post_pa not found r(111);
		
	**# did_imputation (Borusyak et al., 2024)
	* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
	* Only aw or iw are allowed; all weight types (aw\iw\fw\expand _weight) produce identical results.
	* Cohort identifiers: missing = never-treated.
	display "==================== did_imputation (Borusyak et al., 2024) ===================="
		* Without controls
		did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid year) cluster(cantonid)

	**# csdid (Callaway & Sant'Anna, 2021)
	* Only de jure iweights (de facto pweights) allowed.
	* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
	* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
	* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
	* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
	display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
		* Without controls
		csdid forestloss [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
		estat event, window(-10 10) estore(cs_ind_1_p)
// 		matrix cs_ind_1_p_b = e(b)
// 		matrix cs_ind_1_p_v = e(V)

	**# eventstudyinteract (Sun & Abraham, 2021)
	* The Absolute time indicators should take the value of zero for never treated units.
	* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
	* Cohort identifiers should be set to be missing for never treated units.
	display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
		gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
	gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
	forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
		gen F`i'event = (distyear == -`i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	forvalues i = 0/10 {
		gen L`i'event = (distyear == `i' & _treated == 1) // The Absolute time indicators should take the value of zero for never treated units.
	}
	replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
		
		* Without controls
		eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid year) vce(cluster cantonid)
		estimates store sa_ind_1_p
		matrix sa_ind_1_p_b = e(b_iw)
		matrix sa_ind_1_p_v = e(V_iw)
		ereturn post sa_ind_1_p_b sa_ind_1_p_v
		lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
		test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
		
	**# stackedev (Cengiz et al., 2019)
	* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
	* Cohort identifiers must be missing for never treated units.
	display "==================== stackedev (Cengiz et al., 2019) ===================="
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
		
		* Without controls
		stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) clust_unit(cantonid)
		estimates store stack_ind_1_p
		matrix stack_ind_1_p_b = e(b)	
		matrix stack_ind_1_p_v = e(V)
		ereturn post stack_ind_1_p_b stack_ind_1_p_v
		lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
		test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

	**# TWFE: reghdfe
	display "==================== TWFE: reghdfe ===================="
	
	gen pre_10 = (distyear<= -10 & _treated==1)
	forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
		gen pre_`i'  = (distyear== -`i' & _treated==1) 
	}
	forv j = 0/10{
		gen post_`j' = (distyear == `j' & _treated==1)
	}
	replace post_10 = (distyear >= 10 & _treated==1)
	
		* Without controls
		reghdfe forestloss post [fweight = _weight], nocons absorb(pointid year) vce(cluster cantonid)

// Mannually copy data from windows to "$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`policy_bundle'.dta"

* Visualization
// local i 1
// foreach cgroup of global control_groups {
// 	local cgroup_label: word `i' of ${control_groups_labels}
//	
// 	local j 1
// 	foreach depvar of global depvars {
// 		local depvar_label: word `j' of ${depvars_labels}
//		
// 		local k 1
// 		foreach ttype of global treatment_types {
// 			local ttype_label: word `k' of ${treatment_types_labels}					
// 			local l 1
// 			foreach policy_bundle of global policy_bundles {
// 				local policy_bundle_label: word `l' of ${policy_bundles_labels}
// 				local pb: word `l' of ${pbs}
// 				local panel1: word `l' of ${panels1}
//					
// 				use "$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta", clear
//
// 				encode type, gen(typeid)
// 				levelsof typeid, local(xaxisid)
// 				foreach xaxis_label of local xaxisid {
// 					local current_label_text: label (typeid) `xaxis_label'
// 					local xlabels `"`xlabels' `xaxis_label' `"`current_label_text'"'"'
// 				}
// 				gen x_twfe			= typeid - 0.25
// 				gen x_imputation	= typeid - 0.15
// 				gen x_cs			= typeid - 0.05
// 				gen x_sa			= typeid + 0.05
// 				gen x_stack			= typeid + 0.15
// 				gen x_multiplegt	= typeid + 0.25
//				
// 				twoway ///
// 					(scatter x_twfe coef if estimator == "TWFE", msymbol(O) mcolor(cranberry) msize(medium)) ///
// 					(rcap ci_upper ci_lower x_twfe if estimator == "TWFE", vertical lcolor(cranberry) lwidth(medium)) ///
// 					(scatter x_imputation coef if estimator == "Borusyak et al. (2024)", msymbol(D) mcolor(purple) msize(medium)) ///
// 					(rcap ci_upper ci_lower x_imputation if estimator == "Borusyak et al. (2024)", vertical lcolor(purple) lwidth(medium)) ///
// 					(scatter x_cs coef if estimator == "Callaway & Sant'Anna (2021)", msymbol(S) mcolor(blue) msize(medium)) ///
// 					(rcap ci_upper ci_lower x_cs if estimator == "Callaway & Sant'Anna (2021)", vertical lcolor(blue) lwidth(medium)) ///
// 					(scatter x_sa coef if estimator == "Sun & Abraham (2021)", msymbol(T) mcolor(dkorange) msize(medium)) ///
// 					(rcap ci_upper ci_lower x_sa if estimator == "Sun & Abraham (2021)", vertical lcolor(dkorange) lwidth(medium)) ///
// 					(scatter x_stack coef if estimator == "Cengiz et al. (2019)", msymbol(+) mcolor(green) msize(medium)) ///
// 					(rcap ci_upper ci_lower x_stack if estimator == "Cengiz et al. (2019)", vertical lcolor(green) lwidth(medium)) ///
// 					(scatter x_multiplegt coef if estimator == "de Chaisemartin & d'Haultfoeuille (2023)", msymbol(X) mcolor(pink) msize(medium)) ///
// 					(rcap ci_upper ci_lower x_multiplegt if estimator == "de Chaisemartin & d'Haultfoeuille (2023)", vertical lcolor(pink) lwidth(medium)) ///
// 					, ///
// 					xlabel(`xlabels', angle(0) labsize(small) noticks) ///
// 					xtitle("") ///
// 					xscale(reverse) ///
// 					ylabel(-0.15(0.05)0.10, format(%4.2f)) ///
// 					ytitle("Estimate of Overall ATT and 95% Conf. Int.") ///
// 					yline(0, lpattern(dash) lcolor(black)) ///
// 					legend(order(1 "TWFE"				3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
// 								7 "Sun & Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2023)") ///
// 							size(*0.5) rows(2) pos(6)) ///
// 					graphregion(color(white)) ///
// 					title((`panel1') `policy_bundle_label')
// 				graph save "$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.gph", replace
// 				local l = `l' + 1
// 			}
// 			local k = `k' + 1
// 		}
// 		local j = `j' + 1
// 	}
// 	local i = `i' + 1
// }

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
				local panel1: word `l' of ${panels1}
				
				use "$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.dta", clear
				
				encode type, gen(typeid)
				levelsof typeid, local(yaxisid)
				foreach yaxis_label of local yaxisid {
					local current_label_text: label (typeid) `yaxis_label'
					local ylabels `"`ylabels' `yaxis_label' `"`current_label_text'"'"'
				}
				gen y_twfe			= typeid - 0.25
				gen y_imputation	= typeid - 0.15
				gen y_cs			= typeid - 0.05
				gen y_sa			= typeid + 0.05
				gen y_stack			= typeid + 0.15
				gen y_multiplegt	= typeid + 0.25

				twoway ///
					(scatter y_twfe coef if estimator == "TWFE", msymbol(O) mcolor(cranberry) msize(medium)) ///
					(rcap ci_upper ci_lower y_twfe if estimator == "TWFE", horizontal lcolor(cranberry) lwidth(medium)) ///
					(scatter y_imputation coef if estimator == "Borusyak et al. (2024)", msymbol(D) mcolor(purple) msize(medium)) ///
					(rcap ci_upper ci_lower y_imputation if estimator == "Borusyak et al. (2024)", horizontal lcolor(purple) lwidth(medium)) ///
					(scatter y_cs coef if estimator == "Callaway & Sant'Anna (2021)", msymbol(S) mcolor(blue) msize(medium)) ///
					(rcap ci_upper ci_lower y_cs if estimator == "Callaway & Sant'Anna (2021)", horizontal lcolor(blue) lwidth(medium)) ///
					(scatter y_sa coef if estimator == "Sun & Abraham (2021)", msymbol(T) mcolor(dkorange) msize(medium)) ///
					(rcap ci_upper ci_lower y_sa if estimator == "Sun & Abraham (2021)", horizontal lcolor(dkorange) lwidth(medium)) ///
					(scatter y_stack coef if estimator == "Cengiz et al. (2019)", msymbol(+) mcolor(green) msize(medium)) ///
					(rcap ci_upper ci_lower y_stack if estimator == "Cengiz et al. (2019)", horizontal lcolor(green) lwidth(medium)) ///
					(scatter y_multiplegt coef if estimator == "de Chaisemartin and d'Haultfoeuille (2023)", msymbol(X) mcolor(pink) msize(medium)) ///
					(rcap ci_upper ci_lower y_multiplegt if estimator == "de Chaisemartin and d'Haultfoeuille (2023)", horizontal lcolor(pink) lwidth(medium)) ///
					, ///
					ylabel(`ylabels', angle(0) labsize(small) noticks) ///
					ytitle("") ///
					yscale(reverse) ///
					xlabel(-0.15(0.05)0.10, format(%4.2f)) ///
					xtitle("Estimate of ATT and 95% Conf. Int.") ///
					xline(0, lpattern(dash) lcolor(black)) ///
					legend(order(1 "TWFE"				3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
								7 "Sun & Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2023)") ///
							rows(2) pos(6)) ///
					graphregion(color(white)) ///
					title((`panel1') `policy_bundle_label')
				graph save "$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_`policy_bundle'.gph", replace
				
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
		
		grc1leg	"$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_sb.gph" ///
				"$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_sb+pa.gph" ///
				"$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_sb+it.gph" ///
				"$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'_sb+it+pa.gph", ///
				rows(1) cols(4)
		graph save "$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'.gph", replace
		graph export "$dir_estimators\Overall ATT_Estimators_mdm_`cgroup_label'_`depvar_label'.png", as(png) replace width(6000) height(2500)
		
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

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	local j 1
	foreach depvar of global depvars {
		local depvar_label: word `j' of ${depvars_labels}
		
		local k 1
		foreach ttype of global treatment_types {
			local ttype_label: word `k' of ${treatment_types_labels}
			local resolution: word `k' of ${resolutions}
			
			local l 1
			foreach policy_bundle of global policy_bundles {
				local policy_bundle_label: word `l' of ${policy_bundles_labels}
				local pb: word `l' of ${pbs}
					
				use "$results\Baseline_dcdh_`resolution'_mdm_`cgroup_label'_`ttype_label'_`depvar_label'_`policy_bundle'.dta", clear
				gen z = abs(e(Av_tot_effect) / e(se_avg_total_effect))
				gen p = 2 * (1 - normal(z))
				gen significance = ""
				replace significance = "***" if p < 0.01
				replace significance = "**"  if p >= 0.01 & p < 0.05
				replace significance = "*"   if p >= 0.05 & p < 0.1
				save "$results\Baseline_dcdh_`resolution'_mdm_`cgroup_label'_`ttype_label'_`depvar_label'_`policy_bundle'.dta", replace
					
				local l = `l' + 1
			}
			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}
