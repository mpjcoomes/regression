proc import out=teenager
file='E:\SASdata\TEENAGER.sav'
dbms=spss replace;
run;
proc sort data=teenager out=temp;
by yearlevel;
run;
proc summary;
var age;
by yearlevel;
output out=temp
n=N mean=M stddev=SD;
run; proc print noobs; run;
ods graphics on / noborder height=9cm width=15cm;
proc sgpanel data=teenager;
panelby yearlevel / rows=1;
vbox cogcop / category=sex datalabel=id;
colaxis label='Sex';
run;
ods graphics off;

ods graphics on / noborder height=8cm;
proc glm data=teenager plots=all;
class yearlevel sex;
model cogcop = behcop avoidcop yearlevel sex yearlevel*sex
/ solution clparm ;
lsmeans yearlevel sex yearlevel*sex / TDIFF PDIFF;
output out=residplot r=r RSTUDENT=r2;
ods output ParameterEstimates=ests;
run; quit;
proc sort data=residplot out=residplot;
by yearlevel sex;
run;
ods graphics on / noborder height=9cm width=15cm;
proc sgpanel data=residplot;
panelby yearlevel / rows=1;
vbox r2 / category=sex datalabel=id;
colaxis label='Sex';
rowaxis label='Studentised Residuals for ANCOVA';
run;
ods graphics off;
