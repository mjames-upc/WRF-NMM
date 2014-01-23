#!/bin/csh -f
source /machine/gempak/NAWIPS/Gemenviron
setenv DISPLAY imogene:1
cleanup -c
set TOP=/machine/gempak/wrf/rtmodel

set WEBDIR=conan:/content/software/gempak/rtmodel
set GIFFIL=wseta_floater_regions_$$.gif

#set RADDIR=$RAD/NEXRCOMP/1km/n0r
set RADDIR=/machine/ldm/data/nexrcomp/rad/NEXRCOMP/1km
if ( ! -e $RADDIR ) then
   echo "missing NEXRCOMP directory"
   exit
else
   cd $RADDIR
   set RADFIL=`ls dhr_* |tail -n 1`
   if ( $#RADFIL != 1 ) then
      echo "no radar images"
      exit
   endif
endif
cd $TOP
set FILES=`ls -d 201[0-9][01][0-9][0-3][0-9][0-2][0-9] | tail -n 3`
if ( -e floaterlist.dat ) rm floaterlist.dat
foreach FILE ($FILES)
   echo $FILE
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

set FLOATERS=`cat floaterlist.dat | sort -k2,3 -r`

if ( -e $GIFFIL ) rm $GIFFIL
if ( -e /tmp/.bsize.$$ ) rm /tmp/.bsize.$$

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
   set OLAT = $LAT
   set OLON = $LON
end

# reverse (new)
set COLORS=("28" "30" "24" "25" "27")
set POSN=(".04;.98" ".235;.98" ".43;.98" ".625;.98" ".82;.98")
set POST=(".065;.98" ".26;.98" ".455;.98" ".65;.98" ".845;.98")
set MAPL=("30,0,140,40" "200,0,320,40" "380,0,490,40" "550,0,670,40" "730,0,840,40")
@ CNUM = $#COLORS
set CLEAR=YES
#set PROJ="LCC/39.0;-100.0;0.0/0;2;0;1"
set GAREA="22;-123;49.1;-64.5"
set PROJ="sat"
#set WINSZ="500;350"
set WINSZ="600;400"
set WINSZ="900;600"

gpcolor << EOF0
COLORS  = 7=38:38:38;8=112:112:112
DEVICE   = gif|${GIFFIL}|${WINSZ}
r

EOF0

gpmap << EOF_NEX
    \$mapfil = hicnus.nws + histus.nws
    \$mapfil =  histus.nws
    map = 7/1/1 + 8/1/1
    map = 8/1/1
    RADFIL   = $RADDIR/$RADFIL
    SATFIL   = $RADDIR/$RADFIL
    LUTFIL   = default
    PANEL    = 0
    COLORS   = 3
    WIND     = 0
    LINE     = 3/1/1
    IMCBAR   = 0
    LATLON   = 0
    OUTPUT   = t
    TITLE    = 1/3/Real-time Model Domains
    TEXT     = .75/2/1
    CLEAR    = ${CLEAR}
    GAREA    = dset
    PROJ     = ${PROJ}
    DEVICE   = gif|${GIFFIL}|${WINSZ}
    l
    r

    e
EOF_NEX

set CLEAR=NO

cat $TOP/scripts/wseta_index.include >! wseta_model_domains.html

echo '<map name="wseta_map">' >> wseta_model_domains.html

set FLOATERS = `cat /tmp/.bsize.$$ | sort`
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
      DEVICE = gif|${GIFFIL}|${WINSZ}
      clear = $CLEAR
      info = 4/${BSIZE}
      loci=#${LAT};${LON}

      GDFILE = 
      SATFIL = $RADDIR/$RADFIL
      RADFIL = $RADDIR/$RADFIL
      PROJ = ${PROJ}
      ! GAREA = ${GAREA}
      GAREA = dset
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
      info = .8/1/1////hw/L/0/${DATE}
      r

      e
EOF_GPANOT
   echo '<area shape="rect" coords="'${MAPL[$CNUM]}'" href="/cgi-bin/gempak/rtmodel/rtmodel_index?'${DATE}'" target="_top">' >> wseta_model_domains.html
   set CLEAR=no
   @ CNUM = $CNUM - 1
   if ( $CNUM < 1 ) @ CNUM = $#COLORS
end
gpend

echo '</map>' >> wseta_model_domains.html

cp wseta_model_domains.html rtmodel_domains_dynamic.html
echo '<img border="0" src="../rtmodel/wseta_floater_regions.gif" usemap="#wseta_map" >' >> rtmodel_domains_dynamic.html
echo '</body>' >> rtmodel_domains_dynamic.html
echo '</html>' >> rtmodel_domains_dynamic.html
scp rtmodel_domains_dynamic.html  conan:/content/software/gempak/dynamic

# now pull .bsize.$$ into python and spit out javascript
cat /tmp/.bsize.$$ | sort > /tmp/.xy.$$
/usr/bin/python ${TOP}/scripts/lcc2js.py /tmp/.xy.$$ > xy.js
scp xy.js conan:/content/software/gempak/rtmodel/
rm /tmp/.xy.$$


echo '<p>View model current output and radar for Real-time Regional Model ROI. Select the model run corresponding to displayed region by clicking on the corresponding date at the bottom of the map.</p>' >> wseta_model_domains.html
echo '<image src="wseta_floater_regions.gif" usemap="#wseta_map">' >> wseta_model_domains.html




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

rm /tmp/.bsize.$$
exit 0

