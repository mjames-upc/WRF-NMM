#!/bin/csh -f
source /machine/gempak/NAWIPS/Gemenviron
set TOP=/machine/gempak/wrf/rtmodel

set WEBDIR=conan:/content/software/gempak/rtmodel
set GIFFIL=wseta_floater_regions_$$.gif

cd $TOP
set FILES=`ls -d 201[0-9][01][0-9][0-3][0-9][0-2][0-9] | tail -n 5`
if ( -e floaterlist.dat ) rm floaterlist.dat
foreach FILE ($FILES)
   if ( -e $FILE/model_center.dat ) echo "$FILE `cat $FILE/model_center.dat`" >>! floaterlist.dat
end

if ( ! -e floaterlist.dat ) then
   echo WSETA floaters file does not exist
   exit
endif

set FLOATERS=`cat floaterlist.dat | sort -k2,3`

if ( -e $GIFFIL ) rm $GIFFIL
if ( -e /tmp/.bsize.$$ ) rm /tmp/.bsize.$$

set OLON=-9999
set OLAT=-9999
set BSIZE = 8

while ($#FLOATERS >= 3 )
   set DATE=$FLOATERS[1]
   set LAT=$FLOATERS[2]
   set LON=$FLOATERS[3]
   echo LAT $LAT lon $LON DATE $DATE look $OLAT $OLON
   shift FLOATERS
   shift FLOATERS
   shift FLOATERS

   if ( ( $LAT == $OLAT ) && ( $LON == $OLON ) ) then
      set BNEW=`echo "$BSIZE - 0.6" | bc`
      set BSIZE = $BNEW
   else
      set BSIZE = 8
   endif

   echo "$DATE $LAT $LON $BSIZE" >>! /tmp/.bsize.$$
   set OLAT = $LAT
   set OLON = $LON
end

set COLORS=("30" "26" "23" "5" "17" "2")
set POSN=(".90;.1" ".73;.1" ".56;.1" ".39;.1" ".22;.1" ".05;.1")
set POST=(".92;.1" ".75;.1" ".58;.1" ".41;.1" ".24;.1" ".07;.1")
set MAPL=("439,305,500,323" "356,305,437,323" "272,305,354,323" "186,305,269,323" "102,305,183,323" "15,305,97,323")
@ CNUM = $#COLORS
set CLEAR=YES

cat $TOP/scripts/wseta_index.include >! wseta_model_domains.html

echo '<map name="wseta_map">' >> wseta_model_domains.html

set FLOATERS = `cat /tmp/.bsize.$$ | sort`
rm /tmp/.bsize.$$
while ( $#FLOATERS >= 4 )
   set DATE=$FLOATERS[1]
   set LAT=$FLOATERS[2]
   set LON=$FLOATERS[3]
   set BSIZE=$FLOATERS[4]
   shift FLOATERS
   shift FLOATERS
   shift FLOATERS
   shift FLOATERS

   gpanot << EOF_GPANOT
      \$respond = yes
      dev = gif|${GIFFIL}|500;350
      clear = $CLEAR
      info = 4/${BSIZE}
      loci=#${LAT};${LON}

      GDFILE = 
      SATFIL = 
      RADFIL = 
      PROJ = def
      GAREA = uslcc
      PANEL = 0
      SHAPE = marker
      LINE = ${COLORS[$CNUM]}
      CTYPE = c
      r

      clear = no
      info = 19/1
      loci = ${POSN[$CNUM]}
      r

      shape = text
      loci = ${POST[$CNUM]}
      info = .6/1/1////hw/L/0/${DATE}
      r

      e
EOF_GPANOT
  
   echo '<area shape="rect" coords="'${MAPL[$CNUM]}'" href="http://www.unidata.ucar.edu/software/gempak/rtmodel/index.php?'${DATE}'">' >> wseta_model_domains.html
   set CLEAR=no
   @ CNUM = $CNUM - 1
   if ( $CNUM < 1 ) @ CNUM = $#COLORS
end

gpmap << EOF_GPMAP
   dev = gif|${GIFFIL}|500;350
   title = 1/-1/Real-time Model Domains
   text = .75/2/1
   clear = no
   \$mapfil = base
   map = 31/1/1
   latlon = 0
   r

   e
EOF_GPMAP

gpend


echo '</map>' >> wseta_model_domains.html

echo '<p>' >> wseta_model_domains.html

echo '<table>' >> wseta_model_domains.html
echo '<tr>' >> wseta_model_domains.html
echo '<td><image src="wseta_floater_regions.gif" usemap="#wseta_map"></td>' >> wseta_model_domains.html
echo '<td>View model current output and radar for Real-time Regional Model ROI. Select the model run corresponding to displayed region by clicking on the corresponding date at the bottom of the map.</td>' >> wseta_model_domains.html

echo '</tr></table>' >> wseta_model_domains.html



cat $TOP/scripts/wseta_domain.include >> wseta_model_domains.html
echo '</body>' >> wseta_model_domains.html
echo '</html>' >> wseta_model_domains.html

if ( -e $GIFFIL ) then
   scp $GIFFIL $WEBDIR/wseta_floater_regions.gif
   rm $GIFFIL
endif

if ( -e wseta_model_domains.html ) then
   scp wseta_model_domains.html  $WEBDIR/index.html
   rm wseta_model_domains.html
endif

exit 0

