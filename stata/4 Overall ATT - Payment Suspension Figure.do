* Four-panel payment-suspension coefficient plot; no estimation is performed.
version 18
set more off

global dir "G:\My Drive\socio bosque"
global results "$dir\Results\Payment Suspension"

use "$results\dcdh_payment_suspension_figure_data.dta", clear
gen double y = cond(type == "Collective", 2, 1)
replace y = y + .18 if sample == "Baseline"
replace y = y - .18 if sample == "Suspension included"

local bundles `" "sb" "sb+it" "sb+pa" "sb+it+pa" "'
local titles  `" "SB" "SB + IT" "SB + PA" "SB + IT + PA" "'
forvalues k = 1/4 {
    local b : word `k' of `bundles'
    local ttl : word `k' of `titles'
    local yopts = cond(`k' == 1, ///
        `"yscale(range(.55 2.45)) ylabel(1 "Individual" 2 "Collective", angle(0) nogrid) ytitle("")"', ///
        `"yscale(off range(.55 2.45)) ylabel(none) ytitle("")"')
    twoway ///
        (rcap ci_high ci_low y if policy_bundle == "`b'" & sample == "Baseline", ///
            horizontal lcolor(navy) msize(small)) ///
        (scatter y att if policy_bundle == "`b'" & sample == "Baseline", ///
            msymbol(O) mcolor(navy) msize(medlarge)) ///
        (rcap ci_high ci_low y if policy_bundle == "`b'" & sample == "Before suspension", ///
            horizontal lcolor(maroon) msize(small)) ///
        (scatter y att if policy_bundle == "`b'" & sample == "Before suspension", ///
            msymbol(D) mcolor(maroon) msize(medlarge)) ///
        (rcap ci_high ci_low y if policy_bundle == "`b'" & sample == "Suspension included", ///
            horizontal lcolor(forest_green) msize(small)) ///
        (scatter y att if policy_bundle == "`b'" & sample == "Suspension included", ///
            msymbol(T) mcolor(forest_green) msize(medlarge)), `yopts' ///
        xscale(range(-.2 .3)) xlabel(-.2 0 .2, format(%3.1f) nogrid) ///
        xline(0, lpattern(dash) lcolor(gs8)) ///
        xtitle("Overall ATT (pp)", size(small)) ///
        title("(`=char(96+`k')') `ttl'", size(medsmall)) ///
        graphregion(color(white)) plotregion(color(white)) legend(off) ///
        name(panel`k', replace)
}

graph combine panel1 panel2 panel3 panel4, rows(1) cols(4) ///
    graphregion(color(white)) imargin(tiny) ///
    caption("●  Baseline        ◆  1996-2014: before suspension        ▲  1996-2017: suspension included", ///
        position(6) justification(center) size(small))
graph save "$results\payment_suspension_ATT_four_panel.gph", replace
graph export "$results\payment_suspension_ATT_four_panel.png", ///
    as(png) replace width(7000)
graph export "$results\payment_suspension_ATT_four_panel.pdf", ///
    as(pdf) replace
