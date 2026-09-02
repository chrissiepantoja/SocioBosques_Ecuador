
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Mahalanobis Distance Matching & Covariate Balance Diagnostics
*Country: Ecuador
*==============================================================================*

*-------------------------------------------------------------------
* Mahalanobis Distance Matching & Covariate Balance Diagnostics
*-------------------------------------------------------------------

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Data\SBP_data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"

global covariates "road village river population oil pipelines slope elevation"
global cv "farming mining infrastruct"

** Design MDM program
* Never-treated
capture program drop mdm_cohort_never
program define mdm_cohort_never, rclass
    syntax, cohort(integer)

    tempfile full_backup
    save `full_backup', replace
	
	* Set the range for pre-treatment years
	local pre_start = `cohort' - 10
	local pre_end = `cohort' - 1
	local covars "$covariates"
	
	* Loop through the five years
	forvalues y = `pre_start'/`pre_end' {
		capture confirm var forestloss`y'
		if _rc == 0 {
			local covars "`covars' forestloss`y'"
		}
	}
	
    * Check covariate validity
    capture confirm var `covars'
    if _rc != 0 {
        di in red "Missing covariates: `covars'"
        exit
    }

    * Create treated/control indicators
    use `full_backup', clear
    gen treated = (first_treat == `cohort' & within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos >= 0.5)
    gen control = (first_treat == 0 | within_sociobosque == "NA" | pixel_percent_intersect_sociobos < 0.5)
    keep if treated | control

    * Debugging information
    di _n "========== Processing cohort `cohort' =========="
    qui count if treated
    di "Treated group samples: `r(N)'"
    if r(N) <= 1 {
        di in red "Insufficient treated units for cohort `cohort'. Skipping."
        exit
    }
    qui count if control
    di "Control group candidates: `r(N)'"
    if r(N) == 0 {
        di in red "No control candidates for cohort `cohort'. Skipping."
        exit
    }

    * MDM
    tempfile all_matched
    gen dummy = .
    save `all_matched', emptyok replace
    levelsof state if treated == 1 & !missing(state), local(states)
    foreach s of local states {
        di in green "========== Matching within cohort `cohort', state = `s' =========="
        use `full_backup', clear
        gen treated = (first_treat == `cohort' & within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos >= 0.5)
        gen control = (first_treat == 0 | within_sociobosque == "NA" | pixel_percent_intersect_sociobos < 0.5)
        keep if treated | control
        keep if state == "`s'"
        qui count if treated
        di "Treated group samples: `r(N)'"
        if r(N) <= 1 {
            di in red "Insufficient treated pixels in state = `s'. Skipping."
            continue
        }
        qui count if control
        di "Control group candidates: `r(N)'"
        if r(N) <= 2 {
            di in red "Insufficient control group candidates in state = `s'. Skipping."
            continue
        }
        psmatch2 treated, mahalanobis(`covars') n(1) caliper(0.1)
        keep pointid x y polygonid _treated _id _n1 _weight state `covars'
        gen cohort_year = `cohort'
        gen state_match = "`s'"
        append using `all_matched'
        save `all_matched', replace
    }

    * Save matched pairs
    use `all_matched', clear
    capture save "matched_cohort_`cohort'.dta", replace
    if _rc != 0 {
        di in red "Failed to save matched cohort `cohort'"
    }
end

capture program drop mdm_cohort_never_pa
program define mdm_cohort_never_pa, rclass
	syntax, cohort(integer)

	tempfile full_backup
	save `full_backup', replace
	
	* Set the range for pre-treatment years
	local pre_start = `cohort' - 10
	local pre_end = `cohort' - 1
	local covars "$covariates"

	* Loop through the five years
	forvalues y = `pre_start'/`pre_end' {
		capture confirm var forestloss`y'
		if _rc == 0 {
			local covars "`covars' forestloss`y'"
		}
	}
	
	capture confirm var `covars'
	if _rc != 0 {
		di in red "Missing covariates: `covars'"
		exit
	}

	use `full_backup', clear
	gen treated = (first_treat == `cohort' & within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos >= 0.5)
	gen control = (first_treat == 0 | within_sociobosque == "NA" | pixel_percent_intersect_sociobos < 0.5)
	keep if treated | control

	di _n "========== Processing cohort `cohort' =========="
	qui count if treated
	di "Treated group samples: `r(N)'"
	if r(N) <= 1 {
		di in red "Insufficient treated units for cohort `cohort'. Skipping."
		exit
	}
	qui count if control
	di "Control group candidates: `r(N)'"
	if r(N) == 0 {
		di in red "No control group candidates for cohort `cohort'. Skipping."
		exit
	}

	tempfile all_matched
	gen dummy = .
	save `all_matched', emptyok replace

	levelsof state if treated == 1 & !missing(state), local(states)

	foreach s of local states {
		levelsof year_pa if treated == 1 & state == "`s'" & !missing(year_pa), local(years_pa)

		foreach ypa of local years_pa {
			di in green "========== Matching within cohort `cohort', state = `s', year_pa = `ypa' =========="
			use `full_backup', clear
			gen treated = (first_treat == `cohort' & within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos >= 0.5)
			gen control = (first_treat == 0 | within_sociobosque == "NA" | pixel_percent_intersect_sociobos < 0.5)
			keep if treated | control
			keep if state == "`s'"
			keep if year_pa == `ypa'

			qui count if treated
			di "Treated group samples: `r(N)'"
			if r(N) <= 1 {
				di in red "Insufficient treated pixels in state = `s' and year_pa = `ypa'. Skipping."
				continue
			}

			qui count if control
			di "Control group candidates: `r(N)'"
			if r(N) <= 2 {
				di in red "Insufficient control group candidates in state = `s' and year_pa = `ypa'. Skipping."
				continue
			}

			psmatch2 treated, mahalanobis(`covars') n(1) caliper(0.1)
			keep pointid x y polygonid _treated _id _n1 _weight state year_pa `covars'
			gen cohort_year = `cohort'
			gen state_match = "`s'"
			gen pa_match_year = `ypa'

			append using `all_matched'
			save `all_matched', replace
		}
	}

	use `all_matched', clear
	capture save "matched_cohort_`cohort'.dta", replace
	if _rc != 0 {
		di in red "Failed to save matched cohort `cohort'"
	}
end

**# 300*300, Collective, Never-treated------------------------------------------

use "SBP_wide_300.dta", clear

* Step 1: Generate treatment year indicator
gen treatment_year = sociobosque_year
replace treatment_year = 9999 if missing(sociobosque_year) // Mark never-treated units with 9999 (wooldid: Cohort identifier must consist of positive, non-zero integers)
gen first_treat = sociobosque_year
replace first_treat = 0 if missing(sociobosque_year) // Mark never-treated units with 0 (csdid: Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated)

keep if sociobosque_type == "COLECTIVO" | sociobosque_type == "NA" // Restrict to COLECTIVO units

local covervars
forvalues y = 1997/2020 {
	local covervars `covervars' forestcover`y'
}
* Calculate max pre-treatment forestcover
egen max_cover_pre = rowmax(`covervars')
* Drop if forestcover was zero in all pre/post-treatment years
drop if max_cover_pre <= 0.3
drop max_cover_pre
drop if (within_sociobosque == "NA" & pixel_percent_intersect_sociobos >= 0.5) | (within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos < 0.5)
save "SBP_wide_300_Collective.dta", replace
levelsof sociobosque_year if !missing(sociobosque_year), local(years)
global years `years'
// gen treated = (within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos >= 0.5)
// reshape long forestloss, i(pointid) j(year)
// save "SBP_long_300_Collective.dta", replace

di "*================================== SB Only ==================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Collective.dta", clear
	keep if pa == "NA" & indigenous == "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb.dta", replace

use "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb.dta", clear
drop forestloss*
keep pointid - state_match
merge m:1 pointid using "SBP_wide_300_Collective.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Collective_mdm_Never-treated_sb.dta", replace
di "Completed: Never-treated | Collective | SB"

di "*=============================== SB + IT ===============================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Collective.dta", clear
	keep if indigenous != "NA" & pa == "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it.dta", replace

use "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it.dta", clear
drop forestloss*
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
merge m:1 pointid using "SBP_wide_300_Collective.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
//encode newid, gen (panel_id)
egen panel_id = group(newid)
save "SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta", replace
di "Completed: Never-treated | Collective | SB + IT"

di "*=================================== SB + PA ===================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Collective.dta", clear
	keep if pa != "NA" & indigenous == "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never_pa, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+pa.dta", replace

use "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+pa.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb+pa.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb+pa.dta", clear
drop forestloss*
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
merge m:1 pointid using "SBP_wide_300_Collective.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta", replace
di "Completed: Never-treated | Collective | SB + PA"

di "*============================ SB + IT + PA ============================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Collective.dta", clear
	keep if pa != "NA" & indigenous != "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never_pa, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it+pa.dta", replace

use "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it+pa.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it+pa.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it+pa.dta", clear
drop forestloss*
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
merge m:1 pointid using "SBP_wide_300_Collective.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Collective_mdm_Never-treated_sb+it+pa.dta", replace
di "Completed: Never-treated | Collective | SB + IT +PA"

**## Covariate Balance Diagnostics for whole sample
use "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb.dta", clear
append using "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it.dta"
append using "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+pa.dta"
append using "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sb+it+pa.dta"
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
order pointid cohort_year forestloss*, sequential
mata:
	start_col = st_varindex("forestloss1998")
	end_col   = st_varindex("forestloss2014")
	cols      = start_col::end_col
	if (rows(cols) > 1) {
		cols = cols'
	}
	X = st_data(., cols)
	n = rows(X)
	m = cols(X)
	Y = J(n, 10, .)          // initialize with system‐missing
	for (i = 1; i <= n; i++) {
		cnt = 0
		for (j = 1; j <= m & cnt < 10; j++) {
			if (!missing(X[i,j])) {
				cnt++
				Y[i,cnt] = X[i,j]
			}
		}
	}
	for (k = 1; k <= 10; k++) {
		varname = "forestloss_pre" + strofreal(10 - k + 1)
		st_addvar("double", varname)
		st_store(., varname, Y[.,k])
	}
end
describe forestloss_pre*
sum forestloss_pre*
di "Done! Now forestloss_pre10–pre1 have been created."
ds forestloss????, has(type numeric) 
drop `r(varlist)'
di "All actual-year forestloss variables dropped. Only forestloss_pre* remain."
save "all_(un)matched_pairs_wide_300_Collective_mdm_Never-treated_sociobosque.dta", replace

global covariates "road village river population oil pipelines slope elevation"
asdoc pstest $covariates forestloss*, both treated(_treated) mweight(_weight) nograph save($dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Collective_mdm_Never-treated_sociobosque.doc) replace
* (a) Dot chart
pstest $covariates forestloss*, both treated(_treated) mweight(_weight) graph
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_dot chart_Collective_mdm_Never-treated_sociobosque.gph", replace
* (b) Histogram
pstest $covariates forestloss*, both treated(_treated) mweight(_weight) hist
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_histogram_Collective_mdm_Never-treated_sociobosque.gph", replace
* (c) Scatter plot
pstest $covariates forestloss*, both treated(_treated) mweight(_weight) scatter xtitle(Standardized % bias across covariates)
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_scatter plot_Collective_mdm_Never-treated_sociobosque.gph", replace

graph combine 	"$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_dot chart_Collective_mdm_Never-treated_sociobosque.gph" ///
				"$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_histogram_Collective_mdm_Never-treated_sociobosque.gph" ///
				"$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_scatter plot_Collective_mdm_Never-treated_sociobosque.gph", ///
				rows(1) imargin(0 0 0 0) graphregion(color(white)) plotregion(color(white))
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Collective_mdm_Never-treated_sociobosque.gph", replace
graph export "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Collective_mdm_Never-treated_sociobosque.png", as(png) replace width(12000) height(5000)
graph export "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Collective_mdm_Never-treated_sociobosque.pdf", as(pdf) replace

**# 300*300, Individual, Never-treated------------------------------------------

use "SBP_wide_300.dta", clear

* Step 1: Generate treatment year indicator
gen treatment_year = sociobosque_year
replace treatment_year = 9999 if missing(sociobosque_year) // Mark never-treated units with 9999 (wooldid: Cohort identifier must consist of positive, non-zero integers)
gen first_treat = sociobosque_year
replace first_treat = 0 if missing(sociobosque_year) // Mark never-treated units with 0 (csdid: Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated)

keep if sociobosque_type == "INDIVIDUAL" | sociobosque_type == "NA" // Restrict to INDIVIDUAL units

local covervars
forvalues y = 1997/2020 {
	local covervars `covervars' forestcover`y'
}
* Calculate max pre-treatment forestcover
egen max_cover_pre = rowmax(`covervars')
* Drop if forestcover was zero in all pre/post-treatment years
drop if max_cover_pre <= 0.3
drop max_cover_pre
drop if (within_sociobosque == "NA" & pixel_percent_intersect_sociobos >= 0.5) | (within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos < 0.5)
save "SBP_wide_300_Individual.dta", replace
levelsof sociobosque_year if !missing(sociobosque_year), local(years)
global years `years'
// gen treated = (within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos >= 0.5)
// reshape long forestloss, i(pointid) j(year)
// save "SBP_long_300_Individual.dta", replace

di "*================================== SB Only ==================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Individual.dta", clear
	keep if pa == "NA" & indigenous == "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb.dta", replace

use "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb.dta", clear
drop forestloss*
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
merge m:1 pointid using "SBP_wide_300_Individual.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Individual_mdm_Never-treated_sb.dta", replace
di "Completed: Never-treated | Individual | SB"

di "*=============================== SB + IT ===============================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Individual.dta", clear
	keep if indigenous != "NA" & pa == "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it.dta", replace

use "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it.dta", clear
drop forestloss*
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
merge m:1 pointid using "SBP_wide_300_Individual.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta", replace
di "Completed: Never-treated | Individual | SB + IT"

di "*=================================== SB + PA ===================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Individual.dta", clear
	keep if pa != "NA" & indigenous == "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never_pa, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+pa.dta", replace

use "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+pa.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb+pa.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb+pa.dta", clear
// keep pointid - pa_match_year
drop forestloss*
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
merge m:1 pointid using "SBP_wide_300_Individual.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta", replace
di "Completed: Never-treated | Individual | SB + PA"

di "*============================ SB + IT + PA ============================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Individual.dta", clear
	keep if pa != "NA" & indigenous != "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never_pa, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it+pa.dta", replace

use "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it+pa.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it+pa.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it+pa.dta", clear
// keep pointid - pa_match_year
drop forestloss*
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
merge m:1 pointid using "SBP_wide_300_Individual.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Individual_mdm_Never-treated_sb+it+pa.dta", replace
di "Completed: Never-treated | Individual | SB + IT + PA"

**## Covariate Balance Diagnostics for whole sample
use "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb.dta", clear
append using "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it.dta"
append using "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+pa.dta"
append using "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sb+it+pa.dta"
ds
foreach var of varlist `r(varlist)' {
    quietly summarize `var'
    if r(N) == 0 {
        di "Dropping variable `var' (all values missing)"
        drop `var'
    }
}
order pointid cohort_year forestloss*, sequential
mata:
	start_col = st_varindex("forestloss1998")
	end_col   = st_varindex("forestloss2014")
	cols      = start_col::end_col
	if (rows(cols) > 1) {
		cols = cols'
	}
	X = st_data(., cols)
	n = rows(X)
	m = cols(X)
	Y = J(n, 10, .)          // initialize with system‐missing
	for (i = 1; i <= n; i++) {
		cnt = 0
		for (j = 1; j <= m & cnt < 10; j++) {
			if (!missing(X[i,j])) {
				cnt++
				Y[i,cnt] = X[i,j]
			}
		}
	}
	for (k = 1; k <= 10; k++) {
		varname = "forestloss_pre" + strofreal(10 - k + 1)
		st_addvar("double", varname)
		st_store(., varname, Y[.,k])
	}
end
describe forestloss_pre*
sum forestloss_pre*
di "Done! Now forestloss_pre10–pre1 have been created."
ds forestloss????, has(type numeric) 
drop `r(varlist)'
di "All actual-year forestloss variables dropped. Only forestloss_pre* remain."
save "all_(un)matched_pairs_wide_300_Individual_mdm_Never-treated_sociobosque.dta", replace

global covariates "road village river population oil pipelines slope elevation"
asdoc pstest $covariates forestloss*, both treated(_treated) mweight(_weight) nograph save($dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Individual_mdm_Never-treated_sociobosque.doc) replace
* (a) Dot chart
pstest $covariates forestloss*, both treated(_treated) mweight(_weight) graph
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_dot chart_Individual_mdm_Never-treated_sociobosque.gph", replace
* (b) Histogram
pstest $covariates forestloss*, both treated(_treated) mweight(_weight) hist
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_histogram_Individual_mdm_Never-treated_sociobosque.gph", replace
* (c) Scatter plot
pstest $covariates forestloss*, both treated(_treated) mweight(_weight) scatter xtitle(Standardized % bias across covariates)
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_scatter plot_Individual_mdm_Never-treated_sociobosque.gph", replace

graph combine 	"$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_dot chart_Individual_mdm_Never-treated_sociobosque.gph" ///
				"$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_histogram_Individual_mdm_Never-treated_sociobosque.gph" ///
				"$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_scatter plot_Individual_mdm_Never-treated_sociobosque.gph", ///
				rows(1) imargin(0 0 0 0) graphregion(color(white)) plotregion(color(white))
graph save "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Individual_mdm_Never-treated_sociobosque.gph", replace
graph export "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Individual_mdm_Never-treated_sociobosque.png", as(png) replace width(12000) height(5000)
graph export "$dir\Results\Covariate Balance Diagnostics\Covariate Balance Diagnostics_300_Individual_mdm_Never-treated_sociobosque.pdf", as(pdf) replace

**# 300*300, PA, Never-treated------------------------------------------

use "SBP_wide_300.dta", clear

* Step 1: Generate treatment year indicator
gen treatment_year = year_pa
replace treatment_year = 9999 if missing(year_pa) // Mark never-treated units with 9999 (wooldid: Cohort identifier must consist of positive, non-zero integers)
gen first_treat = year_pa
replace first_treat = 0 if missing(year_pa) // Mark never-treated units with 0 (csdid: Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated)

local covervars
forvalues y = 1997/2020 {
	local covervars `covervars' forestcover`y'
}
* Calculate max pre-treatment forestcover
egen max_cover_pre = rowmax(`covervars')
* Drop if forestcover was zero in all pre/post-treatment years
drop if max_cover_pre <= 0.3
drop max_cover_pre
// drop if (within_sociobosque == "NA" & pixel_percent_intersect_sociobos >= 0.5) | (within_sociobosque == "TRUE" & pixel_percent_intersect_sociobos < 0.5)
save "SBP_wide_300_pa.dta", replace
levelsof sociobosque_year if !missing(year_pa) & year_pa >= 1997, local(years)
global years `years'

di "*================================== PA Only ==================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_pa.dta", clear
	keep if indigenous == "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_mdm_Never-treated_pa.dta", replace

use "all_(un)matched_pairs_wide_300_mdm_Never-treated_pa.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_mdm_Never-treated_pa.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_mdm_Never-treated_pa.dta", clear
drop forestloss*
keep pointid - state_match
merge m:1 pointid using "SBP_wide_300_pa.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_mdm_Never-treated_pa.dta", replace
di "Completed: Never-treated | PA"

di "*================================== PA + IT ==================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_pa.dta", clear
	keep if indigenous != "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_never, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_mdm_Never-treated_pa+it.dta", replace

use "all_(un)matched_pairs_wide_300_mdm_Never-treated_pa+it.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_mdm_Never-treated_pa+it.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_mdm_Never-treated_pa+it.dta", clear
drop forestloss*
keep pointid - state_match
merge m:1 pointid using "SBP_wide_300_pa.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_mdm_Never-treated_pa+it.dta", replace
di "Completed: Never-treated | PA + IT"


**# 300*300, Individual as TREATED, Collective as CONTROL (itcc), Never-treated------------------------------------------

global types ""sb" "sb+pa" "sb+it""

foreach type of global types {
	use "SBP_long_300_did_Collective_mdm_Never-treated_`type'.dta", clear
	keep if _treated == 1
	replace _treated = 0
	replace treatment_year = 9999
	replace sociobosque_year = .
	save "SBP_long_300_did_Collective_mdm_`type'_control.dta", replace
	
	use "SBP_long_300_did_Individual_mdm_Never-treated_`type'.dta", clear
	keep if _treated == 1
	save "SBP_long_300_did_Individual_mdm_`type'_treated.dta", replace

	append using "SBP_long_300_did_Collective_mdm_`type'_control.dta" "SBP_long_300_did_Individual_mdm_`type'_treated.dta"
	duplicates drop panel_id year, force	
	save "SBP_long_300_did_Collective_Individual_mdm_`type'_control_treated.dta", replace
	
	capture erase "SBP_long_300_did_Collective_mdm_`type'_control.dta" 
	capture erase "SBP_long_300_did_Individual_mdm_`type'_treated.dta"
}

use "SBP_long_300_did_Collective_Individual_mdm_sb_control_treated.dta", clear
drop if _treated == 0 & cohort_year != 2008
xtset panel_id year
gen post = (year >= treatment_year) if treatment_year != 9999
replace post = 0 if treatment_year == 9999
gen distyear = year - sociobosque_year
display "==================== SB ===================="
did_multiplegt_dyn forestloss pointid year post, effects(10) placebo(10) cluster(cantonid)
estimates store dcdh_sb

use "SBP_long_300_did_Collective_Individual_mdm_sb+pa_control_treated.dta", clear
drop if _treated == 0 & cohort_year != 2011
xtset panel_id year
gen post = (year >= treatment_year) if treatment_year != 9999
replace post = 0 if treatment_year == 9999
gen distyear = year - sociobosque_year
display "==================== SB + PA ===================="
did_multiplegt_dyn forestloss pointid year post, effects(10) placebo(10) cluster(cantonid)
estimates store dcdh_sbpa

gen canton_id = cantonid
gen post_pa = (year >= year_pa) if !missing(year_pa)
gen fd_post_pa = D.post_pa
did_multiplegt_old forestloss pointid year post, ///
	robust_dynamic dynamic(10) placebo(9) ///
	longdiff_placebo jointtestplacebo average_effect cluster(cantonid) ///
	count_switchers_contr count_switchers_tot ///
	trends_lin(canton_id) ///
	breps(50) seed(111) ///
	if_first_diff(fd_post_pa==0) trends_nonparam(post_pa) always_trends_nonparam ///
	save_results("$dir\Results\Baseline\Baseline_dcdh_300_mdm_Never-treated_Collective_Individual_Absolute forest loss_sb+pa.dta") // fd_post_pa not found r(111);
	
use "SBP_long_300_did_Collective_Individual_mdm_sb+it_control_treated.dta", clear
xtset panel_id year
gen post = (year >= treatment_year) if treatment_year != 9999
replace post = 0 if treatment_year == 9999
gen distyear = year - sociobosque_year
display "==================== SB + IT ===================="
did_multiplegt_dyn forestloss pointid year post, effects(10) placebo(10) cluster(cantonid)
estimates store dcdh_sbit

esttab	dcdh_sb dcdh_sbpa dcdh_sbit ///
		using "$dir\Results\Baseline\Table 1. Panel `panel1'. Baseline_`type_label'.rtf", ///
		b(%8.4f) se(%6.4f) star(* 0.10 ** 0.05 *** 0.01) ///
		parentheses lines compress depvars ///
		scalars("CountyYearFE County x Year FE" "ProvinceYearMonthFE Province x Year-month FE" N r2 r2_a F) ///
		varwidth(15) ///
		mtitles("log(TN)" "log(TN)" "log(TN)") ///
		nogaps obslast replace
	
* Pending for indigenous data
capture program drop mdm_cohort_itcc_sbit // Delete the existing mdm_cohort program (if any)
program define mdm_cohort_itcc_sbit, rclass
	syntax, cohort(integer)

	preserve // Preserve the dataset currently in memory
	
	* Determine the range of years before treatment
	local pre_end = `cohort' - 1 // Set the time range before treatment, which is the last year before the cohort
	if `pre_end' < 1996 {
		di in red "Skip invalid cohort: `cohort'"
		resto
		exit
	}
	* Generate a list of covariates: Static covariates + Dynamically select covariates between 1996 and cohort-1 as matching covariates
	local covars "$covariates" // Static covariates
	forvalues y = 1997/`pre_end' {
		capture confirm var forestloss`y' 
		if _rc == 0 {
			local covars "`covars' forestloss`y'" // If the selected covariate exists (_rc == 0), add it to the covars list
		}
	}	
	
	* Check the validity of covariates
	capture confirm var `covars'
	if _rc != 0 {
		di in red "Missing covariates: `covars'"
		restore
		exit
	}
	
	* Create treatment identifier
    gen treated = (sociobosque_year == `cohort' & sociobosque_type == "INDIVIDUAL")
    gen control = (sociobosque_year == `cohort' & sociobosque_type == "COLECTIVO")
	keep if treated | control // Only keep obs where at least one of the variables treated or control is true (non-zero/non missing)
	
	* Debugging information
	di _n "========== Processing cohort `cohort' =========="
	qui count if treated
	di "Treated group samples: `r(N)'"
	if r(N) <= 1 {
		di in red "Insufficient treated units for cohort `cohort'. Skipping."
		restore
		exit // Skip but do not terminate the program
	}
	qui count if control
	di "Control group candidates: `r(N)'"
	if r(N) <= 2 {
		di in red "Insufficient control group candidates for cohort `cohort'. Skipping."
		restore
		exit // Skip but do not terminate the program
	}
	
	* MDM
	psmatch2 treated, mahalanobis(`covars') n(1)
	* Save matched pairs
	keep pointid x y polygonid _treated _id _n1 _weight `covars' // _n1: pointid of matched control groups
	gen cohort_year = `cohort'
	capture save "matched_cohort_`cohort'.dta", replace
	if _rc != 0 {
		di in red "Failed to save matched cohort `cohort'"
	}
	restore
end

capture program drop mdm_cohort_itcc_sbit_state
program define mdm_cohort_itcc_sbit_state, rclass
    syntax, cohort(integer)

    tempfile full_backup
    save `full_backup', replace
	
	* Set the range for pre-treatment years
	local pre_start = `cohort' - 10
	local pre_end = `cohort' - 1
	local covars "$covariates"
	
	* Loop through the five years
	forvalues y = `pre_start'/`pre_end' {
		capture confirm var forestloss`y'
		if _rc == 0 {
			local covars "`covars' forestloss`y'"
		}
	}
	
    * Check covariate validity
    capture confirm var `covars'
    if _rc != 0 {
        di in red "Missing covariates: `covars'"
        exit
    }

    * Create treated/control indicators
    use `full_backup', clear
    gen treated = (sociobosque_year == `cohort' & sociobosque_type == "INDIVIDUAL")
    gen control = (sociobosque_year == `cohort' & sociobosque_type == "COLECTIVO")
    keep if treated | control

    * Debugging information
    di _n "========== Processing cohort `cohort' =========="
    qui count if treated
    di "Treated group samples: `r(N)'"
    if r(N) <= 1 {
        di in red "Insufficient treated units for cohort `cohort'. Skipping."
        exit
    }
    qui count if control
    di "Control group candidates: `r(N)'"
    if r(N) == 0 {
        di in red "No control candidates for cohort `cohort'. Skipping."
        exit
    }

    * MDM
    tempfile all_matched
    gen dummy = .
    save `all_matched', emptyok replace
    levelsof state if treated == 1 & !missing(state), local(states)
    foreach s of local states {
        di in green "========== Matching within cohort `cohort', state = `s' =========="
        use `full_backup', clear
		gen treated = (sociobosque_year == `cohort' & sociobosque_type == "INDIVIDUAL")
		gen control = (sociobosque_year == `cohort' & sociobosque_type == "COLECTIVO")
        keep if treated | control
        keep if state == "`s'"
        qui count if treated
        di "Treated group samples: `r(N)'"
        if r(N) <= 1 {
            di in red "Insufficient treated pixels in state = `s'. Skipping."
            continue
        }
        qui count if control
        di "Control group candidates: `r(N)'"
        if r(N) <= 2 {
            di in red "Insufficient control group candidates in state = `s'. Skipping."
            continue
        }
        psmatch2 treated, mahalanobis(`covars') n(1)
        keep pointid x y polygonid _treated _id _n1 _weight state `covars'
        gen cohort_year = `cohort'
        gen state_match = "`s'"
        append using `all_matched'
        save `all_matched', replace
    }

    * Save matched pairs
    use `all_matched', clear
    capture save "matched_cohort_`cohort'.dta", replace
    if _rc != 0 {
        di in red "Failed to save matched cohort `cohort'"
    }
end

// capture program drop mdm_cohort_itcc_sbpa_pacohort // Delete the existing mdm_cohort program (if any)
// program define mdm_cohort_itcc_sbpa_pacohort, rclass
// 	syntax, cohort(integer)
//
// 	tempfile full_backup
// 	save `full_backup', replace
//	
// 	* Determine the range of years before treatment
// 	local pre_end = `cohort' - 1 // Set the time range before treatment, which is the last year before the cohort
// 	if `pre_end' < 1996 {
// 		di in red "Skip invalid cohort: `cohort'"
// 		exit
// 	}
// 	* Generate a list of covariates: Static covariates + Dynamically select covariates between 1996 and cohort-1 as matching covariates
// 	local covars "$covariates" // Static covariates
// 	forvalues y = 1997/`pre_end' {
// 		capture confirm var forestloss`y' 
// 		if _rc == 0 {
// 			local covars "`covars' forestloss`y'" // If the selected covariate exists (_rc == 0), add it to the covars list
// 		}
// 	}	
//	
// 	* Check the validity of covariates
// 	capture confirm var `covars'
// 	if _rc != 0 {
// 		di in red "Missing covariates: `covars'"
// 		exit
// 	}
//	
// 	* Create treatment identifier
// 	use `full_backup', clear
//     gen treated = (sociobosque_year == `cohort' & sociobosque_type == "INDIVIDUAL")
//     gen control = (sociobosque_year == `cohort' & sociobosque_type == "COLECTIVO")
// 	keep if treated | control // Only keep obs where at least one of the variables treated or control is true (non-zero/non missing)
//	
// 	* Debugging information
// 	di _n "========== Processing cohort `cohort' =========="
// 	qui count if treated
// 	di "Treated group samples: `r(N)'"
// 	if r(N) <= 1 {
// 		di in red "Insufficient treated units for cohort `cohort'. Skipping."
// 		exit // Skip but do not terminate the program
// 	}
// 	qui count if control
// 	di "Control group candidates: `r(N)'"
// 	if r(N) == 0 {
// 		di in red "No control group candidates for cohort `cohort'. Skipping."
// 		exit // Skip but do not terminate the program
// 	}
//	
// 	* MDM
// 	tempfile all_matched
// 	gen dummy = .
// 	save `all_matched', emptyok replace
// 	levelsof year_pa if treated == 1 & !missing(year_pa), local(years_pa)
// 	foreach ypa of local years_pa {
// 		di in green "========== Matching within cohort `cohort', year_pa = `ypa' ========== "
// 		use `full_backup', clear
// 		gen treated = (sociobosque_year == `cohort' & sociobosque_type == "INDIVIDUAL")
// 		gen control = (sociobosque_year == `cohort' & sociobosque_type == "COLECTIVO")
// 		keep if treated | control
// 		keep if year_pa == `ypa'
// 		qui count if treated
// 		di "Treated group samples: `r(N)'"
// 		if r(N) <= 1 {
// 			di in red "No treated pixels in year_pa = `ypa'. Skipping."
// 			continue
// 		}
// 		qui count if control
// 		di "Control group candidates: `r(N)'"
// 		if r(N) <= 2 {
// 			di in red "No control group candidates in year_pa = `ypa'. Skipping."
// 			continue
// 		}
// 		psmatch2 treated, mahalanobis(`covars') n(1)
// 		keep pointid x y polygonid _treated _id _n1 _weight `covars' year_pa // _n1: pointid of matched control groups
// 		gen cohort_year = `cohort'
// 		gen pa_match_year = `ypa'
// 		append using `all_matched'
// 		save `all_matched', replace
// 	}
//	
// 	* Save matched pairs
// 	use `all_matched', clear
// 	capture save "matched_cohort_`cohort'.dta", replace
// 	if _rc != 0 {
// 		di in red "Failed to save matched cohort `cohort'"
// 	}
// end

// capture program drop mdm_cohort_itcc_sbpa_state_pacohort
// program define mdm_cohort_itcc_sbpa_state_pacohort, rclass
// 	syntax, cohort(integer)
//
// 	tempfile full_backup
// 	save `full_backup', replace
//	
// 	* Set the range for pre-treatment years
// 	local pre_start = `cohort' - 10
// 	local pre_end = `cohort' - 1
// 	local covars "$covariates"
//
// 	* Loop through the five years
// 	forvalues y = `pre_start'/`pre_end' {
// 		capture confirm var forestloss`y'
// 		if _rc == 0 {
// 			local covars "`covars' forestloss`y'"
// 		}
// 	}
//	
// 	capture confirm var `covars'
// 	if _rc != 0 {
// 		di in red "Missing covariates: `covars'"
// 		exit
// 	}
//
// 	use `full_backup', clear
//     gen treated = (sociobosque_year == `cohort' & sociobosque_type == "INDIVIDUAL")
//     gen control = (sociobosque_year == `cohort' & sociobosque_type == "COLECTIVO")
// 	keep if treated | control
//
// 	di _n "========== Processing cohort `cohort' =========="
// 	qui count if treated
// 	di "Treated group samples: `r(N)'"
// 	if r(N) <= 1 {
// 		di in red "Insufficient treated units for cohort `cohort'. Skipping."
// 		exit
// 	}
// 	qui count if control
// 	di "Control group candidates: `r(N)'"
// 	if r(N) == 0 {
// 		di in red "No control group candidates for cohort `cohort'. Skipping."
// 		exit
// 	}
//
// 	tempfile all_matched
// 	gen dummy = .
// 	save `all_matched', emptyok replace
//
// 	levelsof state if treated == 1 & !missing(state), local(states)
//
// 	foreach s of local states {
// 		levelsof year_pa if treated == 1 & state == "`s'" & !missing(year_pa), local(years_pa)
//
// 		foreach ypa of local years_pa {
// 			di in green "========== Matching within cohort `cohort', state = `s', year_pa = `ypa' =========="
// 			use `full_backup', clear
// 			gen treated = (sociobosque_year == `cohort' & sociobosque_type == "INDIVIDUAL")
// 			gen control = (sociobosque_year == `cohort' & sociobosque_type == "COLECTIVO")
// 			keep if treated | control
// 			keep if state == "`s'"
// 			keep if year_pa == `ypa'
//
// 			qui count if treated
// 			di "Treated group samples: `r(N)'"
// 			if r(N) <= 1 {
// 				di in red "Insufficient treated pixels in state = `s' and year_pa = `ypa'. Skipping."
// 				continue
// 			}
//
// 			qui count if control
// 			di "Control group candidates: `r(N)'"
// 			if r(N) <= 2 {
// 				di in red "Insufficient control group candidates in state = `s' and year_pa = `ypa'. Skipping."
// 				continue
// 			}
//
// 			psmatch2 treated, mahalanobis(`covars') n(1)
// 			keep pointid x y polygonid _treated _id _n1 _weight state year_pa `covars'
// 			gen cohort_year = `cohort'
// 			gen state_match = "`s'"
// 			gen pa_match_year = `ypa'
//
// 			append using `all_matched'
// 			save `all_matched', replace
// 		}
// 	}
//
// 	use `all_matched', clear
// 	capture save "matched_cohort_`cohort'.dta", replace
// 	if _rc != 0 {
// 		di in red "Failed to save matched cohort `cohort'"
// 	}
// end

use "SBP_wide_300.dta", clear

keep if sociobosque_type != "NA" & pixel_percent_intersect_sociobos >= 0.5

* Step 1: Generate treatment year indicator
gen treatment_year = sociobosque_year
replace treatment_year = 9999 if sociobosque_type == "COLECTIVO" // Mark never-treated units with 9999 (wooldid: Cohort identifier must consist of positive, non-zero integers)
gen first_treat = sociobosque_year
replace first_treat = 0 if sociobosque_type == "COLECTIVO" // Mark never-treated units with 0 (csdid: Groups that are never treated should be coded as Zero. Any positive value indicates which year a group was initially treated. And once a group is treated, the underlying assumption is that it always remains treated)

local covervars
forvalues y = 1997/2020 {
	local covervars `covervars' forestcover`y'
}
* Calculate max pre-treatment forestcover
egen max_cover_pre = rowmax(`covervars')
* Drop if forestcover was zero in all pre/post-treatment years
drop if max_cover_pre <= 0.3
drop max_cover_pre
save "SBP_wide_300_Individual_Collective.dta", replace
levelsof sociobosque_year if sociobosque_type == "INDIVIDUAL", local(years)
global years `years'

di "*================================== SB + IT ==================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Individual_Collective.dta", clear
	keep if pa == "NA" & indigenous != "NA"
	di "========== Processing cohort `i' =========="
	mdm_cohort_itcc_sbit, cohort(`i')
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+it.dta", replace

use "all_(un)matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+it.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+it.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+it.dta", clear
drop forestloss*
// keep pointid - state_match
keep pointid - cohort_year
merge m:1 pointid using "SBP_wide_300_Individual_Collective.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Individual_Collective_mdm_Never-treated_sb+it.dta", replace
di "Completed: Never-treated | Individual + Collective | SB + IT ==================================*"

di "*================================== SB + PA ==================================*"
global covariates "road village river population oil pipelines slope elevation"

* Step 2: Perform loop matching
foreach i of global years {
	use "SBP_wide_300_Individual_Collective.dta", clear
	keep if pa != "NA" & indigenous == "NA"
	di "========== Processing cohort `i' =========="
	if `i' != 2013 {
		mdm_cohort_itcc_sbit, cohort(`i')
	}
	if `i' == 2013 {
		continue
	}
}

* Step 3: Consolidate matched pairs
clear
foreach i of global years {
	capture confirm file "matched_cohort_`i'.dta"
	if _rc == 0 {
		append using "matched_cohort_`i'.dta"
	}
}
duplicates drop pointid cohort_year, force
sort pointid cohort_year _treated
// egen forestcover_pre = rowfirst(forestcover*)
drop if missing(_treated) // Rule out observations with missing covariates which are not included in matching at all
save "all_(un)matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+pa.dta", replace

use "all_(un)matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+pa.dta", clear
keep if _weight != . // Only keep samples that are in the common support (_Support==1 ONLY for PSM) and whose matching weights are not empty (_weight != .)
save "all_matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+pa.dta", replace

* Step 5: Clean temporary files
foreach i of global years {
	capture erase "matched_cohort_`i'.dta"
}

* Step 6: Reshape wide data into long data
use "all_matched_pairs_wide_300_Individual_Collective_mdm_Never-treated_sb+pa.dta", clear
drop forestloss*
keep pointid - cohort_year
merge m:1 pointid using "SBP_wide_300_Individual_Collective.dta", keep(matched) nogen
egen newid = concat(pointid cohort_year), punct(_)
reshape long forestcover forestloss relforestloss $cv, i(newid) j(year)
encode newid, gen (panel_id)
save "SBP_long_300_did_Individual_Collective_mdm_Never-treated_sb+pa.dta", replace
di "Completed: Never-treated | Individual + Collective | SB + PA"






















capture program drop dcdh_effect_export_rate
program define dcdh_effect_export_rate
    // Usage:
    // 1) Run your De Chaisemartin & D'Haultfoeuille (DCDH) estimator first.
    //    It must store the average total effect as e(Av_tot_effect)
    //    and its standard error as e(se_avg_total_effect).
    // 2) Then run:
    //       dcdh_effect_export_rate, DEPVAR(forestloss)
    //    where `forestloss` is a level variable (not logged), typically measured
    //    in percentage points of annual forest net loss.
    //
    // Purpose:
    //   This post-estimation helper calculates:
    //     (i)  Baseline mean and SD of the dependent variable (pre-treatment),
    //     (ii) Absolute effect (in pp),
    //     (iii) Relative effect (percent of pre mean),
    //     (iv) Standardized effect (in pre SDs),
    //   and stores all results via estadd for easy esttab/estout export.

    version 16
    syntax, DEPVAR(name)

    tempvar es
    gen byte `es' = e(sample)

    // --- 1. Baseline mean and SD (pre-treatment, within estimation sample)
    quietly summarize `depvar' if `es' & post == 0
    scalar mean_pre = r(mean)
    scalar sd_pre   = r(sd)

    // --- 2. Read DCDH average total effect and its SE (in percentage points)
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

    // --- 3. Confidence interval (default to 95% if not stored)
    scalar level = 95
    capture confirm scalar e(level)
    if !_rc scalar level = e(level)
    scalar zcrit = invnormal(0.5 + level/200)

    scalar abs_b = `b'
    scalar abs_se = `se'
    scalar abs_l = abs_b - zcrit*abs_se
    scalar abs_h = abs_b + zcrit*abs_se

    // --- 4. Add absolute effect (in percentage points)
    estadd scalar PctPointEffect = abs_b, replace
    estadd scalar PctPointSE     = abs_se, replace
    estadd scalar PctPointLow    = abs_l, replace
    estadd scalar PctPointHigh   = abs_h, replace

    // Significance stars
    scalar abs_z = .
    if abs_se>0 scalar abs_z = abs_b/abs_se
    scalar abs_p = 2*normal(-abs(abs_z))
    local  PctPoint_stars = cond(abs_p<0.01,"***", cond(abs_p<0.05,"**", cond(abs_p<0.10,"*","")))
    local  PctPoint_num : display %9.3f abs_b
    local  PctPoint_fmt `"`PctPoint_num'`PctPoint_stars'"'
    estadd local PctPoint_stars "`PctPoint_stars'", replace
    estadd local PctPoint_fmt   "`PctPoint_fmt'",   replace

    // --- 5. Add baseline statistics
    estadd scalar PreMean = mean_pre, replace
    estadd scalar PreSD   = sd_pre,   replace

    // --- 6. Relative effect (percent of pre mean)
    if mean_pre!=. & mean_pre!=0 {
        nlcom (relpct: 100 * (`b') / mean_pre)
        scalar rel_b  = r(b)[1,1]
        scalar rel_se = sqrt(r(V)[1,1])
        scalar rel_l  = rel_b - zcrit*rel_se
        scalar rel_h  = rel_b + zcrit*rel_se

        estadd scalar RelPctEffect = rel_b,  replace
        estadd scalar RelPctSE     = rel_se, replace
        estadd scalar RelPctLow    = rel_l,  replace
        estadd scalar RelPctHigh   = rel_h,  replace

        // Significance stars
        scalar rel_z = .
        if rel_se>0 scalar rel_z = rel_b/rel_se
        scalar rel_p = 2*normal(-abs(rel_z))
        local  RelPct_stars = cond(rel_p<0.01,"***", cond(rel_p<0.05,"**", cond(rel_p<0.10,"*","")))
        local  RelPct_num : display %9.3f rel_b
        local  RelPct_fmt `"`RelPct_num'`RelPct_stars'"'
        estadd local RelPct_stars "`RelPct_stars'", replace
        estadd local RelPct_fmt   "`RelPct_fmt'",   replace
    }
    else {
        di as error ">>> mean_pre is zero or missing; skip relative-percent effect."
    }

    // --- 7. Standardized effect (in pre-period SDs)
    if sd_pre!=. & sd_pre>0 {
        nlcom (std_level: (`b') / sd_pre)
        estadd scalar StdEffectSD = r(b)[1,1], replace
    }
    else {
        di as error ">>> sd_pre is zero or missing; skip standardized effect."
    }

    // --- 8. Display summary in console
    di as text "----------------------------------------------"
    di as text "Baseline (pre-treatment, within e(sample)):"
    di as result "  Mean = " %9.3f mean_pre "   SD = " %9.3f sd_pre "   (units: percentage points)"
    di as text "Estimated effect (DCDH average total effect):"
    di as result "  Abs = " %9.3f abs_b " pp   (SE " %9.3f abs_se "),  " ///
                 "`=string(level, "%2.0f")'% CI: [" %9.3f abs_l ", " %9.3f abs_h "]"
    if mean_pre!=. & mean_pre!=0 {
        di as result "  Rel = " %9.3f rel_b " %   (SE " %9.3f rel_se ")"
    }
    if sd_pre!=. & sd_pre>0 {
        di as result "  Std = " %9.3f r(b)[1,1] " SDs"
    }
    di as text "----------------------------------------------"
end
