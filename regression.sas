
ods pdf file='C:\Users\lkona\Desktop\SAS\Assignment\college\college_lkona.pdf' pdftoc=2;
Options topmargin="5in";

/* Loading the college dataset for .csv format*/
ods proclabel "Import college dataset";
title "college dataset";
filename stdata 'C:\Users\lkona\Desktop\SAS\Assignment\college\College.csv';
proc import datafile=stdata
DBMS=csv out=college replace;
proc print data=college (obs=10);run;

/* Dummy coding for the variable "Private" */
ods proclabel "'Private' Dummy Variable code";
title "Dataset with 'Private' Dummy Variable";
data college_dum;
set college;
if (private='Yes') then P_1 = 1; else P_1 = 0;
run;
proc print data=college_dum (obs=10);run;


/* Generating boxplot for 'accept', 'top10perc' and 'enroll' side by side */
ods proclabel "Box Plot for 3 variables side by side";
title "Box Plot for 3 variables side by side";
data college_box; set college_dum;
  keep id accept top10perc enroll; 
  id = _n_;
run;
proc transpose data=college_box out=college_box_t; by id; run;
data college_box_t; set college_box_t;
label _name_ = "Variable";
label col1 = "Value";
run;
proc sgplot data=college_box_t;
vbox col1 / group=_name_ ;
run;

/* Log-transforming 'p_undergrad' and Dividing into train and test datasets */
ods proclabel "ENROLLTRAIN dataset";
title "ENROLLTRAIN dataset 1-544 observations";
data enrolltrain;
set college_dum(firstobs=1 obs=544);
lp_undergrad=log(p_undergrad);
run;
proc print data=enrolltrain(obs=10);run;

ods proclabel "ENROLLTEST dataset";
title "ENROLLTEST dataset 545-777 observations";
data enrolltest;
set college_dum(firstobs=545 obs=777);
lp_undergrad=log(p_undergrad);
run;
proc print data=enrolltest(obs=10);run;



/* Removing outliers and to achieve the linear distribution in the Normal Quantile Plot */

ods proclabel "Identifying outliers";
title "Identifying outliers";
proc univariate data=enrolltrain normal plot;
var accept top10perc f_undergrad lp_undergrad room_board grad_rate P_1 enroll; run;

data enrolltrain_mod;
set enrolltrain;
if accept > 4074.5 then delete;
if top10perc > 65 then delete;
if f_undergrad > 5953 then delete;
if enroll > 1401.75 then delete;
run;

ods proclabel "after cleaning  outliers";
title "Proc Univariate Analysis after cleaning outliers";
proc univariate data=enrolltrain_mod normal plot;
var accept top10perc f_undergrad lp_undergrad room_board grad_rate P_1 enroll; run;

ods proclabel "Trained Dataset count after cleaning outliers";
proc sql;
	select count(*) as enrolltrain_mod from enrolltrain_mod;
quit;

/*Fitting Multiple Linear Regression*/
ods proclabel "Fitting MLR to training dataset";
title "Fitting MLR to training dataset";
ods output ParameterEstimates = estimates;
proc reg data=enrolltrain_mod;
model enroll= accept top10perc f_undergrad lp_undergrad room_board grad_rate P_1/ tol vif collin;
plot r.*p.;
run;

/**** Identify higher VIF values > 5 and higher p-values > 0.05 ***/
ods proclabel "Variables with higher p-values";
title "Variables with higher p-values";

proc print data=estimates noobs;
var Variable Estimate tValue Probt varianceinflation;
where (VarianceInflation > 5 or Probt > 0.05);
run;

/* Running regression iteratively after dropping variables with high p-values values */
ods proclabel "Regression after dropping variables";
title "Regression after dropping variables";
proc reg data=enrolltrain_mod;
model enroll= accept f_undergrad lp_undergrad room_board P_1 / tol vif collin;
plot r.*p.;
run;

ods proclabel "Trained Dataset count after dropping variables";
proc sql;
	select count(*) as enrolltrain_mod from enrolltrain_mod;
quit;


/* Calculating the mean squared error for test dataset */
data mod_test;
set enrolltest;
y_bar = 126.16808 + (0.13419*accept) + (0.13532*f_undergrad) + (-3.39419*lp_undergrad) + (-0.02518*room_board) + (32.92484* P_1);
Predicted_err = ((enroll - y_bar)**2)/113;
run;
ods proclabel "mean squared error for test dataset";
title "mean squared error for test dataset";
title1 "Predicted_err sum=108047.10";

proc print data = mod_test ;
sum Predicted_err;
run;
ods pdf close;
