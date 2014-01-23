#!/bin/csh -f

source /machine/gempak/NAWIPS/Gemenviron
setenv DISPLAY laraine:1

set NTSDIR=~gempak/wseta_region

if (-e ams_region.sfc ) rm ams_region.sfc
sfcfil << EOF_SFCFIL
   restore $NTSDIR/wseta_sfcfil
   SFOUTF = ams_region.sfc
   STNFIL = $NTSDIR/conus_mos.stn
   r

   e
EOF_SFCFIL


gdgsfc << EOF_GDGSFC
   restore $NTSDIR/wseta_gdgsfc
   GDFILE = ${1}_eta218.gem
   SFFILE = ams_region.sfc
   r

   e
EOF_GDGSFC

if ( -e ams_forecast.dat ) rm ams_forecast.dat
sflist << EOF_SFLIST
   restore $NTSDIR/wseta_sflist
   SFFILE   = ams_region.sfc
   OUTPUT   = f/ams_forecast.dat
   r

   e
EOF_SFLIST

set STID=`tail +4 ams_forecast.dat | sort -k 3bnr | head -1`
tail +4 ams_forecast.dat | sort -k 3bnr | head -10

set SLAT=$STID[4]
set SLON=$STID[5]

echo "$SLAT $SLON" >! model_center_$1.dat
