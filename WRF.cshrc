#!/bin/csh 
#-------------------------------------------------------
#
# cshrc file for the workstation WRF Model usage
# 
# Please read all the comments below and when requested,
# make changes to reflect your system configuration.
#
# Log
#       R.Rozumalski    09/04   Version 0.1
#-------------------------------------------------------
#
# Make sure WRF home directory exists
#

setenv WRF  /machine/gempak/wrf

set ARCH = `/bin/uname -p`
if ($ARCH != x86_64 ) then
   set ARCH = x86_pc
endif

setenv ARCH $ARCH

if ( ! -d $WRF ) then
	echo "Can not find Workstation WRF distribution -- Check directory and"
	echo "modify WRF.cshrc"
        unsetenv WRF
        exit 1
endif

setenv NO_STOP_MESSAGE 1

#
# SOO/STRC WRF EMS package environment variables.
#
# No need to change these, unless you have a good reason
# and just because is not a good reason.
#
    setenv WRF_HOME		$WRF
    setenv WRF_BIN              $WRF_HOME/bin
    setenv WRF_DATA		$WRF_HOME/data
    setenv WRF_ETC              $WRF_HOME/etc
    setenv WRF_STRC		$WRF_HOME/strc
    setenv WRF_RUN              $WRF_HOME/runs
    setenv WRF_UTIL             $WRF_HOME/util
    setenv WRF_DOCS             $WRF_HOME/docs
    setenv WRF_LIB              $WRF_HOME/lib
    setenv WRF_LOGS             $WRF_HOME/logs

    setenv WRF_MPI              $WRF_UTIL/mpich

    setenv DATA_GEOG            $WRF_DATA/geog
    setenv DATA_CONF		$WRF_DATA/conf
    setenv DATA_SI		$WRF_DATA/wrfsi
    setenv DATA_DOMS		$WRF_DATA/domains

    setenv NETCDF               $WRF_UTIL/netcdf
    setenv PATH_TO_PERL         /usr/bin/perl

    setenv NCPUS 2
    setenv OMP_NUM_THREADS $NCPUS
    setenv MPSTKZ 256M

    unset limits
    limit stacksize unlimited
    
#  The following are needed for the various SI GUI scripts.
# 
    setenv INSTALLROOT		$WRF_HOME
    setenv MOAD_DATAROOT        $WRF_HOME
    setenv EXT_DATAROOT         $WRF_HOME

    setenv DATAROOT             $WRF_RUN

    setenv SOURCE_ROOT          $DATA_SI
    setenv TEMPLATES            $DATA_DOMS

    setenv GEOG_DATAROOT	$DATA_GEOG

    setenv NCARG_ROOT		$WRF_UTIL/ncarg
    setenv WRF_NCL              $WRF_UTIL/graphics/ncl
    setenv NCL_COMMAND		$NCARG_ROOT/bin/ncl

#  GRADS environment variables
#
    setenv GADDIR $WRF_UTIL/grads/data
    setenv GAUDFT $WRF_UTIL/grads/data/tables/
    setenv GASCRP $WRF_UTIL/grads/scripts
#
#  Add WS WRF executables and scripts to the existing path
#
set path = ( . $WRF_STRC $WRF_ETC $WRF_BIN $NETCDF $WRF_UTIL/bin $GADDIR $NCARG_ROOT/bin $WRF_MPI/bin $path )

# Done!
