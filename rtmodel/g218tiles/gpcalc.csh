#!/bin/csh -f

if ($#argv != 4 ) then
   echo "Usage: CCOL CROW DXCOL DYROW"
   exit -1
endif

@ YSTART = 1

set NROW=6
set NCOL=9

@ SUMJ = 0

@ ICOUNT = 0
@ MAXCOUNT = $NROW * $NCOL
@ FCNT = 1
while ( $ICOUNT < $MAXCOUNT )
   @ FPOS = $ICOUNT + 1
   if ( $FPOS < 10 ) then
     set CNT=0${FPOS}
   else
     set CNT=$FPOS
   endif
   set FILE=latlon.grid218.$CNT
   set VALS=`tail -1 $FILE | tr -s " " | cut -f2,3 -d" "`

   if ( $FCNT == 1 ) then
      if ( $SUMJ > 0 ) @ YSTART = $SUMJ + 1
      @ SUMJ = $SUMJ + $VALS[2]
      @ XSTART = 1
      @ SUMI = 0
   else
      @ XSTART = $SUMI + 1
   endif
   @ SUMI = $SUMI + $VALS[1]

   @ IMIN = $1 - $3
   @ IMAX = $1 + $3
   @ JMIN = $2 - $4
   @ JMAX = $2 + $4

   if ( ( ( $1 >= $XSTART ) && ( $1 <= $SUMI ) ) || ( ( $IMIN >= $XSTART ) && ( $IMIN <= $SUMI ) ) || \
        ( ( $IMAX >= $XSTART ) && ( $IMAX <= $SUMI ) ) ) then
        if ( ( ( $2 >= $YSTART ) && ( $2 <= $SUMJ ) ) || ( ( $JMIN >= $YSTART ) && ( $JMIN <= $SUMJ ) ) || \
             ( ( $JMAX >= $YSTART ) && ( $JMAX <= $SUMJ ) ) ) then
             echo FOUND TILE $FILE for $1 $2
             echo $FILE $VALS[1] $VALS[2] "(${XSTART},${SUMI})" "(${YSTART},${SUMJ})"
        endif
   endif

   @ ICOUNT = $ICOUNT + 1
   @ FCNT = $FCNT + 1
   if ( $FCNT > $NCOL ) @ FCNT = 1
end
