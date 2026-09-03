*==============================================================================*
* AER table and three-sample coefficient figure for payment suspension
* Requires the 1996-2014 and 1996-2017 results produced by the main do-file.
* Baseline is the unrestricted original estimation sample.
*==============================================================================*

version 18
set more off

global dir "G:\My Drive\socio bosque"
global data "$dir\data"
global results "$dir\Results\Payment Suspension"

capture program drop run_dcdh_baseline
program define run_dcdh_baseline
    args type bundle cohort posthandle

    use "$data\SBP_long_300_did_`type'_mdm_Never-treated_`bundle'.dta", clear
    gen byte post = (year >= treatment_year) if treatment_year != 9999
    replace post = 0 if treatment_year == 9999

    local sample "1"
    if "`cohort'" != "." local sample "cohort_year == `cohort'"

    quietly count if `sample'
    local N = r(N)
    quietly summarize year if `sample'
    local firstyear = r(min)
    local lastyear = r(max)
    quietly levelsof cantonid if `sample', local(cantons)
    local n_clusters : word count `cantons'
    local clusteropt ""
    if `n_clusters' > 1 local clusteropt "cluster(cantonid)"

    display as text _newline "============================================================"
    display as text "Baseline dCDH | `type' | `bundle' | `firstyear'-`lastyear'"
    display as text "============================================================"
    did_multiplegt_dyn forestloss pointid year post if `sample', ///
        weight(_weight) effects(10) placebo(10) `clusteropt'

    scalar __att = e(Av_tot_effect)
    scalar __se = e(se_avg_total_effect)
    scalar __p = 2 * normal(-abs(__att / __se))
    scalar __lo = __att - invnormal(.975) * __se
    scalar __hi = __att + invnormal(.975) * __se
    post `posthandle' ("`type'") ("`bundle'") ("Baseline") ///
        (`firstyear') (`lastyear') (__att) (__se) (__lo) (__hi) (__p) (`N')
end

tempfile baseline
tempname bh
postfile `bh' str12 type str12 policy_bundle str24 sample ///
    int start_year end_year double att se ci_low ci_high p long N_sample ///
    using "`baseline'", replace

run_dcdh_baseline "Collective" "sb" 2008 `bh'
run_dcdh_baseline "Individual" "sb" . `bh'
run_dcdh_baseline "Collective" "sb+it" . `bh'
run_dcdh_baseline "Individual" "sb+it" . `bh'
run_dcdh_baseline "Collective" "sb+pa" 2011 `bh'
run_dcdh_baseline "Individual" "sb+pa" . `bh'
run_dcdh_baseline "Collective" "sb+it+pa" 2010 `bh'
postclose `bh'

* Combine baseline with the two payment-suspension windows.
use "$results\dcdh_payment_suspension_results.dta", clear
capture confirm variable switch_periods
if _rc gen double switch_periods = .
* Backward-compatible values recovered from the verified dCDH run log.
replace switch_periods =  16779 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb"       & end_year==2014
replace switch_periods = 142613 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb+it"    & end_year==2014
replace switch_periods =   5692 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb+pa"    & end_year==2014
replace switch_periods =   2045 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb+it+pa" & end_year==2014
replace switch_periods =   8529 if missing(switch_periods) & type=="Individual" & policy_bundle=="sb"       & end_year==2014
replace switch_periods =   1157 if missing(switch_periods) & type=="Individual" & policy_bundle=="sb+it"    & end_year==2014
replace switch_periods =    535 if missing(switch_periods) & type=="Individual" & policy_bundle=="sb+pa"    & end_year==2014
replace switch_periods =  23970 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb"       & end_year==2017
replace switch_periods = 257923 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb+it"    & end_year==2017
replace switch_periods =   9961 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb+pa"    & end_year==2017
replace switch_periods =   3272 if missing(switch_periods) & type=="Collective" & policy_bundle=="sb+it+pa" & end_year==2017
replace switch_periods =  15108 if missing(switch_periods) & type=="Individual" & policy_bundle=="sb"       & end_year==2017
replace switch_periods =   2018 if missing(switch_periods) & type=="Individual" & policy_bundle=="sb+it"    & end_year==2017
replace switch_periods =    982 if missing(switch_periods) & type=="Individual" & policy_bundle=="sb+pa"    & end_year==2017
keep type policy_bundle start_year end_year att se ci_low ci_high p N_sample switch_periods
gen str24 sample = cond(end_year == 2014, "Before suspension", ///
    "Suspension included")
append using "`baseline'"

gen byte model = .
replace model = 1 if policy_bundle == "sb"       & type == "Collective"
replace model = 2 if policy_bundle == "sb"       & type == "Individual"
replace model = 3 if policy_bundle == "sb+it"    & type == "Collective"
replace model = 4 if policy_bundle == "sb+it"    & type == "Individual"
replace model = 5 if policy_bundle == "sb+pa"    & type == "Collective"
replace model = 6 if policy_bundle == "sb+pa"    & type == "Individual"
replace model = 7 if policy_bundle == "sb+it+pa" & type == "Collective"
gen byte sample_order = cond(sample == "Baseline", 1, ///
    cond(sample == "Before suspension", 2, 3))
sort model sample_order
save "$results\dcdh_payment_suspension_figure_data.dta", replace
export delimited using ///
    "$results\dcdh_payment_suspension_figure_data.csv", replace

* Prepare formatted AER table cells.
forvalues m = 1/7 {
    foreach yr in 14 17 {
        local endyr = 2000 + `yr'
        quietly summarize att if model == `m' & end_year == `endyr'
        local b = r(mean)
        quietly summarize se if model == `m' & end_year == `endyr'
        local s = r(mean)
        quietly summarize p if model == `m' & end_year == `endyr'
        local pv = r(mean)
        quietly summarize N_sample if model == `m' & end_year == `endyr'
        local nn = r(mean)
        quietly summarize switch_periods if model == `m' & end_year == `endyr'
        local sw = r(mean)
        local stars = cond(`pv' < .01, "***", cond(`pv' < .05, "**", ///
            cond(`pv' < .10, "*", "")))
        local coef`yr'_`m' : display %9.4f `b'
        local coef`yr'_`m' "`coef`yr'_`m''`stars'"
        local se`yr'_`m' : display %9.4f `s'
        local n`yr'_`m' : display %12.0fc `nn'
        local sw`yr'_`m' : display %12.0fc `sw'
    }
}

* Publication-ready AER LaTeX table.
file open tex using "$results\payment_suspension_AER_table.tex", write replace
file write tex "% Requires: \usepackage{booktabs,threeparttable}" _n
file write tex "\begin{table}[!htbp]\centering" _n
file write tex "\caption{Socio Bosque effectiveness before and during the payment suspension}" _n
file write tex "\label{tab:payment_suspension_att}" _n
file write tex "\begin{threeparttable}" _n
file write tex "\begin{tabular}{l*{7}{c}}" _n
file write tex "\toprule" _n
file write tex " & \multicolumn{2}{c}{SB} & \multicolumn{2}{c}{SB + IT} &" ///
    " \multicolumn{2}{c}{SB + PA} & \multicolumn{1}{c}{SB + IT + PA} \\" _n
file write tex "\cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-7}" ///
    "\cmidrule(lr){8-8}" _n
file write tex " & Collective & Individual & Collective & Individual &" ///
    " Collective & Individual & Collective \\" _n
file write tex " & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\" _n
file write tex "\midrule" _n
file write tex "\multicolumn{8}{l}{\textit{1996--2014 (before payment suspension)}} \\" _n
file write tex "Overall ATT"
forvalues m = 1/7 {
    file write tex " & `coef14_`m''"
}
file write tex " \\" _n
file write tex " "
forvalues m = 1/7 {
    file write tex " & (`se14_`m'')"
}
file write tex " \\" _n
file write tex "\addlinespace" _n
file write tex "\multicolumn{8}{l}{\textit{1996--2017 (payment suspension included)}} \\" _n
file write tex "Overall ATT"
forvalues m = 1/7 {
    file write tex " & `coef17_`m''"
}
file write tex " \\" _n
file write tex " "
forvalues m = 1/7 {
    file write tex " & (`se17_`m'')"
}
file write tex " \\" _n
file write tex "\midrule" _n
file write tex "Unit fixed effects & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\" _n
file write tex "Year fixed effects & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\" _n
file write tex "Switch \(\times\) Periods (1996--2014)"
forvalues m = 1/7 {
    file write tex " & `sw14_`m''"
}
file write tex " \\" _n
file write tex "Switch \(\times\) Periods (1996--2017)"
forvalues m = 1/7 {
    file write tex " & `sw17_`m''"
}
file write tex " \\" _n
file write tex "Observations (1996--2014)"
forvalues m = 1/7 {
    file write tex " & `n14_`m''"
}
file write tex " \\" _n
file write tex "Observations (1996--2017)"
forvalues m = 1/7 {
    file write tex " & `n17_`m''"
}
file write tex " \\" _n
file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n
file write tex "\begin{tablenotes}[flushleft]\footnotesize" _n
file write tex "\item Notes: Entries are dCDH average cumulative treatment effects." ///
    " Standard errors are in parentheses and are clustered by canton whenever" ///
    " more than one canton is available. The dCDH estimator absorbs unit and" ///
    " year fixed effects. Switch \(\times\) Periods is the number of treatment" ///
    " switches multiplied by the post-switch periods entering the average." ///
    " * \(p<0.10\), ** \(p<0.05\), *** \(p<0.01\)." _n
file write tex "\end{tablenotes}" _n
file write tex "\end{threeparttable}" _n
file write tex "\end{table}" _n
file close tex

* AER-style RTF table with four header rows and seven model columns.
file open rtf using "$results\payment_suspension_AER_table.rtf", write replace
file write rtf "{\rtf1\ansi\deff0{\fonttbl{\f0 Times New Roman;}}" _n
file write rtf "\fs22\b Socio Bosque effectiveness before and during the payment suspension\b0\par" _n
file write rtf "\fs18\par" _n

* Policy-bundle header.
file write rtf "\trowd\trgaph70\cellx2600\clmgf\cellx4600\clmrg\cellx6600" ///
    "\clmgf\cellx8600\clmrg\cellx10600\clmgf\cellx12600\clmrg\cellx14600" ///
    "\cellx16600" _n
file write rtf "\intbl \cell\qc SB\cell\cell SB + IT\cell\cell SB + PA\cell\cell" ///
    " SB + IT + PA\cell\row" _n

file write rtf "\trowd\trgaph70\cellx2600\cellx4600\cellx6600\cellx8600" ///
    "\cellx10600\cellx12600\cellx14600\cellx16600" _n
file write rtf "\intbl \cell\qc Collective\cell Individual\cell Collective\cell" ///
    " Individual\cell Collective\cell Individual\cell Collective\cell\row" _n
file write rtf "\trowd\trgaph70\cellx2600\cellx4600\cellx6600\cellx8600" ///
    "\cellx10600\cellx12600\cellx14600\cellx16600" _n
file write rtf "\intbl \cell\qc (1)\cell (2)\cell (3)\cell (4)\cell (5)\cell" ///
    " (6)\cell (7)\cell\row" _n

foreach yr in 14 17 {
    local panel = cond(`yr' == 14, ///
        "1996-2014 (before payment suspension)", ///
        "1996-2017 (payment suspension included)")
    file write rtf "\trowd\trgaph70\clmgf\cellx2600\clmrg\cellx4600\clmrg" ///
        "\cellx6600\clmrg\cellx8600\clmrg\cellx10600\clmrg\cellx12600" ///
        "\clmrg\cellx14600\clmrg\cellx16600" _n
    file write rtf "\intbl\i `panel'\i0\cell\cell\cell\cell\cell\cell\cell\cell\row" _n
    file write rtf "\trowd\trgaph70\cellx2600\cellx4600\cellx6600\cellx8600" ///
        "\cellx10600\cellx12600\cellx14600\cellx16600" _n
    file write rtf "\intbl Overall ATT\cell"
    forvalues m = 1/7 {
        file write rtf "\qc `coef`yr'_`m''\line (`se`yr'_`m'')\cell"
    }
    file write rtf "\row" _n
}

foreach label in "Unit fixed effects" "Year fixed effects" {
    file write rtf "\trowd\trgaph70\cellx2600\cellx4600\cellx6600\cellx8600" ///
        "\cellx10600\cellx12600\cellx14600\cellx16600" _n
    file write rtf "\intbl `label'\cell\qc Yes\cell Yes\cell Yes\cell Yes\cell" ///
        " Yes\cell Yes\cell Yes\cell\row" _n
}
foreach yr in 14 17 {
    file write rtf "\trowd\trgaph70\cellx2600\cellx4600\cellx6600\cellx8600" ///
        "\cellx10600\cellx12600\cellx14600\cellx16600" _n
    file write rtf "\intbl Switch x Periods (1996-20`yr')\cell"
    forvalues m = 1/7 {
        file write rtf "\qc `sw`yr'_`m''\cell"
    }
    file write rtf "\row" _n
}
foreach yr in 14 17 {
    file write rtf "\trowd\trgaph70\cellx2600\cellx4600\cellx6600\cellx8600" ///
        "\cellx10600\cellx12600\cellx14600\cellx16600" _n
    file write rtf "\intbl Observations (1996-20`yr')\cell"
    forvalues m = 1/7 {
        file write rtf "\qc `n`yr'_`m''\cell"
    }
    file write rtf "\row" _n
}
file write rtf "\par\fs16 Notes: dCDH average cumulative treatment effects." ///
    " Standard errors in parentheses; canton-clustered when more than one canton" ///
    " is available. The estimator absorbs unit and year fixed effects. Switch x" ///
    " Periods is the number of treatment switches multiplied by post-switch" ///
    " periods. * p<0.10, ** p<0.05, *** p<0.01.\par}" _n
file close rtf

* Four-panel horizontal coefficient plot.
do "$dir\stata\4 Overall ATT - Payment Suspension Figure.do"
