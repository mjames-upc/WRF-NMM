#!/bin/csh -f

source /machine/gempak/NAWIPS/Gemenviron
set TOP=/machine/gempak/wrf/rtmodel

setenv DISPLAY imogene:1

if ( $#argv > 0 ) then
   set CYCLE=$1
else
   set CYCLE=`date -u '+%Y%m%d%H'`
endif

cd $TOP
if ( ! -e ${CYCLE} ) mkdir ${CYCLE}

cd $CYCLE
mkdir thumbs

set GIF=wseta_${CYCLE}_sfc.gif
set MINI=wseta_${CYCLE}_mini.gif

gdplot2_gf << EOF_SFC
  restore ../wseta_emsl_p01i.nts
  dev = gf|${GIF}|900;675
  \$mapfil = inter+county+base
  map = 2/1/2+8/1/1+31/1/2 
  r

  e
EOF_SFC

gdplot2_gf << EOF_MINI
  restore ../wseta_gdplot2_mini.nts
  dev = gf|${MINI}|200;180
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

# This directory should already be made, but make sure!
ssh conan mkdir -p /content/software/gempak/rtmodel/${CYCLE}

cd thumbs
foreach FILE ($FILES)
   convert -colors 64 -geometry 500x500 ../${FILE} $FILE
   scp -Bq ../${FILE} conan:/content/software/gempak/rtmodel/${CYCLE}
end
cd ..


set FIRST=$FILES[1]
shift FILES

set NUM=$#FILES
set LAST=$FILES[$NUM]
set FILES[$NUM]=""
convert -loop 0 -delay 100 $FIRST -delay 10 $FILES -delay 200 $LAST ${CYCLE}_sfc_anim.gif

cd thumbs
convert -loop 0 -delay 100 $FIRST -delay 10 $FILES -delay 200 $LAST ${CYCLE}_sfc_small.gif
scp -Bq ${CYCLE}_sfc_small.gif conan:/content/software/gempak/rtmodel/${CYCLE}

cd ..

set MINI=`ls ${MINI}*`
set FIRST=$MINI[1]
shift MINI
set NUM=$#MINI
set LAST=$MINI[$NUM]
set MINI[$NUM]=""
convert -loop 0 -delay 100 $FIRST -delay 10 $MINI -delay 200 $LAST mini.gif
scp -Bq mini.gif conan:/content/software/gempak/rtmodel/wseta_current_mini.gif
