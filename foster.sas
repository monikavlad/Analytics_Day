/* Generated Code (IMPORT) */
/* Source File: FC2020v1.xlsx */
/* Source Path: /home/u50356504/vlad.analytics */
/* Code generated on: 10/31/22, 3:19 PM */

%web_drop_table(WORK.foster);


FILENAME REFFILE '/home/u50356504/vlad.analytics/FC2020v1.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.foster;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.foster; RUN;


%web_open_table(WORK.foster);



/* cleaning categorical variables */

data work.foster;
   set work.foster;
   if ctkfamst = 'Unable to determine' then delete;
   if clindis = 'Not yet determined' then delete;
run;


* CHECK FOR DIFFERENT CODING OF MISSING VALUES ;

PROC FREQ data = work.foster;
Tables ctkfamst clindis lifelos;
run;

/* VISUAL CHECK IF VARIANCE ACROSS THE COMBINATIONS OF FAMILY STRUCTURE AND CLINICALLY DISABLED OR NOT HAVE THE SAME
VARIANCE OF LENGTH OF STAY. 
*/

PROC GLM data=work.foster;
  CLASS ctkfamst clindis;
  MODEL lifelos = ctkfamst clindis ctkfamst*clindis / SS3;
  LSMEANS ctkfamst clindis ctkfamst*clindis;
  OUTPUT out=pred p=ybar r=residual;
run;

/* Visual check for equality of variance within combinations.*/
PROC GPLOT data=pred;
 PLOT residual*ybar/vref=0;
run;

/* BOXPLOT TO CHECK THE ASSUMPTION of equality of variance of lifelos for all combinations
of clindis and ctkfamst.

The sort statement will sort by the caretaker family structure and then by presence or absence of clinical disability.
Remember in the boxplot command to use the 2nd sorted variable (here it is "clindis") 
as the x-axis variable in the boxplot. 
If you specify BOXSTYLE=SCHEMATIC, a whisker is drawn from the upper edge of the box 
to the largest observed value within the upper fence, and another is drawn from the 
lower edge of the box to the smallest observed value within the lower fence.
*/

/* WE WANT TO HAVE clindis BE THE X AXIS, SO WE PUT clindis LAST IN THE SORT. 
*/
proc sort data=work.foster;
   by ctkfamst clindis;
run;

proc boxplot data=work.foster;
   plot lifelos4*clindis (ctkfamst) /boxstyle=schematic;
   inset min mean max stddev / header = 'Overall Statistics' pos = tm;
   insetgroup n mean std;
run;

data work.foster;
set work.foster;
lifelos4=lifelos**(1/4);
run;

/* You can also use the means chart to get the largest standard deviation and the smallest. */
proc means data = work.foster mean std median Qrange min Q1 Q3 max skew;
 class clindis ctkfamst;
 var lifelos4;
 run;

proc means data = work.foster;
 class ctkfamst clindis;
 var lifelos;
 run;
 
 /*******************************************************************/
/*************** BEGINNING: NORMALITY *******************/
/*******************************************************************/ 

/* This is the required normality check.
CHECK NORMALITY OF THE QUANTITATIVE VALUE CALLED lifelos 
FOR ALL  combinations of ctkfamst and clindis.  */
PROC UNIVARIATE DATA = work.foster PLOTS NORMAL;
      class ctkfamst clindis;  /*CATEGORICAL*/
      VAR lifelos;   /*QUANTITATIVE*/
RUN;

/*******************************************************************/
/*************** END: NORMALITY *******************/
/*******************************************************************/ 

/*******************************************************************/
/*************** BEGINNING: TWO-WAY ANOVA *******************/
/*******************************************************************/ 

/* TWO-WAY ANOVA

This is a two-way anova for unbalanced data, meaning there are unequal sample sizes in the 
combinations of clindis and ctkfamst.

In addition, the equal variance assumaption is not satisfied, so the following 
results may be biased.
*/
TITLE1 'Table 1:  Does a combination of Aroma and Flavor Predict Quality?';
PROC GLM DATA = work.wineCAT2;
   CLASS FlavorCAT2 AromaCAT2;
   MODEL Quality = FlavorCAT2 AromaCAT2 FlavorCAT2*AromaCAT2 / SS3;
RUN;
quit;
PROC GLM DATA = work.foster;
   TITLE1 'Table 1:  Does a combination of Caretaker Family Structure and Clinical Disability result in Longer Length of Stay in Foster Care?';
   CLASS ctkfamst clindis;      /*First one in the class statement is the x axis of the interaction plot.*/
   MODEL lifelos4 = ctkfamst clindis ctkfamst*clindis/ss3 ;

RUN;
quit;

PROC GLM DATA = work.foster;
   TITLE1 'Table 1:  Does a combination of Caretaker Family Structure and Clinical Disability result in Longer Length of Stay in Foster Care?';
   CLASS ctkfamst clindis;      /*First one in the class statement is the x axis of the interaction plot.*/
   MODEL lifelos4 = ctkfamst clindis ;
   means ctkfamst /tukey lines;
RUN;
quit;

/* Reverse order for interaction plot. USE THE SS3 TABLE. SS3 is what the model term adds in the presence
of the other variables. SS1 is sequential, meaning it is what the model term adds in the presence
of the variable above it in the table, e.g. what the second main effect adds in the presence of 
only the first main effect.*/
PROC GLM DATA = work.foster;
   TITLE1 'Table 1:  Does a combination of Caretaker Family Structure and Clinical Disability result in Longer Length of Stay in Foster Care?';
   CLASS clindis ctkfamst;     /*First one in the class statement is the x axis of the interaction plot.*/
   MODEL lifelos = ctkfamst clindis ctkfamst*clindis ;
RUN;
quit;

/*******************************************************************/
/* Note YOU MAY JUST RUN THE SS3 VERSION FOR DELIVERABLES. */
/*******************************************************************/ 

PROC GLM DATA = work.foster;
   TITLE1 'Table 1:  Does a combination of Caretaker Family Structure and Clinical Disability result in Longer Length of Stay in Foster Care?';
   CLASS clindis ctkfamst;     /*First one in the class statement is the x axis of the interaction plot.*/
   MODEL lifelos = ctkfamst clindis ctkfamst*clindis /SS3;
   means clindis /tukey lines;
  
RUN;
quit;
/*******************************************************************/
/*************** END: TWO-WAY ANOVA *******************/
/*******************************************************************/ 

/*******************************************************************/
/*************** BEGINNING: GRAPHICS TO TELL STORY *******************/
/*******************************************************************/ 

/* INTERACTION PLOT
The benefit of an interaction plot that is separate from the Two-way analysis run is that you 
can make a descriptive title. The default interaction plot is not as legible nor is it a stand-alone
graphic, because the titles are not descriptive.

Both pieces of this code are necessary. The Proc Summary calculates and outputs the treatment combination means
and puts them into the variable TipPct in the output file called Prtfile. Then Proc Gplot is the 
graphics procedure that turns the information stored in Prtfile to a graphic.

See what happens if you leave off the Quit. 
Source: https://communities.sas.com/t5/New-SAS-User/Difference-between-Run-and-Quit-statement/td-p/565555
Whether a step uses QUIT or not depends on whether it allows "run groups".  
That is that you can run something without leaving the procedure and 
then add more statements and run those. For procedures that support run groups you need to 
use the QUIT statement to end the procedure. 
Another source: https://stackoverflow.com/questions/33764328/quit-vs-run-statements-in-sas/33764972

IF THE INTERACTION IS NOT SIGNIFICANT THE MODEL TO PREDICT lifelos IS ADDITIVE. average length of stay = clindis + ctkfamst
IF THE INTERACTION IS SIGNIFICANT SO THAT family structure HAS A DIFFERENT RESULT FOR CHILDREN WHO ARE/ARENOT CLINICALLY DISABLED THE MODEL IS NON-ADDITIVE. average Length of Stay = clindis + ctkfamst + clindis*ctkfamst.

*/

PROC SUMMARY DATA = work.foster NWAY;
   CLASS clindis ctkfamst;
   VAR lifelos4;
   OUTPUT OUT = Outfile MEAN = length;
RUN;

proc print data=outfile;
run;

data work.outfile;
set work.outfile;
length=length**4;
run;

PROC GPLOT DATA = Outfile;
   PLOT length * clindis = ctkfamst;   /*Variable with the Quantitative variable is the x axis on the interaction plot. */
   SYMBOL1 V = dot H = 2 I = join COLOR = green;
   SYMBOL2 V = dot H = 2 I = join COLOR = blue;
   TITLE1 H = 2 'Figure 1:  Interaction Plot for Length of Stay versus';
   Title2 H=2 'Family Structure and Presence of Clinical Disability';
RUN;quit;

PROC GPLOT DATA = Outfile;
   PLOT length * ctkfamst = clindis;   /*Variable with the Quantitative variable is the x axis on the interaction plot. */
   SYMBOL1 V = dot H = 2 I = join COLOR = green;
   SYMBOL2 V = dot H = 2 I = join COLOR = blue;
   TITLE1 H = 2 'Figure 2:  Interaction Plot for Length of Stay versus';
   Title2 H=2 'Family Structure and Presence of Clinical Disability';
RUN;
quit;
/*******************************************************************/
/*************** END: GRAPHICS TO TELL STORY *******************/
/*******************************************************************/ 


/* STORED CODE */


/*Visual check for normality for all of the residuals at once.
This is just extra. The normality must be checked for each of the combinations of the 
levels of the categorical variables with the PROC UNIVARIATE below with the class statement
and var.*/
PROC GLM data=work.foster;
  CLASS ctkfamst clindis;
  MODEL lifelos = ctkfamst clindis ctkfamst*clindis;
  LSMEANS ctkfamst clindis ctkfamst*clindis;
  OUTPUT out=pred p=ybar r=resid;
run;

PROC UNIVARIATE data=pred plots;
run;

data foster;
   set work.foster;
   if ctkfamst = 'Unable to determine' then delete;
   if clindis = 'Not Yet Determined' then delete;
run;

proc print data=work.foster;
   title 'table';
run;