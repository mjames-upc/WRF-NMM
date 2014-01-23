#!/bin/csh -f

source /machine/gempak/NAWIPS/Gemenviron
setenv DISPLAY imogene:1
set LDMHOST=motherlode.ucar.edu

set TOP=/machine/gempak/wrf/rtmodel

cd $TOP

if ( $#argv > 0 ) then
   set CYCLE=$1
else
   set CYCLE=`date -u '+%H'`
endif

set FDATE=`date -u '+%y%m%d'`"/${CYCLE}00"
set YMDH=`date -u '+%Y%m%d'`"${CYCLE}"

# make this directory now, just in case we fail later
ssh conan mkdir /content/software/gempak/rtmodel/${YMDH}

# see if we have the necessary data files...
@ ATTEMPT = 0
@ IWAIT = 1
while ( ( $ATTEMPT < 10 ) && ( $IWAIT ) )
   @ COUNT = 0
   @ MISS = 0
   while ( $COUNT <= 33 )
      if ( $COUNT < 10 ) then
         set FCNT=00${COUNT}
      else
         set FCNT=0${COUNT}
      endif
      if ( ! -e $MODEL/nam12km/${YMDH}f${FCNT}_nam218.gem ) @ MISS = $MISS + 1
      @ COUNT = $COUNT + 3
   end
   if ( $MISS == 0 ) then
      @ IWAIT = 0
   else
      echo "missing $MISS files on attempt $ATTEMPT" | mail -s "WRF error" mjames@unidata.ucar.edu
      sleep 300
   endif
   @ ATTEMPT = $ATTEMPT + 1
end
if ( $IWAIT ) then
   echo "May have data reception problem, or need to punt to nam40"
   echo "Missing $MISS 12km files, May have nam40" | mail -s "WRF error" mjames@unidata.ucar.edu
endif

echo "We have data for ${YMDH}, now get region"


#Once a week, do a cleanup, just in case!
set dayofweek=`date -u '+%w'`
if ( ( $dayofweek == 0 ) && ( $CYCLE == 12 ) ) then
   cleanup -c
endif


if ( -e p24m_highs.dat ) rm p24m_highs.dat

gdcsv << EOF_CSV
 GDATTIM  = ${FDATE}f030
 GDFILE   = nam12+cmask.gem
 GLEVEL   = 0
 GAREA    = grid
 PROJ     = def
 GVCORD   = none
 GFUNC    = high(mask(gwfs(p24m,40),sgt(cmask^060316/0000f000+2,1)),30)
 SCALE    = 0
 OUTPUT   = f/p24m_highs.dat
 l
 r

 e
EOF_CSV


if ( ! -e p24m_highs.dat ) then
   # try NAM40 grids, use the cmask 12km grid as the grid output
   echo "NAM12 failed GDCSV, trying NAM40"
   gdcsv << EOF_CSV1
      GDATTIM  = f030
      GDFILE   = cmask.gem+nam40
      GLEVEL   = 0
      GAREA    = grid
      PROJ     = def
      GVCORD   = none
      GFUNC    = high(mask(gwfs(p24m+2^f030,40),sgt(cmask^f000,1)),30)
      SCALE    = 0
      OUTPUT   = f/p24m_highs.dat
      l
      r
     
      e
EOF_CSV1
   if ( ! -e p24m_highs.dat ) then
      echo "gdcsv failed to generate locations | mail -s "WRF error" mjames@unidata.ucar.edu"
      exit -1
   endif
   set USENAM=nam40
else
   set USENAM=nam12
endif

if ( -e model_center_loc.001 ) rm model_center_loc.*
sort -t, -k 5bnr p24m_highs.dat | head -2 | awk -f csv.awk

if ( ( -e model_center.override ) && ( -e model_center_loc.001 ) ) then
   set FILES=`ls model_center_loc.*`
   @ NFILE = $#FILES
   while ( $NFILE > 0 )
      @ N1 = $NFILE + 1 
      if ( $N1 < 10 ) then
         set EXT=00${N1}
      else
         set EXT=0${N1}
      endif
      mv $FILES[$NFILE] model_center_loc.${EXT}
      @ NFILE = $NFILE - 1
   end
   cp model_center.override model_center_loc.001
else if ( -e model_center.override ) then
   cp model_center.override model_center_loc.001
endif

if ( -e model_center_loc.001 ) cp model_center_loc.001 model_center.dat

#
# Make the domain image gifs

set LATLON=`cat model_center.dat`

if ( -e eta_conus.gif ) rm eta_conus.gif

gdplot2 << EOF_GDPLOT2
   restore wseta_gdplot2 
   \$respond = yes
   gdfile = ${USENAM}
   panel = 0
   proj=lcc/40;-100;40
   GAREA    =22;-123;49.1;-64.5
   DEVICE   = gf|eta_conus.gif|900;600
   clrbar = 0
   clear = y
   TEXT     = .7/2/1/hw
   TITLE = 5/-1/WRF Selected Region of Interest
   l
   r

   e
EOF_GDPLOT2

@ CNT = 1
while ( $CNT <= 2 )
   set locfile="model_center_loc.00${CNT}"
   set LATLON=`cat $locfile`
   if ( $CNT == 1 ) then
      set LINE='31/1/3'
   else 
      set LINE='2/10/1'
   endif
   gpanot << EOF_ANOT
      restore gpanot_domain.nts
      DEV = gf|eta_conus.gif|900;600
      clear = n
      info = 4/8
      line = $LINE
      loci=#${LATLON[1]};${LATLON[2]}
      r

      e
EOF_ANOT
   @ CNT = $CNT + 1
end
gpend


if ( ! -e $YMDH ) mkdir $YMDH

# done above to make sure this directory exists later
# ssh conan mkdir /content/software/gempak/rtmodel/${YMDH}

if (-e eta_conus.gif ) then
   scp -Bq eta_conus.gif conan:/content/software/gempak/rtmodel/${YMDH}
   mv eta_conus.gif $YMDH
   #~ldm/bin/ldmsend -h 128.117.15.119 -f SPARE -l ldmsend.log ${YMDH}/eta_conus.gif
   #~ldm/bin/ldmsend -h $LDMHOST -f SPARE -l ldmsend.log ${YMDH}/eta_conus.gif
endif
if ( -e model_center.dat) then
   scp -Bq model_center.dat conan:/content/software/gempak/rtmodel/${YMDH}
   cp -p model_center.dat $YMDH
   cp -p model_center_loc.* $YMDH
   if ( -e model_center.override ) cp -p model_center.override $YMDH
   #~ldm/bin/ldmsend -h 128.117.15.119 -f SPARE -l ldmsend.log ${YMDH}/model_center.dat
   #~ldm/bin/ldmsend -h $LDMHOST -f SPARE -l ldmsend.log ${YMDH}/model_center*
endif

#
# create updated index.html and imagemap for model centers
scripts/wseta_domain_radar.csh
exit 0
