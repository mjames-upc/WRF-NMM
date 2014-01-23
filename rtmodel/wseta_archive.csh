#!/bin/csh -f

set ARCH=/machine/gempak/wseta_archive
set RTHOST="conan"
set RTDIR="/content/software/gempak/rtmodel"

if ( ! -e $ARCH ) then
   echo "Must run script on imogene"
   exit 0
endif

cd /machine/gempak/wrf/rtmodel

#set FILES=`ls -d 20050[23456789]????`
#set FILES=`ls -d 20061[2]???? 20061[2]????_nmm 20061[2]????_nmm_alt1`
#set FILES=`ls -d 20071[1][0123]??? 20071[1][0123]???_nmm 20071[1][0123]???_nmm_alt1`

set CURRENT=`date -u +'%Y%m'`
set FILES=`ls -d 20[0-9][0-9][01][0-9][0-3][0-9][0-2][0-9]* | grep -v '^'${CURRENT}`

foreach FILE ($FILES)
   echo FILE $FILE
   set YYYYMM=`echo $FILE | cut -c1-6`
   set DATE=`echo $FILE | cut -f1 -d_`

   if ( ! -e ${ARCH}/${YYYYMM}/${DATE} ) then
      echo making ${ARCH}/${YYYYMM}/${DATE}
      mkdir -p ${ARCH}/${YYYYMM}/${DATE}
   endif

   if ( -e ${ARCH}/${YYYYMM}/${DATE} ) then
      if ( $DATE == $FILE ) then
         set RUN="wseta_region"
      else
         set RUN=`echo $FILE | cut -f2- -d_`
      endif
      if ( ! -e ${ARCH}/${YYYYMM}/${FILE}/${RUN} ) then
	 echo move $FILE to $RUN
         mv $FILE ${ARCH}/${YYYYMM}/${DATE}/${RUN}
	 scp -r ${RTHOST}:${RTDIR}/${DATE} ${ARCH}/${YYYYMM}
         set STATUS=$status
	 # remove remote directory if sucessfully copied
         if ( $status == 0 ) then
	    ssh ${RTHOST} rm -r ${RTDIR}/${DATE}
         endif
      else
	 echo ${ARCH}/${YYYYMM}/${DATE}/${RUN} exists
      endif
   endif
end
