*I have downloaded data sets on Power Outages and the National Risk Index
*I chose these two becuase I have an interest in Emergency Managament and want to see if there is a connection between aging infrustructure and how often power is lost. 
*One data set was from FEMA and the other is from Science Data 



***First dataset: Power Outages 
clear mata

set maxvar 32767


cd "`c(pwd)'"

import excel ///
"https://docs.google.com/spreadsheets/d/105LKuD8cjKzvP4ZMqCIj6_sLTb6wfAD5Y7uUbDgbcZE/export?format=xlsx", ///
firstrow clear


***Data cleaning 
rename year YEAR
rename state STATE
rename total_customers TOTAL_CUSTOMERS
rename min_covered MIN_COVERED
rename max_covered MAX_COVERED
rename min_pct_covered MIN_PCT_COVERED
rename max_pct_covered MAX_PCT_COVERED
label variable TOTAL_CUSTOMERS	"Total Customers"
label variable MIN_COVERED		"Minimum Customers with Data on Outage History"
label variable MAX_COVERED		"Maximum Customers with Data on Outage History"
label variable MIN_PCT_COVERED	"Minimum Percent of Customers with Data on Outage History"
label variable MAX_PCT_COVERED	"Maximum Percent of Customers with Data on Outage History"

format YEAR %td
list YEAR in 1/20


***Playing with data 
tab YEAR
summarize YEAR
///Noticed that this data is from 2018-2022, and that 2022 had the largest cummulative score. 

tabulate MAX_COVERED
///It was interesting that there were 18 observations that had zero customers affrcted

describe

save "PowerCoverage.dta", replace


clear


***Second dataset: National Risk Index 
import excel ///
"https://docs.google.com/spreadsheets/d/11dodqRgkplo3DhgVOgqLw50UGE5QSDfzadDV9b7Q624/export?format=xlsx", ///
firstrow clear


***Data cleaning 

replace STATE = strupper(strtrim(STATE))

count if missing(STATE)

label variable STATE			"State Name"
label variable STATEFIPS		"State FIPS Code"
label variable EAL_SCORE		"Expected Annual Loss - Score - Composite"
label variable EAL_RATNG		"Expected Annual Loss - Rating - Composite"
label variable EAL_VALT			"Expected Annual Loss - Total - Composite"
label variable EAL_VALB			"Expected Annual Loss - Building Value - Composite"
label variable EAL_VALP			"Expected Annual Loss - Population - Composite"
label variable EAL_VALPE		"Expected Annual Loss - Population Equivalence - Composite"
label variable EAL_VALA			"Expected Annual Loss - Agriculture Value - Composite"
label variable ALR_VALB			"Annualized Loss Rate – Building Value"
label variable ALR_VALA			"Annualized Loss Rate – Agriculture Value"
label variable ALR_NPCTL		"Annualized Loss Rate – National Percentile"
label variable ALR_VALP			"Annual Loss Ratio - Value of Property"
label variable NRI_VER			"National Risk Index Version"


***Playing with data 
summarize EAL_SCORE
///With mean being 50- most states face moderate disaster related loss. The St. dev is very high, meaning the loss is not distributed evenly amongest all states and there are some that have much higher rates of loss. 
tab EAL_SCORE
///This is nice to see which states call into what percentile, based on the cummulative score, but the lack of labeling which state is which causes a lot of confusion

summarize ALR_NPCTL
///This also having such a large std. dev shows how there are select states that experience loss at much higher rates than the other states. 
tab ALR_NPCTL

tab EAL_VALB
///This shows that about 50% of states have below 1.1 billion dollars in damage a year- where 75% of states have below 2.2 billion in damage 
summarize EAL_VALB
///There is a mean of 1.93 billion but a std. dev of 3.30 billion. This is an extremely large std. dev.!

describe

save "NationalRiskIndex.dta", replace



//Merging Datasets 1:1//
clear
input str2 STATE byte STATEFIPS
"AL" 1
"AK" 2
"AZ" 4
"AR" 5
"CA" 6
"CO" 8
"CT" 9
"DE" 10
"FL" 12
"GA" 13
"HI" 15
"ID" 16
"IL" 17
"IN" 18
"IA" 19
"KS" 20
"KY" 21
"LA" 22
"ME" 23
"MD" 24
"MA" 25
"MI" 26
"MN" 27
"MS" 28
"MO" 29
"MT" 30
"NE" 31
"NV" 32
"NH" 33
"NJ" 34
"NM" 35
"NY" 36
"NC" 37
"ND" 38
"OH" 39
"OK" 40
"OR" 41
"PA" 42
"RI" 44
"SC" 45
"SD" 46
"TN" 47
"TX" 48
"UT" 49
"VT" 50
"VA" 51
"WA" 53
"WV" 54
"WI" 55
"WY" 56
"DC" 11
end

save "state_abbrev_to_fips.dta", replace


use "PowerCoverage.dta", clear
replace STATE = strupper(strtrim(STATE))
merge m:1 STATE using "state_abbrev_to_fips.dta"
keep if _merge==3
drop _merge
save "PowerCoverage_withFIPS.dta", replace

use "NationalRiskIndex.dta", clear
destring STATEFIPS, replace force

collapse (mean) EAL_SCORE EAL_VALPE ALR_VALP ALR_NPCTL ///
         (firstnm) NRI_VER, by(STATEFIPS)

label variable EAL_SCORE		"Expected Annual Loss - Score - Composite"
label variable EAL_VALPE		"Expected Annual Loss - Population Equivalence - Composite"
label variable ALR_NPCTL		"Expected Annual Loss Rate - National Percentile - Composite"
label variable ALR_VALP			"Expected Annual Loss Rate - Population - Composite"
		 
		 
save "NRI_state.dta", replace

use "PowerCoverage_withFIPS.dta", clear
merge m:1 STATEFIPS using "NRI_state.dta"

tab _merge

drop _merge


***Playing with BOTH datasets 
summarize EAL_SCORE EAL_VALPE ALR_VALP ALR_NPCTL 

tabstat EAL_SCORE EAL_VALPE ALR_VALP ALR_NPCTL, ///
stats(mean sd min max n) columns(statistics)
//////Overall, all variables show that there is a large skew in distruption amongst states. There are a few that have a lot of extreme loss, where most other states are a lot lower.


tabstat EAL_SCORE ALR_NPCTL, by(STATE) ///
stats(mean) columns(statistics)
///States such as CA, FL, LA, WA, SC, and WV are the couple that are unproportionally high, and raise the std. dev. amongst all the states. 



/* =========================
   PS 2 
   ========================= */
///Annaliese Tancos- my project is looking at the correlation between power outages and aging infrustructure


summarize EAL_SCORE
*There being a std dev. of 27 shows that there is a lot of variation between the state's EAL scores. 

summarize MAX_PCT_COVERED
*The max participants observed being covered or restored being 86% seems low until you see the std. dev of 13 percent. With that, you can either observe the whole community or 75%, which if it was the latter option consistently there would be issues in the EM world.

summarize ALR_VALP
*This shows that between the states, the expected property loss is about 0.0011% annually. 


table (STATE) (YEAR), statistic(mean EAL_SCORE) nformat(%9.2f)
*All of the states were listed, and every state has 5 observations. This format is helpful in seeing how consistent the EAL scores yearly, or if there is a pattern within each state. 


///frequency table 
gen year_only = year(YEAR)
format year_only %ty

preserve
collapse (mean) EAL_SCORE (mean) MAX_COVERED, by(STATE)
sort EAL_SCORE
list STATE EAL_SCORE MAX_COVERED, clean noobs
restore
*This chart shows each state, what rate those with max coverage experienced outages and what their expected to lose yearly to emergency incidents. 


preserve
collapse (mean) EAL_SCORE, by(STATE)
table (STATE), statistic(mean EAL_SCORE) nformat(%9.2f)
restore
//This is an easy way to read see the true variation in state EAL scores, after seeing states like CA have a mean of 100% and Road Island with 7.4%


///Cross-tabulation 
xtile outage_cat = MAX_COVERED, n(3)
label define outcat 1 "Low Outage" 2 "Medium Outage" 3 "High Outage"
label values outage_cat outcat
xtile eal_cat = EAL_SCORE, n(3)
label define ealcat 1 "Low EAL" 2 "Medium EAL" 3 "High EAL"
label values eal_cat ealcat
tabulate outage_cat eal_cat, row column
*This graph is really helpful to see the correlation between frenquency of outages and mean of each state's EAL score. It seems like the obvious that low outages and high EAL scores are at zero, and vise versa, but I liked the visual and confirmation



//two graphs- bar, line, pie 
graph hbar EAL_SCORE, ///
over(STATE, sort(1) label(labsize(vsmall)))
*I liked this graph becuase the stats show that there is a lot of variation between each state, but the imagine shows a very steady incline. 

twoway scatter MAX_PCT_COVERED EAL_SCORE
*This is the scatter before using different codes that would make it more reader friendly. 

twoway ///
(scatter MAX_PCT_COVERED EAL_SCORE, msize(small)) ///
(lfit MAX_PCT_COVERED EAL_SCORE), ///
legend(off) ///
xlabel(, labsize(medium)) ///
ylabel(, labsize(medium)) ///
title("Power Outage Coverage vs Hazard Risk", size(medium)) ///
xtitle("Annualized Loss Rate (Property)", size(medium)) ///
ytitle("Maximum % Covered", size(medium))






/* =====================================================
   PS 3
   ================================================== */
///Annaliese Tancos 

describe EAL_SCORE MAX_PCT_COVERED ALR_VALP STATE YEAR
summarize EAL_SCORE MAX_PCT_COVERED ALR_VALP


//Specify Regression Model
regress MAX_PCT_COVERED EAL_SCORE ALR_VALP
*My dependent Variable (DV) is: MAX_PCT_COVERED
*My independent Variables (IVs) is: EAL_SCORE and ALR_VALP
*I believe that the states with higher disaster risk and expected loss will experience lower power restoration coverage due to their infrastructure being more stressed.

*The regression predicts if the risk metrics are associated with a states ability to restore power to buildings after an outage. 
*The p-value being 0.000 shows that there is an association and the model is statistically significant. 
*30.2% of power variation is directly explained by disaster risk variables.  
*Both of the IVs are statiscally significantly. This means that states that face greater disaster risk may also have higher restoration rates, while those with higher property loss have lower power restoration.


//Visualize Relationship
twoway ///
(scatter MAX_PCT_COVERED EAL_SCORE, msize(small)) ///
(lfit MAX_PCT_COVERED EAL_SCORE), ///
title("Power Restoration Coverage vs Disaster Risk") ///
xtitle("Expected Annual Loss Score") ///
ytitle("Maximum % Power Coverage") ///
legend(off)

*This plot confirms the relationship shown in the regression.
*There seems to be a strain placed on infrastructure from severe disasters, making power restoration harder after major events. 


//Visualize Predicted Values
margins, at(EAL_SCORE=(0(20)100))

*The margins show that as the average EAL_SCORE (expected annual loss-score- composite) increases, so does the maximun percent of customers with power restoration. 
*This model may indicate that the states who frequently have disasters may put more resources into preparing for the outcomes- such as power loss. 

marginsplot, ///
title("Predicted Power Coverage by Disaster Risk") ///
xtitle("Expected Annual Loss Score") ///
ytitle("Predicted Maximum Power Coverage")


//Export Regression Table
eststo clear
eststo model1: regress MAX_PCT_COVERED EAL_SCORE ALR_VALP

*This shows that the variables explain the variation in power being restored across the states. The expected annual loss score has a positive restoration coverage, while higher property loss rates on average have lower restoration rates. 

esttab model1 using "regression_results.rtf", ///
replace se star(* 0.10 ** 0.05 *** 0.01) ///
label ///
title("Regression Results: Disaster Risk and Power Restoration")


//Next Step:
*A possible next step would be to include control variables such as population, infrastructure age, or other regional specifics that would help to clarify if the relationship found here can be explained away.





