#!/bin/csh -f

if ( ! $?WRF ) then
   echo sourcing WRF cshrc
   source /machine/gempak/wrf/WRF.cshrc
endif

echo "\n Running nam212_grib.csh\n"

set GRIBDIR=/data/ldm/wseta

if ( $#argv != 2 ) then
   echo "Usage: $0 YMDH CYCLE"
   exit -1
endif

set YMDH=$1
set CYCLE=$2

set YYMMDDHH=`echo $YMDH | cut -c3-`

if ( ! -e $WRF/runs/$YMDH ) exit -1
cd $WRF/runs/$YMDH

if ( ! -e grib ) mkdir grib
cd grib

echo "\n Getting ready to copy files\n"

set HOURS=("00" "03" "06" "09" "12" "15" "18" "21" "24" "27" "30")
foreach HOUR ($HOURS)
   echo HOUR $HOUR $YMDH $CYCLE
   set OUTFILE=${YYMMDDHH}.nam.t${CYCLE}z.awip3d${HOUR}.tm00
   if ( -z $OUTFILE ) rm $OUTFILE
#   if ( ( ! -e $OUTFILE ) && ( -e ${GRIBDIR}/${YMDH}/f00${HOUR} ) ) then 
#   if ( ( ! -e $OUTFILE ) && ( -e ${GRIBDIR}/${YMDH}/f00${HOUR} ) ) then 
#	 cat ${GRIBDIR}/${YMDH}/f00${HOUR}/* > $OUTFILE

echo "\n outfile = $OUTFILE, filename = ${GRIBDIR}/nam40grb2.${YMDH}f${HOUR} \n"
#    if ( ( ! -e $OUTFILE ) && ( -e ${GRIBDIR}/${YMDH}.nam.t12z.awip3d${HOUR}.tm00 ) ) then
    if ( ( ! -e $OUTFILE ) && ( -e ${GRIBDIR}/nam40grb2.${YMDH}f${HOUR} ) ) then
#         cp ${GRIBDIR}/${YMDH}.nam.t12z.awip3d${HOUR}.tm00 $OUTFILE
         cp ${GRIBDIR}/nam40grb2.${YMDH}f${HOUR} $OUTFILE
	 echo "\n Copying to file $OUTFILE\n"
   endif
end

exit 0
