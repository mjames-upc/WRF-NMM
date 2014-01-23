#!/usr/bin/perl
#dis
#dis    Open Source License/Disclaimer, Forecast Systems Laboratory
#dis    NOAA/OAR/FSL, 325 Broadway Boulder, CO 80305
#dis
#dis    This software is distributed under the Open Source Definition,
#dis    which may be found at http://www.opensource.org/osd.html.
#dis
#dis    In particular, redistribution and use in source and binary forms,
#dis    with or without modification, are permitted provided that the
#dis    following conditions are met:
#dis
#dis    - Redistributions of source code must retain this notice, this
#dis    list of conditions and the following disclaimer.
#dis
#dis    - Redistributions in binary form must provide access to this
#dis    notice, this list of conditions and the following disclaimer, and
#dis    the underlying source code.
#dis
#dis    - All modifications to this software must be clearly documented,
#dis    and are solely the responsibility of the agent making the
#dis    modifications.
#dis
#dis    - If significant modifications or enhancements are made to this
#dis    software, the FSL Software Policy Manager
#dis    (softwaremgr@fsl.noaa.gov) should be notified.
#dis
#dis    THIS SOFTWARE AND ITS DOCUMENTATION ARE IN THE PUBLIC DOMAIN
#dis    AND ARE FURNISHED "AS IS."  THE AUTHORS, THE UNITED STATES
#dis    GOVERNMENT, ITS INSTRUMENTALITIES, OFFICERS, EMPLOYEES, AND
#dis    AGENTS MAKE NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE USEFULNESS
#dis    OF THE SOFTWARE AND DOCUMENTATION FOR ANY PURPOSE.  THEY ASSUME
#dis    NO RESPONSIBILITY (1) FOR THE USE OF THE SOFTWARE AND
#dis    DOCUMENTATION; OR (2) TO PROVIDE TECHNICAL SUPPORT TO USERS.
#dis
#dis

# Script Name:  wrfprep.pl
#
# Purpose:  This script runs the WRFSI hinterp/vinterp routines
#           and the WRF "real.exe" program to prepare initial
#           and lateral boundary conditions for the WRF model.
#
# Usage:
#   
#   wrfprep.pl -h to see options
#
#        

# RAR Changed
#$ENV{PATH}="$ENV{PATH}:/usr/local/netcdf/bin";
$ENV{PATH}="$ENV{PATH}:$ENV{'NETCDF'}/bin";
##
require 5;
use strict;
use Time::Local;
use vars qw($opt_c $opt_d $opt_e $opt_f $opt_h
            $opt_i $opt_o  $opt_p
            $opt_q $opt_r $opt_s $opt_t $opt_T $opt_u);
use Getopt::Std;
print "Routine: wrfprep.pl\n";
my $mydir = `pwd`; chomp $mydir;

# Get command line options
getopts('a:b:c:d:e:f:hi:l:o:p:q:r:s:t:Tu:');

# Did the user ask for help?
if ($opt_h){
  print "Usage:  wrfprep.pl [options]

          Valid Options:
          ===============================================================

          -c NODETYPE
             Used to set node type when requesting jobs via 
             PBS/SGE queuing system (-q option must be set). If not
             set, the script assumes type is comp

          -d MOAD_DATAROOT
             Sets or overrides the MOAD_DATAROOT environment variable.
             If no environment variable is set, this must be provided.

          -e ENDTIME (YYYYMMDDHH format)
             Used to set the end time of the simulation.  If set,
             then the -f argument is ignored

          -f RUN_LENGTH (in hours)
             If not set, the program assumes a 24-h forecast period

          -h 
             Prints this message

          -i INSTALLROOT 
             Sets/overrides the INSTALLROOT environment variable.

          -o OFFSET_HOURS
             Set initial time to current time + OFFSET_HOURS.  To
             run for a previous hour, this value should be negative.

          -p nproc
             Number of processors to use for real.exe if -r p is set. 
             If requesting parallized real.exe run and you do not set
             this option, 1 processor will be used.

          -q hh:mm:ss
             Use the PBS queuing system to run the job.  Requires
             hh::mm:ss be set to max run time expected in hours
             minutes,seconds.

          -r [ p|s ]
             Used to run real.exe as part of the run string.  
             Set equal to p to use the parallel version,
             Set equal to s to use the serial version

          -s STARTTIME (YYYYMMDDHH UTC format)
             Use this time as the initial time instead of the 
             system clock

          -t LBC_INTERVAL (hours)
             Hours between lateral boundary condition files
             (If not set, 3 hours is the default)
 
          -T 
             Set to use the times in the wrfsi.nl (i.e., all
             time options to wrfprep are ignored and the 
             start/stop times in wrfsi.nl are not edited.
 
          -u PROJECTNAME
             Used to set the project account name when using the 
             PBS/SGE queuing system (e.g., on jet at FSL)
           \n"; 
  exit;
}

# Set up run-time environment

my $runtime = time;
my ($installroot, $moad_dataroot);

# Determine the installroot.  Use the -i flag as first option,
# followed by INSTALLROOT environment variable, followed by
# current working directory with ../. appended.

if (! defined $opt_i){
  if (! $ENV{INSTALLROOT}){
    print "No INSTALLROOT environment variable set! \n";
    print "Attempting to use the current diretory to set installroot.\n";
    my $curdir = `pwd`; chomp $curdir;
    my $script = $0;
    if ($script =~ /^(\S{1,})\/wrfprep.pl$/){
      chdir "$1/..";
    }else{
      chdir "..";
    }
    $installroot = `pwd`; chomp $installroot;
    chdir "$curdir";
    if (! -e "$installroot/bin/hinterp.exe") {
      die "Cannot determine installroot\n";
    }else{
      $ENV{INSTALLROOT} = $installroot;
    }
  }else{
    $installroot = $ENV{INSTALLROOT};
  }
}else{
  $installroot = $opt_i;
  $ENV{INSTALLROOT}=$installroot;
}

# Look for some critical executables.
my $hinterpexe = "$installroot/bin/hinterp.exe";
my $vinterpexe = "$installroot/bin/vinterp.exe";
my $realexe = "$installroot/../main/real.exe";

if (! -e "$hinterpexe" ) {
  die "No hinterp.exe found in $installroot/bin\n";
}
if (! -e "$vinterpexe") {
  die "No vinterp.exe found in $installroot/bin\n";
}
print "INSTALLROOT = $installroot\n";
require "$installroot/etc/wrfsi_utils.pm";

# Process MOAD_DATAROOT.  Use -d argument first, followed by 
# environment variable.

if (! defined $opt_d){
  if (! $ENV{MOAD_DATAROOT}){
    print "No MOAD_DATAROOT environment variable set! \n";
    print "Using default: $installroot/data\n";
    $moad_dataroot = "$installroot/data";
    $ENV{MOAD_DATAROOT} = $moad_dataroot;
  }else{
    $moad_dataroot = $ENV{MOAD_DATAROOT};
  }
}else{
  $moad_dataroot = $opt_d;
  $ENV{MOAD_DATAROOT} = $moad_dataroot;
}
# Check for a couple of critical files in moad_dataroot
if (! -e "$moad_dataroot/static/wrfsi.nl"){
  die "No wrfsi.nl file in $moad_dataroot/static\n";
}
print "MOAD_DATAROOT = $moad_dataroot\n";

# Set some other variables 
my $workdir = "$moad_dataroot/siprd";
my $staticdir = "$moad_dataroot/static";
my $wrfsinl = "$staticdir/wrfsi.nl";
my $wrfnl = "$staticdir/wrf.nl";

# If the user has asked for real to be run,
# we need to make sure it is possible by ensuring
# we have the wrf.nl file and the real executable.
my $nprocreal = 1;
if ($opt_r){
  if (! -e "$realexe") {
    print "No real.exe found in $installroot/../main\n";
    print "Cannot run the real.exe portion.\n";
    die;
  }
  if (! -e "$wrfnl") {
    print "No wrf.nl found: $wrfnl\n";
    print "real.exe cannot be run.\n";
    die;
  }
  if ($opt_r =~ /p/i){
    if ($opt_p) {
      $nprocreal = $opt_p;
      if (-f "$moad_dataroot/static/mpi_machines.conf"){
        $ENV{MACHINE_FILE} = "$moad_dataroot/static/mpi_machines.conf";
        $ENV{GMPICONF} =  $ENV{MACHINE_FILE};
      }else{
        if ((! $ENV{MACHINE_FILE})and(! $ENV{GMPICONF})and(! $opt_q)){
           print "You have requested a multi-processor MPI run with -p $opt_p\n";
           print "But...no machines file seems to be present.  I checked:\n";
           print "GMPICONF environment variable, MACHINE_FILE environment variable, \
n";
           print "and $moad_dataroot/static/mpi_machines.conf\n";
           print "So, if things go awry, this may be why!\n";
        }
      }
    }
  }
}

# Read the wrfsi namelist
open (WRFSI, "$wrfsinl");
my @silines = <WRFSI>;
close(WRFSI);
my %wrfsihash = &wrfsi_utils::get_namelist_hash(@silines);
my $num_init_times = ${${wrfsihash{NUM_INIT_TIMES}}}[0];
my @initdirs = @{${wrfsihash{ANALPATH}}};
my @initnames = @{${wrfsihash{INIT_ROOT}}};
my @lbcdirs = @{${wrfsihash{LBCPATH}}};
my @lsmdirs =  @{${wrfsihash{LSMPATH}}};
my @lbcnames = @{${wrfsihash{LBC_ROOT}}};
my @lsmnames = @{${wrfsihash{LSM_ROOT}}};
my @constants_path =  @{${wrfsihash{CONSTANTS_PATH}}};
my @constants_names = @{${wrfsihash{CONSTANTS_FULL_NAME}}};
my @wrflevels = @{${wrfsihash{LEVELS}}};
my $nwrflevels = @wrflevels;
my $dx = ${${wrfsihash{MOAD_DELTA_Y}}}[0];
my $dy = ${${wrfsihash{MOAD_DELTA_Y}}}[0];
my $nx = ${${wrfsihash{XDIM}}}[0];
my $ny = ${${wrfsihash{YDIM}}}[0];

# Clean the work directory
opendir (WORK, "$workdir");
foreach (readdir WORK){
  if (-e "$workdir/$_"){ unlink "$workdir/$_";}
}
closedir (WORK);
chdir "$workdir";

# Process other arguments...set defaults as required
my ($runlength, $interval, $offset, $starttime_sec, $endtime_sec);
my ($interval_sec,$year_beg,$month_beg,$day_beg,$hour_beg,$min_beg,$sec_beg,
                  $year_end,$month_end,$day_end,$hour_end,$min_end,$sec_end,
                  $jjj_beg,$jjj_end, $isdst,$wday);
if (! $opt_T){ # We compute times to edit wrfsi.nl

 if (! $opt_e) { # Determine run lenght if end not set
   if ( $opt_f) {
     $runlength = $opt_f;
   }else{ 
     print "Using default forecast length of 24 hours.\n";
     print "Use -f hours to change forecast length.\n";
     $runlength = 24;
   }
 }else{  # Ignore -f because end-time is specified
  if($opt_f){ print "-f $opt_f option ignored because -e $opt_e is set\n";}
 }

 if ($opt_t){
   $interval = $opt_t;
   $interval_sec = $interval * 3600;
 }else{
   print "Using wrfsi.nl time interval\n";
   $interval_sec = ${wrfsihash{INTERVAL}}[0] ;
   $interval = $interval_sec/3600;
 }
 if ($opt_o) {
   $offset = $opt_o;
 }else{
   $offset = 0;
 }

 if ($opt_s) {
   # Parse the string
   if ($opt_s =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)$/) {
     my $year = $1 - 1900;
     my $month = $2 - 1;
     my $day = $3;
     my $hour = $4;
     $starttime_sec =timegm(0,0,$hour,$day, $month,$year);
   }else{
     die "Invalid start time passed in on -s. Use YYYYMMDDHH\n";
   }
 }else{
   # Assume start time is current hour + offset
   $starttime_sec = $runtime - ($runtime % 3600);
 }

 # Adjust starttime_sec for offset

 $starttime_sec = $starttime_sec + ($offset*3600);

 # Compute endtime_sec
 if (! $opt_e) { # Compute from runlength 
   $endtime_sec = $starttime_sec + ($runlength * 3600);
 }else{ # Compute from argument
   if ($opt_e =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)$/) {
     my $year = $1 - 1900;
     my $month = $2 - 1;
     my $day = $3;
     my $hour = $4;
     $endtime_sec =timegm(0,0,$hour,$day, $month,$year);
     if ($endtime_sec < $starttime_sec){
       die "Endtime specified is before starttime!\n";
     }
   }else{
     die "Invalid end time passed in on -s. Use YYYYMMDDHH\n";
   }
   $runlength = ($endtime_sec - $starttime_sec)/3600;
 }
 

 # Convert start/end times to normal string values

 ($sec_beg, $min_beg, $hour_beg, $day_beg, $month_beg, $year_beg,
  $wday, $jjj_beg, $isdst) = gmtime($starttime_sec);
 $month_beg++;
 $year_beg = $year_beg + 1900;
 $jjj_beg++;
 $month_beg = "0".$month_beg while(length($month_beg) < 2);
 $day_beg = "0".$day_beg while(length($day_beg) < 2);
 $hour_beg = "0".$hour_beg while(length($hour_beg) < 2);
 $min_beg = "0".$min_beg while(length($min_beg) < 2);
 $sec_beg = "0".$sec_beg while(length($sec_beg) < 2);
 $jjj_beg = "0".$jjj_beg while(length($jjj_beg) < 3);

 ($sec_end, $min_end, $hour_end, $day_end, $month_end, $year_end,
  $wday, $jjj_end, $isdst) = gmtime($endtime_sec); 
 $month_end++;
 $year_end = $year_end + 1900;
 $jjj_end++;
 $month_end = "0".$month_end while(length($month_end) < 2);
 $day_end = "0".$day_end while(length($day_end) < 2);
 $hour_end = "0".$hour_end while(length($hour_end) < 2);
 $min_end = "0".$min_end while(length($min_end) < 2);
 $sec_end = "0".$sec_end while(length($sec_end) < 2);
 $jjj_end = "0".$jjj_end while(length($jjj_end) < 3);

}else{  # Get values from existing namelist and compute forecast
        # length from those

 $year_beg = ${${wrfsihash{START_YEAR}}}[0];
 $month_beg = ${${wrfsihash{START_MONTH}}}[0];
 $day_beg = ${${wrfsihash{START_DAY}}}[0];
 $hour_beg =  ${${wrfsihash{START_HOUR}}}[0];
 $min_beg = ${${wrfsihash{START_MINUTE}}}[0];
 $sec_beg = ${${wrfsihash{START_SECOND}}}[0];

 $year_end = ${${wrfsihash{END_YEAR}}}[0];
 $month_end = ${${wrfsihash{END_MONTH}}}[0];
 $day_end = ${${wrfsihash{END_DAY}}}[0];
 $hour_end =  ${${wrfsihash{END_HOUR}}}[0];
 $min_end = ${${wrfsihash{END_MINUTE}}}[0];
 $sec_end = ${${wrfsihash{END_SECOND}}}[0];

 $starttime_sec = timegm(0,0,$hour_beg,$day_beg, $month_beg-1,$year_beg-1900);
 $endtime_sec   = timegm(0,0,$hour_end,$day_end, $month_end-1,$year_end-1900);

 ($sec_beg, $min_beg, $hour_beg, $day_beg, $month_beg, $year_beg,
  $wday, $jjj_beg, $isdst) = gmtime($starttime_sec);
 $month_beg++;
 $year_beg = $year_beg + 1900;
 $jjj_beg++;
 $month_beg = "0".$month_beg while(length($month_beg) < 2);
 $day_beg = "0".$day_beg while(length($day_beg) < 2);
 $hour_beg = "0".$hour_beg while(length($hour_beg) < 2);
 $min_beg = "0".$min_beg while(length($min_beg) < 2);
 $sec_beg = "0".$sec_beg while(length($sec_beg) < 2);
 $jjj_beg = "0".$jjj_beg while(length($jjj_beg) < 3);

 ($sec_end, $min_end, $hour_end, $day_end, $month_end, $year_end,
  $wday, $jjj_end, $isdst) = gmtime($endtime_sec);
 $month_end++;
 $year_end = $year_end + 1900;
 $jjj_end++;
 $month_end = "0".$month_end while(length($month_end) < 2);
 $day_end = "0".$day_end while(length($day_end) < 2);
 $hour_end = "0".$hour_end while(length($hour_end) < 2);
 $min_end = "0".$min_end while(length($min_end) < 2);
 $sec_end = "0".$sec_end while(length($sec_end) < 2);
 $jjj_end = "0".$jjj_end while(length($jjj_end) < 3);

 $interval_sec =  ${${wrfsihash{INTERVAL}}}[0];
 $interval = $interval_sec/3600.;
 $runlength = ($endtime_sec - $starttime_sec) / 3600.; 
}
print "Start time: $year_beg/$month_beg/$day_beg $hour_beg:$min_beg:$sec_beg\n";
print "End time:   $year_end/$month_end/$day_end $hour_end:$min_end:$sec_end\n";

my $endtimefile = $year_end."-".$month_end."-".$day_end."_";
$endtimefile = $endtimefile.$hour_end.":".$min_end.":".$sec_end;

# Build cycle ID for cycle file
my $year2;
if ($year_beg ge "2000") {
  $year2 = $year_beg-2000;
}else{
  $year2 = $year_beg-1900;
}
my $runlen4 = $runlength;
$runlen4 = "0".$runlen4 while (length($runlen4)<4);
$year2 = "0".$year2 while(length($year2)<2);
my $cycleid = $year2.$jjj_beg.$hour_beg.$min_beg.$runlen4;
print "CYCLE.$cycleid\n";
my $cyclefile = "CYCLE.$cycleid";

# Set log times
my $logtime = $year_beg.$month_beg.$day_beg.$hour_beg;

# Set log file names
my $wrfpreplog = "$moad_dataroot/log/$logtime.wrfprep";
my $hinterplog = "$moad_dataroot/log/$logtime.hinterp";
my $vinterplog = "$moad_dataroot/log/$logtime.vinterp";
my $reallog = "$moad_dataroot/log/$logtime.real";

# Open the log file for wrfprep
open (WPLOG, ">$wrfpreplog");
print WPLOG "Log for wrfprep.pl\n";
print WPLOG "----------------------------------------------------------\n";
my $timenow = `date -u`; chomp $timenow;
print WPLOG "Opened $timenow\n";
print WPLOG "----------------------------------------------------------\n";
print WPLOG "INSTALLROOT: $installroot\n";
print WPLOG "MOAD_DATAROOT: $moad_dataroot\n";
print WPLOG "CYCLE START: $year_beg/$month_beg/$day_beg $hour_beg:$min_beg:$sec_beg\n";
print WPLOG "CYCLE END:   $year_end/$month_end/$day_end $hour_end:$min_end:$sec_end\n";
print WPLOG "FCST LENGTH: $runlength\n";
print WPLOG "INTERVAL:    $interval\n";
print WPLOG "\n";

# Now, based on start time and interval, we can build a list of times
# to process

my (@inittimes,@lbctimes);
my $time_sec;

my $time_sec = $starttime_sec;
my $timecnt = 1;
while ($time_sec <= $endtime_sec){
  my ($sec,$min,$hour,$day,$month,$year,$wday,$jjj,$isd) = gmtime($time_sec);
  $month++;
  $year = $year + 1900;
  $month = "0".$month while(length($month) < 2);
  $day = "0".$day while(length($day) < 2);
  $hour = "0".$hour while(length($hour) < 2);
  my $time_str = $year."-".$month."-".$day."_".$hour;
  if ($timecnt <= $num_init_times) {
    print "ictime = $time_str\n";
    push @inittimes, $time_str;
  }else{
    print "lbctime = $time_str\n";
    push @lbctimes, $time_str;
  }
  $time_sec = $time_sec + ($interval_sec);
  $timecnt++;
}


# Link all constants files

# - set up a hash to keep track of which names we find
my %searchhash;
my @file_linked;
undef @file_linked;

foreach (@constants_names) {
  ${${searchhash{$_}}} = "false";
}
my ($cpath,$cfile);
foreach $cfile (@constants_names) {
  foreach $cpath (@constants_path) {
    print WPLOG "Looking for $cpath/$cfile ... ";
    if (-e "$cpath/$cfile") {
      ${${searchhash{$cfile}}} = "true";
      print WPLOG "found and linking $cpath/$cfile to $workdir/$cfile\n";
      symlink "$cpath/$cfile", "$workdir/$cfile";
      push @file_linked, $cfile;
    }else{
      print WPLOG "not found.\n";
    }
  }
}
# Check the hash table to see what was not found
foreach (@constants_names) {
  if (${${searchhash{$_}}} eq "false") {
    print WPLOG "WARNING: No constants file named $_ found.\n";
  }
}

# If we are doing an initialization, then see if we
# have any of the initialization files requested.  This assumes
# one source for initial conditions, and that multiple entries
# in the namelist file is a priority list (i.e., link the first
# one found and ignore the other entries)
my ($initsrc,$lbcsrc,$numdirs,$numnames,$foundallinit,$foundalllbc,
    $ndirsread,$nnamesread, $nfound);

$foundallinit = 1;
$foundalllbc = 1;

#+LXZ

#####################################################################
# If we are doing an initialization, then see if we
# have all of the initialization files requested for each init times.
# For each source in the (initnames) list, we search all directories
# (initdirs) for the files that match the source at the init time.
# The first file found is linked while the duplicate ones are ignored.
# If no file is found, then cleanup all linked files and die. 
# As such we assume that at least one file must exist in (initdirs)
# that match each source and each init time.
#--------------------------------------------------------------------

if ($num_init_times > 0) {
  print WPLOG "===) Searching for init files...\n";
  # Initialize some flags
  $numdirs = @initdirs;
  $numnames = @initnames;

  # Try each init time...
  foreach (@inittimes) {

    # Try each source...
    $nnamesread = 0;
    while ($nnamesread < $numnames) {
      my $icname = $initnames[$nnamesread];

      # Search all directories for files matching this source & time...
      $nfound = 0;
      $ndirsread = 0;
      while ($ndirsread < $numdirs) {
        my $icdir = $initdirs[$ndirsread];
        if (-e "$icdir/$icname:$_") {
          $nfound++;
          if (-e "$workdir/$icname:$_") {
            print WPLOG "found existing link: $workdir/$icname:$_\n";
          }
          else {
            print WPLOG "found and linking $icdir/$icname:$_\n";
            symlink "$icdir/$icname:$_","$workdir/$icname:$_";
            push @file_linked, "$icname:$_";
            $initsrc = $icname;
          }
        }
        $ndirsread++;
      }
      if ($nfound > 1) {
        print WPLOG "warning: found $nfound duplicate $icname:$_\n";
      } elsif ($nfound < 1) {
        # We found no matching, remove all previous links and die.
        $foundallinit = 0;
        print WPLOG "xxxx DIE...found no matching init file source & time: $icname:$_\n";
        print WPLOG "Consider using the wrfprep.pl -o or -s flags to match the $icname data\n";
        print WPLOG "\tfile times created by running grip_prep.pl.\n\n";
        goto CLEANUP_DIE;
      }
      $nnamesread++;
    }
  }

  #------------------------------------------------------------------
  # Link LSM (optional) file...
  #------------------------------------------------------------------

  if (length($lsmnames[0])>0) {
    print WPLOG "---> Looking for  $lsmdirs[0]/$lsmnames[0]...\n";
    foreach(@inittimes){
      my $lsmfile = "$lsmdirs[0]/$lsmnames[0]:$_";
      if (-e "$lsmfile") {
        print WPLOG "found and linking $lsmfile.\n";
        symlink "$lsmfile","$workdir/$lsmnames[0]:$_";
        push @file_linked, "$lsmnames[0]:$_";
      } else {
        # We are still going since it is optional...
        print WPLOG "warning: found no $lsmfile\n";
      }
    }
  }
}

#####################################################################
# Do the same thing for lateral boundary conditions
#--------------------------------------------------------------------

my  $num_lbc_times =@lbctimes;
if ($num_lbc_times > 0) {
  print WPLOG "===) Searching for LBC files...\n";
  # Initialize some flags
  $numdirs = @lbcdirs;
  $numnames = @lbcnames;

  # Try each lbc time...
  foreach (@lbctimes) {

    # Try each source...
    $nnamesread = 0;
    while ($nnamesread < $numnames){
      my $lbcname = $lbcnames[$nnamesread];

      # Search all directories for files matching this source & time...
      $nfound = 0;
      $ndirsread = 0;
      while ($ndirsread < $numdirs) {
        my $lbcdir = $lbcdirs[$ndirsread];
        if (-e "$lbcdir/$lbcname:$_") {
          $nfound++;
          if (-e "$workdir/$lbcname:$_") {
            print WPLOG "found existing link: $workdir/$lbcname:$_\n";
          } else {
            print WPLOG "found and linking $lbcdir/$lbcname:$_\n";
            symlink "$lbcdir/$lbcname:$_","$workdir/$lbcname:$_";
            push @file_linked, "$lbcname:$_";
            $lbcsrc = $lbcname;
          }
        }
        $ndirsread++;
      }
      if ($nfound > 1) {
        print WPLOG "warning: found $nfound duplicate $lbcname:$_\n";
      } elsif ($nfound < 1) {
        # We found no matching, remove all previous links and die.
        $foundalllbc = 0;
        print WPLOG "xxxx DIE...found no matching lbc file source & time: $lbcname:$_\n";
        print WPLOG "Consider editing the wrfprep.pl -f, -o or -s flags to match the $lbcname\n";
        print WPLOG "\tdata file times created by running grip_prep.pl.\n\n";
        goto CLEANUP_DIE;
      }
      $nnamesread++;
    }
  }

  #------------------------------------------------------------------
  # Link LSM (optional) file...
  #------------------------------------------------------------------

  if (length($lsmnames[0])>0) {
    print WPLOG "---> Looking for  $lsmdirs[0]/$lsmnames[0]...\n";
    foreach(@lbctimes){
      my $lsmfile = "$lsmdirs[0]/$lsmnames[0]:$_";
      if (-e "$lsmfile") {
        print WPLOG "found and linking $lsmfile\n";
        symlink "$lsmfile","$workdir/$lsmnames[0]:$_";
        push @file_linked, "$lsmnames[0]:$_";
      } else {
        # We are still going since it is optional...
        print WPLOG "warning: found no $lsmfile\n";
      }
    }
  }
}

#####################################################################
# Do cleanup and die if necessary init & lbc files are not all found
#--------------------------------------------------------------------
CLEANUP_DIE:
  if ((! $foundallinit)or(! $foundalllbc)) {
    # We found insufficient matching, remove all previous links and die.
    foreach (@file_linked){
      system ("rm -f $workdir/$_");
    }
    $timenow = `date -u`; chomp $timenow;
    print WPLOG "Died at $timenow\n";
    close (WPLOG);
    die;
  }

#####################################################################

#-LXZ

print WPLOG "Initialization source used: $initsrc\n";
print WPLOG "Lateral boundary source:    $lbcsrc\n";
print WPLOG "\n";

# Edit the wrfsi.nl filetimespec

open (SINL, ">$wrfsinl");
my $line;
foreach $line (@silines) {
  if ($line =~ /^\s*(start_year)\s*=/i)  {$line = " $1 = $year_beg,\n";}
  if ($line =~ /^\s*(start_month)\s*=/i) {$line = " $1 = $month_beg,\n";}
  if ($line =~ /^\s*(start_day)\s*=/i)   {$line = " $1 = $day_beg,\n";}
  if ($line =~ /^\s*(start_hour)\s*=/i)  {$line = " $1 = $hour_beg,\n";}
  if ($line =~ /^\s*(start_minute)\s*=/i)  {$line = " $1 = $min_beg,\n";}
  if ($line =~ /^\s*(start_second)\s*=/i)  {$line = " $1 = $sec_beg,\n";}
  if ($line =~ /^\s*(end_year)\s*=/i)    {$line = " $1 = $year_end,\n";}
  if ($line =~ /^\s*(end_month)\s*=/i)   {$line = " $1 = $month_end,\n";}
  if ($line =~ /^\s*(end_day)\s*=/i)     {$line = " $1 = $day_end,\n";}
  if ($line =~ /^\s*(end_hour)\s*=/i)    {$line = " $1 = $hour_end,\n";}
  if ($line =~ /^\s*(end_minute)\s*=/i)    {$line = " $1 = $min_end,\n";}
  if ($line =~ /^\s*(end_second)\s*=/i)    {$line = " $1 = $sec_end,\n";}
  if (($line =~ /^\s*(interval)\s*=/i)and($opt_t)){
    $line = " $1 = $interval_sec,\n";
   }
  print SINL "$line";
}
close (SINL);

# Put an edited version of moad_dataroot/static/wrf.nl into
# the work directory using the name "namelist.input"
# ONLY IF WE ARE RUNNING REAL!
my ($time_step_max,$output_freq_min, $run_days, $run_hours, $run_minutes,
    $run_seconds);
if ($opt_r) {
  # Read wrf.nl

  open (WRFNL, "$wrfnl");
  my @lines = <WRFNL>;
  close (WRFNL);
  my %wrfhash = &wrfsi_utils::get_namelist_hash(@lines);

  # Compute a recommended timestep based on WRF dx and check setting
  my $rec_dt = ($dx/1000.)*5;
  my $dt =  ${wrfhash{TIME_STEP}}[0];
  my $max_dt = $rec_dt*1.2;
  my $min_dt = $rec_dt - $rec_dt*0.4;
  if ($dt > $max_dt) {
    print WPLOG "WARNING:  dt in wrf.nl looks to be too long for dx of $dx\n";
  }
  if ($dt < $min_dt) {
    print WPLOG "WARNING:  dt in wrf.nl looks to be too short for dx of $dx\n";
  }
  # Compute time_step_max from dt and forecast length
  $time_step_max = int( (($runlength*3600)/$dt) + 0.5);
  $run_days = int($runlength / 24 );
  $run_hours = $runlength % 24 ;
  $run_minutes = ($runlength*60) % 60 ;
  $run_seconds = ($runlength*3600) % 3600 ; 
  # Compute output frequency in seconds
  my $output_freq_sec = ${wrfhash{TIME_STEP_COUNT_OUTPUT}}[0]*$dt;
  $output_freq_min = $output_freq_sec/60;
  my $output_freq_hours = $output_freq_sec/3600.;

  open (WNL, ">$workdir/namelist.input");
  foreach $line (@lines) {
    if ($line =~ /^\s*(time_step_max)\s*=/i)  {$line = " $1 = $time_step_max,\n";}
    if ($line =~ /^\s*(run_days)\s*=/i)  {$line = " $1 = $run_days,\n";}
    if ($line =~ /^\s*(run_hours)\s*=/i)  {$line = " $1 = $run_hours,\n";}
    if ($line =~ /^\s*(run_minutes)\s*=/i)  {$line = " $1 = $run_minutes,\n";}
    if ($line =~ /^\s*(run_seconds)\s*=/i)  {$line = " $1 = $run_seconds,\n";}
    if ($line =~ /^\s*(dx)\s*=/i)  {$line = " $1 = $dx,\n";}
    if ($line =~ /^\s*(dy)\s*=/i)  {$line = " $1 = $dy,\n";}
    if ($line =~ /^\s*(s_we)\s*=/i)  {$line = " $1 = 1,\n";}
    if ($line =~ /^\s*(e_we)\s*=/i)  {$line = " $1 = $nx,\n";}
    if ($line =~ /^\s*(s_sn)\s*=/i)  {$line = " $1 = 1,\n";}
    if ($line =~ /^\s*(e_sn)\s*=/i)  {$line = " $1 = $ny,\n";}
    if ($line =~ /^\s*(s_vert)\s*=/i)  {$line = " $1 = 1,\n";}
    if ($line =~ /^\s*(e_vert)\s*=/i)  {$line = " $1 = $nwrflevels,\n";}
    if ($line =~ /^\s*(start_year)\s*=/i)  {$line = " $1 = $year_beg,\n";}
    if ($line =~ /^\s*(start_month)\s*=/i) {$line = " $1 = $month_beg,\n";}
    if ($line =~ /^\s*(start_day)\s*=/i)   {$line = " $1 = $day_beg,\n";}
    if ($line =~ /^\s*(start_hour)\s*=/i)  {$line = " $1 = $hour_beg,\n";}
    if ($line =~ /^\s*(start_minute)\s*=/i)  {$line = " $1 = $min_beg,\n";}
    if ($line =~ /^\s*(start_second)\s*=/i)  {$line = " $1 = $sec_beg,\n";}
    if ($line =~ /^\s*(end_year)\s*=/i)    {$line = " $1 = $year_end,\n";}
    if ($line =~ /^\s*(end_month)\s*=/i)   {$line = " $1 = $month_end,\n";}
    if ($line =~ /^\s*(end_day)\s*=/i)     {$line = " $1 = $day_end,\n";}
    if ($line =~ /^\s*(end_hour)\s*=/i)    {$line = " $1 = $hour_end,\n";}
    if ($line =~ /^\s*(end_minute)\s*=/i)    {$line = " $1 = $min_end,\n";}
    if ($line =~ /^\s*(end_second)\s*=/i)    {$line = " $1 = $sec_end,\n";}
    if ($line =~ /^\s*(interval_seconds)\s*=/i) {$line = " $1 = $interval_sec,\n";}
   print WNL "$line";
 }
  close (WNL);
  system("cp $workdir/namelist.input $wrfnl");
}
my ($walltime,$jobid,$pbsserver);
if ($opt_q) {
  print WPLOG "Preparing to run using PBS.\n";
  my $pbsscript = "$workdir/qsub_wrfprep.sh";
  my ($nodetype,$walltime);
  # Get the user options for the PBS job submission

  print WPLOG "Setting up PBS/SGE config\n";
  if ($opt_c) {
    $nodetype = $opt_c;
  }else{
    $nodetype = "comp";
  }
  $walltime = $opt_q;

  my $pbscfg = "#PBS -lnodes=$nprocreal:$nodetype,walltime=$walltime";

  # Account for ijet custome setup-mpi script
  my $setupmpi;
  if (-e "/usr/local/bin/setup-mpi.sh"){
    $setupmpi = "/usr/local/bin/setup-mpi.sh";
  }else{
    $setupmpi = "$installroot/etc/setup-mpi.sh";
  }
  print WPLOG "Creating PBS script: $pbsscript\n"; 
  open (PBS, ">$pbsscript");
  print PBS "#!/bin/sh\n";
  print PBS "$pbscfg\n";
  # Add SGE syntax directives for jet/ijet:
  print PBS "#\$ -S /bin/ksh\n";
  print PBS "#\$ -pe $nodetype $nprocreal\n";
  print PBS "#\$ -l h_rt=$walltime\n";
  print PBS "#\n";
  print PBS "# real.exe is an mpi program, even though it uses only 1 process.\n";
  print PBS ". $setupmpi\n";
  print PBS "cd $workdir\n";
  print PBS "echo \$PBS_JOBID > $hinterplog\n";
  print PBS "echo \$PBS_NODEFILE >> $hinterplog\n";
  print PBS "$hinterpexe >> $hinterplog 2>&1\n";
  print PBS "#\n";
  print PBS "echo \$PBS_JOBID > $vinterplog\n";
  print PBS "echo \$PBS_NODEFILE >> $vinterplog\n";
  print PBS "$vinterpexe >> $vinterplog 2>&1\n";
  print PBS "#\n";
  if ((-e "$realexe") and ($opt_r)){
    print PBS "echo \$PBS_JOBID > $reallog\n";
    print PBS "echo \$PBS_NODEFILE >> $reallog\n";
    if ($opt_r =~ /p/i){
      print PBS "/usr/pgi/linux86/bin/mpirun -np $nprocreal $realexe >> $reallog 2>&1\n";
      print PBS "rm -f \$GMPICONF\n";
    }else{
      print PBS "$realexe >> $reallog 2>&1\n";
    }
  }
  print PBS "exit\n";
  close (PBS);
  chmod 0777, "$pbsscript";
  my $command;
  if ($opt_u){
    $command = "/bin/qsub -A $opt_u -V -Nwrfprep $pbsscript";
  }else{
    $command = "/bin/qsub -V -Nwrfprep $pbsscript";
  }
   

  system ("$command > qsub.out");

  # Now, we need to wait until the job is complete before moving on.
  # On jet at FSL, we can use the wait_job script.  On other systems
  # with PBS, we will use qstat if wait job is not available.  In either
  # even, we need to get the job number.
  open (JF, "qsub.out");
  my @lines = <JF>;
  close (JF);
  foreach (@lines){
   if (/(\d{1,})/) {
     $jobid = $1;
     #$pbsserver = $2;
    }
  }
  if (! $jobid){
    print WPLOG "Problem with job submission...here is output:\n";
    print WPLOG "@lines\n";
    $timenow = `date -u`; chomp $timenow;
    print WPLOG "Died at $timenow\n";
    close (WPLOG);
    die;
  }
  if (-e "/bin/wait_job"){
    my $qsubwait = &wrfsi_utils::qsub_hms2sec($walltime) + 300;
    print WPLOG "Using wait_job $jobid $qsubwait\n";
    system("/bin/wait_job $jobid $qsubwait");
  }else{
    # Go into a loop using qstat and grep to
    # check if job is running
    my $stdout = "$workdir/wrfprep.o$jobid";
    my $jobcheck = `/bin/qstat | grep $jobid`;
    while ( ($jobcheck) or (! -e "$stdout") ){
       sleep 10;
       $jobcheck = `/qstat | grep $jobid`;
    }
  }
  $timenow = `date -u`; chomp $timenow;
  print WPLOG "Programs complete at $timenow\n";
  
  # Check to see if we got output from all appropriate stages...
  my $result = system("ls $workdir/hinterp.d??.$endtimefile"); 
print "HINTERP ls result: $result\n";
  if ($result) {
    print WPLOG "FAILURE: hinterp failed to complete.\n";
    print WPLOG "  --- See $hinterplog\n";
    close (WPLOG);
    die;
  }
  $result = system("ls *real_input*.d??.$endtimefile");
  if ($result){
    print WPLOG "FAILURE: vinterp failed to complete.\n";
    print WPLOG "  --- See $vinterplog\n";
    close (WPLOG);
    die;
  }
  if ( ((! -e "$workdir/wrfinput_d01")or    
        (! -e "$workdir/wrfbdy_d01")) and $opt_r){
    print WPLOG "FAILURE: real failed to complete.\n";
    print WPLOG "  --- See $reallog\n";
    close (WPLOG);
    die;
  }

# No PBS, run on this node

}else{

  $timenow = `date -u`; chomp $timenow;
  print WPLOG "$timenow : Running hinterp\n";
  system("$hinterpexe > $hinterplog 2>&1");
  $timenow = `date -u`; chomp $timenow;
  print WPLOG "$timenow : hinterp finished.\n";
  my $errcode = system("ls $workdir/hinterp.d??.$endtimefile");
  if ($errcode){ 
    print WPLOG "FAILURE: hinterp failed to complete.\n";
    print WPLOG "  --- See $hinterplog\n";
    close (WPLOG);
    die;
  }
  $timenow = `date -u`; chomp $timenow;
  print WPLOG "$timenow : Running vinterp\n";
  system("$vinterpexe > $vinterplog 2>&1");
  $timenow = `date -u`; chomp $timenow;
  print WPLOG "$timenow : vinterp finished.\n";
  my $errcode = system("ls $workdir/*real_input*.d??.$endtimefile");
  if ($errcode){
    print WPLOG "FAILURE: vinterp failed to complete.\n";
    print WPLOG "  --- See $vinterplog\n";
    close (WPLOG);
    die;
  }

  if ((-e "$realexe")and($opt_r)){
    $timenow = `date -u`; chomp $timenow;
    print WPLOG "$timenow : Running real\n";
    if ($opt_r =~ /p/i){
      # Run mpi version
      system("/usr/pgi/linux86/bin/mpirun -np $nprocreal $realexe > $reallog");
    }else{
      # Run serial version
      system("$realexe > $reallog 2>&1");
    }
    $timenow = `date -u`; chomp $timenow;
    print WPLOG "$timenow : real finished.\n";
    if (-e "$workdir/rsl.out.0000") {
      system("cat $workdir/rsl.out.* >> $reallog");
    }
    if ((! -e "$workdir/wrfinput_d01")or
       (! -e "$workdir/wrfbdy_d01")){
      print WPLOG "FAILURE: real failed to complete.\n";
      print WPLOG "  --- See $reallog\n";
      close (WPLOG);
      die;
    }
  }
}

$timenow = `date -u`; chomp $timenow;

# We made it this far, so create a CYCLE file
open (CF,">$workdir/CYCLE.$cycleid");
print CF "WRF initialization files created on $timenow <br>\n";
print CF "Initialization Source:        $initsrc <br>\n";
print CF "Lateral Boundary Conditions:  $lbcsrc <br>\n"; 
print CF "LBC Interval:                 $interval <br>\n";
if ($opt_r){
  print CF "WRF time_step_max:            $time_step_max <br>\n";
  print CF "WRF output freq (min)         $output_freq_min <br>\n";
}
close (CF);

print WPLOG "$timenow : wrfprep.pl ended normally.\n";
close (WPLOG);

# Clean up
opendir (WDIR, "$workdir");
foreach (readdir WDIR){
  if ((! /CYCLE.$cycleid/) and (! /^wrfinput_/) and (! /^wrfbdy_/) and
     (! /^namelist.input$/) and (! /^wrfprep.\w$jobid/) and 
     (! /^rsl.\w*.\d\d\d\d/) and (! /^hinterp/) and (! /real_input_/)) {
    unlink "$workdir/$_";
  }else{
    if (/^wrfprep.\w$jobid/){
      system ("echo $_ >> $wrfpreplog");
      system ("cat $workdir/$_ >> $wrfpreplog"); 
      unlink "$workdir/$_";
    }
    if (/^rsl.\w*.\d\d\d\d/) {
      system("echo $_>> $reallog");
      system("cat $workdir/$_ >>$reallog");
      unlink "$workdir/$_";
    }
  }
}

exit;
