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
%let macro_qt = Q1;	/* if for all year data, put 0 here */
*********************;

/* Step 1: Filter GSE dataset*/
%macro filter_gse(yr = &macro_yr, qt = &macro_qt);
%step1_1(&yr);
%step1_2();
%step1_3(&yr., &qt.);
%mend filter_gse;

/* Step 1.1: Input & Fomat
1. import file;
2. change var names for different years in a same format;
3. pick out useful vars */
%macro step1_1(yr);
%if &yr = 2012 %then %do;
data f.tmp1_1;
set gseds.fannie_acquisition&yr.;
date 			=	put(Orig_date, yymmn6.);
seller 			=	SELLER;
loan_term		=	ORIG_TERM;
ltv				=	OLTV;
loan_purpose	=	LOAN_PURPOSE;
prop_type		=	PROP_TYPE;
zip				=	ZIP_3;
state			=	STATE;
%end;
%if &yr = 2014 %then %do;
data f.tmp1_1;
set gseds.fannie_acquisition&yr.;
date 			=	scan(trim(Orig_date),2)*100+scan(trim(Orig_date),1)*1;
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

/* Step 1.2: Filter out Cook county & Single-family obs */
%macro step1_2();
PROC SQL;
	CREATE TABLE F.tmp1_2 AS 
		SELECT t.PROP_TYPE, 
		t.SELLER, 
		t.LOAN_PURPOSE, 
		t.DATE, 
		t.LOAN_TERM, 
		t.LTV, 
		t.ZIP
	FROM F.tmp1_1 t
	WHERE UPPER(t.STATE) = 'IL'
		AND UPPER(t.PROP_TYPE) = 'SF';
QUIT;
%mend step1_2;

/* Step 1.3: Filter out certain year and quater obs */
%macro step1_3(yr, qt);
data 	f.tmp1_3;
set 	f.tmp1_2;
prop_type 	= upcase(prop_type);
year 		= int(date/100);
month 		= mod(date, 100);
if year = &yr.;
if (month < anydigit("&qt.")*3 and month > anydigit("&qt.")*3-3);
drop year month;
run;
%mend step1_3;


%filter_gse();