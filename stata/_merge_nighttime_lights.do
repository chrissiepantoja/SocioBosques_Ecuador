clear all
set more off

global dir "G:\My Drive\socio bosque"
cd "$dir\data"

local ntl "$dir\processed_data\nighttime lights\nighttime_lights_long.dta"

local files ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb.dta ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb+it+pa.dta ///
	SBP_long_300_did_Individual_mdm_Never-treated_sb.dta ///
	SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta ///
	SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta

foreach f of local files {
	display as text "Merging nighttime lights into `f'"
	use "`f'", clear
	gen long __orig_order = _n
	capture drop nighttime_lights
	merge m:1 pointid year using "`ntl'", keep(master match) keepusing(nighttime_lights)
	count if _merge == 1
	local unmatched = r(N)
	count if missing(nighttime_lights)
	local missing = r(N)
	drop _merge
	sort __orig_order
	drop __orig_order
	label variable nighttime_lights "Nighttime lights (harmonized DN)"
	compress
	save "`f'", replace
	display as result "Saved `f' | unmatched master rows: `unmatched' | missing nighttime_lights: `missing'"
}
