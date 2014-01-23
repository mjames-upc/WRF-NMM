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
set MINI=${RUNNAME}_${CYCLE}_mini.gif

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

gdplot2_gf << EOF_MINI
  restore ../wseta_gdplot2_mini.nts
  gdfile = ${GDNAME}
  dev = gf|${MINI}|300;270
  \$mapfil = base
  r

  e
EOF_MINI

if ( ( -e $GIF ) && ( ! -e $GIF.000 ) ) mv $GIF $GIF.000
if ( ( -e $MINI ) && ( ! -e $MINI.000 ) ) mv $MINI $MINI.000

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
rm -rf *_sfc.gif.*
scp -Bq ${RUNNAME}_${CYCLE}_sfc_anim.gif conan:/content/software/gempak/rtmodel/${CYCLE}
scp -Bq ${RUNNAME}_${CYCLE}_sfc_anim.gif conan:/content/software/gempak/rtmodel/${RUNNAME}_current.gif

cd thumbs
convert -loop 0 -delay 100 $FIRST -delay 10 $FILES -delay 200 $LAST ${RUNNAME}_${CYCLE}_sfc_small.gif
rm -rf *_sfc.gif.*
scp -Bq ${RUNNAME}_${CYCLE}_sfc_small.gif conan:/content/software/gempak/rtmodel/${CYCLE}

cd ..

set MINI=`ls ${MINI}*`
set FIRST=$MINI[1]
shift MINI
set NUM=$#MINI
set LAST=$MINI[$NUM]
set MINI[$NUM]=""
convert -loop 0 -delay 100 $FIRST -delay 10 $MINI -delay 200 $LAST ${RUNNAME}_mini.gif
scp -Bq ${RUNNAME}_mini.gif conan:/content/software/gempak/rtmodel/${RUNNAME}_current_mini.gif
