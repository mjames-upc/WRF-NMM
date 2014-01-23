#!/bin/csh -f
#
# This script uses the WRF temperature grids to produce
# plotting MASKs for the radar reflectivity grids. This is only
# an estimate of precipitation type using model temperatures.
# It is not based on surface observations.
#
# The precipitation type is estimated using surface temperature and
# the 30:0 mb pressure layer temperature. The following simple 
# nomagram shows the masks used:
#
#     +-----------+-----------+-----------+ 30:0 pressure layer temperature
#     |           |           |           |
#     |   Snow    |   Snow    |   Rain    |  <0C
#     |           |           |           |
#     +-----------+-----------+-----------+
#     |           |           |           |
#     |   Frozen  |   Rain    |   Rain    |  >0C
#     |           |           |           |
#     +-----------+-----------+-----------+
#          <0C         0-3C         >3C
#
#             Surface (2m) temperature
#
# Michael James
# Unidata
# December 2013

source /machine/gempak/NAWIPS/Gemenviron
set WEBDIR=conan:/content/staff/mjames/rtmodel/

cd /tmp
set WORK=.nexrwork.$$
if(! -e $WORK) mkdir $WORK

cd $WORK


set YMD=`date -u '+%Y%m%d'`
echo $YMD
set HH=`date -u '+%H'`
echo $HH
exit;

#
#
# Use a special color table for precipitation type plotting
#
cp $GEMTBL/colors/coltbl.ptype coltbl.xwp
#
#
# create a new grid file of the same projection as the RADAR mosaic
# NEXR is the template for the national mosaic defined in datatype.tbl.
#
gdcfil << EOFC
  \$respond = yes
  gdoutf = ptype.gem
  cpyfil = wrf:primary.gem
  maxgrd = 25
  anlyss = 
  r

  e
EOFC
#
# -rw-r--r--   1 mjames ustaff  5632 2013-12-10 19:54 ptype.gem
#
#
gddiag << EOFD
gdfile = wrf:primary.gem
gdoutf = ptype.gem
glevel = 30:0
gfunc = tmpc
gvcord = pdly
gdattim = f001
gpack = none
r

glevel = 2
gvcord = hght
r

glevel = 0
gvcord = none
gfunc = refc
l
r

EOFD
gpend

gdinfo << EOF
gdfile = ptype.gem
glevel = all
gvcord = all
gfunc = all
gdattim = all
r

e
EOF

# GRID FILE: ptype.gem                                                                                           
#
# GRID NAVIGATION: 
#     PROJECTION:          LCC                 
#     ANGLES:                33.1   -91.6    33.1
#     GRID SIZE:          201 155
#     LL CORNER:              30.08    -96.10
#     UR CORNER:              36.03    -86.87
#
#     GRID AREA:            29.00  -97.00   37.00  -86.00
#     EXTEND AREA:          29.00  -98.00   37.00  -86.00
#     DATA AREA:            29.00  -98.00   37.00  -86.00
#
# Number of grids in file:     3
#
# Maximum number of grids in file:     25
#
#  NUM       TIME1              TIME2           LEVL1 LEVL2  VCORD PARM
#    1     131213/1200F001                          2         HGHT TMPC        
#    2     131213/1200F001                          0         NONE REFC        
#    3     131213/1200F001                         30  0      PDLY TMPC  

gdlist << EOF
garea = ar
gfunc = refc
glevel = 0
gvcord = none
gdattim = f001
r

!gfunc = tmpc
!glevel = 2
!gvcord = hght
!r
!
!gvcord = pdly
!glevel = 30:0
!r
!
e
EOF


exit;

gdcntr << EOF2
device   = gif|radar_type.gif|900;600
gdfile   = ptype.gem
\$mapfil = hipowo.cia
proj     = lcc/40;-100;40
garea    = dset
map      = 1
clear    = y
gdattim  = f001 
text     = 1/1/1
TITLE    = 1/-1/~ Unidata 6km type composite
GLEVEL   = 0
GVCORD   = none
CTYPE    = F
PANEL    = 0
SKIP     = 0
SCALE    = 0
CONTUR   = 0
HILO     =
LATLON   = 0
STNPLT   =
SATFIL   =
RADFIL   =
LUTFIL   = 
STREAM   =
POSN     = 0
COLORS   = 1
MARKER   = 0
GRDLBL   = 0
FILTER   = YES
!
! plot precip masked by echo tops greater than 5km. This is
! just the background precip. Snow and frozen will overlay
! and will not be masked.
GFUNC    = refc 
FINT     = 5;15;25;35;45;55;65;75
FLINE    = 0;14-19;19;19;19;19;19
CLRBAR   = 1/V/LL/0.001;0.1/0.5;0.01/1|.7/1/1
!
GDFILE = wrf:primary.gem
GFUNC    = p01i
FINT     = .01;.1;.25;.5;.75;1;1.25;1.5;1.75;2;2.5;3;4;5;6;7;8;9
FLINE    = 0;21-30;14-20;5
HILO     =
HLSYM    =
CLRBAR   = 1/v/cl/.001;.5
WIND     = bk1
REFVEC   =
TITLE    = 5/-1/24-HR FORECAST PRECIPITATION (IN) for ~ ?
l
r

e
EOF2
gpend

if(-e radar_type.gif) scp radar_type.gif $WEBDIR
mv ptype.gem /machine/gempak/wrf/rtmodel/ptype.gem
cd ..
rm -rf $WORK

exit;

#gdinfo << eof
#gdfile = ptype.gem
#glevel = all
#gvcord = all
#gfunc = all
#gdattim = all
#r
#
#e
#eof


gddiag << EOFD
gfunc = sgt(tmpc,0)
GRDNAM = rain1@0%none
r

gfunc = sgt(tmpc@30:0%pdly,0)
grdnam = rain2@0%none
r

EOFD

#   NUM       TIME1              TIME2           LEVL1 LEVL2  VCORD PARM
#    1     131210/0000F000                          2         HGHT TMPC        
#    2     131210/0000F000                          0         NONE REFC        
#    3     131210/0000F000                          0         NONE RAIN1       
#    4     131210/0000F000                          0         NONE RAIN2       
#    5     131210/0000F000                         30  0      PDLY TMPC  
#
gddiag << EOFD
gdfile = ptype.gem
gdoutf = ptype.gem
gdattim = f000
glevel = 0
gvcord = none
gfunc = mask(rain1,rain2)
grdnam = rain@0%none
cpyfil = 
l
r

e
EOFD


gdinfo << eof
gdfile = ptype.gem
glevel = all
gdattim = all
gvcord = all
gfunc = all
r

e
eof

#   NUM       TIME1              TIME2           LEVL1 LEVL2  VCORD PARM
#     1     131210/0000F000                          2         HGHT TMPC        
#     2     131210/0000F000                          0         NONE REFC        
#     3     131210/0000F000                          0         NONE RAIN1       
#     4     131210/0000F000                          0         NONE RAIN2       
#     5     131210/0000F000                          0         NONE RAIN        
#     6     131210/0000F000                         30  0      PDLY TMPC  

gddiag << EOFD
gdattim = f000
glevel = 2
gvcord = hght
gfunc = sle(tmpc,3)
grdnam = snow1@0%none
r

gfunc = sle(tmpc@30:0%pdly,0)
grdnam = snow2@0%none
r

glevel = 0
gvcord = none
gfunc = mask(snow1@0%none,snow2@0%none)
grdnam = snow
r

glevel = 2
gvcord = hght
gfunc = sle(tmpc,0)
grdnam = frzn1@0%none
r

e
EOFD


gddiag << EOFD
gdfile = ptype.gem
gdoutf = ptype.gem
glevel = 0
gvcord = none
gfunc = mask(frzn1,rain2)
grdnam = frzn
r

e
EOFD

gdlist << eof
gdfile = ptype.gem
garea = dset
glevel = 0
gfunc = refc
gvcord = none
r

e

eof

gdcntr << EOF2
device   = gif|radar_type.gif|900;700
gdfile   = wrf:primary.gem
\$mapfil = hipowo.cia
proj     = lcc/25;-103;60
garea    = dset
map      = 1
clear    = y
gdattim  = LAST
text     = 1/1/1
TITLE    = 1/-1/~ Unidata 6km type composite
GLEVEL   = 0
GVCORD   = none
CTYPE    = F
PANEL    = 0
SKIP     = 0
SCALE    = 0
CONTUR   = 0
HILO     =
LATLON   = 0
STNPLT   =
SATFIL   =
RADFIL   =
LUTFIL   = 
STREAM   =
POSN     = 0
COLORS   = 1
MARKER   = 0
GRDLBL   = 0
FILTER   = YES
!
! plot precip masked by echo tops greater than 5km. This is
! just the background precip. Snow and frozen will overlay
! and will not be masked.
GFUNC    = refc
FINT     = 5;15;25;35;45;55;65;75
FLINE    = 0;14-19;19;19;19;19;19
CLRBAR   = 1/V/LL/0.001;0.1/0.5;0.01/1|.7/1/1
l
r

!
! Plot the frozen mask
!GFUNC    = mask(refc,frzn+2@0%none)
!FINT     = 5;15;25;35;45;55;65;75
!FLINE    = 0;20-25;25;25;25;25;25;25;25
!CLRBAR   = 1/V/LL/0.025;0.1/0.5;0.01/1|.7/1/1
!clear = n
!title =
!l
!r

!
! plot the snow mask
!GFUNC = mask(refc,snow+2@0%none)
!FINT = 5;15;25;35;45;55;65;75
!FLINE = 0;26-31;31;31;31;31;31;31;31;31
!CLRBAR   = 1/V/LL/0.050;0.1/0.5;0.01/1|.7/1/1
!r
!
e
EOF2
 
gpend

if(-e radar_type.gif) scp radar_type.gif $WEBDIR
mv ptype.gem /machine/gempak/wrf/rtmodel/ptype.gem
cd ..
rm -rf $WORK

