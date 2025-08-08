/*--------RACEL_DV----------(BHPS)-------*/

// Creates racel_dv_all_waves - 

// INPUT FILES - w_indresp.dta (BHPS AND UKHLS) , xwavedat.dta
// OUTPUT FILE - racel_dv_all_waves.dta


clear all
set more off

// Modules
ssc install isvar
ssc install fre

// Set wd
cd "/Users/albertward/My Drive/OXFORD/MAIN THESIS WORK/Data" 
pwd

// WRITE FILEPATH WHERE YOU HAVE DOWNLOADED THE EUL DATA
global indresp "US 1-11 and BHPS 1-18/stata/stata13_se"
// WRITE FILEPATH WHERE YOU HAVE DOWNLOADED EUL CROSSWAVE DATA
global xWaveData "US 1-11 and BHPS 1-18/stata/stata13_se/ukhls"
// WRITE FILEPATH WHERE YOU WOULD LIKE TO SAVE THE OUTPUT FILE
global outpath "IMPORT"

// Add the wave letters for including future waves
global ukhlswavelist "abcdefghi"
global allukhlswaves a b c d e f g h i
global ukhlswavesNta   b c d e f g h i

global allbhpswaves  a b c d e f g h i j k l m n o p q r
global bhpswavelist  "abcdefghijklmnopqr"
global bhpswavesNta    b c d e f g h i j k l m n o p q r


// BHPS
foreach w of global allbhpswaves {
	local i=strpos("$bhpswavelist","`w'")
	use "$indresp/bhps/b`w'_indresp", clear
	isvar pidp b`w'_race b`w'_racel*
	keep `r(varlist)'
	save b`w', replace
}
use ba, clear
foreach w of global bhpswavesNta {
	merge 1:1 pid using b`w', nogen
}
g race_bh=.
foreach w in a b c d e f g h i j k l {
	replace race_bh =b`w'_race  if race_bh==. & b`w'_race>=1 & b`w'_race<=9
}
g racel_bh=.
foreach w in m n o p q r {
	replace racel_bh=b`w'_racel if racel_bh==. & b`w'_racel>0 & b`w'_racel<=97
}
keep pidp race_bh racel_bh
save bhps, replace


// UKHLS
foreach w of global allukhlswaves {
	local i = strpos("$ukhlswavelist","`w'")
	use "$indresp/ukhls/`w'_indresp"
	isvar pidp `w'_racel `w'_racelt `w'_racelwt `w'_racelmt `w'_racelat `w'_racelbt `w'_racelo_code `w'_racelot_code
	keep `r(varlist)'
	d
	save `w', replace
}
use a, clear
foreach w of global ukhlswavesNta {
	merge 1:1 pidp using `w', nogen
}
merge 1:1 pidp using bhps, nogen
merge 1:1 pidp using "$xWaveData/xwavedat", nogen keepus(hhorig)
cap label drop racel_dv
foreach var in racelt racelwt racelmt racelat racelbt racelot_code {
	g a_`var'=.
	g b_`var'=.
}
foreach w of global allukhlswaves {
	recode `w'_racelo_code (997 = 97) 
	recode `w'_racelot_code (997 = 97)
	generat `w'_racel_dv=`w'_racel
	replace `w'_racel_dv=1  if `w'_racel==1  | `w'_racelwt==1  // white british 
	replace `w'_racel_dv=2  if `w'_racel==2  | `w'_racelwt==2  // irish
	replace `w'_racel_dv=3  if `w'_racel==3  | `w'_racelwt==3  // gypsy
	replace `w'_racel_dv=4  if `w'_racel==4  | `w'_racelwt==97 // any other white
	replace `w'_racel_dv=5  if `w'_racel==5  | `w'_racelmt==1  // mix white black carib
	replace `w'_racel_dv=6  if `w'_racel==6  | `w'_racelmt==2  // mix white black afri
	replace `w'_racel_dv=7  if `w'_racel==7  | `w'_racelmt==3  // mix white asian
	replace `w'_racel_dv=8  if `w'_racel==8  | `w'_racelmt==97 // mix other
	replace `w'_racel_dv=9  if `w'_racel==9  | `w'_racelat==1  // indian
	replace `w'_racel_dv=10 if `w'_racel==10 | `w'_racelat==2  // pakistani
	replace `w'_racel_dv=11 if `w'_racel==11 | `w'_racelat==3  // bangladeshi
	replace `w'_racel_dv=12 if `w'_racel==12 | `w'_racelt==5   // chinese
	replace `w'_racel_dv=13 if `w'_racel==13 | `w'_racelat==97 // any other asian
	replace `w'_racel_dv=14 if `w'_racel==14 | `w'_racelbt==1  // caribbean
	replace `w'_racel_dv=15 if `w'_racel==15 | `w'_racelbt==2  // african
	replace `w'_racel_dv=16 if `w'_racel==16 | `w'_racelbt==97 // any other black
	replace `w'_racel_dv=17 if `w'_racel==17 | `w'_racelt==6   // arab
	replace `w'_racel_dv=97 if `w'_racel==97 | `w'_racelt==97  // any other
	replace `w'_racel_dv=`w'_racelo_code  if `w'_racelo_code>0  & `w'_racelo_code<97 
	replace `w'_racel_dv=`w'_racelot_code if `w'_racelot_code>0 & `w'_racelot_code<97
}
foreach var in racel_dv {
	generat racel_dv=-9
	foreach w of global allukhlswaves {
		replace racel_dv=`w'_racel_dv if `w'_racel_dv<. & `w'_racel_dv>=0 & racel_dv==-9
	}
	la var racel_dv "Ethnic group incorp. all waves, codings, modes and bhps"
	d racel_dv
	lab def racel_dv ///
		-9 "missing" ///
		1 "british/english/scottish/welsh/northern irish (white)" ///
		2 "irish (white)" ///
		3 "gypsy or irish traveller (white)" ///
		4 "any other white background (white)" ///
		5 "white and black caribbean (mixed)" ///
		6 "white and black african (mixed)" ///
		7 "white and asian (mixed)" ///
		8 "any other mixed background (mixed)" ///
		9 "indian (asian or asian british)" ///
		10 "pakistani (asian or asian british)" ///
		11 "bangladeshi (asian or asian british)" ///
		12 "chinese (asian or asian british)" ///
		13 "any other asian background (asian or asian british)" ///
		14 "caribbean (black or black british)" ///
		15 "african (black or black britih)" ///
		16 "any other black background (black or black britih)" ///
		17 "arab (other ethnic group)" ///
		97 "any other ethnic group (other ethnic group)"
	lab val racel_dv racel_dv
	fre racel_dv
}
// UPDATING RACEL_DV WITH BHPS INFO
replace racel_dv=1          if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & inlist(racel_bh,1,3,4)
replace racel_dv=2          if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & racel_bh==2
replace racel_dv=4          if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & racel_bh==5
replace racel_dv=racel_bh-1 if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & racel_bh>=6 & racel_bh<=12
replace racel_dv=12         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & racel_bh==17
replace racel_dv=racel_bh   if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & racel_bh>=13 & racel_bh<=16 
replace racel_dv=97         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & racel_bh==18

replace racel_dv=1          if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==1
replace racel_dv=14         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==2
replace racel_dv=15         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==3
replace racel_dv=16         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==4
replace racel_dv=9          if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==5
replace racel_dv=10         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==6
replace racel_dv=11         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==7
replace racel_dv=12         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==8
replace racel_dv=97         if inlist(racel_dv,-9,.) & inlist(hhorig,3,4,5,6,14,15,16) & race_bh==9

replace racel_dv=-9 if inlist(hhorig,3,4,5,6,14,15,16) & racel_dv==. & race_bh==-9 & racel_bh==-9

// Finalise
keep pidp racel_dv
save "${outpath}/racel_dv_all_waves", replace


// CLEAN UP
erase bhps.dta
foreach w of global allbhpswaves {
	cap erase b`w'.dta
}
foreach w of global allukhlswaves {
	cap erase `w'.dta
}

