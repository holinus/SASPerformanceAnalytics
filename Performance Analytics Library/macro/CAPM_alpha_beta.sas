/*---------------------------------------------------------------
* NAME: CAPM_alpha_beta.sas
*
* PURPOSE: computes values of alpha and beta as defined in the capital asset pricing model.
*
* NOTES: Alpha and Beta of a desired asset are calculated given returns, a risk free rate, and a benchmark. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outBeta - Optional. Output Data Set of asset Alphas and Betas. Default= "alphas_and_betas"
* MODIFIED:
* 6/17/2015 � DP - Initial Creation
* 9/25/2015 - CJ - Assigned random names to temporary variables and data sets.
*				   Replaced PROC SQL statement with %get_number_column_names macro.
*				   Deleted macro %renamer that converted character to numeric variables, replaced with PROC TRANSPOSE
* 3/05/2016 � RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro CAPM_alpha_beta(returns, 
						BM=, 
						Rf= 0,
						dateColumn= DATE,  
						outBeta= alphas_and_betas);

%local vars RP Betas Names;
/*Find all variable names excluding the date column, benchmark, and risk free variables*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM); 
%put VARS IN CAPM_alpha_beta: (&vars);
/*Define temporary data set names with random names*/
%let RP= %ranname();
%let Betas= %ranname();
%let Names= %ranname();
%return_excess(&returns, 
					 	Rf= &Rf, 
						dateColumn= &dateColumn, 
						outReturn= &RP);


/***************************************
*Use proc reg to compute alpha and beta
****************************************/

proc reg data= &RP OUTEST= &Betas noprint;
model &vars = &BM;
run;
 
data &Betas;
set &Betas;
drop &vars _model_ _type_ _rmse_;
rename Intercept= alphas;
rename &BM= betas;
run;

proc transpose data= &Betas out=&outBeta  name= _STAT_;
id _depvar_;
run;

data &outBeta(drop= _label_);
set &outBeta;
run;

proc datasets lib= work nolist;
delete &RP &Betas &Names;
run;
quit;
%mend;
