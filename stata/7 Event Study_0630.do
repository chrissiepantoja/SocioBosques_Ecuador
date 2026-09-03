
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Event Study
*Country: Ecuador
*==============================================================================*

*--------------------------------------------
* Event Study
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

* Heterogeneity-Robust TWFE (Wooldridge, 2021; Correia, 2017): allowing for a flexible specification of the $\theta_{g,t}$ avoids the problem of bad controls and negative weights that have been identified in the literature as potential problems in the estimation of DID models using traditional TWFE estimators.
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

* did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
* de Chaisemartin, C. and d'Haultfoeuille, X., 2024. Difference-in-differences estimators of intertemporal treatment effects. Review of Economics and Statistics, pp.1-45.
* de Chaisemartin, C. and d'Haultfoeuille, X., 2020. Two-way fixed effects estimators with heterogeneous treatment effects. American Economic Review, 110(9), pp.2964-2996.
* de Chaisemartin, C. and d'Haultfoeuille, X., 2023. Two-way fixed effects and differences-in-differences with heterogeneous treatment effects: A survey. The Econometrics Journal, 26(3), pp.C1-C30.
* https://cran.r-project.org/web/packages/DIDmultiplegtDYN/DIDmultiplegtDYN.pdf
* Jia, W., Xie, R., Ma, C., Gong, Z. and Wang, H., 2024. Environmental regulation and firms' emission reduction–The policy of eliminating backward production capacity as a quasi-natural experiment. Energy Economics, 130, p.107271.

* stackedev (Cengiz et al., 2019)
* Cengiz, D., Dube, A., Lindner, A. and Zipperer, B., 2019. The effect of minimum wages on low-wage jobs. The Quarterly Journal of Economics, 134(3), pp.1405-1454.
* Appends together individual datasets or stacks. Each stack includes all observations from a cohort o that receive treatment in the same time period and all units that never received treatment. Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units. That approach avoids erroneous compari late to early implementing units that may bias Two-Way Fixed Effects (TWFE) estimates if effects vary across treated cohorts (Goodman-Bacon, 2021).

clear all
set more off, perm

global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
cd "$dir\Data\SBP_data\annual"

/*
global control_groups			"never notyet"
global control_groups_labels	`""Never-treated" "Not-yet-treated""'
*/

global control_groups			"never"
global control_groups_labels	`""Never-treated""'

global depvars			"forestloss"
global depvars_labels	`""Absolute forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'

global policy_bundles			`""none" "indigenous" "pa" "pa & indigenous""'
global policy_bundles_labels	`""SB only" "SB + IT" "SB + PA" "SB + IT + PA""'
global pbs						`""n" "i" "p" "pi""'

global panels "a b c d"

set maxvar 120000 // For did2s (Gardner, 2021)

				use "SBP_long_did_Collective_mdm_Never-treated_none_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn forestloss pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_col_1_n
					matrix dcdh_col_1_n_b = e(b)
					matrix dcdh_col_1_n_v = e(V)
				
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_col_1_n
// 					matrix imput_col_1_n_b = e(b)
// 					matrix imput_col_1_n_v = e(V)

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid forestloss i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
					estat event, window(-10 10) estore(cs_col_1_n)
// 					matrix cs_col_1_n_b = e(b)
// 					matrix cs_col_1_n_v = e(V)

				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_col_1_n
					matrix sa_col_1_n_b = e(b_iw)
					matrix sa_col_1_n_v = e(V_iw)
					
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
					stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_col_1_n
// 					matrix stack_col_1_n_b = e(b)				
// 					matrix stack_col_1_n_v = e(V)
// 					ereturn post stack_col_1_n_b stack_col_1_n_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe forestloss pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_col_1_n
// 					matrix reghdfe_col_1_n_b = e(b)
// 					matrix reghdfe_col_1_n_v = e(V)
					
				color_style egypt, n(6)
				event_plot reghdfe_col_1_n imput_col_1_n cs_col_1_n sa_col_1_n_b#sa_col_1_n_v stack_col_1_n dcdh_col_1_n_b#dcdh_col_1_n_v, ///
				stub_lag(post_#		tau#	Tp#	L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#	F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(a) SBP only", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
										7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(4) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
 					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_Never-treated_Absolute forest loss_Collective_none.gph", replace


				use "SBP_long_did_Collective_mdm_Never-treated_indigenous_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn forestloss pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_col_1_i
					matrix dcdh_col_1_i_b = e(b)
					matrix dcdh_col_1_i_v = e(V)
				
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_col_1_i
// 					matrix imput_col_1_i_b = e(b)
// 					matrix imput_col_1_i_v = e(V)

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid forestloss i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
					estat event, window(-10 10) estore(cs_col_1_i)
// 					matrix cs_col_1_i_b = e(b)
// 					matrix cs_col_1_i_v = e(V)

				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_col_1_i
					matrix sa_col_1_i_b = e(b_iw)
					matrix sa_col_1_i_v = e(V_iw)
					
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
					stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_col_1_i
// 					matrix stack_col_1_i_b = e(b)				
// 					matrix stack_col_1_i_v = e(V)
// 					ereturn post stack_col_1_i_b stack_col_1_i_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe forestloss pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_col_1_i
// 					matrix reghdfe_col_1_i_b = e(b)
// 					matrix reghdfe_col_1_i_v = e(V)
					
				color_style egypt, n(6)
				event_plot reghdfe_col_1_i imput_col_1_i cs_col_1_i sa_col_1_i_b#sa_col_1_i_v stack_col_1_i dcdh_col_1_i_b#dcdh_col_1_i_v, ///
				stub_lag(post_#		tau#	Tp#	L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#	F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(b) SBP + ITs", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
									  7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(4) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
 					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_Never-treated_Absolute forest loss_Collective_indigenous.gph", replace


				use "SBP_long_did_Collective_mdm_Never-treated_pa_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn forestloss pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_col_1_p
					matrix dcdh_col_1_p_b = e(b)
					matrix dcdh_col_1_p_v = e(V)
				
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_col_1_p
// 					matrix imput_col_1_p_b = e(b)
// 					matrix imput_col_1_p_v = e(V)

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid forestloss i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
					estat event, window(-10 10) estore(cs_col_1_p)
// 					matrix cs_col_1_p_b = e(b)
// 					matrix cs_col_1_p_v = e(V)

				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_col_1_p
					matrix sa_col_1_p_b = e(b_iw)
					matrix sa_col_1_p_v = e(V_iw)
					
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
					stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_col_1_p
// 					matrix stack_col_1_p_b = e(b)				
// 					matrix stack_col_1_p_v = e(V)
// 					ereturn post stack_col_1_p_b stack_col_1_p_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe forestloss pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_col_1_p
// 					matrix reghdfe_col_1_p_b = e(b)
// 					matrix reghdfe_col_1_p_v = e(V)
					
				color_style egypt, n(6)
				event_plot reghdfe_col_1_p imput_col_1_p cs_col_1_p sa_col_1_p_b#sa_col_1_p_v stack_col_1_p dcdh_col_1_p_b#dcdh_col_1_p_v, ///
				stub_lag(post_#		tau#	Tp#	L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#	F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(b) SBP + ITs", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
										7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(4) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
 					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_Never-treated_Absolute forest loss_Collective_pa.gph", replace

				use "SBP_long_did_Collective_mdm_Never-treated_pa & indigenous_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn forestloss pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_col_1_pi
					matrix dcdh_col_1_pi_b = e(b)
					matrix dcdh_col_1_pi_v = e(V)
				
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_col_1_pi
// 					matrix imput_col_1_pi_b = e(b)
// 					matrix imput_col_1_pi_v = e(V)

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid forestloss i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
					estat event, window(-10 10) estore(cs_col_1_pi)
// 					matrix cs_col_1_pi_b = e(b)
// 					matrix cs_col_1_pi_v = e(V)

				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_col_1_pi
					matrix sa_col_1_pi_b = e(b_iw)
					matrix sa_col_1_pi_v = e(V_iw)
					
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
					stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_col_1_pi
// 					matrix stack_col_1_pi_b = e(b)				
// 					matrix stack_col_1_pi_v = e(V)
// 					ereturn post stack_col_1_pi_b stack_col_1_pi_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe forestloss pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_col_1_pi
// 					matrix reghdfe_col_1_pi_b = e(b)
// 					matrix reghdfe_col_1_pi_v = e(V)
					
				color_style egypt, n(6)
				event_plot reghdfe_col_1_pi imput_col_1_pi cs_col_1_pi sa_col_1_pi_b#sa_col_1_pi_v stack_col_1_pi dcdh_col_1_pi_b#dcdh_col_1_pi_v, ///
				stub_lag(post_#		tau#	Tp#	L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#	F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(b) SBP + ITs", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
										7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(4) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
 					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_Never-treated_Absolute forest loss_Collective_pa & indigenous.gph", replace

				use "SBP_long_did_Individual_mdm_Never-treated_none_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn forestloss pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_ind_1_n
					matrix dcdh_ind_1_n_b = e(b)
					matrix dcdh_ind_1_n_v = e(V)
				
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_ind_1_n
// 					matrix imput_ind_1_n_b = e(b)
// 					matrix imput_ind_1_n_v = e(V)

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid forestloss i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
					estat event, window(-10 10) estore(cs_ind_1_n)
// 					matrix cs_ind_1_n_b = e(b)
// 					matrix cs_ind_1_n_v = e(V)

				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_ind_1_n
					matrix sa_ind_1_n_b = e(b_iw)
					matrix sa_ind_1_n_v = e(V_iw)
					
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
					stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_ind_1_n
// 					matrix stack_ind_1_n_b = e(b)				
// 					matrix stack_ind_1_n_v = e(V)
// 					ereturn post stack_ind_1_n_b stack_ind_1_n_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe forestloss pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_ind_1_n
// 					matrix reghdfe_ind_1_n_b = e(b)
// 					matrix reghdfe_ind_1_n_v = e(V)
					
				color_style egypt, n(6)
				event_plot reghdfe_ind_1_n imput_ind_1_n cs_ind_1_n sa_ind_1_n_b#sa_ind_1_n_v stack_ind_1_n dcdh_ind_1_n_b#dcdh_ind_1_n_v, ///
				stub_lag(post_#		tau#	Tp#	L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#	F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(a) SBP only", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
										7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(4) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
 					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_Never-treated_Absolute forest loss_Individual_none.gph", replace


				use "SBP_long_did_Individual_mdm_Never-treated_indigenous_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn forestloss pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_ind_1_i
					matrix dcdh_ind_1_i_b = e(b)
					matrix dcdh_ind_1_i_v = e(V)
				
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_ind_1_i
// 					matrix imput_ind_1_i_b = e(b)
// 					matrix imput_ind_1_i_v = e(V)

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid forestloss i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
					estat event, window(-10 10) estore(cs_ind_1_i)
// 					matrix cs_ind_1_i_b = e(b)
// 					matrix cs_ind_1_i_v = e(V)

				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_ind_1_i
					matrix sa_ind_1_i_b = e(b_iw)
					matrix sa_ind_1_i_v = e(V_iw)
					
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
					stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_ind_1_i
// 					matrix stack_ind_1_i_b = e(b)				
// 					matrix stack_ind_1_i_v = e(V)
// 					ereturn post stack_ind_1_i_b stack_ind_1_i_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe forestloss pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_ind_1_i
// 					matrix reghdfe_ind_1_i_b = e(b)
// 					matrix reghdfe_ind_1_i_v = e(V)
					
				color_style egypt, n(6)
				event_plot reghdfe_ind_1_i imput_ind_1_i cs_ind_1_i sa_ind_1_i_b#sa_ind_1_i_v stack_ind_1_i dcdh_ind_1_i_b#dcdh_ind_1_i_v, ///
				stub_lag(post_#		tau#	Tp#	L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#	F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(b) SBP + ITs", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
										7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(4) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
 					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_Never-treated_Absolute forest loss_Individual_indigenous.gph", replace


				use "SBP_long_did_Individual_mdm_Never-treated_pa_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn forestloss pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_ind_1_p
					matrix dcdh_ind_1_p_b = e(b)
					matrix dcdh_ind_1_p_v = e(V)
				
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation forestloss pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_ind_1_p
// 					matrix imput_ind_1_p_b = e(b)
// 					matrix imput_ind_1_p_v = e(V)

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid forestloss i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2
					estat event, window(-10 10) estore(cs_ind_1_p)
// 					matrix cs_ind_1_p_b = e(b)
// 					matrix cs_ind_1_p_v = e(V)

				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				gen F10event = (distyear <= -10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 { // Virtual interactions of distyear == -1 with the treated group should be discarded to avoid omit issues
					gen F`i'event = (distyear == -`i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				forvalues i = 0/10 {
					gen L`i'event = (distyear == `i' & _treated == 1) // The relative time indicators should take the value of zero for never treated units.
				}
				replace L10event = (distyear >= 10 & _treated == 1) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					eventstudyinteract forestloss F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_ind_1_p
					matrix sa_ind_1_p_b = e(b_iw)
					matrix sa_ind_1_p_v = e(V_iw)
					
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
					stackedev forestloss P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_ind_1_p
// 					matrix stack_ind_1_p_b = e(b)				
// 					matrix stack_ind_1_p_v = e(V)
// 					ereturn post stack_ind_1_p_b stack_ind_1_p_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe forestloss pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_ind_1_p
// 					matrix reghdfe_ind_1_p_b = e(b)
// 					matrix reghdfe_ind_1_p_v = e(V)
					
				color_style egypt, n(6)
				event_plot reghdfe_ind_1_p imput_ind_1_p cs_ind_1_p sa_ind_1_p_b#sa_ind_1_p_v stack_ind_1_p dcdh_ind_1_p_b#dcdh_ind_1_p_v, ///
				stub_lag(post_#		tau#	Tp#	L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#	F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(b) SBP + ITs", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	 5 "Callaway & Sant'Anna (2021)" ///
										7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(4) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
 					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_Never-treated_Absolute forest loss_Individual_pa.gph", replace










































































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
				
				di "Estimating: `cgroup_label' | `depvar_label' | `ttype_label' | `policy_bundle_label'"
				if "`ttype'" == "ind" & "`policy_bundle'" == "pa & indigenous" {
					di in red "No treated units. Skipping."
					restore
					exit
				}
				
				use "SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'_bbb.dta", clear
				xtset panel_id year
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				egen cantonid_year = group(cantonid year), label
				
				**# did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020)
				* Group and time fixed effects are automatically controlled for.
				display "==================== did_multiplegt (de Chaisemartin and d'Haultfoeuille, 2020) ===================="
				gen canton_id = cantonid
					* Without controls
					did_multiplegt_dyn `depvar' pointid year post, weight(_weight) normalized normalized_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year) // trends_nonparam(canton_id) //parallel trends and no anticipation assumptions tests will fail if included!
					estimates store dcdh_`ttype'_`j'_`pb'
					matrix dcdh_`ttype'_`j'_`pb'_b = e(b)
					matrix dcdh_`ttype'_`j'_`pb'_v = e(V)
					
/*
					* With controls
					did_multiplegt_dyn `depvar' pointid year post, weight(_weight) normalized normalized_weights normalized normalized_weights_weights effects(10) placebo(10) cluster(cantonid) controls(cantonid_year $cv) // trends_nonparam(canton_id) // parallel trends and no anticipation assumptions tests will fail!
					estimates store dcdh_`ttype'_cv_`j'_`pb'
					matrix dcdh_`ttype'_`j'_`pb'_b = e(b)
					matrix dcdh_`ttype'_`j'_`pb'_v = e(V)
*/
				**# did_imputation (Borusyak et al., 2024)
				* Regardless of whether the pre-trend test is performed, the reference group for estimation is always all pre-treatment (or never-treated) observations.
				* Only aw or iw are allowed; all weight types (aw/iw/fw/expand _weight) produce identical results.
				* Cohort identifiers: missing = never-treated.
					display "==================== did_imputation (Borusyak et al., 2024) ===================="
					* Without controls
					did_imputation `depvar' pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10)
					estimates store imput_`ttype'_`j'_`pb'
					
/*
					* With controls
					did_imputation `depvar' pointid year sociobosque_year [aweight = _weight], autosample fe(pointid cantonid#year) cluster(cantonid) pretrends(10) horizons(0/10) controls($cv)
					estimates store imput_`ttype'_cv_`j'_`pb'
*/

				**# csdid (Callaway & Sant'Anna, 2021)
				* Only de jure iweights (de facto pweights) allowed.
				* The default is using never treated only. If there are no never treated observations, notyet is used automatically.
				* Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated.
				* method(drimp): Sant'Anna and Zhao (2020) Improved doubly robust DiD estimator based on inverse probability of tilting and weighted least squares.
				* wboot: Request Estimation of Standard errors using a multiplicative WildBootstrap procedure. The default uses 999 repetitions using mammen approach.
				display "==================== csdid (Callaway & Sant'Anna, 2021) ===================="			
					* Without controls
					csdid `depvar' i.cantonid_year [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(event) cluster(cantonid) long2 `= cond("`cgroup'"=="notyet", "notyet", "")'
					estat event, window(-10 10) estore(cs_`ttype'_`j'_`pb')
					
/*
					* With controls
					csdid `depvar' cantonid_year $cv [iweight = _weight], i(pointid) t(year) gvar(first_treat) method(drimp) agg(simple) cluster(cantonid) long2 `= cond("`cgroup'"=="notyet", "notyet", "")'
					estat event, window(-10 10) estore(csdid_`ttype'_cv_`j'_`pb')
*/
					
					
/*
				**# did2s (Gardner, 2021)
				display "==================== did2s (Gardner, 2021) ===================="
				gen M_10 = (distyear <= -10) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
				forvalues i = 9(-1)2 {
					gen M_`i' = (distyear == -`i')
				}
				forvalues i = 0/10 {
					gen N_`i' = (distyear == `i')
				}
				replace N_10 = (distyear >= 10) // Leave out the distant leads due to few observations. Implicitly this assumes that effects outside the lead windows are zero.
					
					* Without controls
					did2s `depvar' [fweight = _weight], first_stage(i.pointid i.cantonid#i.year) second_stage(M_* N_*) treatment(post) cluster(cantonid)
					estimates store did2s_`ttype'_`j'_`pb'
					
					* With controls
					did2s `depvar' [fweight = _weight], first_stage(i.pointid i.cantonid#i.year $cv) second_stage(M_* N_*) treatment(post) cluster(cantonid)
					estimates store did2s_`ttype'_cv_`j'_`pb'
*/
				
				**# eventstudyinteract (Sun & Abraham, 2021)
				* The relative time indicators should take the value of zero for never treated units.
				* Sun and Abraham (2021) only establishes the validity of the interaction weighted (IW) estimators for balanced panel data without covariates.
				* Cohort identifiers should be set to be missing for never treated units.
				display "==================== eventstudyinteract (Sun & Abraham, 2021) ===================="
				if "`cgroup'" == "never" {
					gen control_cohort = (missing(sociobosque_year)) // Never-treated unit as control cohort
				}
				if "`cgroup'" == "notyet" {
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
					
					* Without controls
					eventstudyinteract `depvar' F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store sa_`ttype'_`j'_`pb'
					matrix sa_`ttype'_`j'_`pb'_b = e(b_iw)
					matrix sa_`ttype'_`j'_`pb'_v = e(V_iw)
// 					ereturn post sa_`ttype'_`j'_`pb'_b sa_`ttype'_`j'_`pb'_v
// 					lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
// 					test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)					
/*
					* With controls
					eventstudyinteract `depvar' F*event L*event [fweight = _weight], cohort(sociobosque_year) control_cohort(control_cohort) absorb(pointid cantonid#year) vce(cluster cantonid) covariates($cv)
					estimates store eventstudy_`ttype'_cv_`j'_`pb'
					matrix event_`ttype'_cv_`j'_`pb'_b = e(b_iw)
					matrix event_`ttype'_cv_`j'_`pb'_v = e(V_iw)
					ereturn post event_`ttype'_cv_`j'_`pb'_b event_`ttype'_cv_`j'_`pb'_v
					lincom (L0event + L1event + L2event + L3event + L4event + L5event + L6event + L7event + L8event + L9event + L10event)/11
					test (F10event=0) (F9event=0) (F8event=0) (F7event=0) (F6event=0) (F5event=0) (F4event=0) (F3event=0) (F2event=0)
*/
					
				**# stackedev (Cengiz et al., 2019)
				* Effects are identified within each stack by comparing an individual cohort of treated units to never-treated units.
				* Cohort identifiers must be missing for never treated units.
				display "==================== stackedev (Cengiz et al., 2019) ===================="
				if "`cgroup'" == "never" {
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
					stackedev `depvar' P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid)
					estimates store stack_`ttype'_`j'_`pb'
// 					matrix stack_`ttype'_never_cv_`j'_`pb'_b = e(b)
// 					matrix stack_`ttype'_never_cv_`j'_`pb'_v = e(V)
// 					ereturn post stack_`ttype'_`j'_`pb'_b stack_`ttype'_`j'_`pb'_v
// 					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
// 					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)
					
/*
					* With controls
					stackedev `depvar' P_* Q_* ref [fweight = _weight], cohort(sociobosque_year) time(year) never_treat(control_cohort) unit_fe(pointid) other_fe(cantonid#year) clust_unit(cantonid) covariates($cv)
					estimates store stack_`ttype'_never_cv_`j'_`pb'
					matrix stack_`ttype'_never_cv_`j'_`pb'_b = e(b)
					matrix stack_`ttype'_never_cv_`j'_`pb'_v = e(V)
					ereturn post stack_`ttype'_cv_`j'_`pb'_b stack_`ttype'_cv_`j'_`pb'_v
					lincom (Q_0 + Q_1 + Q_2 + Q_3 + Q_4 + Q_5 + Q_6 + Q_7 + Q_8 + Q_9 + Q_10)/11
					test (P_10=0) (P_9=0) (P_8=0) (P_7=0) (P_6=0) (P_5=0) (P_4=0) (P_3=0) (P_2=0)
*/
				}
				
/*
				**# Heterogeneity-Robust TWFE (wooldid) (Wooldridge, 2021)
				* Cohort identifier must consist of positive, non-zero integers.
				* [fweight = _weight] is not allowed in wooldid; only aw/pw are allowed.
				* subgroup(treatment_year) is equivalent to subgroup(first_treat).
				* By default, wooldid uses cohorts treated after the end of the sample the same way as never-treated control cohorts (i.e., such cohorts are "out-of-sample treated controls").
				expand _weight
/*
				display "==================== Heterogeneity-Robust TWFE (wooldid) (Wooldridge, 2021) ===================="
					* Without controls
					wooldid `depvar' treatment_year year sociobosque_year, att cluster(cantonid) subgroup(treatment_year) fe(pointid cantonid#year) esfixedbaseperiod esrelativeto(-1) jointtests espre(10) espost(10)
					estimates store wooldid_`ttype'_`j'_`pb'
					
					* With controls
					wooldid `depvar' treatment_year year sociobosque_year, att cluster(cantonid) subgroup(treatment_year) fe(pointid cantonid#year) controls($cv) esfixedbaseperiod esrelativeto(-1) jointtests espre(10) espost(10)
					estimates store wooldid_`ttype'_cv_`j'_`pb'
*/
					
/*
				**# staggered (Roth and Sant'Anna, 2023)
				* Weights not allowed.
				* The panel should have a unique outcome for each (i, t) value.
				display "==================== staggered (Roth and Sant'Anna, 2023) ===================="
					* Without controls
					staggered `depvar', i(pointid) t(year) g(treatment_year) estimand(simple)
					estimates store rs_`ttype'_`j'_`pb'
					
					* With controls
					staggered `depvar' $cv, i(pointid) t(year) g(treatment_year) estimand(simple)
					estimates store rs_`ttype'_cv_`j'_`pb'
*/
*/

				**# TWFE: reghdfe
					display "==================== TWFE: reghdfe ===================="
					
					gen pre_10 = (distyea r<= -10 & _treated==1)
					forv i = 9(-1)2{ // Reference: pre_1 (normalize t=-1 to zero)
						gen pre_`i'  = (distyear== -`i' & _treated==1) 
					}
					forv j = 0/10{
						gen post_`j' = (distyear == `j' & _treated==1)
					}
					replace post_10 = (distyear >= 10 & _treated==1)
					
					* Without controls
					reghdfe `depvar' pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_`ttype'_`j'_`pb'
					
/*
					* With controls
					reghdfe `depvar' pre_* post_* [fweight = _weight], nocons absorb(pointid cantonid#year) vce(cluster cantonid)
					estimates store reghdfe_`ttype'_cv_`j'_`pb'
*/

				color_style egypt, n(6)
				event_plot reghdfe_`ttype'_`j'_`pb' imput_`ttype'_`j'_`pb' cs_`ttype'_`j'_`pb' sa_`ttype'_`j'_`pb'_b#sa_`ttype'_`j'_`pb'_v stack_`ttype'_`j'_`pb' dcdh_`ttype'_`j'_b#dcdh_`ttype'_`j'_v, ///
				stub_lag(post_#		tau#	Tp#		L#event		Q_#		Effect_#) ///
				stub_lead(pre_#		pre#	Tm#		F#event		P_#		Placebo_#) ///
				plottype(scatter) ciplottype(rcap) trimlead(10) trimlag(10) ///
				together perturb(-0.325(0.13)0.455)  noautolegend ///
					graph_opt(title("(`panel') `policy_bundle_label'", size(medlarge)) ///
						xtitle("Periods since the event") ytitle("Estimate of ATT and 95% Conf. Int.") ///
						xlabel(-10(1)10) ylabel(-0.06(0.01)0.03) ///
						legend(order(1 "TWFE"					3 "Borusyak et al. (2024)"	5 "Callaway & Sant'Anna (2021)" ///
									  7 "Sun-Abraham (2021)"	9 "Cengiz et al. (2019)"	11 "de Chaisemartin & d'Haultfoeuille (2020)") ///
									 size(*0.5) ring(0) rows(3) pos(8)) ///
						xline(-1, lcolor(gs8) lpattern(dash)) ///
						yline(0, lcolor(gs8) lpattern(dash)) ylabel(, angle(horizontal)) ///
						graphregion(color(white)) bgcolor(white) ///
					) 	///
					lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
					lag_opt2(msymbol(D) color(purple)) lag_ci_opt2(color(purple)) ///
					lag_opt3(msymbol(S) color(blue)) lag_ci_opt3(color(blue)) ///
					lag_opt4(msymbol(T) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
					lag_opt5(msymbol(+) color(green)) lag_ci_opt5(color(green)) ///
					lag_opt6(msymbol(X) color(pink)) lag_ci_opt6(color(pink))
				graph save "$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_`policy_bundle'.gph", replace

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

/*
		grc1leg "$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Collective_none.gph" ///
				"$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Collective_indigenous.gph" ///
				"$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Collective_pa.gph" ///
				"$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Collective_pa & indigenous.gph", ///
				rows(2) cols(2) title("Panel A. Collective", size(medium) pos(11))
		graph save "$dir\Results\Event Study\eventstudy__mdm_`cgroup_label'_`depvar_label'_Collective.gph", replace
		graph export "$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Collective.png", as(png) replace width(10000) height(8000)
*/

		grc1leg "$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Individual_none.gph" ///
				"$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Individual_indigenous.gph" ///
				"$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Individual_pa.gph", ///
				rows(2) cols(2) title("Panel B. Individual", size(medium) pos(11))
		graph save "$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Individual.gph", replace
		graph export "$dir\Results\Event Study\eventstudy_mdm_`cgroup_label'_`depvar_label'_Individual.png", as(png) replace width(10000) height(8000)
		
		local j = `j' + 1
	}
	local i = `i' + 1
}