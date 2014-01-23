#!/bin/csh -f
source /machine/gempak/NAWIPS/Gemenviron
set TOP=/machine/gempak/wrf/rtmodel

set WEBDIR=conan:/content/software/gempak/rtmodel
set GIFFIL=wseta_floater_regions_$$.gif

set RADDIR=$RAD/NEXRCOMP/1km/n0r
#set RADDIR=/machine/ldm/data/nexrcomp/rad/NEXRCOMP/1km
if ( ! -e $RADDIR ) then
   echo "missing NEXRCOMP directory"
   exit
else
   cd $RADDIR
   set RADFIL=`ls  | tail -n 1`
   if ( $#RADFIL != 1 ) then
      echo "no radar images"
      exit
   endif
endif

cd $TOP
set FILES=`ls -d 201[0-9][01][0-9][0-3][0-9][0-2][0-9] | tail -n 5`
if ( -e floaterlist.dat ) rm floaterlist.dat
foreach FILE ($FILES)
   if ( -e $FILE/model_center.override ) then
      echo "$FILE `cat $FILE/model_center.override`" >>! floaterlist.dat
   else if ( -e $FILE/model_center.dat ) then
      echo "$FILE `cat $FILE/model_center.dat`" >>! floaterlist.dat
   endif
end

if ( ! -e floaterlist.dat ) then
   echo WSETA floaters file does not exist
   exit
endif

set FLOATERS=`cat floaterlist.dat | sort -k2,3`

if ( -e $GIFFIL ) rm $GIFFIL
if ( -e /tmp/.bsize.$$ ) rm /tmp/.bsize.$$
if ( -e /tmp/.xy.$$ ) rm /tmp/.xy.$$

set OLON=-9999
set OLAT=-9999
set BSIZE = 6

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
      set BSIZE = 6
   endif

   echo "$DATE $LAT $LON $BSIZE" >>! /tmp/.bsize.$$
   /usr/bin/python /home/mjames/nationalcomp/gini/lcc2xy.py $LAT $LON $DATE >>! /tmp/.xy.$$
   set OLAT = $LAT
   set OLON = $LON
end

set COLORS=("30" "26" "23" "5" "17" "2")
set POSN=(".905;.05" ".82;.05" ".625;.05" ".43;.05" ".235;.05" ".04;.05")
set POST=(".92;.05" ".845;.05" ".65;.05" ".455;.05" ".26;.05" ".065;.05")
#set MAPL=("439,305,500,323" "356,305,437,323" "272,305,354,323" "186,305,269,323" "102,305,183,323" "15,305,97,323")
set MAPL=("399,244,400,259" "323,244,399,259" "245,244,322,259" "167,244,244,259" "89,244,166,259" "11,244,88,259")
@ CNUM = $#COLORS
set CLEAR=YES
#set PROJ="LCC/39.0;-100.0;0.0/0;2;0;1"
set GAREA="22.1;-123.0;49.1;-64.5"
set PROJ="rad"
set IMGSIZE="900;600"

gpnids << EOF_N0R
    RADFIL   = N0RCOMP
    RADFIL   = $RADDIR/$RADFIL
    RADTIM   = current
    PANEL    = 0
    COLORS   = 3
    WIND     = 0
    LINE     = 3/1/1
    CLRBAR   = 0
    IMCBAR   = 0
    LATLON   = 0
    OUTPUT   = t
!
    TITLE    = 1/-1/Real-time Model Domains
    TEXT     = .75/2/1
    CLEAR    = ${CLEAR}
    GAREA    = dset
!    GAREA    = ${GAREA}
    PROJ     = ${PROJ}
    \$mapfil = base
    MAP      = 31/1/1
    DEVICE   = gif|${GIFFIL}|${IMGSIZE}
    r

    e

EOF_N0R

set CLEAR=NO

cat $TOP/scripts/wseta_index.include >! wseta_model_domains.html

# write floater bounds to SVG
set FLOATERS = `cat /tmp/.bsize.$$ | sort`
# rm /tmp/.bsize.$$
#   set DATE=$FLOATERS[1]
#   set LAT=$FLOATERS[2]
#   set LON=$FLOATERS[3]
#   set BSIZE=$FLOATERS[4]
#   shift FLOATERS
#   shift FLOATERS
#   shift FLOATERS
#   shift FLOATERS

gpend


cp wseta_model_domains.html rtmodel_domains_dynamic.html
echo '<img border="0" src="../rtmodel/wseta_floater_regions.gif" usemap="#wseta_map" >' >> rtmodel_domains_dynamic.html
echo '</body>' >> rtmodel_domains_dynamic.html
echo '</html>' >> rtmodel_domains_dynamic.html
scp rtmodel_domains_dynamic.html  conan:/content/software/gempak/dynamic
echo '{"floaters": [' > xy.js
cat /tmp/.xy.$$ >> xy.js
echo ']}' >> xy.js
echo " var jsonString = '[';" > xy.js
cat /tmp/.xy.$$ >> xy.js
echo " jsonString += ']';" >> xy.js
scp xy.js conan:/content/software/gempak/rtmodel/
rm /tmp/.xy.$$
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

