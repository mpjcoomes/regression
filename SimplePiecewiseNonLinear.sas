ods rtf style=styles.Myway1
file='E:MY_OUTPUT.rtf';

proc import out=teenager
file='E:\SASdata\TEENAGER.sav'
dbms=spss replace;
run;

*Exploratory Analysis & Simple Linear Regression;
ods graphics on / noborder height=7cm;
proc sgplot data=teenager;
hbox depr / DATALABEL=id;
run;
proc summary data=teenager;
var depr;
output out=depr_nmsd(drop=_type_ _freq_)
n=N mean=M stddev=SD skew=Skew kurt=Kurt;
run; proc print noobs round; run;
proc sgplot data=teenager;
hbox extagg / DATALABEL=id;
run;
proc summary data=teenager;
var extagg;
output out=extagg_nmsd(drop=_type_ _freq_)
n=n mean=M stddev=SD skew=Skew kurt=Kurt;
run; proc print noobs round; run;
ods graphics off;

ods graphics on / noborder height=10cm;
proc sgscatter data=teenager;
matrix depr extagg /
DIAGONAL=(histogram kernel NORMAL);
run;
proc corr data=teenager nosimple plots=none;
var depr;
with extagg;
run;
proc reg data=teenager plots(stats=none)=
(predictions(X=extagg smooth) diagnostics(stats=all)
rstudentbypredicted cooksd(label));
id id;
model depr=extagg / dw ;
run; quit;
ods graphics off;

*Bivariate Polynomial Regression;
proc sql; *centering predictors;
create table centering as select *,
extagg-mean(extagg) as extaggcent
from teenager;
quit;
data centered;
set centering;
extaggcent2=extaggcent*extaggcent;
extaggcent3=extaggcent*extaggcent*extaggcent;
run;
proc corr data=centered;
var extaggcent;
with extaggcent2 extaggcent3;
run;
ods graphics on / noborder height=10cm;
proc reg data=centered plots(stats=none)=
(predictions(X=extaggcent smooth) diagnostics(stats=all)
rstudentbypredicted cooksd(label))
outest=stats aic bic sbc adjrsq;
id id;
selection: model depr=extaggcent extaggcent2 extaggcent3
/ selection=ADJRSQ;
cubic: model depr=extaggcent extaggcent2 extaggcent3
/ tol vif;
run; quit;
proc sgplot data=centered;
hbox extaggcent2  / DATALABEL=id;
run;
proc sgplot data=centered;
hbox extaggcent3  / DATALABEL=id;
run;
data centered2; *removing influential points;
set centered(
where=(id^=169 & id^=327 & id^=70 & id^=130
& id^=67 & id^=276 & id^=287 & id^=113 & id^=162));
run;
proc reg data=centered2 plots(stats=none)=
(predictions(X=extaggcent smooth) diagnostics(stats=all)
rstudentbypredicted cooksd(label))
outest=stats aic bic sbc adjrsq;
id id;
selection: model depr=extaggcent extaggcent2 extaggcent3
/ selection=ADJRSQ;
cubic: model depr=extaggcent extaggcent2 extaggcent3
/ tol vif;
run; quit;
ods graphics off;

*Piecewise Linear Regression, knot=2;
data piecewise;
set teenager;
if extagg > 2 then extagg2 = 1;
if extagg2 ^= 1 then extagg2 = 0;
extagg2star = (extagg-2)*extagg2;
run;
ods graphics on / noborder height=10cm;
proc reg data=piecewise plots(stats=none)=
(predictions(X=extagg smooth) diagnostics(stats=all)
rstudentbypredicted cooksd(label))
outest=stats aic bic sbc adjrsq;
id id;
piecewise: model depr=extagg extagg2star / tol vif;
run; quit;
ods graphics off;

*Non-linear Reg Proc only, iteratively selected knot;
proc nlin data=teenager save maxiter=1000 outest=knot(
where=(_TYPE_='FINAL' & _STATUS_='0 Converged'));
parameters intercept=1.1 beta1=0.38 knot=1.2 beta2=-.13;
model depr=intercept+beta1*extagg+beta2*(extagg-knot)
*(extagg>knot);
run;
data _null_; set knot; call symput('knot2',knot);
run; %put knot is &knot2;
data teenager2; set teenager;
if extagg > &knot2 then x2 = 1;
if x2 ^= 1 then x2 = 0;
x2star = (extagg - &knot2)*x2;
run;
ods graphics on / noborder height=10cm;
proc reg data=teenager2 plots(stats=none)=
(predictions(X=extagg smooth) diagnostics(stats=all)
rstudentbypredicted cooksd(label))
outest=stats aic bic sbc adjrsq;
id  id;
  model depr = extagg x2star;
run; quit;
ods graphics off;&knot2;

*Non-linear Reg Proc only, bootstrapped k;
proc surveyselect data=teenager out=outbootseed=4587023
method=urs samprate=1 outhits rep=5000 noprint;
run; 
proc nlin data=outboot save noprint outest=bootknot(where=(
_TYPE_='FINAL' & _STATUS_='0 Converged')) maxiter=1000;
by replicate;
bounds 1 <= knot <= 4;
parameters intercept=1.1 beta1=0.38 knot=1.2 beta2=-.13;
model depr=intercept+beta1*extagg+beta2*(extagg-knot)
*(extagg>knot);
run;
proc univariate data=bootknot;
var knot;
output out=finalbknot mean=knot;
run;
data _null_; set finalbknot; call symput('knot2',knot);
run; %put knot is &knot2;
data teenager2; set teenager;
if extagg > &knot2 then x2 = 1;
if x2 ^= 1 then x2 = 0;
x2star = (extagg - &knot2)*x2;
run;
ods graphics on / noborder height=10cm;
proc reg data=teenager2 plots(stats=none)=
(predictions(X=extagg smooth) diagnostics(stats=all)
rstudentbypredicted cooksd(label))
outest=stats aic bic sbc adjrsq;
  model depr = extagg x2star;
run; quit;
ods graphics off;&knot2;

*Michaelis Menten Non-linear Model;
proc nlin data=teenager save maxiter=1000 outest=knot(
where=(_TYPE_='FINAL' & _STATUS_='0 Converged'));
parameters b1=0 b2=0;
model depr= b1 * extagg / (extagg + b2); 
output out=bootnlin u95=u95 l95=l95 u95m=u95m l95m=l95m
p=p student=student sse=_SSE_;
run;
ods graphics on / noborder height=8cm;
proc sort data=bootnlin out=bootplot; by extagg; run;
proc sgplot data=bootplot;
band x=extagg upper=u95 lower=l95 / nofill outline
lineattrs=(pattern=2) legendlabel='95% CI of prediction';
band x=extagg upper=u95m lower=l95m / transparency=.2
legendlabel='95% CI of mean';
scatter x=extagg y=depr;
PBSPLINE x=extagg y=p / nomarkers legendlabel=' ';
run;
proc sgplot data=bootnlin;
scatter x=p y=student;
refline 2 -2 / lineattrs=(pattern=2);
xaxis label='Predicted Value';
yaxis label='RStudent';
run;
data fitstats;
set bootnlin(obs=1);
AIC = 229*log(_SSE_/229)+2*2;
SBC = 229*log(_SSE_/229)+2*log(229);
run;proc print; var AIC SBC; run;
ods graphics off;

*Mediation;
ods graphics on / noborder height=8cm;
proc reg data=teenager corr plots(stats=none)=(diagnostics
(stats=all)rstudentbypredicted cooksd(label));
id id;
a: model hostil = extagg / stb clb vif tol;
b: model depr = extagg / stb clb vif tol;
c: model depr = hostil / stb clb vif tol;
d: model depr = extagg hostil / stb clb vif tol;
run; quit;
ods graphics off;

*Moderation;
data teenagermod; set teenager;
extaggXhostil = extagg*hostil;
run;
ods graphics on / noborder height=8cm;
proc reg data=teenagermod corr plots(stats=none)=(diagnostics
(stats=all)rstudentbypredicted cooksd(label));
id id;
base: model depr = extagg hostil / stb clb vif tol;
mod: model depr = extagg hostil extaggXhostil / stb clb vif tol;
test extaggXhostil = 0;
run; quit;
ods graphics off;

*Testing Improvements;
ods graphics on / noborder height=8cm LABELMAX=3000;
proc reg data=teenager corr plots(label)=(rstudentbypredicted
cooksd dffits);
Stage1Hier: model depr = na sex / stb clb vif tol;
Stage2Hier: model depr = na sex extagg hostil
/ stb clb vif tol partial;
test extagg=0, hostil = 0;
run; quit;
ods graphics off;
