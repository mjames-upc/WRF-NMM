#!/bin/csh -f

if ( ! $?WRF ) then
   echo sourcing WRF cshrc
   source /machine/gempak/wrf/WRF.cshrc
endif

source /machine/gempak/NAWIPS/Gemenviron
set TOP=/machine/gempak/wrf/rtmodel

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
if ( ! -e $YMDH ) mkdir $YMDH
cd $YMDH

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

cat $WRF/upc/wrfsi.nl | sed 's/@YYYY_START@/'${YYYY_START}'/g' | \
   sed 's/@MONTH_START@/'${MONTH_START}'/g' | \
   sed 's/@DAY_START@/'${DAY_START}'/g' | \
   sed 's/@HOUR_START@/'${HOUR_START}'/g' | \
   sed 's/@YYYY_STOP@/'${YYYY_STOP}'/g' | \
   sed 's/@MONTH_STOP@/'${MONTH_STOP}'/g' | \
   sed 's/@DAY_STOP@/'${DAY_STOP}'/g' | \
   sed 's/@HOUR_STOP@/'${HOUR_STOP}'/g' | \
   sed 's/@CLAT@/'${DEFCLAT}'/g' | \
   sed 's/@CLON@/'${DEFCLON}'/g' >! wrfsi.nl 

if ( ! -e $DATAROOT/$YMDH ) mkdir $DATAROOT/$YMDH
cd $DATAROOT/$YMDH
$WRF/etc/window_domain_rt.pl \
	-w wrfsi.rotlat \
	-s $DATA_SI \
	-i $WRF \
	-d $DATAROOT/$YMDH \
	-t $DATA_DOMS/$YMDH 



# copy grib data to local directory
$WRF/upc/nam212_grib.csh $YMDH $CYCLE
set ESTATUS=$status
if ( $ESTATUS != 0 ) then
   echo "Problem copying grib files. Please fix and try again."
   exit -1
endif

wrf_prep --dset nam212 --cycle ${CYCLE}:0:30

wrf_run

wrf_post --grib

if ( -e wrfpost/grib ) then
   cat wrfpost/grib/*_nmm.GrbF??? | dcgrib2 -d log/dcgrib2.log -v 1 $MODEL/nmm/YYYYMMDDHHfFFF_nmm.gem
   $TOP/nmm_gdplot2_output.csh ${YMDH}

   cd wrfpost/grib
   ~ldm/bin/ldmsend -v -l log/ldmsend.log -h $LDMHOST -f SPARE *_nmm.GrbF???
   cd ../..
endif

mv log $WRF/logs/runs/${YMDH}
wrf_clean --level 5

exit

The system command to execute is: /machine/gempak/wrf/etc/window_domain_rt.pl
	Model:		    -w wrfsi.rotlat
	SOURCE_ROOT:	    -s /machine/gempak/wrf/data/wrfsi
	INSTALLROOT:	    -i /machine/gempak/wrf
	MOAD_DATAROOT:  -d /machine/gempak/wrf/runs/testme
	Domain:		    -t /machine/gempak/wrf/data/domains/testme
	Configure:	    


