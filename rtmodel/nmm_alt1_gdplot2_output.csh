#!/bin/csh -f

source /machine/gempak/NAWIPS/Gemenviron

set TOP=/machine/gempak/wrf/rtmodel

setenv DISPLAY imogene:1

if ( $#argv > 0 ) then
   set CYCLE=$1
else
   set CYCLE=`date -u '+%Y%m%d%H'`
endif

if ( $0:t == "nmm_primary_gdplot2_output.csh" ) then
   set RUNNAME="nmm_primary" 
   set GDNAME="wrf:primary.gem"
   set RUNCYCLE=${CYCLE}_${RUNNAME}
else if ( $0:t == "nmm_alt1_gdplot2_output.csh" ) then
   set RUNNAME="nmm_alt1" 
   set GDNAME="wrf:alt1.gem"
   set RUNCYCLE=${CYCLE}_${RUNNAME}
else if ( $0:t == "nmm_alt2_gdplot2_output.csh" ) then
   set RUNNAME="nmm_alt2" 
   set GDNAME="wrf:alt2.gem"
   set RUNCYCLE=${CYCLE}_${RUNNAME}
else
   set RUNNAME="nmm" 
   set GDNAME="wrf:primary.gem"
   set RUNCYCLE=${CYCLE}_${RUNNAME}
endif

cd $TOP
if ( ! -e ${RUNCYCLE} ) mkdir ${RUNCYCLE}

cd ${RUNCYCLE}
mkdir thumbs

set GIF=${RUNNAME}_${CYCLE}_sfc.gif

gdplot2_gf << EOF_SFC
  restore ../wseta_emsl_p01i.nts
  gdfile = ${GDNAME}
  title = 31/-2/WRF-NMM ? ~ ( 1 hr Precip, SLP )
  dev = gf|${GIF}|900;675
  \$mapfil = inter+county+base
  map = 2/1/2+8/1/1+31/1/2 
  r

  e
EOF_SFC

if ( ( -e $GIF ) && ( ! -e $GIF.000 ) ) mv $GIF $GIF.000

set FILES=`ls ${GIF}*`
if ($#FILES < 1 ) then
   echo "No sfc gif files found"
   exit
endif

cd thumbs
foreach FILE ($FILES)
   convert -geometry 450x450 ../${FILE} $FILE
   scp -Bq ../${FILE} conan:/content/software/gempak/rtmodel/${CYCLE}
end
cd ..


set FIRST=$FILES[1]
shift FILES

set NUM=$#FILES
set LAST=$FILES[$NUM]
set FILES[$NUM]=""
convert -loop 0 -delay 100 $FIRST -delay 10 $FILES -delay 200 $LAST ${RUNNAME}_${CYCLE}_sfc_anim.gif
scp -Bq ${RUNNAME}_${CYCLE}_sfc_anim.gif conan:/content/software/gempak/rtmodel/${CYCLE}

cd thumbs
convert -loop 0 -delay 100 $FIRST -delay 10 $FILES -delay 200 $LAST ${RUNNAME}_${CYCLE}_sfc_small.gif
scp -Bq ${RUNNAME}_${CYCLE}_sfc_small.gif conan:/content/software/gempak/rtmodel/${CYCLE}

cd ..

