#!/bin/csh -f
#
# things to start`

source /machine/gempak/NAWIPS/Gemenviron
setenv DISPLAY imogene:1

#
# things to set

set ModelName="rtma" 
set AnimationName=${ModelName}_tmpf
set TopLevelDir=/machine/gempak/wrf/rtmodel
cd $TopLevelDir
#cp $TopLevelDir/coltbl.tmpf $TopLevelDir/coltbl.xwp

#
# things to create

if ( ! -e ${AnimationName} ) mkdir ${AnimationName}
cd ${AnimationName}
set GifName=${ModelName}_tmpf.gif

@ HourCount = 0
while ( $HourCount <= 1 )

if ( $HourCount < 10 ) then
   set ForecastHour=00${HourCount}
else
   set ForecastHour=0${HourCount}
endif


#
# things to run
cat coltbl.xwp

gdplot2_gf << EOF_GIF
  restore ../rtma.nts
  gdattim = last 
  garea = dset
  gdfile = rtma
  proj = lcc
  dev = gif|${GifName}|900;675
  \$mapfil = inter+county+base
  map = 25/1/1+32/1/1+32/1/2

  r

  e
EOF_GIF

if ( ( -e $GifName ) && ( ! -e $GifName.000 ) ) mv $GifName $GifName.000
@ HourCount = $HourCount + 1
end

set GifFileList=`ls ${GifName}*`
if ($#GifFileList < 1 ) then
   echo "No tmpf gif files found"
   exit
endif

#
# things to loop

set FirstFileName=$GifFileList[1]
shift GifFileList

set NUM=$#GifFileList
set LastFileName=$GifFileList[$NUM]
set GifFileList[$NUM]=""
convert -loop 0 -delay 100 $FirstFileName -delay 10 $GifFileList -delay 200 $LastFileName ${ModelName}_2m_temp_10kt_wind.gif
scp -Bq ${ModelName}_2m_temp_10kt_wind.gif conan:/content/software/gempak/rtmodel/

rm -rf *gif*

# remove coltbl
#rm -rf ../coltbl.xwp

