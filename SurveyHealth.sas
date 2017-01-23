/********************************************************************************
* PROGRAM NAME : SurveyHealth.sas						*
* DESCRIPTION : Analysis of the National Survey of on Drug Use and Health, 2012	*
* PROGRAMMED BY : Jason Piccone							*
* DATE WRITTEN : 1/20/17							*
* MODIFICATIONS : 1/22/17							*
* SAS VERSION : University Edition 2.9 9.4M3					*
*********************************************************************************/

/***********************************
*                                  *
*          Import Data             *
*                                  *
***********************************/

PROC IMPORT datafile="/folders/myfolders/SurveyHealth.csv" dbms=csv out=db1 replace;
	GETNAMES=yes;
RUN;

/***********************************
*                                  *
*    Recode and Display Data       *
*                                  *
***********************************/

/* turn on ods for enhanced graphics */
ODS GRAPHICS ON  

/* Recode overall health variable labels for easier interpretation. 
   Note that the values had previously been standardized */
   
/* Establishes the labeling scheme */
PROC FORMAT;   
  VALUE  HEALTHY -1.223570279="Very Healthy"
		 -0.15957938="Moderately Healthy"
          	  0.904411518="Somewhat Healthy"
          	  1.968402416="Moderately Unhealthy"
          	  3.032393315="Very Unhealthy";
RUN;

/* Applies the label scheme to the database */
PROC FREQ DATA=db1;  
   FORMAT  HEALTH  HEALTHY.;
   TABLES HEALTH;
RUN;

/* Display distribution for the primary outcome: overall health */
PROC SGPLOT data=db1;
	TITLE "Distribution of Overall Health";
	FORMAT  HEALTH  HEALTHY.;
	vbar HEALTH; 
RUN;

/* Double check for missing data and sample sizes */
PROC MEANS DATA = db1 NMISS N; 
RUN; 

/* Display basic demographics */

/* Demographics - Age */
PROC FORMAT;   
  VALUE  AGE2b  -0.553509068="18"
                -0.350349648="19"
                -0.147190228="20"
          	 0.055969193="21"
          	 0.259128613="22-23"
          	 0.462288033="24-25"
          	 0.665447453="26-29"
          	 0.868606873="30-34"
          	 1.071766293="35-49"
          	 1.274925714="50-64"
          	 1.478085134="65+";
RUN;

PROC SGPLOT data=db1;
	TITLE "Distribution of Respondents' Age";
	FORMAT  AGE2 AGE2b.;
	XAXIS LABEL="Age";
	vbar AGE2; 
RUN;

/* Demographics - Sex */
PROC FORMAT;   
  VALUE  IRSEXb 0.0="Male"
  		1.0="Female";
RUN;
  
PROC SGPLOT sgplot data=db1;
	TITLE "Distribution of Respondents' Sex";
	FORMAT IRSEX IRSEXb.;
	XAXIS LABEL="Sex";
	vbar IRSEX; 
RUN;

/* Demographics - Married */
PROC FORMAT;   
  VALUE  MARRIEDb 0.0="No"
  		  1.0="Yes";
RUN;
  
PROC SGPLOT data=db1;
	TITLE "Distribution of Respondents' Marital Status";
	FORMAT  MARRIED MARRIEDb.;
	XAXIS LABEL="Married";
	vbar MARRIED; 
RUN;

/* Demographics - Ethnicity */
PROC FORMAT;   
  VALUE WHITEb 0.0="No"
  	       1.0="Yes";
RUN;
  
PROC SGPLOT data=db1;
	TITLE "Distribution of Respondents' Ethnicity";
	FORMAT  WHITE WHITEb.;
	XAXIS LABEL="Caucasian";
	VBAR WHITE; 
RUN;
 
/***********************************
*                                  *
*   Primary Predictive Analysis    *
*                                  *
***********************************/

/* create train/test split */
PROC SURVEYSELECT data=db1 out=traintest seed = 103 samprate=0.7 method=srs outall;
RUN;

/* perform Lasso (least absolute shrinkage and selection operator) regression */
PROC GLMSELECT data = traintest plots=all seed=103;
   partition ROLE=selected(train='1' test='0');
   model HEALTH = CIGEVER HALNOLST AMYLNIT ADDERALL COLDMEDS BOOKED INHOSPYR AURXYR 
		MEDICARE SCHENRL WHITE ASIAN PARTTIME AGE35_49 AGE50_64 RSKPKCIG RKFQPBLT 
		NMERTMT2 SNYSTOLE SNRLGSVC DSTNRV30 DSTHOP30 DSTEFF30 DSTNGD30 IRFAMSZ2 
		IRPINC3 AGE2 IREDUC2 RSKMJOCC RKTRYLSD RKTRYHER RKCOCOCC RK5ALWK RSKDIFMJ 
		RKDIFLSD RKDIFCOC RKDIFCRK RKFQDNGR RKFQRSKY RKFQDBLT SNYSELL SNYATTAK 
		SNFAMJEV SNRLGIMP SNRLDCSN SNRLFRND DSTRST30 DSTCHR30 IRHHSIZ2 IRKI17_2 
		IRHH65_2 IRKIDFA2 IRFAMIN3 SNFEVER CIGAREVR PIPEVER ALCEVER MJEVER COCEVER 
		CRKEVER HEREVER PCP PEYOTE MESC PSILCY ECSTASY CLEFLU GAS GLUE ETHER SOLVENT 
		LGAS NITOXID SPPAINT AEROS INHNOLST DARVTYLC PERCTYLX ANLNOLST KLONOPIN 
		XNAXATVN VALMDIAZ TRNEVER METHDES DIETPILS RITMPHEN STMNOLST STMEVER SEDEVER 
		AMBIEN KETAMINE RSKSELL PROBATON TXEVER TXNDILAL AUINPYR AUOPTYR AUUNMTYR 
		SUICTHNK ADDPREV IRFAMSOC IRFAMWAG IRFAMSVC PRVHLTIN HLCNOTYR SERVICE IRSEX 
		MARRIED WIDOWED DIVORCED NEVER_MARRIED BLACK PACISL MULTIPLE HISPANIC 
		FULLTIME UNEMPLOYED OTHER AGE18_25 AGE26_34 AGE65 COUNTY_LARGE COUNTY_SMALL 
		COUNTY_NONMETRO
   /selection=lar(choose=cv stop=none) cvmethod=random(10);
RUN;

/* The Lasso analysis selects 54 variables as meaningful contributors to the predictive model,
    these are ordered from the most to least meaningful. While they are statistically 
    meaningful, it is important to consider them from a practical perspective:
1. IREDUC2 = education (low to high)
2. DSTCHR30 = During the past 30 days, how often did you feel so sad or depressed that
   nothing could cheer you up? (all the time to none of the time)
3. DSTEFF30 = During the past 30 days, how often did you feel that everything was an effort? (all of the time to none of the time)
4. DSTHOP30 = During the past 30 days, how often did you feel hopeless? (all of the time to none of the time)
5. MEDICARE = Covered by Medicare
6. PRVHLTIN = Covered by private insurance
7. AGE2
8. DSTNGD30 = During the past 30 days, how often did you feel down on yourself, no good, or
   worthless? (from all of the time to none of the time)
9. NMERTMT2 = # of times been treated in the emergency room in the past 12 months
10. AURXYR1 = Took any prescription medications for mental health condition in the past 12 months
11. INHOSPYR = Stayed overnight as inpatient in hospital in the past 12 months
12. CIGEVER = Ever tried a cigarette
13. OTHER = Employment (NOT fulltime, partime or unemployed)
14. IRFAMSOC = Family receives social security or RR payments
15. AGE50_64
16. DSTNRV30 = During the past 30 days, how often did you feel nervous?
17. BOOKED = Ever been arrested and booked for breaking the law
18. SNRLGSVC = Past 12 months, how many religious services have you attended
19. SCHENRL = Are you now enrolled in any school
20. IRPINC3 = respondant's total income
21. ADDPREV = Several days or longer when you felt sad/empty/depressed
22. MJEVER = Ever used Marijuana/Hashish
23. RSKPKCIG1 = Risk of smoking 1 or more packs of cigarettes per day (from no risk to great risk)
24. DARVTYLC = Ever used Darvocet, Darvon, or Tylenol with Codeine
25. COUNTY_LARGE
26. PARTTIME work
27. WHITE
28. AMYLNIT = Ever inhaled Amyl Nitrite, poppers, rush, etc.
29. DIVORCED
30. PIPEVER = Ever smoked pipe tobacco
31. HEREVER = Ever used Heroin 
32. DSTRST301 = How often felt restless/fidgety in the past 30 days (all of the time to none of the time)
33. AGE35_49
34. SNYSTOLE1 = Stolen/tried to steal anything worth > $50 (0 times to 10 or more)
35. IRFAMWAG = Family received income from job
36. AGE18_25
37. RSKSELL = Approached by someone selling illicit drugs in the past 30 days
38. IRSEX = Gender (male, female)
39. RKCOCOCC1 = Risk of using Cocaine once a month (no risk to great risk)
40. COLDMEDS = ever use cold meds
41. SNFAMJEV = How do you feel about adults trying MJ/Hash (neither approve nor dis to strongly dis)
42. ADDERALL = Ever used Adderall that was not prescribed
43. RITMPHEN = Ever used Ritalin or Methyphenidate
44. SERVICE = Ever been in the US armed forces
45. COUNTY_NONMETRO
46. HLCNOTYR = Anytime you did not have health insurance/coverage in the past 12 months
47. RKFQDNGR = Get a real kick out of doing dangerous things
48. PROBATON1 = Been on probation at any time in the past 12 months
49. MARRIED
50. IRFAMSVC = Family received welfare/job placement/childcare
51. UNEMPLOYED
52. INHNOLST = Ever used other inhalents
53. RK5ALWK1 = How much risk in having 5 or more drinks once or twice a week (no risk to great risk)
54. GAS = Ever inhaled gasoline or lighter fluid  */

/***********************************
*                                  *
*       Detailed Analysis          *
*                                  *
***********************************/

/* We can now see which variables are the most important, let's look more closely at how 
they are related to the outcome of interest (overall health) */

/* Establishes the labeling scheme (again) */
PROC FORMAT;   
	VALUE  HEALTHYb -1="Very Healthy"
    			 0="Moderately Healthy"
          		 1="Somewhat Healthy"
          		 2="Moderately Unhealthy"
          		 3="Very Unhealthy";
RUN;

/* (1) Education Level by health */
PROC FORMAT;
	VALUE IREDUC2b   1.0=">12 Grade"
			 0.0="10-12 Grade"
			-1.0="8-9 Grade"
			-2.0="<8 Grade";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH  HEALTHYb.;
	FORMAT IREDUC2 IREDUC2b.;
	REG x=HEALTH Y=IREDUC2 / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Education Level";
	YAXIS LABEL="Education Level" values=(-2.0 to 1.0 by 1.0);
	XAXIS fitpolicy=none;  
RUN;

/* (2) Feel Sad/Depressed by health */
PROC FORMAT;
	VALUE DSTCHR30b -4.0="Always"
			-3.0="Mostly"
			-2.0="Sometimes"
			-1.0="A Little"
			 0.0="Never";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT DSTCHR30 DSTCHR30b.;
	REG x=HEALTH Y=DSTCHR30 / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Feeling Sad/Depressed";
	YAXIS LABEL="Feel Sad/Depressed" values=(-4.0 to 0.0 by 1.0);
	XAXIS fitpolicy=none;  
RUN;

/* (3) Everything is an effort by health */
PROC FORMAT;
	VALUE DSTEFF30b -4.0="Always"
			-3.0="Mostly"
			-2.0="Sometimes"
			-1.0="A Little"
			 0.0="Never";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT DSTEFF30 DSTEFF30b.;
	REG x=HEALTH Y=DSTEFF30 / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Everything is an Effort";
	YAXIS LABEL="Everything is an Effort" values=(-4.0 to 0.0 by 1.0);
	XAXIS fitpolicy=none;  
RUN;

/* (4) Hopeless by health */
PROC FORMAT;
	VALUE DSTHOP30b -4.0="Always"
			-3.0="Mostly"
			-2.0="Sometimes"
			-1.0="A Little"
			 0.0="Never";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT DSTHOP30 DSTHOP30b.;
	REG x=HEALTH Y=DSTHOP30 / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Feeling Hopeless";
	YAXIS LABEL="Hopeless" values=(-4.0 to 0.0 by 1.0);
	XAXIS fitpolicy=none;  
RUN;

/* (5) Medicare by health */
PROC FORMAT;
	VALUE PROC FORMAT;
	VALUE MEDICAREb 0="Yes"
			1="No";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT MEDICARE MEDICAREb.;
	REG x=HEALTH Y=MEDICARE  / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Medicare Coverage";
	YAXIS LABEL="Medicare Coverage" values=(0 to 1 by 1);
RUN;

/* (6) Covered by insurance by health */
PROC FORMAT;
	VALUE PRVHLTINb 0="Yes"
			1="No";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT PRVHLTIN PRVHLTINb.;
	REG x=HEALTH Y=PRVHLTIN  / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Insurance Coverage";
	YAXIS LABEL="Insurance Coverage" values=(0 to 1 by 1);
RUN;

/* (7) Age by health */
PROC FORMAT;
	VALUE AGE2b -0.5="Younger"
		     1.5="Older";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT AGE2 AGE2b.;
	REG x=HEALTH Y=AGE2 / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Age";
	YAXIS LABEL="Age" values=(-0.5 to 1.5 by 2.0);
	XAXIS fitpolicy=none;  
RUN;

/* (8) Feel Worthless by health */
PROC FORMAT;
	VALUE DSTNGD30b -4.0="Always"
			-3.0="Mostly"
			-2.0="Sometimes"
			-1.0="A Little"
			 0.0="Never";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT DSTNGD30 DSTNGD30b.;
	REG x=HEALTH Y=DSTNGD30 / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Feeling Worthless";
	YAXIS LABEL="Feel Worthless" values=(-4.0 to 0.0 by 1.0);
	XAXIS fitpolicy=none;  
RUN;

/* (9) Times in Emergency Room Past 12 Months by health */
ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	REG x=HEALTH Y=NMERTMT2 / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Num. Times in Emergency Room Past 12 Months";
	YAXIS LABEL="# Times Emergency Room"; 
	XAXIS fitpolicy=none;  
RUN;

/* (10) Took meds for mental health condition by health */
PROC FORMAT;
	VALUE AURXYRb  0="Yes"
		       1="No";
RUN;

ODS GRAPHICS / antialias=on antialiasmax=10000;
PROC SGPLOT DATA=db1 NOAUTOLEGEND;
	FORMAT HEALTH HEALTHYb.;
	FORMAT AURXYR AURXYRb.;
	REG x=HEALTH Y=AURXYR  / lineattrs=(color=red thickness=2);
	TITLE "Overall Health By Took Meds for Mental Health Condition";
	YAXIS LABEL="Took Meds for Mental Health" values=(0 to 1 by 1);
RUN;
