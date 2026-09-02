
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Descriptive Statistics
*Country: Ecuador
*==============================================================================*

*--------------------------------------------
* Descriptive Statistics
*--------------------------------------------

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Data\SBP_data\annual"
// global dir "C:\Users\dz136\Box\Socio Bosque"
// cd "$dir\data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"

global covariates "road village river population oil pipelines protected_areas indigenous_community soil slope elevation"
global cv "farming mining infrastruct"

global control_groups			"never"
global control_groups_labels	`"Never-treated"'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'
global resolutions				"300 300"

global policy_bundles			`""sb" "sb+pa" "sb+it" "sb+it+pa""'
global policy_bundles_labels	`""SB" "SB + PA" "SB + IL" "SB + PA + IL""'
global pbs						`""s" "sp" "si" "spi""'

global panels1 "a b c d"
global panels2 "A B"

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
		
	local j 1
	foreach ttype of global treatment_types {
		local ttype_label: word `j' of ${treatment_types_labels}
		local resolution: word `j' of ${resolutions}
		
		local l 1
		foreach policy_bundle of global policy_bundles {
			local policy_bundle_label: word `l' of ${policy_bundles_labels}
			local pb: word `l' of ${pbs}
			local panel1: word `l' of ${panels1}
			
			* Visualization of treatment status
			if "`ttype'" == "ind" & "`policy_bundle'" == "pa & indigenous" { 
				clear
				set obs 1
				gen x = .
				gen y = .
				twoway scatter y x, ///
					yscale(off) xscale(off) ///
					ylabel(, nogrid) xlabel(, nogrid) ///
					legend(off) ///
					xtitle("") ytitle("") ///
					graphregion(color(white)) ///
					title("") ///
					name(blankgraph, replace)
				graph save "$dir\Results\Descriptive Statistics\panelview_`resolution'_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.gph", replace
			}
			else {
				use "SBP_long_`resolution'_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
// 				* Treated share by sociobosque type
// 				tabstat pixel_percent_intersect_sociobos, by(state) stat(mean sd min max n) columns(statistics)
// 				tabstat withinsb, by(state) stat(mean sd min max n) columns(statistics)
//
// 				* Skewness & Rescaling
// 				count if forestloss == 0
// 				display "Count if forestloss == 0: " r(N)
// 				count if forestloss < 0
// 				display "Count if forestloss < 0: " r(N)
// 				sum forestloss, detail
// 				sktest forestloss
//				
// 				count if relforestloss == 0
// 				display "Count if relforestloss == 0: " r(N)
// 				count if relforestloss < 0
// 				display "Count if relforestloss < 0: " r(N)
// 				sum relforestloss, detail
// 				sktest relforestloss
//				
// 				* Percentage point!
// 				gen original_forestloss = forestloss
// 				replace forestloss = 100 * forestloss
// 				gen ihs_forestloss = asinh(forestloss)
// 				sum ihs_forestloss, detail
// 				sktest ihs_forestloss
// // 				twoway scatter ihs_forestloss forestloss, msize(tiny)
// // 				graph save "$dir\Results\Descriptive Statistics\Scatter_`resolution'_ihs_forestloss & forestloss_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.gph", replace
// // 				graph export "$dir\Results\Descriptive Statistics\Scatter_`resolution'_ihs_forestloss & forestloss_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.png", as(png) replace width(800) height(600)
//				
// 				gen original_relforestloss = relforestloss
// 				replace relforestloss = 100 * relforestloss
// 				gen ihs_relforestloss = asinh(relforestloss)
// 				sum ihs_relforestloss, detail
// 				sktest ihs_relforestloss
// // 				twoway scatter ihs_relforestloss relforestloss, msize(tiny)
// // 				graph save "$dir\Results\Descriptive Statistics\Scatter_`resolution'_ihs_relforestloss & relforestloss_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.gph", replace
// // 				graph export "$dir\Results\Descriptive Statistics\Scatter_`resolution'_ihs_relforestloss & relforestloss_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.png", as(png) replace width(800) height(600)
// 				save "SBP_long_`resolution'_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", replace
//				
				* Generate post, did, and distyear
				gen post = (year >= treatment_year) if treatment_year != 9999
				replace post = 0 if treatment_year == 9999
				gen did = _treated * post
				gen distyear = year - sociobosque_year
				
				panelview forestloss post, i(panel_id) t(year) type(treat) xtitle("Year") ytitle("Pixel") ylabel("") title("(`panel1') `policy_bundle_label'", size(medium)) legend(position(6)) prepost bytiming
				graph save "$dir\Results\Descriptive Statistics\panelview_`resolution'_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.gph", replace
			}
			
			local l = `l' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
		
	local j 1
	foreach ttype of global treatment_types {
		local ttype_label: word `j' of ${treatment_types_labels}
		local resolution: word `j' of ${resolutions}
		local panel2: word `j' of ${panels2}

		grc1leg "$dir\Results\Descriptive Statistics\panelview_`resolution'_`ttype_label'_mdm_`cgroup_label'_sb.gph" ///
				"$dir\Results\Descriptive Statistics\panelview_`resolution'_`ttype_label'_mdm_`cgroup_label'_sb+pa.gph" ///
				"$dir\Results\Descriptive Statistics\panelview_`resolution'_`ttype_label'_mdm_`cgroup_label'_sb+it.gph" ///
				"$dir\Results\Descriptive Statistics\panelview_`resolution'_`ttype_label'_mdm_`cgroup_label'_sb+it+pa.gph", ///
				title("Panel `panel2'. `ttype_label' SB Contracts", size(medium) position(11)) ///
				rows(1) cols(4)
		graph save "$dir\Results\Descriptive Statistics\panelview_`resolution'_`ttype_label'_mdm_`cgroup_label'.gph", replace
		
		local j = `j' + 1
	}
	local i = `i' + 1
}

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}
	
	grc1leg	"$dir\Results\Descriptive Statistics\panelview_300_Collective_mdm_`cgroup_label'.gph" ///
			"$dir\Results\Descriptive Statistics\panelview_300_Individual_mdm_`cgroup_label'.gph", ///
			rows(2) cols(1) ///
			position(6) ring(0)
	graph save "$dir\Results\Descriptive Statistics\panelview_300_mdm_`cgroup_label'_sociobosque.gph", replace
	graph export "$dir\Results\Descriptive Statistics\panelview_300_mdm_`cgroup_label'_sociobosque.png", as(png) replace width(10000) height(6000)

	local i = `i' + 1
}