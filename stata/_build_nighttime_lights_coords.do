clear all
set more off

global dir "G:\My Drive\socio bosque"
cd "$dir\data"

tempfile coords one
clear
save `coords', emptyok replace

local files ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb.dta ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb+it.dta ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb+pa.dta ///
	SBP_long_300_did_Collective_mdm_Never-treated_sb+it+pa.dta ///
	SBP_long_300_did_Individual_mdm_Never-treated_sb.dta ///
	SBP_long_300_did_Individual_mdm_Never-treated_sb+it.dta ///
	SBP_long_300_did_Individual_mdm_Never-treated_sb+pa.dta

foreach f of local files {
	display as text "Collecting coordinates from `f'"
	use pointid x y using "`f'", clear
	duplicates drop pointid x y, force
	append using `coords'
	duplicates drop pointid x y, force
	save `coords', replace
}

use `coords', clear
isid pointid
sort pointid
label variable pointid "Point ID"
label variable x "Longitude"
label variable y "Latitude"
save "$dir\processed_data\nighttime lights\nighttime_lights_unique_points.dta", replace
export delimited using "$dir\processed_data\nighttime lights\nighttime_lights_unique_points.csv", replace

display as result "Saved unique points: $dir\processed_data\nighttime lights\nighttime_lights_unique_points.dta"
