	 /////// Data Cleaning //////
//// Analyst: Lindsay Kobayashi ////
//// Date created: 06.02.2022 ////
//// Date last updated: 11.15.23 ////

//We are using the KHANDLE Waves 1-4 and STAR Waves 1-3.
//This do-file uses the following raw datasets, downloaded most recently on 08.04.23:
//khandle_all_waves_20230912.csv (variables to create financial mobility exposure variable, and parental education and country of birth, downloaded 09.14.23)
//star_all_waves_20220309.csv (variables to create financial mobility exposure variable, and parental education and country of birth, downloaded 08.04.23)
//khan_star_la90_senas_ecog_longitudinal.dta (all other variables, downloaded 08.04.23)

//This data cleaning do-file does the following steps:

// 1. Derives financial mobility variables in KHANDLE and STAR, using the method from Peterson et al. BMC Public Health //
// 2. Merges these new financial mobility and early-life variables in with the merged KHANDLE and STAR longitudinal dataset //
// 3. Creates the intersectionality identity exposure variable, cleans covariate data, and summarizes missing obs to identify the analytical sample
// 4. Prepares some additional variables for analysis

cd "/Users/lkob/Dropbox (University of Michigan)/psyMCA2022/Stata/" //set directory

///////////////////// Step 1: Derive financial mobility variables ///////////////////////////

//Starting with KHANDLE data//
use "khandle_all_waves_20230912.dta"

//Coding childhood SES - KHANDLE//
tab W1_GROWINGUP_GOHUNGRY
recode W1_GROWINGUP_GOHUNGRY (1 = 0 "No") (2/5 = 1 "Yes") (88 99 = .), gen(hungry)
tab hungry

tab W1_GROWINGUP_FINANCE
recode W1_GROWINGUP_FINANCE (1 2 4 = 0 "No") (3 = 1 "Yes") (88 99 = .), gen(poorfinance)
tab poorfinance

tab W1_GROWINGUP_HOUSING
recode W1_GROWINGUP_HOUSING (2 = 0 "No") (1 3 = 1 "Yes") (88 99 = .), gen(poorhousing)
tab poorhousing

egen foo=group(hungry poorfinance poorhousing), label(foo, replace)
tab foo
recode foo (1/3 = 0 "High") (4/8 = 1 "Low"), gen(childses)
drop foo
tab childses

//Coding late adulthood SES - KHANDLE//
tab W1_INCOME_EST //total income//
tab W1_INCOME2 //supplemental social security
tab W1_INCOME4 //state welfare
tab W1_INCOME5 //help from family/friends

tab W1_INCOME_RANGE
recode W1_INCOME_RANGE (1/9 = 1 "Below 75k") (10/13 = 0 "Above 75k") (88 99 = .), gen(incomebelow75k)
tab incomebelow75k

tab W1_INCOME_WORRY
recode W1_INCOME_WORRY (1 2 = 1 "Always/Often") (3 4 = 0 "Sometimes/Never") (88 99 = .), gen(incomeworry)
tab incomeworry

egen foo=group(incomeworry incomebelow75k), label(foo, replace)
tab foo
recode foo (1/3 = 0 "No") (4 = 1 "Yes"), gen(incomegroup)
tab incomegroup
drop foo

gen adultses = 0
replace adultses = 1 if W1_INCOME_EST==1
replace adultses = 1 if W1_INCOME2==1
replace adultses = 1 if W1_INCOME4==1
replace adultses = 1 if W1_INCOME5==1
replace adultses = 1 if incomegroup==1
label define adultses 0 "High" 1 "Low" 
label values adultses adultses
tab adultses
replace adultses = . if (W1_INCOME_EST==88 | W1_INCOME_EST==99) & (W1_INCOME2==88 | W1_INCOME2==99) & (W1_INCOME4==88 | W1_INCOME4==99) & (W1_INCOME5==88 | W1_INCOME5==99) & (incomegroup==.)
	
//Coding financial mobility - KHANDLE//
egen socialmob=group(childses adultses), label(socialmob, replace)
tab socialmob 

//Re-naming the Wave 4 verbal episodic memory variable that we have added to the dataset
rename W4_SENAS_vrmem vrmem4

//Re-coding the variable for years since baseline for KHANDLE Wave 4, as this is the timescale (note: this timescale variable for waves 1-3 for KHANDLE and STAR is in the merged longitudinal dataset in line 171)
rename W1_TO_W4_DAYS daysbl //note this variable is masked at -90 for those aged over 90 at Wave 4 - will deal with this later in the do file after we have identified the analytical sample

//Preparing to merge - need to fix id variable, change some variable names, and drop the KHANDLE Wave 4 refresher cohort (n=180)//
//gen str6 tempid = string(STUDYID,"%06.0f")
//gen id="K"+tempid
gen id="K"+STUDYID

rename childses childses1
rename adultses adultses1
rename socialmob socialmob1
rename W1_MATERNAL_EDUCATION w1_maternal_education1
rename W1_PATERNAL_EDUCATION w1_paternal_education1
rename W1_COUNTRY_BORN w1_country_born1

drop if COHORT==2 //180 removed

save "khan_social_mobility_11.15.23.dta", replace

//Next we do the same for the STAR data//
import delimited "star_all_waves_20220309.csv", clear
save "star_all_waves_20220309.dta"
use "star_all_waves_20220309.dta"

//Coding childhood SES//
tab w1_growingup_gohungry
recode w1_growingup_gohungry (1 = 0 "No") (2/5 = 1 "Yes") (88 99 = .), gen(hungry)
tab hungry

tab w1_growingup_finance
recode w1_growingup_finance (1 2 4 = 0 "No") (3 = 1 "Yes") (88 99 = .), gen(poorfinance)
tab poorfinance

tab w1_growingup_housing
recode w1_growingup_housing (2 = 0 "No") (1 3 = 1 "Yes") (88 99 = .), gen(poorhousing)
tab poorhousing

egen foo=group(hungry poorfinance poorhousing), label(foo, replace)
tab foo
recode foo (1/3 = 0 "High") (4/8 = 1 "Low"), gen(childses)
drop foo
tab childses

//Coding late adulthood SES//
tab w1_income_est //total income//
tab w1_income2 //supplemental social security
tab w1_income4 //state welfare
tab w1_income5 //help from family/friends

tab w1_income_range
recode w1_income_range (1/9 = 1 "Below 75k") (10/13 = 0 "Above 75k") (88 99 = .), gen(incomeunder75k)
tab incomeunder75k

tab w1_income_worry
recode w1_income_worry (1 2 = 1 "Always/Often") (3 4 = 0 "Sometimes/Never") (88 99 = .), gen(incomeworry)
tab incomeworry

egen foo=group(incomeworry incomeunder75k), label(foo, replace)
tab foo
recode foo (1/3 = 0 "No") (4 = 1 "Yes"), gen(incomegroup)
tab incomegroup
drop foo

gen adultses = 0
replace adultses = 1 if w1_income_est==1
replace adultses = 1 if w1_income2==1
replace adultses = 1 if w1_income4==1
replace adultses = 1 if w1_income5==1
replace adultses = 1 if incomegroup==1
label define adultses 0 "High" 1 "Low" 
label values adultses adultses
tab adultses
replace adultses = . if (w1_income_est==88 | w1_income_est==99) & (w1_income2==88 | w1_income2==99) & (w1_income4==88 | w1_income4==99) & (w1_income5==88 | w1_income5==99) & (incomegroup==.)
tab adultses

//Coding social mobility//
egen socialmob=group(childses adultses), label(socialmob, replace)
tab socialmob

//Preparing to merge - need to fix id variable//
gen str6 tempid = string(studyid,"%06.0f")
gen id="S"+tempid

save "star_social_mobility.dta", replace

///////////////////// Step 2: Merge data ///////////////////////////

//Prepare the merged KHANDLE/STAR longitudinal dataset for merging
use "khan_star_la90_senas_ecog_longitudinal.dta", clear
sort id
drop if study=="LA90" //not using LA90
reshape wide cat exec on pa phon sem vm vrmem vmform lsform testlang wm cat_sem on_sem pa_sem phon_sem vm_sem wm_sem telephone concerned_thinking mem1 mem2 lang1 lang2 visual_spatial1 visual_spatial2 visual_spatial3 visual_spatial4 visual_spatial5 planning1 planning2 planning3 organization1 organization2 divided_attention1 divided_attention2 nmiss_ecog nmiss_sen yrsbl aget89, i(id) j(wave) string

replace age_bl = aget891 if age_bl==. //filling in missing values of baseline age with the baseline value of time-varying age - 435/2476 values filled in

save "khan_star_longitudinal.dta", replace

//Merging in STAR data//
merge 1:1 id using "star_social_mobility.dta", keepusing(id childses adultses socialmob w1_maternal_education w1_paternal_education w1_country_born)

//Result                      Number of obs
//    -----------------------------------------
//    Not matched                         1,713
//        from master                     1,713  (_merge==1)
//        from using                          0  (_merge==2)
//
//    Matched                               764  (_merge==3)
//    -----------------------------------------
drop _merge

//Merging in KHANDLE data//
merge 1:1 id using "khan_social_mobility_11.15.23.dta", keepusing(id childses1 adultses1 socialmob1 w1_maternal_education1 w1_paternal_education1 w1_country_born1 vrmem4 daysbl)

//    Result                      Number of obs
//    -----------------------------------------
//    Not matched                           765
//        from master                       765  (_merge==1)
//        from using                          0  (_merge==2)
//
//    Matched                             1,712  (_merge==3)
//    -----------------------------------------
drop _merge

replace childses=childses1 if study=="KHANDLE"
replace adultses=adultses1 if study=="KHANDLE"
replace socialmob=socialmob1 if study=="KHANDLE"
replace w1_maternal_education=w1_maternal_education1 if study=="KHANDLE"
replace w1_paternal_education=w1_paternal_education1 if study=="KHANDLE"
replace w1_country_born=w1_country_born1 if study=="KHANDLE"

save "khan_star_longitudinal_analysis.dta", replace

///////////////////// Step 3: Creating intersectionality identity variable, cleaning covariate data, summarizing missing obs ///////////////////// 

//Race
sort study
by study: tab race_summary //3/1712 Native American in KHANDLE; 1/764 Native American in STAR, 3/764 Refused/Missing in STAR
gen race_new = race_summary
replace race_new = "" if race_summary=="Native American" | race_summary=="Refused/Missing"
tab race_new

//All four combinations of social mobility//
egen cluster1=group(gender race_new socialmob), label
tab cluster1

label define clusters 1 "Man Asian High-High" 2 "Man Asian High-Low" 3 "Man Asian Low-High" 4 "Man Asian Low-Low" 5 "Man Black High-High" 6 "Man Black High-Low" 7 "Man Black Low-High" 8 "Man Black Low-Low" 9 "Man Latinx High-High" 10 "Man Latinx High-Low" 11 "Man Latinx Low-High" 12 "Man Latinx Low-Low" 13 "Man White High-High" 14 "Man White High-Low" 15 "Man White Low-High" 16 "Man White Low-Low" 17 "Woman Asian High-High" 18 "Woman Asian High-Low" 19 "Woman Asian Low-High" 20 "Woman Asian Low-Low" 21 "Woman Black High-High" 22 "Woman Black High-Low" 23 "Woman Black Low-High" 24 "Woman Black Low-Low" 25 "Woman Latinx High-High" 26 "Woman Latinx High-Low" 27 "Woman Latinx Low-High" 28 "Woman Latinx Low-Low" 29 "Woman White High-High" 30 "Woman White High-Low" 31 "Woman White Low-High" 32 "Woman White Low-Low"
label values cluster1 clusters

//Maternal education
recode w1_maternal_education (0 = 0 "High school or less") (1 2 = 1 "Some college or Associate's degree") (3/5 = 2 "Bachelor's degree or higher") (66 88 99 = 3 "Missing or NA"), gen(mother_educ)
tab mother_educ

//Paternal education
recode w1_paternal_education (0 = 0 "High school or less") (1 2 = 1 "Some college or Associate's degree") (3/5 = 2 "Bachelor's degree or higher") (66 88 99 = 3 "Missing or NA"), gen(father_educ)
tab father_educ

//Country of birth
tab w1_country_born //43/2476 refused (==88) and 7/2476 reported don't know/not ascertained (==99)
recode w1_country_born (1 = 1 "US") (2/27 = 2 "Elsewhere") (88/99 = .), gen(country_born)
tab country_born

//Summarizing missing observations//
summ age_bl //n=2476
tab gender //n=2476
tab race_new //n=2469, 7 missing (breakdown by study/reason is above)
tab socialmob //n=2352, 124 missing
tab mother_educ //n=2476, 0 missing because we use a missing indicator
tab father_educ //n=2476, 0 missing because we use a missing indicator
tab country_born //n=2426, 50 missing (breakdown by reason above)

//Creating indicator for missing data
gen missany=0
replace missany=1 if age_bl==. //0 changes made
replace missany=1 if socialmob==. //124 changes made to missing
replace missany=1 if gender==. //0 changes made
replace missany=1 if race_new=="" //5 changes made to missing
replace missany=1 if mother_educ==. //0 changes made
replace missany=1 if father_educ==. //0 changes made
replace missany=1 if country_born==. //0 changes made - everyone missing data on this variable was also missing social mobility
sort study
by study: tab missany if race_summary!="Native American" //checking to see how many are excluded due to missing race/ethnicity by study

//2347 with non-missing values on all variables - this is the analytical sample!

///////////////////// Step 4: Preparing some additional variables for analysis ///////////////////// 

//Centering baseline age
center if missany==0, cont(age_bl) //this uses a user-written ado by Rich Jones - let me know if you want the installation files

//Standardizing vrmem to baseline distribution//
summ vrmem1 if missany==0 //mean = .1709057, SD = .8722915
gen zvrmem1 = (vrmem1-.1709057)/.8722915 if missany==0
summ zvrmem1
gen zvrmem2 = (vrmem2-.1709057)/.8722915 if missany==0
summ zvrmem2
gen zvrmem3 = (vrmem3-.1709057)/.8722915 if missany==0
summ zvrmem3
gen zvrmem4 = (vrmem4-.1709057)/.8722915 if missany==0
summ zvrmem4

//Calculating years since baseline for the KHANDLE Wave 4 sample
tab daysbl if missany==0 & vrmem4!=. //32/474 observations are masked at -90
gen yrsbl4 = daysbl/365 if daysbl!=-90 //converting days since baseline to years since baseline
replace yrsbl4 = 4.96 if daysbl==-90 //for those with masked values, assign them the mean years since baseline

//Calculating age at each follow-up for practice effect investigation//
gen currage1 = age_bl
gen currage2 = age_bl+yrsbl2
gen currage3 = age_bl+yrsbl3
gen currage4 = age_bl+yrsbl4

//Creating filter for practice effect investigation - including only those with balanced data at waves 1 and 2 with in-person assessments, and no missing data
gen practice=1
replace practice=0 if zvrmem1==. //143 changed to missing
replace practice=0 if zvrmem2==. //386 changed to missing
replace practice=0 if telephone2==1 //265 changed to missing
replace practice=0 if missany==1 //0 changed to missing
tab practice if missany==0 //1683/2347 have a value of 1 for practice - will be included when estimating offset for practice effect

//Destring race/ethnicity variable - probably making this harder than it is
tab race_new
gen race_groups = 0
replace race_groups = 1 if race_new=="Black"
replace race_groups = 2 if race_new=="LatinX"
replace race_groups = 3 if race_new=="White"
replace race_groups = . if race_new==""

label define race_groups 0 "Asian" 1 "Black" 2 "LatinX" 3 "White"
label values race_groups race_groups

tab race_groups

save "khan_star_longitudinal_analysis.dta", replace
