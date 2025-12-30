/*******************************************************************************
** Project:    Extreme Rainfall and Urban Consumption in Chinese Business Districts  
** Data:       2019–2022 daily transactions from 4,028 districts across 40 cities  
** Purpose:    Estimate causal, nonlinear, and heterogeneous impacts of rainfall  
**             on offline consumption, and assess district/city vulnerability.  
** Author:     Ye Shu  
** Date:       2025/12/30 
*******************************************************************************/

clear all
set more off
set seed 12345

// Set working directory (update path as needed)
cd "D:\data"

/*******************************************************************************
** 1. Load and Prepare Data  
*******************************************************************************/
use "data/df.dta", clear

// Encode string identifiers
encode 商圈, gen(business_district)
encode 交易城市, gen(city)
encode 交易区县, gen(county)

// Rename weather variables to English
rename 平均气温 temp_avg
rename pre precipitation
rename pm25_24 pm25_daily
rename 最大风速 wind_speed_max
rename 相对湿度 relative_humidity

// Generate log transaction amount (dependent variable)
gen log_transaction_amount = log(transaction_amount)

// Set panel structure
xtset business_district date

/*******************************************************************************
** 2. Main Analysis: Nonlinear Rainfall–Consumption Response  
*******************************************************************************/
// Define rainfall bins (10 mm intervals)  
recode precipitation (0 = 0) (0/10 = 1) (10/20 = 2) (20/30 = 3) (30/40 = 4) ///
                     (40/50 = 5) (50/60 = 6) (60/70 = 7) (70/80 = 8) ///
                     (80/90 = 9) (90/100 = 10) (100/110 = 11) (110/120 = 12) ///
                     (120/130 = 13) (130/140 = 14) (140/150 = 15) (150/max = 16), ///
       gen(rainfall_bin_10mm)

// High-dimensional fixed-effects regression with nonlinear rainfall effects  
reghdfe log_transaction_amount i.rainfall_bin_10mm c.temp_avg##c.temp_avg ///
        pm25_daily wind_speed_max relative_humidity, ///
        absorb(i.holiday i.dow i.epidemic i.date i.business_district#i.year#i.month) ///
        vce(cluster business_district)

// Store and export results  
estimates store main_nonlinear
esttab main_nonlinear using "results/main_nonlinear.rtf", ///
       replace r2 ar2 t ci level(95) drop(_cons temp_* pm25_daily wind_speed_max relative_humidity)

/*******************************************************************************
** 3. Distributed-Lag Model: Dynamic Adjustment After Rainfall  
*******************************************************************************/
use "data/df_lag.dta", clear
encode 商圈, gen(business_district)
rename 平均气温 temp_avg
xtset business_district date
gen log_transaction_amount = log(transaction_amount)

// Define official rainfall grades  
gen rainfall_grade = 0 if precipitation == 0
replace rainfall_grade = 1 if precipitation > 0 & precipitation < 10
replace rainfall_grade = 2 if precipitation >= 10 & precipitation < 25
replace rainfall_grade = 3 if precipitation >= 25 & precipitation < 50
replace rainfall_grade = 4 if precipitation >= 50 & precipitation < 100
replace rainfall_grade = 5 if precipitation >= 100

// Lagged effects: days 0–9, 10–19, 20–30  
reghdfe log_transaction_amount i.rainfall_grade i.rainfall_grade_? ///
        c.temp_avg##c.temp_avg pm25_daily wind_speed_max relative_humidity, ///
        absorb(i.holiday i.dow i.epidemic i.date i.business_district#i.year#i.month) ///
        vce(cluster business_district)

estimates store lag_effects
esttab lag_effects using "results/lag_effects.rtf", ///
       replace r2 ar2 t ci level(95) mtitle("0–9 days" "10–19 days" "20–30 days")

/*******************************************************************************
** 4. Heterogeneity by Adaptation Factors  
*******************************************************************************/
// 4.1 Historical rainfall exposure  
use "data/df.dta", clear
* [Prep as in Section 1]
reghdfe log_transaction_amount i.rainfall_grade c.temp_avg##c.temp_avg ///
        pm25_daily wind_speed_max relative_humidity if historical_rainfall_group == "High", ///
        absorb(i.holiday i.dow i.epidemic i.date i.business_district#i.year#i.month) ///
        vce(cluster business_district)
estimates store high_hist

* [Repeat for Medium and Low groups; store and compare]

// 4.2 Population age structure  
reghdfe log_transaction_amount i.rainfall_grade c.temp_avg##c.temp_avg ///
        pm25_daily wind_speed_max relative_humidity if elderly_share_group == "High", ///
        absorb(...) vce(cluster business_district)
estimates store high_age

* [Repeat for Medium and Low]

// 4.3 Transport accessibility (road density)  
reghdfe log_transaction_amount i.rainfall_grade c.temp_avg##c.temp_avg ///
        pm25_daily wind_speed_max relative_humidity if road_density_group == "High", ///
        absorb(...) vce(cluster business_district)
estimates store high_road

// 4.4 Impervious surface coverage  
reghdfe log_transaction_amount i.rainfall_grade c.temp_avg##c.temp_avg ///
        pm25_daily wind_speed_max relative_humidity if impervious_group == "High", ///
        absorb(...) vce(cluster business_district)
estimates store high_imperv

// Export grouped results  
esttab high_hist high_age high_road high_imperv using "results/heterogeneity.rtf", ///
       replace r2 ar2 t ci level(95)

/*******************************************************************************
** 5. Urban and Intra-Urban Vulnerability Mapping  
*******************************************************************************/
use "data/dta_busid_val_predict.dta", clear
* [Prep as in Section 1; ensure log_road, hmindex, per_capital, impervious_ratio are present]

// Interaction model for marginal effects  
reghdfe log_transaction_amount c.precipitation##c.log_road ///
        c.precipitation##i.hmindex c.precipitation##c.per_capital ///
        c.precipitation##c.impervious_ratio c.temp_avg##c.temp_avg ///
        pm25_daily wind_speed_max relative_humidity, ///
        absorb(i.city i.holiday i.dow i.epidemic i.date i.business_district#i.year#i.month) ///
        vce(cluster business_district)

estimates store vulnerability_model
esttab vulnerability_model using "results/vulnerability_model.rtf", ///
       replace r2 ar2 t ci level(95)

// Compute district-level marginal loss per mm rainfall  
predictnl marginal_loss = _b[precipitation] + ///
                         _b[c.precipitation#c.log_road]*log_road + ///
                         _b[1.hmindex#c.precipitation]*(hmindex==1) + ///
                         ... [other interactions] ..., ci(lb ub)

// Aggregate to city level (consumption-weighted)  
collapse (mean) marginal_loss, by(city)

/*******************************************************************************
** 6. Robustness Checks  
*******************************************************************************/
// 6.1 Exclude districts with <1000 days  
use "data/df_10mm.dta", clear
bysort business_district: gen days = _N
keep if days >= 1000
* [Run main nonlinear model; store & export]

// 6.2 Use transaction count instead of amount  
gen log_transaction_count = log(交易笔数)
* [Run main model; store & export]

// 6.3 Exclude air pollution controls  
reghdfe log_transaction_amount i.rainfall_bin_10mm c.temp_avg##c.temp_avg ///
        wind_speed_max relative_humidity, absorb(...) vce(cluster ...)
estimates store no_pollution

// 6.4 Linear rainfall effect  
reghdfe log_transaction_amount c.precipitation c.temp_avg##c.temp_avg ///
        pm25_daily wind_speed_max relative_humidity, absorb(...) vce(...)
estimates store linear_rain

// Export robustness results  
esttab no_pollution linear_rain using "results/robustness.rtf", ///
       replace r2 ar2 t ci level(95)


/*******************************************************************************
** End of Script  
*******************************************************************************/