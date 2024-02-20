	 /////// Data Analysis //////
//// Analyst: Lindsay Kobayashi ////
//// Date created: 06.02.2022 ////
//// Date last updated: 11.15.23 ////

//We are using the KHANDLE Waves 1-4 and STAR Waves 1-3.
//This do-file uses the derived dataset "khan_star_longitudinal_analysis.dta" created in "Intersectionality - Data Cleaning - 11.15.23.do"

//This data analysis do-file does the following steps:

// 1. Describes characteristics of the sample (Table 1)
// 2. Estimates the practice effect offet as per Ruijia Chen et al (2023) - a sanity check to confirm the magnitude in my analytical sample
// 3. Runs the null and intersectional mixed effects models (Table 2)
// 4. Runs postestimation commands and creates Figures 1 and 2

cd "/Users/lkob/Dropbox (University of Michigan)/psyMCA2022/Stata/" //set directory
use "khan_star_longitudinal_analysis.dta", clear

////////////// Step 1: Create Table 1 //////////////
sort study
by study: summ age_bl if missany==0
summ age_bl if missany==0
tab gender study if missany==0, row col
tab race_new study if missany==0, row col
tab socialmob study if missany==0, row col
tab mother_educ study if missany==0, row col
tab father_educ study if missany==0, row col
tab country_born study if missany==0, row col

////////////// Step 2: Estimate the practice effect offset, as per Ruijia Chen et al 2023 //////////////

//Reshape to long//
reshape long cat exec on pa phon sem vm vrmem zvrmem vmform lsform testlang wm cat_sem on_sem pa_sem phon_sem vm_sem wm_sem telephone concerned_thinking mem1 mem2 lang1 lang2 visual_spatial1 visual_spatial2 visual_spatial3 visual_spatial4 visual_spatial5 planning1 planning2 planning3 organization1 organization2 divided_attention1 divided_attention2 nmiss_ecog nmiss_sen yrsbl aget89 currage, i(id) j(wave)

//// Estimating practice effects in KHANDLE and STAR ////
mixed zvrmem c.currage c.wave i.gender i.race_groups i.education if study=="KHANDLE" & wave!=3 & wave!=4 & practice==1 || id: , reml 
//practice effect is 0.106 in KHANDLE (coef is 0.106, 95% CI: 0.062, 0.15)
mixed zvrmem c.currage c.wave i.gender i.race_groups i.education if study=="STAR" & wave!=3 & wave!=4 & practice==1 || id: , reml
//no practice effect in STAR (coef is -0.021, 95% CI: -0.089, 0.048)

//Subtracting practice effects from wave 2 and 3 observations in KHANDLE - I could not get the offset term to run with the mixed command in Stata
reshape wide
gen pracmag = 0.106
replace pracmag = 0 if study=="STAR"

gen pzvrmem1 = zvrmem1
gen pzvrmem2 = zvrmem2 - pracmag
gen pzvrmem3 = zvrmem3 - pracmag
gen pzvrmem4 = zvrmem4 - pracmag

//Reshape back to long for modeling
reshape long cat exec on pa phon sem vm vrmem zvrmem pzvrmem vmform lsform testlang wm cat_sem on_sem pa_sem phon_sem vm_sem wm_sem telephone concerned_thinking mem1 mem2 lang1 lang2 visual_spatial1 visual_spatial2 visual_spatial3 visual_spatial4 visual_spatial5 planning1 planning2 planning3 organization1 organization2 divided_attention1 divided_attention2 nmiss_ecog nmiss_sen yrsbl aget89 currage, i(id) j(wave)


/////////////////// Step 3: Null and intersectional mixed effects models (Table 2 ///////////////////////////////

//First, lets check that results are the same using current age and tine as the timescale//
gen wave1=0
replace wave1=1 if wave==1
mixed zvrmem c.currage i.wave1 i.telephone i.gender i.mother_educ i.father_educ i.country_born|| cluster1: || id: , reml 
//coef for currage is -0.0452
mixed zvrmem c.cage_bl c.yrsbl i.telephone i.gender i.mother_educ i.father_educ i.country_born|| cluster1: || id: , reml
//coef for cage_bl is -0.0458
//the coefficients for currage and cage_bl are very similar in both models - good!

// Now, we run null and intersectional longitudinal hierarchical model with memory observations (level 1) clustered within individuals (level 2), clustered within intersectional identities (level 3). Both models include random intercepts and random slopes at levels 2 and 3. We include these random effects a priori because want to decompose variance according to these random effects. //

//First, we check interactions of covariates with time in the null model (baseline age, mother's education, father's education, country of birth) //
mixed pzvrmem c.cage_bl##c.yrsbl i.mother_educ i.father_educ i.country_born i.telephone i.mother_educ#c.yrsbl i.father_educ#c.yrsbl i.country_born#c.yrsbl || cluster1: yrsbl, cov(un) || id: yrsbl, cov(un) reml
//We will only retain the baseline age*time interaction in subsequent models//

////////////////////// NULL MODEL ////////////////////// 
mixed pzvrmem c.cage_bl##c.yrsbl i.mother_educ i.father_educ i.country_born i.telephone || cluster1: yrsbl, cov(un) || id: yrsbl, cov(un) reml
estat icc //this is the same thing as the VPC, mentioned in the paper
//I also calculate the ICCs by hand, below, as a sanity check. The results should equal what we get from the command "estat icc"//
//Intercept ICC for intersectional identities = .1051376/(.1051376+.4507632+.3244234) = 0.119431
/////// 12% of variance in baseline memory is explained by variance between the intersectional identities in the null model
// Intercept ICC for persons within intersectional identities = (.1051376+.4507632)/(.1051376+.4507632+.3244234) = 0.631473
/////// 63% of variance in baseline memory is explained by between-person variance in the null model

////////////////////// MAIN EFFECTS MODEL ////////////////////// 
//Testing interactions of main effects with time - not including in the final model//
mixed pzvrmem c.cage_bl##c.yrsbl i.mother_educ i.father_educ i.country_born i.telephone i.gender i.race_groups ib1.socialmob ib1.socialmob#c.yrsbl i.gender#c.yrsbl i.race_groups#c.yrsbl || cluster1: yrsbl, cov(un) || id: yrsbl, cov(un) reml
estat icc
//Final main effects model, without time interactions//
mixed pzvrmem c.cage_bl##c.yrsbl i.mother_educ i.father_educ i.country_born i.telephone i.gender i.race_groups ib1.socialmob || cluster1: yrsbl, cov(un) || id: yrsbl, cov(un) reml
estat icc //this is the same thing as the VPC, mentioned in the paper
//Intercept ICC for intersectional identities = .0014807/(.0014807+.4497077+.3245887) = 0.001909
/////// 0.2% of variance in baseline memory is explained by variance between the intersectional identities in the main effects model
//Intercept ICC for persons within intersectional identities = (.0014807+.4497077)/(.0014807+.4497077+.3245887) = 0.581595
/////// 58% of variance in baseline memory is explained by between-person variance in the main effects model

//Main effects model post-estimation
predict ri3 rc3 rc2 ri2, reffects //ri3 is the cluster-level random intercept, rc3 is the cluster-level random slope, rc2 is the person-level random slope, ri2 is the person-level random intercept - these are the random effects aka BLUPs
predict resid, residuals //these are observation-level residuals
predict predtraj, fitted

//Two interesting plots that we won't use in this analysis//
twoway scatter ri3 cluster1

scatter rc2 ri2 if wave==1, saving(yx, replace) xtitle("Random intercept") ytitle("Random slope")
histogram rc2, freq horiz saving(hy, replace) yscale(alt) ytitle(" ") fxsize(35) normal
histogram ri2, freq saving(hx, replace) xscale(alt) xtitle(" ") fysize(35) normal
graph combine hx.gph yx.gph hy.gph, hole(2) imargin(0 0 0 0)

/// Figure 1 ///
egen pick_cluster = tag(cluster1)
replace ri3=. if pick_cluster!=1
replace ri2 =. if wave!=1
graph box res ri2 ri3, ascategory box(1, bstyle(outline)) yvaroptions(relabel(1 "Wave" 2 "Person" 3 "Intersectional identity")) medline(lcolor(black)) ytitle("Empirical Bayes predictions for random intercepts") //ascending order

/// Figure 2 ///
sort cluster1 id yrsbl
twoway (line predtraj yrsbl, connect(ascending)) if yrsbl<=5, by(cluster1, compact) xtitle(Time in years) ytitle(Verbal episodic memory score (SD units))

//Supplemental Table 1//
sort cluster1
by cluster1: summ vrmem
reshape wide
tab cluster1

save "khan_star_longitudinal_analysis.dta", replace


