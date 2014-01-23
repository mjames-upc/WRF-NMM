#!/bin/csh -f

source /machine/gempak/NAWIPS/Gemenviron

set TOP=/machine/gempak/wrf/rtmodel
cd $TOP

if ( $#argv > 0 ) then
   set CYCLE=$1
else
   set CYCLE=`date -u '+%H'`
endif

set FDATE=`date -u '+%y%m%d'`"/${CYCLE}00"
set YMDH=`date -u '+%Y%m%d'`"${CYCLE}"

if (-e tile_region.sfc ) rm tile_region.sfc
sfcfil << EOF_SFCFIL
   restore wseta_sfcfil
   sfprmf = EPCP;IGPT;JGPT
   sfoutf = tile_region.sfc
   r

   e
EOF_SFCFIL


gdgsfc << EOF_GDGSFC
   restore wseta_gdgsfc
   sffile = tile_region.sfc
   r

   gfunc = igpt
   sfparm = igpt
   r

   gfunc = jgpt
   sfparm = jgpt
   r

   e
EOF_GDGSFC

if ( -e tile_location.dat ) rm tile_location.dat
sflist << EOF_SFLIST
   restore wseta_sflist
   sffile = tile_region.sfc
   sfparm = epcp>0;slat;slon;igpt;jgpt
   output = f/tile_location.dat
   r

   e
EOF_SFLIST

set STID=`tail +4 tile_location.dat | sort -k 3bnr | head -1`
tail +4 tile_location.dat | sort -k 3bnr | head -10

set SLAT=$STID[4]
set SLON=$STID[5]
set CCOL=$STID[6]
set CROW=$STID[7]

echo "$SLAT $SLON $CCOL $CROW" >! tile_center.dat
exit 0

