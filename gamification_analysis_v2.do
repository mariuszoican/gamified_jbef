// Load data
// -------------------------------------
clear all
set more off

local directory "C:\Users\admin-zoicanma\Dropbox\Research\ckz_gamification\NewProtocol\"
import delimited "`directory'Data\processed_data_main.csv"

rename owner__participant__code participantid
rename owner__round_number round
rename subsessiontick_frequency tick


// Generate dummies
// -------------------------------------
generate female=1 if playergender=="Female"
replace female=0 if female==.

generate high_crashrisk=1 if owner__crash_probability>0.03
replace high_crashrisk=0 if high_crashrisk==.

generate gamified=1 if owner__gamified=="True"
replace gamified=0 if gamified==.

// Standardize controls
// ----------------------------
egen age_std=std(playerage) 
**# Bookmark #1
egen FinScore_std=std(finscore)
egen round_std=std(round)

// Generate interactions
// --------------------------------
generate finscore_high=1 if FinScore_std>0
generate gamified_finscore=gamified*finscore_high

generate gamified_highrisk=gamified*high_crashrisk
label variable gamified_highrisk "Gamified $\times$ High risk"

generate gamified_score=gamified*FinScore_std
label variable gamified_score "Gamified $\times$ Quiz score"

generate gamified_course=gamified*playercourse_financial
label variable gamified_course "Gamified $\times$ Finance course"

generate gamified_major_fin=gamified*(playerstudy_major=="Finance") 
label variable gamified_major_fin "Gamified $\times$ Finance course"

generate major_finance_mgt=((playerstudy_major=="Finance") | (playerstudy_major=="Economics") | (playerstudy_major=="Other Management"))
label variable major_finance_mgt "Business major"
generate gamified_major_econmgmt=gamified*((playerstudy_major=="Finance") | (playerstudy_major=="Economics") | (playerstudy_major=="Other Management"))
label variable gamified_major_econmgmt "Gamified $\times$ Business major"

generate postgrad=((playereducation=="master") | (playereducation=="PhD"))
label variable postgrad "Postgraduate"
generate gamified_postgrad=gamified*((playereducation=="master") | (playereducation=="PhD"))
label variable gamified_postgrad "Gamified $\times$ Postgraduate"

generate freqtrader=((playertrading_frequency=="Daily") | (playertrading_frequency=="Weekly") | (playertrading_frequency=="Multiple times a day"))
label variable freqtrader "Frequent trader"
generate gamified_freqtrader=gamified*freqtrader
label variable gamified_freqtrader "Gamified $\times$ Frequent trader"

label variable playeronline_trading_experience "Online trader"
generate gamified_onlinetrad=gamified*playeronline_trading_experience
label variable gamified_onlinetrad "Gamified $\times$ Online trader"

generate riskyassetclass=((playerasset_class=="Cryptocurrencies") | (playerasset_class=="Derivatives (Options, Futures)"))
label variable riskyassetclass "Risky asset trader"
generate gamified_riskytrader=gamified*riskyassetclass
label variable gamified_riskytrader "Gamified $\times$ Risky asset trader"

generate leverageuser=((playeruse_leverage=="Yes"))
label variable leverageuser "Uses leverage"
generate gamified_leverage=gamified*leverageuser
label variable gamified_leverage "Gamified $\times$ Uses leverage"


label variable gamified_first "Gamified rounds first"
generate gamified_gfirst=gamified*gamified_first
label variable gamified_gfirst "Gamified $\times$ Gamified rounds first"

generate gamified_age=gamified*age_std
label variable gamified_age "Gamified $\times$ Age"

generate gamified_female=gamified*female
label variable gamified_female "Gamified $\times$ Female"

generate onlineshoppers=(owner__session__code=="tcbozsj9") | (owner__session__code=="xm39f2ij")
label variable onlineshoppers "Frequent online shopper"
generate gamified_shopper=gamified*onlineshoppers
label variable gamified_shopper "Gamified $\times$ Frequent shopper"

generate postgrad_prolific=(owner__session__code=="tcbozsj9") | (owner__session__code=="hgp2owka")
label variable postgrad_prolific "Postgraduate"
generate gamified_postgrad_pr=gamified*postgrad_prolific
label variable gamified_postgrad_pr "Gamified $\times$ Postgraduate"


// Label variables
// ---------------------------------
label variable gamified "Gamified"
label variable age_std "Age"
label variable round_std "Round"
label variable female "Gender: Female"
label variable high_crashrisk "High risk"
label variable FinScore_std "Quiz score"
label variable finscore_high "High quiz score"
label variable secs_since_round_starts "Trading time"
label variable playercourse_financial "Finance course"

// H1: Gamification increases time-to-sell (Tobit model)
// ---------------------------------------------------------------------

tobit secs_since_round_starts gamified high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_Tobit_TTS.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p))  ctitle("(Tobit)")

// Marginal effects
//margins, dydx(gamified) predict(ystar(0,.))

tobit secs_since_round_starts gamified, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_Tobit_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")

tobit secs_since_round_starts gamified high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_Tobit_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p))  ctitle("(Tobit)")

tobit secs_since_round_starts gamified high_crashrisk FinScore_std round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_Tobit_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p))  ctitle("(Tobit)")

tobit secs_since_round_starts gamified high_crashrisk FinScore_std age_std female , ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_Tobit_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")


// H1R: Gamification increases selling price (OLS model)
// ---------------------------------------------------------------------

reghdfe owner__exit_price gamified high_crashrisk FinScore_std age_std female round_std if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_ExitPrice.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)") title("Trading time")

reghdfe owner__exit_price gamified if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_ExitPrice.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe owner__exit_price gamified high_crashrisk if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_ExitPrice.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe owner__exit_price gamified high_crashrisk FinScore_std round_std if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_ExitPrice.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe owner__exit_price gamified high_crashrisk FinScore_std round_std age_std if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_ExitPrice.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

// H1B: Gamification increases time-to-sell (linear model, condition on sell)
// ---------------------------------------------------------------------

reghdfe secs_since_round_starts gamified high_crashrisk FinScore_std age_std female round_std if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_TTS.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)") title("Trading time")

reghdfe secs_since_round_starts gamified if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe secs_since_round_starts gamified high_crashrisk if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe secs_since_round_starts gamified high_crashrisk FinScore_std round_std if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe secs_since_round_starts gamified high_crashrisk FinScore_std round_std age_std if exit_sell==1, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H1_OLS_TTS.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")


// ----------------------------------------------------------------------


// H2: Gamification increases the likelihood of a crash
// ---------------------------------------------------------------------


reghdfe exit_crash gamified high_crashrisk FinScore_std age_std female round_std, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H2_OLS_CrashRisk.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*)  ctitle("(OLS)") title("Market crash indicator")

reghdfe exit_crash gamified, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H2_OLS_CrashRisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe exit_crash gamified high_crashrisk, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H2_OLS_CrashRisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*)  ctitle("(OLS)")

reghdfe exit_crash gamified high_crashrisk FinScore_std round_std, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H2_OLS_CrashRisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe exit_crash gamified high_crashrisk FinScore_std age_std female, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H2_OLS_CrashRisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

// H3: Impact of education financial knowledge
// ---------------------------------------------------------------------

tobit secs_since_round_starts gamified gamified_score high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3_FinScore.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")

tobit secs_since_round_starts gamified gamified_score FinScore_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3_FinScore.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_score high_crashrisk FinScore_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3_FinScore.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_score high_crashrisk FinScore_std round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3_FinScore.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_score high_crashrisk FinScore_std age_std female, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3_FinScore.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")



// H4: Impact of high risk environment
// ---------------------------------------------------------------------

tobit secs_since_round_starts gamified gamified_highrisk high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H4_Highrisk.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")

tobit secs_since_round_starts gamified gamified_highrisk high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H4_Highrisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_highrisk high_crashrisk FinScore_std round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H4_Highrisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_highrisk high_crashrisk FinScore_std age_std female, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H4_Highrisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_highrisk high_crashrisk FinScore_std round_std age_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H4_Highrisk.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")


// H5: Impact of trading patterns
// ---------------------------------------------------------------------

tobit secs_since_round_starts gamified gamified_riskytrader riskyassetclass high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H5_TraderProfile.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")
tobit secs_since_round_starts gamified gamified_riskytrader riskyassetclass high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H5_TraderProfile.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")


tobit secs_since_round_starts gamified gamified_onlinetrad playeronline_trading_experience high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H5_TraderProfile.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")
tobit secs_since_round_starts gamified gamified_onlinetrad playeronline_trading_experience high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H5_TraderProfile.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")


tobit secs_since_round_starts gamified gamified_freqtrader freqtrader high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H5_TraderProfile.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")
tobit secs_since_round_starts gamified gamified_freqtrader freqtrader high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H5_TraderProfile.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")



// H6: Gamification makes trades change their mind to sell
// ---------------------------------------------------------------------

reghdfe mindchanges gamified high_crashrisk FinScore_std age_std female round_std, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H6_ChangeMind.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)") title("Changes of heart")

reghdfe mindchanges gamified, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H6_ChangeMind.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe mindchanges gamified high_crashrisk, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H6_ChangeMind.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*)  ctitle("(OLS)")

reghdfe mindchanges gamified high_crashrisk FinScore_std round_std, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H6_ChangeMind.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")

reghdfe mindchanges gamified high_crashrisk FinScore_std round_std age_std, noabsorb vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H6_ChangeMind.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*)  ctitle("(OLS)")


// H7: Impact of sequence/learning
// ---------------------------------------------------------------------

tobit secs_since_round_starts gamified gamified_gfirst gamified_first high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H7_Sequence.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(Tobit)") addstat(Pseudo R2, e(r2_p))  title("Trading time")

tobit secs_since_round_starts gamified gamified_gfirst gamified_first round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H7_Sequence.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_gfirst gamified_first high_crashrisk round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H7_Sequence.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_gfirst gamified_first high_crashrisk FinScore_std round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H7_Sequence.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p))  ctitle("(Tobit)")

tobit secs_since_round_starts gamified gamified_gfirst gamified_first high_crashrisk age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H7_Sequence.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)")


// Robustness: Education

// H5: Impact of trading patterns
// ---------------------------------------------------------------------

tobit secs_since_round_starts gamified gamified_course playercourse_financial high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3b_Education.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")
tobit secs_since_round_starts gamified gamified_course playercourse_financial high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3b_Education.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")


tobit secs_since_round_starts gamified gamified_postgrad postgrad high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3b_Education.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")
tobit secs_since_round_starts gamified_postgrad postgrad playeronline_trading_experience high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3b_Education.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")


tobit secs_since_round_starts gamified gamified_major_econmgmt major_finance_mgt high_crashrisk FinScore_std age_std female round_std, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3b_Education.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")
tobit secs_since_round_starts gamified gamified_major_econmgmt major_finance_mgt high_crashrisk, ul(censoring) vce(cluster participantid)
outreg2 using "`directory'\OutputTables\H3b_Education.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) addstat(Pseudo R2, e(r2_p)) ctitle("(Tobit)") title("Trading time")



