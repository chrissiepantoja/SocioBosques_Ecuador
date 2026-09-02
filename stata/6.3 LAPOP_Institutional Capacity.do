clear all
set more off, perm

global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
cd "$dir\LAPOP"

global lapop_years "2004 2006 2008 2010 2012 2014 2016 2018"

foreach lapop_year of global lapop_years {
	
	use "LAPOP_`lapop_year'.dta", clear
	keep year enc prov canton paroq paroq1 zona sec manzana estrato idiomaq b*
	egen institutional_capacity = rowmean(b*)
	bysort canton: egen institutional_capacity_mean = mean(institutional_capacity)
	egen institutional_capacity_mean_all = mean(institutional_capacity)
	duplicates drop canton1, force
	gen above_mean = (institutional_capacity_mean > institutional_capacity_mean_all) if !missing(institutional_capacity_mean, institutional_capacity_mean_all)
	save "LAPOP_`lapop_year'_processed.dta", replace
}