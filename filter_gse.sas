/*************************************************************************
Match Transaction & Mortgage Data
Step 1:	Filter GSE fannie acuisition data
Step 2:	Filter Title data
Step 3:	Match GSE & Title 
Step 4:	
Date:	May 27, 2015
Author:	Yuancheng Zhang
Location:	/opt/data/PRJ/Match_GSE_Title/
*************************************************************************/

option compress = yes;

libname f	"./";
libname gseds	"/opt/data/datamain/GSE/sas_dataset/";
libname titleds	"/opt/data/PRJ/Rep_All/Rep2014Q4/sas_dataset/";

/*******************; 
*	Source dataset	;
GSE 2012Q1:						fannie_acquisition2012.sas7bdat
Mortgage and transaction data:	match_trans_mort_matchlong.sas7bdat
********************************/

*********************;
*   set macro var	*;
%let macro_yr = 2012;
%let macro_qt = Q2;
%put ~~~~~~ Report Period:   &macro_dtst - &macro_yrend &macro_qtrend ~~~~~~;
%put ~~~~~~ Output Date:   &macro_date ~~~~~~;
*********************;

/* Step 1: Filter GSE dataset*/
%macro filter_gse(yr = &macro_yr, qt = &macro_qt);
%step1_1(&yr);
%step1_2(&yr, &qt);
%mend filter_gse;

/* Step 1.1: Fomat
1. change var names for different years in a same format;
2. pick out useful vars */
%macro step1_1(yr);
data f.tmp1_1;
set gseds.fannie_acquisition&yr;
%if &yr = 2012 %then %do;
date 			=	put(ORIG_DATE, yymmn6.);
seller 			=	SELLER;
loan_term		=	ORIG_TERM;
ltv				=	OLTV;
loan_purpose	=	LOAN_PURPOSE;
prop_type		=	PROP_TYPE;
zip				=	ZIP_3;
state			=	STATE;
%end;
%if &yr = 2014 %then %do;
date 			=	put(Orig_date, yymmn6.);
seller 			=	seller_name;
loan_term		=	orig_loan_term;
ltv				=	ltv;
loan_purpose	=	loan_purpose;
prop_type		=	prop_type;
zip				=	zipcode;
state			=	st;
%end;
keep date seller loan_term ltv loan_purpose prop_type zip state;
run;
%mend step1_1;

/* Step 1.2: Filter 
1. filter out Cook county & Single-family obs;
2. filter out certain year and quater obs */
%macro step1_2(yr, qt);
PROC SQL;
	CREATE TABLE F.tmp1_2 AS 
		SELECT t1.PROP_TYPE, 
		t1.STATE, 
		t1.SELLER, 
		t1.LOAN_PURPOSE, 
		t1.date, 
		t1.loan_term, 
		t1.ltv, 
		t1.zip
	FROM F.tmp1_1 t1
	WHERE UPPER(t1.STATE) = 'IL'
		AND UPPER(t1.PROP_TYPE) = 'SF';
QUIT;
/*
data f.tmp1_2;
set f.tmp1_1;
state = upcase(state);
prop_type = upcase(prop_type);
%if(state = "IL") %then;
%if(prop_type = "SF") %then;
run;
*/
%mend step1_2;


%filter_gse();