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

echo CYCLE is $CYCLE

if ( $0:t == "wrf_PRIMARY" ) then
   set DOMAIN_NAME=${YMDH}_12km
   set MODEL_CENTER="model_center_loc.001"
   set GEMNMM=nmm
   set RUNNAME=primary
else if ( $0:t == "wrf_ALT1" ) then
   set DOMAIN_NAME=${YMDH}_12km_alt1
   set MODEL_CENTER="model_center_loc.002"
   set GEMNMM=nmm_alt1
   set RUNNAME=alt1
else if ( $0:t == "wrf_ALT2" ) then
   set DOMAIN_NAME=${YMDH}_12km_alt2
   set MODEL_CENTER="model_center_loc.003"
   set GEMNMM=nmm_alt2
   set RUNNAME=alt2
else
   set DOMAIN_NAME=${YMDH}_12km
   set MODEL_CENTER="model_center.dat"
   set GEMNMM=nmm
   set RUNNAME=nmm
endif

echo look MODEL_CENTER $MODEL_CENTER
cat $TOP/${MODEL_CENTER} | head -1

# make our working directories
cd $DATA_DOMS
if ( ! -e ${DOMAIN_NAME} ) mkdir ${DOMAIN_NAME}
cd ${DOMAIN_NAME}

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

if ( -e $TOP/${MODEL_CENTER} ) then
   set LL=`cat $TOP/${MODEL_CENTER} | head -1`
   set DEFCLAT=$LL[1]
   set DEFCLON=$LL[2]
else
   set DEFCLAT="40.0"
   set DEFCLON="-105.5"
endif
echo DEFCLAT $DEFCLAT DEFCLON $DEFCLON

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

if ( ! -e $DATAROOT/${DOMAIN_NAME} ) mkdir $DATAROOT/${DOMAIN_NAME}
cd $DATAROOT/${DOMAIN_NAME}
$WRF/etc/window_domain_rt.pl \
	-w wrfsi.rotlat \
	-s $DATA_SI \
	-i $WRF \
	-d $DATAROOT/${DOMAIN_NAME} \
	-t $DATA_DOMS/${DOMAIN_NAME} \
	-c

#
# calculate tiles to be used
cd $TOP/g218tiles
#set TILES=`tile_calc $DEFCLAT $DEFCLON $NX $NY $DX $DY`
set TILES=`tile_calc $DEFCLAT $DEFCLON $NX $NY 8000 8000`
echo "Running wrf_prep with $TILES"

cd $DATAROOT/${DOMAIN_NAME}

@ MAXATTEMPT=5
@ DONE=0
@ TRYNUM=0
while ( ( ! $DONE ) && ( $TRYNUM < $MAXATTEMPT ) )
   #wrf_prep --dset tile12 --ftp ncep $TILES --cycle ${CYCLE}:0:30
   #wrf_prep --sfcdset ssthr --dset tile12 --ftp ncep $TILES --cycle ${CYCLE}:0:30
   #wrf_prep --sfcdset ssthr --dset nam212grb2 --ftp ncep --cycle ${CYCLE}:0:30
   wrf_prep --sfcdset ssthr --dset gfsgrb2 --ftp ncep --cycle ${CYCLE}:0:30
   set STATUS_PREP=$status
   if ( $STATUS_PREP == 0 ) then
      set DONE=1
      # copy the ssthr data set
      set SSTHR=rtgssthr_grb_0.083
      set SAVDIR=/machine/gempak/wrf/data/grib/ssthr
      if ( ! -e $SAVDIR ) mkdir -p $SAVDIR
      if ( -e grib/${SSTHR} ) then
	 if ( -e ${SAVDIR}/${SSTHR} ) then
            cmp -s grib/${SSTHR} ${SAVDIR}/${SSTHR}
            set ISDIF=$status
	    if ( $ISDIF != 0 ) cp -p grib/${SSTHR} ${SAVDIR}/${SSTHR}
         else
            cp -p grib/${SSTHR} ${SAVDIR}/${SSTHR}
         endif
      endif
   else
      # wait, and try again shorty
      sleep 300
   endif
   @ TRYNUM = $TRYNUM + 1
end

set NOTDONE=0
set RETRY=0
while ( ( $NOTDONE == 0 ) && ( $RETRY < 2 ) )
   wrf_run --verbose
   set STATUS=$status
   if ( $STATUS != 0 ) then
      echo "wrf run ${DOMAIN_NAME} failed" | mail -s "wrf run error" mjames@unidata.ucar.edu
      wrf_clean --level 2
      @ RETRY = $RETRY + 1
   else
      set NOTDONE=1
   endif
end

if ( $NOTDONE == 0 ) then
   echo "**********************************************"
   echo "wrf run ${DOMAIN_NAME} didn't run retry $RETRY" 
   echo "**********************************************"
   echo "wrf run ${DOMAIN_NAME} didn't run" | mail -s "wrf run died" mjames@unidata.ucar.edu
   exit -1
endif

wrf_post --grib --DM
#
# check the wrfpost archive and rename it
if ( -e /machine/gempak/wrf_archive/grib/${YMDH} ) mv /machine/gempak/wrf_archive/grib/${YMDH} /machine/gempak/wrf_archive/grib/${YMDH}_${RUNNAME}

if ( -e wrfpost/grib ) then
   if ( ! -e gempak ) mkdir gempak
   #cat wrfpost/grib/*_nmm_d01.GrbF* | dcgrib2 -d log/dcgrib2.log -v 1 ${MODEL}/${GEMNMM}/YYYYMMDDHHfFFF_nmm.gem
   #chmod 664 ${MODEL}/${GEMNMM}/*_nmm.gem
   #cat wrfpost/grib/*_nmm_d01.GrbF* | dcgrib2 -d log/dcgrib2.log -v 1 gempak/YYYYMMDDHHfFFF_nmm.gem
   cat wrfpost/grib/*_nmm_d01.GrbF* | dcgrib2 -d log/dcgrib2.log -v 1 gempak/YYYYMMDDHHfFFF_${RUNNAME}.gem
   chmod 664 gempak/*_${RUNNAME}.gem
   cd gempak
   #scp *_nmm.gem ldm@shemp:${MODEL}/${GEMNMM}
   scp *_${RUNNAME}.gem ldm@data:${MODEL}/wrf
   cd ..
   $TOP/${GEMNMM}_gdplot2_output.csh ${YMDH}

   cd wrfpost/grib
   set FILES=`ls *_nmm_d01.GrbF*`
   foreach FILE ($FILES)
      set NEWFILE=`echo $FILE | sed "s@_nmm_d01@_${GEMNMM}@g"`
      ln -s $FILE $NEWFILE
   end

   #if ( ${GEMNMM} != "nmm" ) then
   #endif

   ~ldm/bin/ldmsend -v -l log/ldmsend.log -h $LDMHOST -f SPARE *_${GEMNMM}.GrbF*
   cd ../..
endif

if ( ! -d $WRF/logs/runs ) mkdir $WRF/logs/runs
mv log $WRF/logs/runs/${YMDH}_${GEMNMM}
wrf_clean --level 5<<EOF_CLEAN
yes
EOF_CLEAN


exit 



#wrf_prep --dset tile12 --cycle ${CYCLE}:0:30

wrf_prep --dset nam218grb2 --cycle 18:0:30 --nfs /data/ldm/nam_12km/YYYYMMDDHHf0FF.grib2


exit

