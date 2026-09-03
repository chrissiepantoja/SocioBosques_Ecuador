
*==============================================================================*
*DUKE UNIVERSITY
*Durham, North Carolina
*Author: Andrew (Daye) Zhai & Chrissie A. Pantoja Vallejos
*Topic: Sociobosques
*Title: Importing and merging CSV files
*Country: Ecuador
*==============================================================================*

clear all
set more off, perm
ssc install asdoc
* Set default font
// Download @ https://ctan.org/pkg/cm-unicode
// graph set window fontface "CMU Serif Roman"

// global dir "E:\PROJECT 2022-06_ USFQ.Duke - Ecuador Data"
// cd "$dir\Data\SBP_data"
global dir "G:\My Drive\socio bosque"
cd "$dir\data"

*--------------------------------------------
* Importing and merging CSV files
*--------------------------------------------

**# 900*900---------------------------------------------------------------------

* Forest data
import delimited "$dir\processed_data\csvs\sample_900_forest.csv", clear
tempfile sample_900_forest
forvalues i = 1997/2020 {
    local j = `i' - 1
	gen forestloss`i' = mapbiomas`j' - mapbiomas`i'
	drop mapbiomasloss`i'
	gen relforestloss`i' = forestloss`i' / mapbiomas`j'
}
forvalues i = 1996/2020 {
	rename mapbiomas`i' forestcover`i'
}
save `sample_900_forest'

* Merging with SBP data
import delimited "$dir\processed_data\csvs\sample_900_spatial_attr.csv", clear
tempfile sample_900_spatial_attr
save `sample_900_spatial_attr'
merge 1:1 pointid using `sample_900_forest', keep(matched) nogen
tempfile sample_900_SBP_Forest
save `sample_900_SBP_Forest'

* Merging farming data
import delimited "$dir\processed_data\csvs\sample_900_outcome14.csv", clear
tempfile sample_900_outcome14
drop mapbiomasloss*
forvalues i = 1996/2020 {
	rename mapbiomas`i' farming`i'
}
merge 1:1 pointid using `sample_900_SBP_Forest', keep(matched) nogen
tempfile sample_900_SBP_Forest_outcome14
save `sample_900_SBP_Forest_outcome14'

* Merging mining data
import delimited "$dir\processed_data\csvs\sample_900_outcome24.csv", clear
tempfile sample_900_outcome24
drop mapbiomasloss*
forvalues i = 1996/2020 {
	rename mapbiomas`i' mining`i'
}
merge 1:1 pointid using `sample_900_SBP_Forest_outcome14', keep(matched) nogen
tempfile sample_900_SBP_Forest_outcome24
save `sample_900_SBP_Forest_outcome24'

* Merging urban infrastructure data
import delimited "$dir\processed_data\csvs\sample_900_outcome30.csv", clear
tempfile sample_900_outcome30
drop mapbiomasloss*
forvalues i = 1996/2020 {
	rename mapbiomas`i' infrastruct`i'
}
merge 1:1 pointid using `sample_900_SBP_Forest_outcome24', keep(matched) nogen
tempfile sample_900_SBP_Forest_outcome30
save `sample_900_SBP_Forest_outcome30'

* Merging with distance to road, village, river, population, elevation, oil wells, and pipelines data
import delimited "$dir\processed_data\csvs\sample_900_covs.csv", clear
rename poblados village
merge 1:1 pointid using `sample_900_SBP_Forest_outcome30', keep(matched) nogen
tempfile sample_900_SBP_Forest_Cov
save `sample_900_SBP_Forest_Cov'

* Merging with protected areas data
import delimited "$dir\processed_data\csvs\sample_900_PA.csv", clear
gen year_pa =.
replace year_pa = 1993 if nam == "ANTISANA"
replace year_pa = 1997 if nam == "CAJAS"
replace year_pa = 1970 if nam == "CAYAMBE COCA"
replace year_pa = 2010 if nam == "CERRO PLATEADO"
replace year_pa = 1987 if nam == "CHIMBORAZO"
replace year_pa = 2002 if nam == "COFAN BERMEJO"
replace year_pa = 2014 if nam == "COLONSO CHALUPAS"
replace year_pa = 2019 if nam == "CORDILLERA ORIENTAL DEL CARCHI"
replace year_pa = 1975 if nam == "COTOPAXI"
replace year_pa = 1979 if nam == "CUYABENO"
replace year_pa = 1979 if nam == "EL BOLICHE"
replace year_pa = 1999 if nam == "EL CONDOR"
replace year_pa = 2006 if nam == "EL QUIMI"
replace year_pa = 2006 if nam == "EL ZARZA"
replace year_pa = 2017 if nam == "LA BONITA"
replace year_pa = 1985 if nam == "LIMONCOCHA"
replace year_pa = 1996 if nam == "LLANGANATES"
replace year_pa = 1996 if nam == "LOS ILINIZAS"
replace year_pa = 1982 if nam == "PODOCARPUS"
replace year_pa = 2012 if nam == "QUIMSACOCHA"
replace year_pa = 2018 if nam == "RIO NEGRO SOPLADORA"
replace year_pa = 1975 if nam == "SANGAY"
replace year_pa = 2012 if nam == "SIETE IGLESIAS"
replace year_pa = 1994 if nam == "SUMACO NAPO-GALERAS"
replace year_pa = 2018 if nam == "TAMBILLO"
replace year_pa = 2009 if nam == "YACURI"
replace year_pa = 1979 if nam == "YASUNI"
keep pointid subap year_pa
encode subap, gen(protected_areas)
rename subap pa
// gen within_pa = 0
// replace within_pa = 1 if pa != "NA"
merge 1:1 pointid using `sample_900_SBP_Forest_Cov', keep(matched) nogen
tempfile sample_900_PA
save `sample_900_PA'

* Merging with indigenous data
import delimited "$dir\processed_data\csvs\sample_900_indigenous_new.csv", clear
keep pointid status
encode status, gen(indigenous_land)
rename status indigenous
gen within_indigenous = 0
replace within_indigenous = 1 if indigenous != "NA"
merge 1:1 pointid using `sample_900_PA', keep(matched) nogen
tempfile sample_900_indigenous
save `sample_900_indigenous'

* Merging with soil data
import delimited "$dir\processed_data\csvs\sample_900_soil.csv", clear
keep pointid pen_cod text1_cod shape_area
encode pen_cod, gen(slope)
drop pen_cod
encode text1_cod, gen(soil)
drop text1_cod
encode shape_area, gen(polygonid)
drop shape_area
merge 1:1 pointid using `sample_900_indigenous', keep(matched) nogen
tempfile sample_900_soil
save `sample_900_soil'

* Merging with canton data
import delimited "$dir\processed_data\csvs\sample_900_cantones.csv", clear
keep pointid dpa_canton dpa_descan
rename dpa_descan canton
rename dpa_canton cantonid
merge 1:1 pointid using `sample_900_soil', keep(matched) nogen
tempfile sample_900_cantones
save `sample_900_cantones'

* Merging with coordinate data
import delimited "$dir\processed_data\csvs\sample_900_coord.csv", clear
merge 1:1 pointid using `sample_900_cantones', keep(matched) nogen
tempfile sample_900_coord
save `sample_900_coord'

* Keeping Amazon provinces 
sort state
keep if state == "MORONA SANTIAGO" | state == "NAPO" | state == "ORELLANA" | state == "PASTAZA" | state == "SUCUMBIOS" | state == "ZAMORA CHINCHIPE"
encode state, gen(stateid)

* String to Integer for Sociobosques variables
encode sociobosque_type, gen(sbp_type)
encode within_sociobosque, gen(withinsb)

destring sociobosque_year cantonid elevation, replace force
recast int sociobosque_year cantonid

save "SBP_wide_900.dta", replace

**# 300*300---------------------------------------------------------------------

* Forest data
import delimited "$dir\processed_data\csvs\sample_300_forest.csv", clear
tempfile sample_300_forest
forvalues i = 1997/2020 {
    local j = `i' - 1
	gen forestloss`i' = mapbiomas`j' - mapbiomas`i'
	drop mapbiomasloss`i'
	gen relforestloss`i' = forestloss`i' / mapbiomas`j'
}
forvalues i = 1996/2020 {
	rename mapbiomas`i' forestcover`i'
}
save `sample_300_forest'

* Merging with SBP data
import delimited "$dir\processed_data\csvs\sample_300_spatial_attr.csv", clear
tempfile sample_300_spatial_attr
save `sample_300_spatial_attr'
merge 1:1 pointid using `sample_300_forest', keep(matched) nogen
tempfile sample_300_SBP_Forest
save `sample_300_SBP_Forest'

* Merging farming data
import delimited "$dir\processed_data\csvs\sample_300_outcome14.csv", clear
tempfile sample_300_outcome14
drop mapbiomasloss*
forvalues i = 1996/2020 {
	rename mapbiomas`i' farming`i'
}
merge 1:1 pointid using `sample_300_SBP_Forest', keep(matched) nogen
tempfile sample_300_SBP_Forest_outcome14
save `sample_300_SBP_Forest_outcome14'

* Merging mining data
import delimited "$dir\processed_data\csvs\sample_300_outcome24.csv", clear
tempfile sample_300_outcome24
drop mapbiomasloss*
forvalues i = 1996/2020 {
	rename mapbiomas`i' mining`i'
}
merge 1:1 pointid using `sample_300_SBP_Forest_outcome14', keep(matched) nogen
tempfile sample_300_SBP_Forest_outcome24
save `sample_300_SBP_Forest_outcome24'

* Merging urban infrastructure data
import delimited "$dir\processed_data\csvs\sample_300_outcome30.csv", clear
tempfile sample_300_outcome30
drop mapbiomasloss*
forvalues i = 1996/2020 {
	rename mapbiomas`i' infrastruct`i'
}
merge 1:1 pointid using `sample_300_SBP_Forest_outcome24', keep(matched) nogen
tempfile sample_300_SBP_Forest_outcome30
save `sample_300_SBP_Forest_outcome30'

* Merging with distance to road, village, river, population, elevation, oil wells, and pipelines data
import delimited "$dir\processed_data\csvs\sample_300_covs.csv", clear
rename poblados village
merge 1:1 pointid using `sample_300_SBP_Forest_outcome30', keep(matched) nogen
tempfile sample_300_SBP_Forest_Cov
save `sample_300_SBP_Forest_Cov'

* Merging with protected areas data
import delimited "$dir\processed_data\csvs\sample_300_PA.csv", clear
gen year_pa =.
replace year_pa = 1993 if nam == "ANTISANA"
replace year_pa = 1997 if nam == "CAJAS"
replace year_pa = 1970 if nam == "CAYAMBE COCA"
replace year_pa = 2010 if nam == "CERRO PLATEADO"
replace year_pa = 1987 if nam == "CHIMBORAZO"
replace year_pa = 2002 if nam == "COFAN BERMEJO"
replace year_pa = 2014 if nam == "COLONSO CHALUPAS"
replace year_pa = 2019 if nam == "CORDILLERA ORIENTAL DEL CARCHI"
replace year_pa = 1975 if nam == "COTOPAXI"
replace year_pa = 1979 if nam == "CUYABENO"
replace year_pa = 1979 if nam == "EL BOLICHE"
replace year_pa = 1999 if nam == "EL CONDOR"
replace year_pa = 2006 if nam == "EL QUIMI"
replace year_pa = 2006 if nam == "EL ZARZA"
replace year_pa = 2017 if nam == "LA BONITA"
replace year_pa = 1985 if nam == "LIMONCOCHA"
replace year_pa = 1996 if nam == "LLANGANATES"
replace year_pa = 1996 if nam == "LOS ILINIZAS"
replace year_pa = 1999 if nam == "MARCOS PEREZ DE CASTILLA"
replace year_pa = 1982 if nam == "PODOCARPUS"
replace year_pa = 2012 if nam == "QUIMSACOCHA"
replace year_pa = 2018 if nam == "RIO NEGRO SOPLADORA"
replace year_pa = 1975 if nam == "SANGAY"
replace year_pa = 2012 if nam == "SIETE IGLESIAS"
replace year_pa = 1994 if nam == "SUMACO NAPO-GALERAS"
replace year_pa = 2018 if nam == "TAMBILLO"
replace year_pa = 2009 if nam == "YACURI"
replace year_pa = 1979 if nam == "YASUNI"
keep pointid subap year_pa
encode subap, gen(protected_areas)
rename subap pa
// gen within_pa = 0
// replace within_pa = 1 if sociobosque_year >= year_pa & !missing(sociobosque_year) & !missing(year_pa)
// replace within_pa = 0 if (sociobosque_year <= year_pa | missing(sociobosque_year)) & !missing(year_pa)
merge 1:1 pointid using `sample_300_SBP_Forest_Cov', keep(matched) nogen
tempfile sample_300_PA
save `sample_300_PA'

* Merging with indigenous data
import delimited "$dir\processed_data\csvs\sample_300_indigenous_new.csv", clear
keep pointid status
encode status, gen(indigenous_land)
rename status indigenous
gen within_indigenous = 0
replace within_indigenous = 1 if indigenous != "NA"
merge 1:1 pointid using `sample_300_PA', keep(matched) nogen
tempfile sample_300_indigenous
save `sample_300_indigenous'

* Merging with soil data
import delimited "$dir\processed_data\csvs\sample_300_soil.csv", clear
keep pointid pen_cod text1_cod shape_area
encode pen_cod, gen(slope)
drop pen_cod
encode text1_cod, gen(soil)
drop text1_cod
encode shape_area, gen(polygonid)
drop shape_area
merge 1:1 pointid using `sample_300_indigenous', keep(matched) nogen
tempfile sample_300_soil
save `sample_300_soil'

* Merging with canton data
import delimited "$dir\processed_data\csvs\sample_300_cantones.csv", clear
keep pointid dpa_canton dpa_descan
rename dpa_descan canton
rename dpa_canton cantonid
merge 1:1 pointid using `sample_300_soil', keep(matched) nogen
tempfile sample_300_cantones
save `sample_300_cantones'

* Merging with coordinate data
import delimited "$dir\processed_data\csvs\sample_300_coord.csv", clear
merge 1:1 pointid using `sample_300_cantones', keep(matched) nogen
tempfile sample_300_coord
save `sample_300_coord'

* Keeping Amazon provinces
sort state
keep if state == "MORONA SANTIAGO" | state == "NAPO" | state == "ORELLANA" | state == "PASTAZA" | state == "SUCUMBIOS" | state == "ZAMORA CHINCHIPE"
encode state, gen(stateid)

* String to Integer for Sociobosques variables
encode sociobosque_type, gen(sbp_type)
encode within_sociobosque, gen(withinsb)

destring sociobosque_year cantonid elevation, replace force
recast int sociobosque_year cantonid

save "SBP_wide_300.dta", replace