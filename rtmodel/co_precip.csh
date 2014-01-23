#!/bin/csh -f
#
# things to start`

source /machine/gempak/NAWIPS/Gemenviron
setenv DISPLAY imogene:1.0
#
# things to set

set ModelName="nmm" 
set AnimationName=${ModelName}_precip
set TopLevelDir=/machine/gempak/wrf/rtmodel
cd $TopLevelDir
#cp $TopLevelDir/coltbl.precip $TopLevelDir/coltbl.xwp

#
# things to create

if ( ! -e ${AnimationName} ) mkdir ${AnimationName}
cd ${AnimationName}

@ HourCount = 0
while ( $HourCount <= 30 )

if ( $HourCount < 10 ) then
   set ForecastHour=00${HourCount}
   set GifName=${ModelName}_precip_f0${HourCount}.gif
else
   set ForecastHour=0${HourCount}
   set GifName=${ModelName}_precip_f${HourCount}.gif
endif


#
# things to run
cat coltbl.xwp

gdplot2 << EOF_GIF
  restore ../wseta_emsl_p01i.nts
  \$mapfil = inter+county+base
  map = 2/1/2+8/1/1+31/1/2
  gdattim = f${ForecastHour}
  garea = dset
  gdfile = wrf:co.gem
  proj = lcc
  dev = gif|${GifName}|900;675
  r

  e
EOF_GIF
gpend
@ HourCount = $HourCount + 1
end

set GifFileList=`ls *_precip_f*.gif`
if ($#GifFileList < 1 ) then
   echo "No precip gif files found"
   exit
endif

#
# things to loop

set FirstFileName=$GifFileList[1]
shift GifFileList

set NUM=$#GifFileList
set LastFileName=$GifFileList[$NUM]
set GifFileList[$NUM]=""
convert -loop 0 -delay 100 $FirstFileName -delay 10 $GifFileList -delay 200 $LastFileName ${ModelName}_precip_pmsl.gif
scp -Bq ${ModelName}_precip_pmsl.gif conan:/content/software/gempak/rtmodel/

# remove images
rm -rf *gif*

# remove coltbl
#rm -rf ../coltbl.xwp

