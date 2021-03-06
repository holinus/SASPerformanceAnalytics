/*---------------------------------------------------------------
* NAME: Table_UpDownRatios.sas
*
* PURPOSE: List the table of up/down capture/number/percent ratios.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns and benchmark.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* digits - Optional. Specifies number of digits displayed in the output. Default=4
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with up-down ratios.  Default="TableUpDownRatios".
* printTable - Optional. Option to print table.  {PRINT, NOPRINT} Default= NOPRINT
*
* MODIFIED:
* 6/09/2016 � RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Table_UpDownRatios(returns,
								BM=,
								digits= 4,
								dateColumn= DATE,
								outData= TableUpDownRatios,
								printTable= NOPRINT);

%local vars nvars ratios ratios_t;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Table_UpDownRatios: (&vars);

%let nvars = %sysfunc(countw(&vars));
%let ratios = %ranname();
%let ratios_t = %ranname();

%UpDownRatios(&returns, BM=&BM, dateColumn=&dateColumn, outData=&ratios);

proc transpose data=&ratios out=&ratios_t;
run;

data &outData;
	format _name_ $32.
		   col1 %eval(&digits + 4).&digits
		   col2 %eval(&digits + 4).&digits
		   col3 %eval(&digits + 4).&digits
		   col4 %eval(&digits + 4).&digits
		   col5 %eval(&digits + 4).&digits
		   col6 %eval(&digits + 4).&digits;
	set &ratios_t;
	_name_=catx(' ', _name_, "to", "&BM");

	rename _name_=asset
		   col1=UpCapture
		   col2=DownCapture
		   col3=UpNumber
		   col4=DownNumber
		   col5=UpPercent
		   col6=DownPercent
		   ;
run;
proc datasets lib = work nolist;
	delete &ratios &ratios_t;
run;
quit;

%if %upcase(&printTable)= PRINT %then %do;
	proc print data= &outData noobs;
	run; 
%end;

%mend;
