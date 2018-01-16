Calculating rolling 3 month skewness of prices by stock

 Solutions

    1. WPS/PROC R    ( R calculates skewness differently than SAS)
    2. SAS Base
    3. WPS Base (had to switch to a permanent array and it worked)

        NOTE WPS Base failed with this error (when using a temporary array)

        13        tot=skewness(of ts[*]);
        ERROR: A temporary array cannot be used in this way


Different skewness R and SAS
============================

They describe three types of measures (each with the variant of subtracting 3 from
the kurtosis measure or not - if not subtracted, normally
distributed variables have a kurtosis of 3):

Type 1 (3 not subtracted): used by the R library "moments" and by Stata
Type 2 (3 subtracted): used by SAS and SPSS, by using option type=2
          of the R library "e1071", and obviously also by EXCEL
Type 2 (3 not subtracted): rarely used
Type 3 (3 subtracted): used by MINITAB, BMDP and by using option
        type=3 (default) of the R library "e1071"
Type 3 (3 not subtracted): rarely used.

Dirk_Enzmann profile
https://www.researchgate.net/profile/Dirk_Enzmann
https://www.researchgate.net/post/Different_result_of_skewness_and_kurtosis-any_thoughts


see
https://goo.gl/Pf5PBj
https://communities.sas.com/t5/Base-SAS-Programming/Calculating-rolling-6-month-skewness-from-daily-returns/m-p/427551/highlight/true#M105470


Mkeintz profile ( I made some changes but this really helped)
https://communities.sas.com/t5/user/viewprofilepage/user-id/31461

Changed the problem to make it easier to understand

Not sure I completely understand the ops question

I will explain using a 3 month rolling sum example, and
supply code for an arbitrary window using skewness



INPUT (moving 3 day sums for explanation purposes (non trade days have been interpolated?)
===========================================================================================


 Obs    STOCK         OPEN    |   RULES                   WANT
                              |
   1    IBM           84.50   |                           .
   2    IBM          113.62   |                           .
   3    IBM          103.62   |   84.50+113.62+103.62     301.74
   4    IBM          101.00   |                           318.24
   5    IBM          122.87   |                           327.49
                              |
   6    Intel         33.33   |
   7    Intel         31.90   |
   8    Intel         27.56   |   33.33+31.90+27.56        92.79
   9    Intel         77.62   |                           137.08
  10    Intel        105.81   |
  11    Intel         78.44   |


WORKING CODE
============

   R ( note skewness)

     have[,want := RollingSkew(OPEN,window = 3), by=STOCK]; * type 1 skewness;

   WPS/SAS base (full code)

     data want;
       retain obs 1;
       set sd1.have;
       by stock ;
       if first.stock then obs=1;
       array ts{0:2} _temporary_;   * ring array shift left;
       ts{mod(obs-1,3)}=open;       * mod allows only indexes 0,1,2;
       if obs>=3 then do;
           tot=skewness(of ts{*});  * tyoe 2 skewness;
       end;
       obs+1;
     run;quit;


OUTPUT
======

 WORK.WANT total obs=29

   STOCK     OPEN      WANT_R       WANT_SAS

   IBM       84.50      .              .
   IBM      113.62      .              .
   IBM      103.62    -0.36152     -0.88554
   IBM      101.00     0.58600      1.43540
   IBM      122.87     0.66901      1.63874

   Intel     33.33      .            .
   Intel     31.90      .            .
   Intel     27.56    -0.53125      1.73185
   Intel     77.62     0.68768     -1.55965
   Intel    105.81    -0.32650     -1.27614
   Intel     78.44     0.70503      1.01354


*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
  set sashelp.stocks(where=(uniform(5733)<.035)
       keep=stock open rename=stock=);
  by stock;
  output;
run;quit;

*                      ______
__      ___ __  ___   / /  _ \
\ \ /\ / / '_ \/ __| / /| |_) |
 \ V  V /| |_) \__ \/ / |  _ <
  \_/\_/ | .__/|___/_/  |_| \_\
         |_|
;


%utl_submit_wps64('
libname sd1 sas7bdat "d:/sd1";
options set=R_HOME "C:/Program Files/R/R-3.3.2";
libname wrk sas7bdat "%sysfunc(pathname(work))";
proc r;
submit;
library(haven);
library(dplyr);
library(data.table);
library(RollingWindow);
have<-as.data.table(read_sas("d:/sd1/have.sas7bdat"));
have[,want := RollingSkew(OPEN,window = 3), by=STOCK];
endsubmit;
import r=have  data=wrk.want;
run;quit;
');

*                _
 ___  __ _ ___  | |__   __ _ ___  ___
/ __|/ _` / __| | '_ \ / _` / __|/ _ \
\__ \ (_| \__ \ | |_) | (_| \__ \  __/
|___/\__,_|___/ |_.__/ \__,_|___/\___|

;

data want;
  retain obs 1;
  set sd1.have;
  by stock ;
  if first.stock then obs=1;
  array ts{0:2} _temporary_;   * ring array shift left;
  ts{mod(obs-1,3)}=open;       * mod allows only indexes 0,1,2;
  if obs>=3 then do;
      tot=skewness(of ts[*]);  * tyoe 2 skewness;
  end;
  obs+1;
run;quit;

*                     _
__      ___ __  ___  | |__   __ _ ___  ___
\ \ /\ / / '_ \/ __| | '_ \ / _` / __|/ _ \
 \ V  V /| |_) \__ \ | |_) | (_| \__ \  __/
  \_/\_/ | .__/|___/ |_.__/ \__,_|___/\___|
         |_|
;

%utl_submit_wps64('
libname sd1 sas7bdat "d:/sd1";
libname wrk sas7bdat "%sysfunc(pathname(work))";
data wrk.wantwps;
  retain obs 1 t1-t3;
  set sd1.have;
  by stock ;
  if first.stock then obs=1;
  array ts{0:2} t1-t3;   * ring array shift left;
  ts{mod(obs-1,3)}=open;       * mod allows only indexes 0,1,2;
  if obs>=3 then do;
      tot=skewness(of ts[*]);  * tyoe 2 skewness;
  end;
  obs+1;
run;quit;
');

*____    _
|  _ \  | |_ ___    ___  __ _ ___
| |_) | | __/ _ \  / __|/ _` / __|
|  _ <  | || (_) | \__ \ (_| \__ \
|_| \_\  \__\___/  |___/\__,_|___/

;

* calculate the three types of skewness;
%utl_submit_r64('
library(e1071);
x<-c(84.50 ,113.62 ,103.62);
skewness(x, na.rm = FALSE, type = 1);
skewness(x, na.rm = FALSE, type = 2);
skewness(x, na.rm = FALSE, type = 3);
');


[1] -0.3615194   ( R)

[1] -0.8855382   (SAS and SPSS)

[1] -0.1967863   MINITAB and BMDP)


