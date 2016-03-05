/*---------------------------------------------------------------
* NAME: Appraisal_Ratio.sas
*
* PURPOSE: Appraisal ratio is the Jensen's alpha adjusted for specific risk.  The numerator is divided by 
*		   specific risk instead of total risk.
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* option- Required.  {APPRAISAL, MODIFIED, ALTERNATIVE}.  Choose "appraisal" to calculate the appraisal ratio, 
*					 "modified" to calculate modified Jensen's alpha, or "alternative" to calculate alternative
*					 Jensen's alpha.
* method - Optional. Specifies either geometric or arithmetic chaining method {GEOMETRIC, ARITHMETIC}.  
           Default=GEOMETRIC
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outAppraisalRatio - Optional. output Data Set with Appraisal Ratios.  Default="Appraisal_Ratio"
*
* MODIFIED:
* 7/22/2015 � CJ - Initial Creation
* 3/05/2016 � RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Appraisal_Ratio(returns, 
								BM=, 
								Rf=0, 
								scale= 1,
								option=, 
								method= GEOMETRIC,
								dateColumn= DATE, 
								outAppraisalRatio= Appraisal_Ratio);

%local nv Jensen_Alpha divisor vars i;
/*Assign random names to temporary data sets*/
%let Jensen_Alpha= %ranname();
%let divisor= %ranname();
/*Find and count all variable names excluding date column, risk free and benchmark variables*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put VARS IN Appraisal_Ratio: (&vars);
%let nv= %sysfunc(countw(&vars));
/*Assign random name to counter*/
%let i= %ranname();

%CAPM_JensenAlpha(&returns, 
							BM= &BM, 
							Rf= &Rf, 
							scale= &scale, 
							method= &method,
							dateColumn= &dateColumn, 
							outJensen= &Jensen_Alpha);



%if %upcase (&option)= APPRAISAL %then %do;
%Specific_Risk(&returns, 
						BM=&BM, 
						Rf=&Rf,
						scale= &scale,
						dateColumn= &dateColumn,
						outSpecificRisk= &divisor);

%end;

%else %if %upcase(&option)= MODIFIED %then %do;
%CAPM_alpha_beta(&returns, 
						BM= &BM, 
						Rf= &Rf, 
						dateColumn= &dateColumn, 
						outBeta= &divisor);
data &divisor;
set &divisor;
if alphas_and_betas= 'alphas' then delete;
run;
%end;

%else %if %upcase(&option)= ALTERNATIVE %then %do;
%Systematic_Risk(&returns, 
						BM=&BM, 
						Rf=&Rf,
						scale= &scale,
						dateColumn= &dateColumn,
						outSR= &divisor);
%end;


data &outAppraisalRatio(drop= &i);
set &divisor &Jensen_Alpha;

array vars[*] &vars;
do &i= 1 to &nv;

vars[&i]= vars[&i]/lag(vars[&i]);
end;
run;

data &outAppraisalRatio(rename= _name_= _STAT_);
retain _name_;
set &outAppraisalRatio;

%if %upcase(&option)= APPRAISAL %then %do;
if stat= 'SpecRisk' then delete;
drop stat;
%end;
%else %if %upcase(&option)= MODIFIED %then %do;
if alphas_and_betas= 'betas' then delete;
drop alphas_and_betas;
%end;
%else %if %upcase(&option)= ALTERNATIVE %then %do;
if stat= 'Sys_Risk' then delete;
drop stat;
%end;
run;

data &outAppraisalRatio;
format _STAT_ $32.;
set &outAppraisalRatio;
_STAT_= upcase("&option");
drop Jensen_Alpha;
run;

proc datasets lib= work nolist;
delete &divisor &Jensen_Alpha;
run;
quit;
							
%mend;
