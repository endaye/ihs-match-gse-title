# match-gse-title
Match GSE data with Title data(Transaction amount + Mortgage amount)
-------------------

1. Basic Info

	* Author:	Yuancheng Zhang
	* Date:	May 27, 2015
	* On server:	/opt/data/PRJ/Match_GSE_Title/
	* Github:		github.com/vmvc2v/match-gse-title
2. Step

	1. Step 1:	Filter GSE fannie acuisition dataset

		Test 1: Output a part of GSE/TITLE data as test sets

		1Step 1.1: Input & Fomat GSE data

		Step 1.2: Filter out Cook county & Single-family & Purchased obs
	Step 1.3: Filter out certain year and quater obs
	Step 1.4: Turn out transaction amount
Step 2:	Filter Title dataset (mortgage + transaction)
	Step 2.0: Output a part of title data as a test set
	Step 2.1: Input & Fomat TITLE data
	Step 2.2: Filter out certain data
	Step 2.3: Filter out lender names
	Step 2.4: Add lender names into dataset
	Step 2.5: test step2_4
Step 3:	Step 3: Match GSE and TITLE data 
	Step 3.1: Matching
Step 4:	Show matching result
	Step 4.1: Show matching result

