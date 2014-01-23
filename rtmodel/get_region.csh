#!/bin/csh -f

source /machine/gempak/NAWIPS/Gemenviron
setenv DISPLAY laraine:1

set TOP=/machine/gempak/wrf/rtmodel
set LDMHOST=motherlode.ucar.edu

cd $TOP

if ( $#argv > 0 ) then
   set CYCLE=$1
else
   set CYCLE=`date -u '+%H'`
endif

set FDATE=`date -u '+%y%m%d'`"/${CYCLE}00"
set YMDH=`date -u '+%Y%m%d'`"${CYCLE}"

#Once a week, do a cleanup, just in case!
set dayofweek=`date -u '+%w'`
if ( ( $dayofweek == 0 ) && ( $CYCLE == 12 ) ) then
   cleanup -c
endif

# make this directory now, just in case we fail later
ssh conan mkdir /content/software/gempak/wseta/${YMDH}

if (-e wseta_region.sfc ) rm wseta_region.sfc
sfcfil << EOF_SFCFIL
   restore wseta_sfcfil
   r

   e
EOF_SFCFIL


gdgsfc << EOF_GDGSFC
   restore wseta_gdgsfc
   r

   e
EOF_GDGSFC

if ( -e wseta_forecast.dat ) rm wseta_forecast.dat
sflist << EOF_SFLIST
   restore wseta_sflist
   r

   e
EOF_SFLIST

set STID=`tail +4 wseta_forecast.dat | sort -k 3bnr | head -1`
tail +4 wseta_forecast.dat | sort -k 3bnr | head -10

set SLAT=$STID[4]
set SLON=$STID[5]

echo "$SLAT $SLON" >! model_center.dat
#47.95 -124.55

if ( -e wseta_odomain.gif ) rm wseta_odomain.gif
if ( -e wseta_ndomain.gif ) rm wseta_ndomain.gif

etamap << EOF_ETAMAP
   GCENTER = ${SLAT};${SLON}
   IMJM = 95;151
   GSPACE = .098
   PANEL = 0
   MAP      = 31/1/1
   LATLON   = 0
   TITLE    = 1/-1/WSETA Domain 95x151 $FDATE
   TEXT     = 1/21/1/hw
   CLEAR    = yes
   DEVICE   = gf|wseta_odomain.gif|500;375
   r

   IMJM = 75;121
   GSPACE = .049
   DEVICE   = gf|wseta_ndomain.gif|500;375
   TITLE    = 1/-1/WSETA Nest Domain 75x121 $FDATE
   r
  
   e 
EOF_ETAMAP
gpend

if ( -e eta_conus.gif ) rm eta_conus.gif
if ( -e eta_roi.gif ) rm eta_roi.gif

gdplot2_gf << EOF_GDPLOT2
   restore wseta_gdplot2 
   panel = 0
   DEVICE   = gf|eta_conus.gif|500;375
   clrbar = 0
   clear = y
   TEXT     = .7/2/1/hw
   r

   DEVICE   = gf|eta_roi.gif|500;375
   gdpfun = gwfs(p24i,20)
   TITLE = 5/-1/WSETA Selected Region of Interest
   r

   e
EOF_GDPLOT2

if ( ! -e $YMDH ) mkdir $YMDH

# done above to make sure this directory exists later
# ssh conan mkdir /content/software/gempak/wseta/${YMDH}

if (-e wseta_odomain.gif ) then
   scp -Bq wseta_odomain.gif conan:/content/software/gempak/wseta/${YMDH}
   mv wseta_odomain.gif $YMDH
endif
if (-e wseta_ndomain.gif ) then
   scp -Bq wseta_ndomain.gif conan:/content/software/gempak/wseta/${YMDH}
   mv wseta_ndomain.gif $YMDH
endif
if (-e eta_conus.gif ) then
   scp -Bq eta_conus.gif conan:/content/software/gempak/wseta/${YMDH}
   mv eta_conus.gif $YMDH
   #~ldm/bin/ldmsend -h 128.117.15.119 -f SPARE -l ldmsend.log ${YMDH}/eta_conus.gif
   ~ldm/bin/ldmsend -h $LDMHOST -f SPARE -l ldmsend.log ${YMDH}/eta_conus.gif
endif
if (-e eta_roi.gif ) then
   scp -Bq eta_roi.gif conan:/content/software/gempak/wseta/${YMDH}
   mv eta_roi.gif $YMDH
   #~ldm/bin/ldmsend -h 128.117.15.119 -f SPARE -l ldmsend.log ${YMDH}/eta_roi.gif
   ~ldm/bin/ldmsend -h $LDMHOST -f SPARE -l ldmsend.log ${YMDH}/eta_roi.gif
endif
if ( -e model_center.dat) then
   scp -Bq model_center.dat conan:/content/software/gempak/wseta/${YMDH}
   cp model_center.dat $YMDH
   #~ldm/bin/ldmsend -h 128.117.15.119 -f SPARE -l ldmsend.log ${YMDH}/model_center.dat
   ~ldm/bin/ldmsend -h $LDMHOST -f SPARE -l ldmsend.log ${YMDH}/model_center.dat
endif

#
# create updated index.html and imagemap for model centers
scripts/wseta_domain.csh
