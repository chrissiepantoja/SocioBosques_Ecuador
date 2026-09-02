*==============================================================================*
* Socio Bosque: Overall ATT around payment suspension
* Estimator: de Chaisemartin and d'Haultfoeuille (did_multiplegt_dyn) only
* Samples: 1996-2014 and 1996-2017
* Outputs: complete RTF and publication-ready LaTeX tables
*==============================================================================*

version 18
clear all
set more off

global dir "G:\My Drive\socio bosque"
global data "$dir\data"
global results "$dir\Results\Payment Suspension"
capture mkdir "$results"

capture program drop run_dcdh
program define run_dcdh
    args type bundle endyear cohort posthandle detailhandle

    local file "$data\SBP_long_300_did_`type'_mdm_Never-treated_`bundle'.dta"
    use "`file'", clear
    keep if inrange(year, 1996, `endyear')

    gen byte post = (year >= treatment_year) if treatment_year != 9999
    replace post = 0 if treatment_year == 9999

    local sample "1"
    if "`cohort'" != "." local sample "cohort_year == `cohort'"

    quietly count if `sample'
    local N_sample = r(N)
    quietly count if `sample' & post == 0
    local N_pre = r(N)
    quietly summarize forestloss if `sample' & post == 0
    local pre_mean = r(mean)
    local pre_sd = r(sd)

    quietly levelsof cantonid if `sample', local(cantons)
    local n_clusters : word count `cantons'
    local clusteropt ""
    if `n_clusters' > 1 local clusteropt "cluster(cantonid)"

    display as text _newline "============================================================"
    display as text "dCDH | `type' | `bundle' | 1996-`endyear'"
    display as text "============================================================"

    did_multiplegt_dyn forestloss pointid year post if `sample', ///
        weight(_weight) effects(10) placebo(10) `clusteropt'

    tempname att se
    scalar `att' = .
    scalar `se' = .
    capture scalar `att' = e(Av_tot_effect)
    if missing(`att') capture scalar `att' = e(avg_total_effect)
    if missing(`att') capture scalar `att' = e(ATT)
    capture scalar `se' = e(se_avg_total_effect)
    if missing(`se') capture scalar `se' = e(se_Av_tot_effect)
    if missing(`se') capture scalar `se' = e(se_ATT)

    if missing(`att') | missing(`se') {
        display as error "Average total effect or its SE was not returned."
        exit 498
    }

    local z = `att' / `se'
    local p = 2 * normal(-abs(`z'))
    local ci_low = `att' - invnormal(.975) * `se'
    local ci_high = `att' + invnormal(.975) * `se'
    local rel_effect = 100 * `att' / `pre_mean'
    local std_effect = `att' / `pre_sd'
    local switch_periods = e(N_switchers_effect_average)

    * Save every dynamic effect and placebo returned in e(b).
    matrix __b = e(b)
    matrix __V = e(V)
    local terms : colnames __b
    local nterms = colsof(__b)
    local pfirst = .
    local plast = .
    forvalues j = 1/`nterms' {
        local term : word `j' of `terms'
        scalar __coef = __b[1,`j']
        scalar __se = sqrt(__V[`j',`j'])
        scalar __z = __coef / __se
        scalar __p = 2 * normal(-abs(__z))
        scalar __lo = __coef - invnormal(.975) * __se
        scalar __hi = __coef + invnormal(.975) * __se
        local component = cond(strpos(lower("`term'"), "placebo"), ///
            "Placebo", "Dynamic effect")
        post `detailhandle' ("`type'") ("`bundle'") (1996) (`endyear') ///
            ("`component'") ("`term'") (__coef) (__se) (__lo) (__hi) (__p)
        if "`component'" == "Placebo" {
            if missing(`pfirst') local pfirst = `j'
            local plast = `j'
        }
    }

    * Use the command's own joint placebo test, which handles near-singular V.
    scalar __placebo_joint_p = .
    capture scalar __placebo_joint_p = e(p_jointplacebo)
    local placebo_joint_p = __placebo_joint_p
    if !missing(`placebo_joint_p') {
        post `detailhandle' ("`type'") ("`bundle'") (1996) (`endyear') ///
            ("Placebo test") ("Joint Wald test") (.) (.) (.) (.) ///
            (`placebo_joint_p')
    }

    post `detailhandle' ("`type'") ("`bundle'") (1996) (`endyear') ///
        ("Overall ATT") ("Average total effect") (`att') (`se') ///
        (`ci_low') (`ci_high') (`p')

    post `posthandle' ("`type'") ("`bundle'") (1996) (`endyear') ///
        (`cohort') (`N_sample') (`N_pre') (`n_clusters') ///
        (`pre_mean') (`pre_sd') (`att') (`se') (`z') (`p') ///
        (`ci_low') (`ci_high') (`rel_effect') (`std_effect') ///
        (`placebo_joint_p') (`switch_periods')

    capture graph save ///
        "$results\dcdh_`type'_`bundle'_1996_`endyear'.gph", replace
end

tempfile results
tempfile details
tempname handle detailhandle
postfile `handle' str12 type str12 policy_bundle int start_year end_year ///
    cohort long N_sample N_pre int N_clusters ///
    double pre_mean pre_sd att se z p ci_low ci_high rel_effect_pct ///
    standardized_effect placebo_joint_p switch_periods using "`results'", replace
postfile `detailhandle' str12 type str12 policy_bundle int start_year end_year ///
    str16 component str40 term double estimate se ci_low ci_high p ///
    using "`details'", replace

foreach endyear in 2014 2017 {
    run_dcdh "Collective" "sb" `endyear' 2008 `handle' `detailhandle'
    run_dcdh "Collective" "sb+it" `endyear' . `handle' `detailhandle'
    run_dcdh "Collective" "sb+pa" `endyear' 2011 `handle' `detailhandle'
    run_dcdh "Collective" "sb+it+pa" `endyear' 2010 `handle' `detailhandle'
    run_dcdh "Individual" "sb" `endyear' . `handle' `detailhandle'
    run_dcdh "Individual" "sb+it" `endyear' . `handle' `detailhandle'
    run_dcdh "Individual" "sb+pa" `endyear' . `handle' `detailhandle'
}
postclose `handle'
postclose `detailhandle'

use "`results'", clear
gen str3 significance = cond(p < .01, "***", cond(p < .05, "**", ///
    cond(p < .10, "*", "")))
order type policy_bundle start_year end_year cohort att se ci_low ci_high p ///
    significance placebo_joint_p switch_periods pre_mean pre_sd rel_effect_pct standardized_effect ///
    N_sample N_pre N_clusters
sort type policy_bundle end_year
format att se ci_low ci_high pre_mean pre_sd %10.5f
format p %8.4f
format rel_effect_pct standardized_effect %10.3f

label variable att "dCDH average total effect (percentage points)"
label variable se "Standard error"
label variable ci_low "95% CI lower bound"
label variable ci_high "95% CI upper bound"
label variable rel_effect_pct "ATT as % of pre-period mean"
label variable standardized_effect "ATT in pre-period SDs"

save "$results\dcdh_payment_suspension_results.dta", replace
export delimited using ///
    "$results\dcdh_payment_suspension_results.csv", replace

list type policy_bundle end_year att se ci_low ci_high p significance, ///
    sepby(type policy_bundle) noobs abbreviate(20)

use "`details'", clear
gen str3 significance = cond(p < .01, "***", cond(p < .05, "**", ///
    cond(p < .10, "*", "")))
sort end_year type policy_bundle component term
save "$results\dcdh_payment_suspension_all_results.dta", replace
export delimited using ///
    "$results\dcdh_payment_suspension_all_results.csv", replace

* Complete RTF table (Overall ATT, all dynamic effects, and all placebos).
file open rtf using "$results\dcdh_payment_suspension_all_results.rtf", ///
    write replace
file write rtf "{\rtf1\ansi\deff0{\fonttbl{\f0 Times New Roman;}}" _n
file write rtf "\fs22\b dCDH estimates: payment suspension samples\b0\par" _n
file write rtf "\fs18 Estimates in percentage points; 95% normal confidence intervals." ///
    "\par\par" _n
file write rtf "\trowd\trgaph80\cellx1500\cellx2700\cellx3700\cellx5200" ///
    "\cellx6900\cellx7900\cellx8900\cellx9900\cellx10800" _n
file write rtf "\intbl\b Sample\cell Type\cell Bundle\cell Result\cell Term\cell" ///
    " Estimate\cell SE\cell 95% CI\cell p\b0\cell\row" _n
quietly count
forvalues i = 1/`r(N)' {
    local sample = "1996-" + string(end_year[`i'])
    local ci = "[" + string(ci_low[`i'],"%9.4f") + ", " + ///
        string(ci_high[`i'],"%9.4f") + "]"
    file write rtf "\trowd\trgaph80\cellx1500\cellx2700\cellx3700\cellx5200" ///
        "\cellx6900\cellx7900\cellx8900\cellx9900\cellx10800" _n
    file write rtf "\intbl `sample'\cell `=type[`i']'\cell" ///
        " `=policy_bundle[`i']'\cell `=component[`i']'\cell `=term[`i']'\cell" ///
        " `=string(estimate[`i'],"%9.4f")'`=significance[`i']'\cell" ///
        " `=string(se[`i'],"%9.4f")'\cell `ci'\cell" ///
        " `=string(p[`i'],"%7.4f")'\cell\row" _n
}
file write rtf "\par Notes: * p<0.10, ** p<0.05, *** p<0.01." _n "}"
file close rtf

* Publication-ready LaTeX longtable. Requires booktabs and longtable.
file open tex using "$results\dcdh_payment_suspension_all_results.tex", ///
    write replace
file write tex "% Requires: \usepackage{booktabs,longtable,siunitx}" _n
file write tex "\begin{longtable}{lll ll S[table-format=-1.4] S[table-format=1.4] cc}" _n
file write tex "\caption{dCDH estimates for alternative payment-suspension samples}" ///
    "\label{tab:dcdh_payment_suspension}\\" _n
file write tex "\toprule" _n
file write tex "Sample & Type & Bundle & Result & Term & {Estimate} & {SE} &" ///
    " {95\% CI} & {p-value} \\" _n
file write tex "\midrule\endfirsthead" _n
file write tex "\multicolumn{9}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write tex "\toprule Sample & Type & Bundle & Result & Term & {Estimate} &" ///
    " {SE} & {95\% CI} & {p-value} \\\midrule\endhead" _n
file write tex "\midrule\multicolumn{9}{r}{Continued on next page} \\\endfoot" _n
file write tex "\bottomrule\endlastfoot" _n
quietly count
forvalues i = 1/`r(N)' {
    local sample = "1996--" + string(end_year[`i'])
    local bundle = subinstr(policy_bundle[`i'], "+", "$+$", .)
    local term = subinstr(term[`i'], "_", "\_", .)
    local result = subinstr(component[`i'], "_", "\_", .)
    file write tex "`sample' & `=type[`i']' & `bundle' & `result' & `term' & " ///
        "`=string(estimate[`i'],"%9.4f")' & `=string(se[`i'],"%9.4f")' & " ///
        "[`=string(ci_low[`i'],"%9.4f")', `=string(ci_high[`i'],"%9.4f")'] & " ///
        "`=string(p[`i'],"%7.4f")' \\" _n
}
file write tex "\multicolumn{9}{p{0.96\linewidth}}{\footnotesize Notes: Estimates" ///
    " are in percentage points. Standard errors use canton clustering whenever" ///
    " more than one canton is available. Exact two-sided \(p\)-values are" ///
    " reported.} \\" _n
file write tex "\end{longtable}" _n
file close tex

* AER-formatted comparison table and four-panel baseline/window figure.
do "$dir\stata\4 Overall ATT - Payment Suspension AER.do"
