
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Acknowledgments: Adapted from Yajima & Arimura (2022)
*Topic: Sociobosques
*Title: Goodman-Bacon Decomposition of TWFE
*Country: Ecuador
*==============================================================================*

*------------------------------------------------------------
* Goodman-Bacon Decomposition of TWFE (Goodman-Bacon, 2021)
*------------------------------------------------------------

* Goodman-Bacon, A., 2021. Difference-in-differences with variation in treatment timing. Journal of Econometrics, 225(2), pp.254-277.
* Stevenson, B. and Wolfers, J., 2006. Bargaining in the shadow of the law: Divorce laws and family distress. The Quarterly Journal of Economics, 121(1), pp.267-288.
* Yajima, N. and Arimura, T.H., 2022. Promoting energy efficiency in Japanese manufacturing industry through energy audits: Role of information provision, disclosure, target setting, inspection, reward, and organizational structure. Energy Economics, 114, p.106253. Appendix A. Supplementary data

* bacondecomp implements a Bacon decomposition of a difference-in-differences (DD) estimator with variation in treatment timing, based on Goodman-Bacon (2018). The two-way fixed effects DD model is a weighted average of all possible two-group/two period DD estimators. The command generates a scatterplot of 2x2 difference-in-difference estimates and their associated weights. The data must be xtset and the variable list must include an outcome as the first item, and a treatment that can only turn from zero to one during the time period examined as its second item.

* bacondecomp by default produces a graph for all comparisons and shows up to three types of two-group/two period comparisons, which differ by control group:
*	(1) Timing groups, or groups whose treatment stated at different times can serve as each other's controls groups in two ways: those treated later serves as the control group for an earlier treatment group and those treated earlier serve as the control group for the later group;
*	(2) Always treated, a group treated prior to the start of the analysis serves as the control group;
*	(3) Never treated, a group which never receives the treatment serves as the control group. Also shown are the component due to variation in controls across always treated and never treated groups, and the "within" residual component.

* Without weights or controls, and with the ddetail option specified, bacondecomp shows up to four types of two-group/two period comparisons, which differ by comparison group: 
*	(1) A group treated later serves as the comparison group for an earlier treatment group;
*	(2) A group treated earlier serves as the comparison group for a later treatment group;
*	(3) A group which never receives the treatment serves as the comparison group;
*	(4) A group treated prior to the start of the analysis serves as the comparison group.

* https://zhuanlan.zhihu.com/p/700001535
* https://zhuanlan.zhihu.com/p/646358359

* factor-variable and time-series operators (FE) not allowed
* ddetail: allowed without weights or controls

clear all
set more off, perm

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Results\Goodman-Bacon Decomposition"

global dir "C:\Users\dz136\Box\Socio Bosque"
cd "$dir\Results\Goodman-Bacon Decomposition"

global control_groups			"never"
global control_groups_labels	`""Never-treated"'

global depvars			"ihs_relforestloss"
global depvars_labels	`""Relative forest loss""'

global treatment_types			"col ind"
global treatment_types_labels	`""Collective" "Individual""'

global policy_bundles			`""none" "indigenous" "pa" "pa & indigenous""'
global policy_bundles_labels	`""SB only" "SB + IT" "SB + PA" "SB + IT + PA""'
global pbs						`""n" "i" "p" "pi""'

global panels1 "a b c d"
global panels2 "A B"

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
					graph save "bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv_`policy_bundle'.gph", replace
				}
				else {
					use "$dir\Data\SBP_data\annual\SBP_long_did_`ttype_label'_mdm_`cgroup_label'_`policy_bundle'.dta", clear
					xtset panel_id year
					
					* Generate post, did, and distyear
					gen post = (year >= treatment_year) if treatment_year != 9999
					replace post = 0 if treatment_year == 9999
					gen did = _treated * post
					gen distyear = year - sociobosque_year
					
					display "==================== Estimating: `cgroup_label' | `depvar_label' | `ttype_label' | `policy_bundle_label' ===================="
						* Without controls
						//reghdfe `depvar' post [fweight = _weight], absorb(pointid year cantonid#year) vce(cluster cantonid) noconstant
						//estimates store reghdfe_`ttype'_`cgroup'_nocv_`j'_`pb'
						bacondecomp `depvar' post [fweight = _weight], stub(Bacon_`ttype'_`cgroup'_nocv_`j'_`pb'_) vce(cluster cantonid) ddetail ///
							mcolors(pink midblue midgreen) ///
							ddline(lcolor(gray) lpattern(dash)) ///
							gropt(title("(`panel1') `policy_bundle_label'") ///
								legend(position(1) ring(0) cols(1)))
						graph save "bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv_`policy_bundle'.gph", replace
						asdoc bacondecomp `depvar' post [fweight = _weight], vce(cluster cantonid) ddetail nograph save(bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv_`policy_bundle'.doc) replace
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
			local panel2: word `k' of ${panels2}

			grc1leg "bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv_none.gph" ///
					"bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv_indigenous.gph" ///
					"bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv_pa.gph" ///
					"bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv_pa & indigenous.gph", ///
					title("Panel `panel2': `ttype_label' SB Contracts", size(medium) pos(11)) ///
					rows(1) cols(4)
			graph save "bacondecomp_mdm_`cgroup_label'_`depvar_label'_`ttype_label'_nocv.gph", replace

			local k = `k' + 1
		}
		local j = `j' + 1
	}
	local i = `i' + 1
}

local i 1
foreach cgroup of global control_groups {
	local cgroup_label: word `i' of ${control_groups_labels}

	grc1leg	"bacondecomp_mdm_`cgroup_label'_`depvar_label'_Collective_none & pa & indigenous.gph" ///
			"bacondecomp_mdm_`cgroup_label'_`depvar_label'_Individual_none & pa & indigenous.gph", ///
			rows(2) cols(1) ///
			position(8) ring(0)
	graph save "bacondecomp_mdm_`cgroup_label'_`depvar_label'_nocv_none & pa & indigenous.gph", replace
	graph export "bacondecomp_mdm_`cgroup_label'_`depvar_label'_nocv_none & pa & indigenous.png", as(png) replace width(10000) height(6000)

	local i = `i' + 1
}