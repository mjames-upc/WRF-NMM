#!/bin/csh -f

source /machine/gempak/NAWIPS/Gemenviron

set TOP=/machine/gempak/wrf/rtmodel

setenv DISPLAY imogene:1

mkdir thumbs

set GIF=nexrcomp_dhr.gif

gdplot2_gf << EOF_SFC
  restore ../wseta_emsl_p01i.nts
  gdfile = ${GDNAME}
  title = 31/-2/WRF-NMM ? ~ ( 1 hr Precip, SLP )
  dev = gf|${GIF}|900;600
  \$mapfil = inter+county+base
  map = 2/1/2+8/1/1+31/1/2 
  r

  e
EOF_SFC

if ( ( -e $GIF ) && ( ! -e $GIF.000 ) ) mv $GIF $GIF.000

set FILES=`ls ${GIF}*`
if ($#FILES < 1 ) then
   echo "No dhr gif files found"
   exit
endif

cd thumbs
foreach FILE ($FILES)
   convert -colors 64 -geometry 450x300 ../${FILE} $FILE
   scp -Bq ../${FILE} conan:/content/software/gempak/rtmodel/${CYCLE}
end
cd ..


set FIRST=$FILES[1]
shift FILES

set NUM=$#FILES
set LAST=$FILES[$NUM]
set FILES[$NUM]=""

# full size loop
convert -loop 0 -delay 100 $FIRST -delay 10 $FILES -delay 200 $LAST ${RUNNAME}_${CYCLE}_dhr_anim.gif
scp -Bq ${RUNNAME}_${CYCLE}_dhr_anim.gif conan:/content/software/gempak/rtmodel/${CYCLE}

cd thumbs
convert -loop 0 -delay 100 $FIRST -delay 10 $FILES -delay 200 $LAST ${RUNNAME}_${CYCLE}_dhr_small.gif
scp -Bq ${RUNNAME}_${CYCLE}_dhr_small.gif conan:/content/software/gempak/rtmodel/${CYCLE}

exit;
