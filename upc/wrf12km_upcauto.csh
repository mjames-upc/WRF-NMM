#!/bin/csh -f
set TOP=/machine/gempak/wrf/rtmodel

set NX=101
set NY=155
set DX=6000
set DY=6000

if ( ! $?WRF ) then
   echo sourcing WRF cshrc
   source /machine/gempak/wrf/WRF.cshrc
endif

source /machine/gempak/NAWIPS/Gemenviron

set LDMHOST=motherlode.ucar.edu

if ( $#argv > 0 ) then
   set CYCLE=$1
else
   set CYCLE=`date -u '+%H'`
endif

set FDATE=`date -u '+%y%m%d'`"/${CYCLE}00"
set YMDH=`date -u '+%Y%m%d'`"${CYCLE}"

# make our working directories
cd $DATA_DOMS
if ( ! -e ${YMDH}_12km ) mkdir ${YMDH}_12km
cd ${YMDH}_12km

cp $WRF/upc/nest_info.txt .
echo $DATAROOT >! dataroot.txt


#
# create wrfsi.nl file
#
set YYYY_START=`echo $YMDH | cut -c1-4`
set MONTH_START=`echo $YMDH | cut -c5,6`
set DAY_START=`echo $YMDH | cut -c7,8`
set HOUR_START=`echo $YMDH | cut -c9,10`

set ENDTIME=`datetime $FDATE 30 '%Y%m%d%H'`
set YYYY_STOP=`echo $ENDTIME | cut -c1-4`
set MONTH_STOP=`echo $ENDTIME | cut -c5,6`
set DAY_STOP=`echo $ENDTIME | cut -c7,8`
set HOUR_STOP=`echo $ENDTIME | cut -c9,10`

if ( -e $TOP/model_center.dat ) then
   set LL=`cat $TOP/model_center.dat | head -1`
   set DEFCLAT=$LL[1]
   set DEFCLON=$LL[2]
else
   set DEFCLAT="40.0"
   set DEFCLON="-105.5"
endif

cat $WRF/upc/wrfsi.nl_12km | sed 's/@YYYY_START@/'${YYYY_START}'/g' | \
   sed 's/@MONTH_START@/'${MONTH_START}'/g' | \
   sed 's/@DAY_START@/'${DAY_START}'/g' | \
   sed 's/@HOUR_START@/'${HOUR_START}'/g' | \
   sed 's/@YYYY_STOP@/'${YYYY_STOP}'/g' | \
   sed 's/@MONTH_STOP@/'${MONTH_STOP}'/g' | \
   sed 's/@DAY_STOP@/'${DAY_STOP}'/g' | \
   sed 's/@HOUR_STOP@/'${HOUR_STOP}'/g' | \
   sed 's/@NX@/'${NX}'/g' | sed 's/@NY@/'${NY}'/g' | \
   sed 's/@DX@/'${DX}'/g' | sed 's/@DY@/'${DY}'/g' | \
   sed 's/@CLAT@/'${DEFCLAT}'/g' | \
   sed 's/@CLON@/'${DEFCLON}'/g' >! wrfsi.nl 

if ( ! -e $DATAROOT/${YMDH}_12km ) mkdir $DATAROOT/${YMDH}_12km
cd $DATAROOT/${YMDH}_12km
$WRF/etc/window_domain_rt.pl \
	-w wrfsi.rotlat \
	-s $DATA_SI \
	-i $WRF \
	-d $DATAROOT/${YMDH}_12km \
	-t $DATA_DOMS/${YMDH}_12km

#
# calculate tiles to be used
cd $TOP/g218tiles
#set TILES=`tile_calc $DEFCLAT $DEFCLON $NX $NY $DX $DY`
set TILES=`tile_calc $DEFCLAT $DEFCLON $NX $NY 8000 8000`
echo "Running wrf_prep with $TILES"

cd $DATAROOT/${YMDH}_12km
wrf_prep --dset tile12 --ftp ncep $TILES --cycle ${CYCLE}:0:30

wrf_run

wrf_post --grib

if ( -e wrfpost/grib ) then
   cat wrfpost/grib/*_nmm.GrbF??? | dcgrib2 -d log/dcgrib2.log -v 1 $MODEL/nmm/YYYYMMDDHHfFFF_nmm.gem
   chmod 664 $MODEL/nmm/*_nmm.gem
   $TOP/nmm_gdplot2_output.csh ${YMDH}

   cd wrfpost/grib
   ~ldm/bin/ldmsend -v -l log/ldmsend.log -h $LDMHOST -f SPARE *_nmm.GrbF???
   cd ../..
endif

mv log $WRF/logs/runs/${YMDH}
wrf_clean --level 5<<EOF_CLEAN
yes
EOF_CLEAN


exit 



#wrf_prep --dset tile12 --cycle ${CYCLE}:0:30

wrf_prep --dset nam218grb2 --cycle 18:0:30 --nfs /data/ldm/nam_12km/YYYYMMDDHHf0FF.grib2


exit

