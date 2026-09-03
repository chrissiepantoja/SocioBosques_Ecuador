clear all
set more off

global dir "G:\My Drive\socio bosque"
cd "$dir\data"

local files ///
	"SBP_long_300_did_Collective_mdm_Never-treated_sb.dta" ///
	"SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta" ///
	"SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta" ///
	"SBP_long_300_did_Collective_mdm_Never-treated_sb+it+pa.dta" ///
	"SBP_long_300_did_Individual_mdm_Never-treated_sb.dta" ///
	"SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta" ///
	"SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta"

foreach f of local files {
	di as text "=== `f' ==="
	use pointid panel_id year forestloss _weight _treated treatment_year first_treat sociobosque_year cohort_year cantonid year_pa pa indigenous using "`f'", clear
	xtset pointid year
	gen post = (year >= treatment_year) if treatment_year != 9999
	replace post = 0 if treatment_year == 9999
	capture gen post_pa = (year >= year_pa) if !missing(year_pa)
	capture bysort pointid (year): gen fd_post_pa = post_pa - post_pa[_n-1]
	describe pointid panel_id year forestloss _weight _treated treatment_year first_treat sociobosque_year cohort_year cantonid year_pa pa indigenous post post_pa fd_post_pa
	tab cohort_year _treated, missing
	capture noisily tab post_pa _treated, missing
}
