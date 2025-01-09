// Load data
// -------------------------------------
clear all
set more off

local directory "C:\Research\gamified_jbef\"
import delimited "`directory'Data\panel_participants.csv"

reg finscore playercourse_financial, robust
outreg2 using "`directory'\OutputTables\QuizRobust.tex", replace tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")
reg finscore  playertrading_experience , robust
outreg2 using "`directory'\OutputTables\QuizRobust.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")
reg finscore  playeronline_trading_experience , robust
outreg2 using "`directory'\OutputTables\QuizRobust.tex", append tex tstat label  dec(2) tdec(2) eqdrop(/) keep(*) ctitle("(OLS)")
