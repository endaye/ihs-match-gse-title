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

/*******************/ 
/*	Source dataset	;
GSE 2012Q1:						fannie_acquisition2012.sas7bdat
Mortgage and transaction data:	match_trans_mort_matchlong.sas7bdat
********************/

/********************/
/*   set macro var	*/
%let macro_yr = 2012;
%let macro_qt = Q1;	/* if for all year data, put 0 here */
%let alpha = 0.05;
*********************;

/********************/
/*   The main steps	*/
%macro main(yr = &macro_yr, qt = substr("&macro_qt.",2,1));
*%filter_gse(&yr., &qt.);
*%filter_mort(&yr., &qt.);
%match();
%mend main;

/*****************************/
/* Step 1: Filter GSE dataset*/
%macro filter_gse(yr, qt);
*%test0_1(&yr);
*%step1_1(&yr);
*%step1_2();
*%step1_3(&yr., &qt.);
%step1_4();
%mend filter_gse; 

/* Test 1: Output a part of GSE/TITLE data as test sets* */
%macro test0_1(yr);
data f.test_gse;
set gseds.fannie_acquisition&yr. (obs=500);
run;
data f.test_title;
set titleds.match_trans_mort_matchlong (obs=500);
run;
%mend test0_1;

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
mort_amt	=	ORIG_AMT;
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
mort_amt	=	orig_upb;
loan_purpose	=	loan_purpose;
prop_type		=	prop_type;
zip				=	zipcode;
state			=	st;
%end;
keep date seller loan_term ltv mort_amt loan_purpose prop_type zip state;
run;
%mend step1_1;

/* Step 1.2: Filter out Cook county & Single-family & Purchased obs */
%macro step1_2();
PROC SQL;
	CREATE TABLE F.tmp1_2 AS 
		SELECT t.PROP_TYPE, 
		t.SELLER, 
		t.LOAN_PURPOSE, 
		t.DATE, 
		t.LOAN_TERM, 
		t.LTV, 
		t.MORT_AMT,
		t.ZIP
	FROM F.tmp1_1 t
	WHERE UPPER(t.STATE) = 'IL'
		AND UPPER(t.PROP_TYPE) = 'SF'
		AND UPPER(t.LOAN_PURPOSE) = 'P';
QUIT;
%mend step1_2;

/* Step 1.3: Filter out certain year and quater obs */
%macro step1_3(yr, qt);
data 	f.tmp1_3;
set 	f.tmp1_2;
prop_type 	= upcase(prop_type);
year 		= int(date / 100);
month 		= mod(date, 100);
if year = &yr.;
if (month <= &qt.*3 and month > &qt.*3-3);
*drop year month;
run;
%mend step1_3;

/* Step 1.4: 
1. Remove no value mortgage or LTV
2. Add Transaction Amount = Mortgage Amount / LTV */
%macro step1_4();
data 	f.tmp1_4;
set 	f.tmp1_3;
if mort_amt ^= 0 and mort_amt ^= .;
if ltv ^= 0 and ltv ^= .;
trans_amt 	= ceil(mort_amt / ltv * 100);
run;
%mend step1_4;


/********************************************************/
/* Step 2: Filter Title dataset (mortgage + transaction)*/
%macro filter_mort(yr, qt);
*%step2_0();
%step2_1();
%step2_2(&yr, &qt);
%mend filter_mort;

/* Step 2.0: Output a part of title data as a test set*/
%macro step2_0();
data f.tmp_long;
set titleds.match_trans_mort_matchlong (obs = 50);
run;
data f.tmp_wide;
set titleds.match_trans_mort_matchwide_all (obs = 50);
run;
%mend step2_0;

/* Step 2.1: Input & Fomat
1. import file;
2. change var names for different years in a same format;
3. pick out useful vars, drop others, reduce the file size.*/
%macro step2_1();
data f.tmp2_1;
set titleds.match_trans_mort_matchwide_all;
date 			=	date_doc_m1;
mort_amt		=	amount_m1;
trans_amt 		=	amount_prime;
pin				=	pin1;
keep date mort_amt trans_amt pin;
run;
%mend step2_1;

/* Step 2.2: Filter out certain data
1. target year and quater obs 
2. mortgage or transaction amount is not null*/
%macro step2_2(yr, qt);
data f.tmp2_2;
set f.tmp2_1;
if mort_amt ^= . and mort_amt ^= 0;
if trans_amt ^= . and trans_amt ^= 0;
year 	= year(date);
month	= month(date);
date1 	= put(date, yymmn6.);
if year = &yr.;
if (month <= &qt.*3 and month > &qt.*3-3);
run;
%mend step2_2;
*if doc_type	= "MORTGAGE";

/***********************************/
/* Step 3: Match GSE and TITLE data*/
%macro match();
%step3_1();
%mend match;


/* Step 3.1: Match based on 
1. mortgage amount
2. transaction amount
3. month and year */
%macro step3_1();
PROC SQL;
	CREATE TABLE F.tmp3_1 AS 
		SELECT t1.mort_amt AS G_MORT_AMT,
			t2.mort_amt AS T_MORT_AMT,
			t1.trans_amt AS G_TRANS_AMT,
			t2.trans_amt AS T_TRANS_AMT,
			ABS(t1.trans_amt - t2.trans_amt) AS DIFF,
			(ABS(t1.trans_amt - t2.trans_amt))/t1.trans_amt AS RATE,
			t1.seller AS G_SELLER,
			t1.year AS YEAR,
			t1.month AS MONTH
	FROM F.tmp1_4 t1
		INNER JOIN F.tmp2_2 t2
		ON t1.mort_amt = t2.mort_amt
		AND (ABS(t1.trans_amt - t2.trans_amt))/t1.trans_amt < &alpha.
		AND t1.year = t2.year
		AND t1.month = t2.month;
QUIT;
%mend step3_1;

/* Step 3.2: Match on mortgage and transaction amount */


/* Run */
%main();
