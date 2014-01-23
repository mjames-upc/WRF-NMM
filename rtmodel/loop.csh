#!/bin/csh -f
source /machine/gempak/NAWIPS/Gemenviron
setenv DISPLAY imogene:1
cleanup -c
set TOP=/machine/gempak/wrf/rtmodel
set WEBDIR=conan:/content/software/gempak/rtmodel
set RADDIR=/machine/ldm/data/nexrcomp/rad/NEXRCOMP/1km
if ( ! -e $RADDIR ) then
   echo "missing NEXRCOMP directory"
   exit
else
   cd $RADDIR
   set RADFIL=`ls dhr_* |tail -90`
   if ( $#RADFIL < 1 ) then
      echo "no radar images"
      exit
   endif
endif

cd $TOP

set GAREA="22;-123;49.1;-64.5"
set WINSZ="1200;900"
@ FCOUNT = 0
foreach file ($RADFIL)

	if ($FCOUNT < 10) then
	  set GIFFIL=nexr.gif.00${FCOUNT}
	else
	  set GIFFIL=nexr.gif.0${FCOUNT}
	endif
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
	    SATFIL   = $RADDIR/$file
	    LUTFIL   = default
	    PANEL    = 0
	    TITLE = 
	    COLORS   = 3
	    WIND     = 0
	    LINE     = 3/1/1
	    IMCBAR   = 0
	    LATLON   = 0
	    OUTPUT   = t
	    TEXT     = .75/2/1
	    CLEAR    = y
	    GAREA    = dset
	    PROJ     = sat
	    DEVICE   = gif|${GIFFIL}|${WINSZ}
	    l
	    r

	    e
EOF_NEX
	
	gpend
	#scp ${GIFFIL} ${WEBDIR}/nexr/
	#rm ${GIFFIL}

	@ FCOUNT = $FCOUNT + 1

end


#exit 0

set FILES=`ls nexr.gif*`
if ($#FILES < 1 ) then
   echo "No gif files found"
   exit
endif

set FIRST=$FILES[1]
shift FILES

set NUM=$#FILES
set LAST=$FILES[$NUM]
set FILES[$NUM]=""

# full size loop
convert -loop 0 -delay 10 $FIRST -delay 10 $FILES -delay 20 $LAST nexrcomp_dhr_anim.gif
scp -Bq nexrcomp_dhr_anim.gif conan:/content/software/gempak/rtmodel/
rm nexrcomp_dhr_anim.gif
rm nexr.gif*

exit 0

