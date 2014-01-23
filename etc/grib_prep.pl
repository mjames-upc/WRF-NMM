#!/usr/bin/perl
umask 000; # So that the intermediate files created by grib_prep.pl can
           # be more easily deleted as their size can really add up.
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

# Script Name:  grib_prep.pl
#
# Purpose:  Runs grib_prep.exe for a given model source.
#
# Usage:
#
#      grib_prep.pl source [-i $INSTALLROOT ] [-d $EXT_DATAROOT] 
#                        [-s startdate ] [ -l fcstlen ] [ -t interval ]
#              source = Source data name (must be in the grib_prep.nl SRCNAME)
#
#        INSTALLROOT = location of compiled wrfsi binaries and scripts
#        EXT_DATAROOT = top level directory of grib_prep output and 
#                        configuration data.
#        startdate = YYYYMMDDHH format (optional, otherwise system clock
#                                       is used)
#
#        fcstlen = Number of output hours from start time to produce
#                  output
#        interval = interval between output files in hours
###############################################################################

require 5;
use strict;
use vars qw($opt_c $opt_h $opt_i $opt_d $opt_f $opt_s $opt_l 
            $opt_P $opt_q $opt_t $opt_u);
use Getopt::Std;

print "Routine: grib_prep.pl\n";
my $mydir = `pwd`; chomp $mydir;

getopts('c:hi:d:f:s:l:Pq:t:u:');

if ($opt_h){
    print "grib_prep.pl Usage
          =================
          grib_prep.pl [options] source

          source: which data source to process.  Name supplied must 
                  match one found in the SRCNAME array of grib_prep.nl

          Valid options
          -------------

          -c nodetype
             Type of compute node to use when using PBS
 
          -d EXT_DATAROOT
             Used to set/override the EXT_DATAROOT environment var.

          -f filter
             Used to set a Perl-syntax pattern-match filter to
             apply when looking for GRIB files.  Exclude the 
             bounding / marks on each side. 
          -h
             Prints this help menu

          -i INSTALLROOT
             Used to set/override the WRFSI INSTALLROOT environment var.

          -l Forecast length in hours
             Set the number of forecast hours the data should span.  If
             not set, this will default to 36 hours.

          -P
             Tells grib_prep to purge older files.  This is primarily used
             for real-time users

          -q hh:mm:ss 
             Submit job using PBS qsub routine with this maximum wall time

          -s YYYYMMDDHH
             Cycle time to use for initial time. If not set, the script
             uses the real-time clock in conjuntion with variables in
             the grib_prep.nl file to determine this time.

          -t hours
             Desired interval between output files.  The default if not
             set is 3-hourly output. 
 
          -u Set a user ID for PBS (qsub) use \n";
exit;
}

          
# Get user specified installroot and dataroot.  If they are not
# present, then use environment variables.

my ($installroot, $dataroot);
if (! defined $opt_i){
  if (! $ENV{INSTALLROOT}){
    # Get installroot from script name
    my $scriptname = $0;
    my $curdir = `pwd`; chomp $curdir;
    if ($scriptname =~ /^(\S{1,})\/grib_prep.pl/){
      chdir "$1/../";
    }else{
      chdir "..";
    }
     $installroot = `pwd`; chomp $installroot;
     chdir "$curdir";
     $ENV{INSTALLROOT} = $installroot;
  }else{
    $installroot = $ENV{INSTALLROOT};
  }
}else{
  $installroot = $opt_i;
}
if (! defined $opt_d){
  if (! $ENV{EXT_DATAROOT}){
    $dataroot = "$installroot/extdata";
    $ENV{EXT_DATAROOT}="$dataroot";
  }else{
    $dataroot = $ENV{EXT_DATAROOT};
  }
}else{
  $dataroot = $opt_d;
  $ENV{EXT_DATAROOT} = $dataroot;
}

require "$installroot/etc/wrfsi_utils.pm";

# Get command line arguments
my ($source) = @ARGV;

if (! defined $source) {die "
Need one command line argument, for example:\n
     grib_prep.pl source
     source is model name (AVN or ETA);
\n"};

# Set up some variables to hold directory names, namelist file names,
# etc. for convenience
my $runtime = `date -u +%H%M`; chomp $runtime;
my $nlfilename = "$dataroot/static/grib_prep.nl";
my $workdir = "$dataroot/work/$source";
my $gribprepexe = "$installroot/bin/grib_prep.exe";
print "WORKDIR = $workdir \n";
# Make sure executable is present.

if (! -f "$gribprepexe"){
  die "$gribprepexe does not exist.  Make sure your INSTALLROOT is set
correctly and you have compiled everything.\n";
}

# Make sure dataroot exists.

if (! -d "$dataroot"){
  die "Your specified EXT_DATAROOT does not exist! \n";
}

# Do we need to make the work directory?
if (! -d "$dataroot/work"){
  mkdir "$dataroot/work", 0777 or die "Cannot create top work directory.\n";
}
if (! -d "$workdir"){
  mkdir "$workdir", 0777 or die "Cannot create $workdir. \n";
}

# Is the namelist present?

if (! -f "$nlfilename"){
  die "The namelist: $nlfilename is not found! \n";
}

# OK, if we made it this far we are ready to start.  

# Go to work directory, clean it out, then copy in the Vtable
chdir $workdir;

# Clean up work space
opendir(WORK,$workdir);
foreach (readdir WORK) {
  if (/GRIBFILE/) {unlink "$workdir/$_";}
  if (/Vtable/)   {unlink "$workdir/$_";}
  if (/PFILE:/)   {unlink "$workdir/$_";}
  if (/grib_prep:/)   {unlink "$workdir/$_";}
  }
closedir(WORK);  

# Read the namelist to get default values

print "Opening $nlfilename \n";
open(NL, "$nlfilename");
my @nllines = <NL>;
close(NL);
my %namehash = &wrfsi_utils::get_namelist_hash(@nllines);

# Make sure the requested source is specified in the 
# SRCNAME entry of the namelist
my $srcind = -1;
my @srcname = @{$namehash{"SRCNAME"}};
my $srccnt = @srcname;
if ($srccnt < 1) { die "No sources specified in SRCNAME in grib_prep.nl!\n" }
my $counter = 0;
while (($counter < $srccnt) and ($srcind < 0)){
  if ("$srcname[$counter]" eq "$source"){
    $srcind = $counter;
  }
  $counter++;
}

if ($srcind < 0) { die "$source not found in grib_prep.pl SRCNAME\n"}

# Make sure source has vtable supported.
my $vtabext = ${$namehash{"SRCVTAB"}}[$srcind];
my $vtable = "$dataroot/static/Vtable.$vtabext";
if (!-f "$vtable"){
  die "$vtable not found.  Is this source supported?\n";
}
print "Copying $vtable \n";
system ("cp $vtable Vtable");
my ($startdate, $enddate, $interval, $startyear, $startmonth, $startday, 
    $starthour, $endyear, $endmonth, $endday, $endhour);

# Determine starting time string. It is either defined on the command
# line (opt_s) or we use the real-time system clock along with some
# of the namelist entries.

my $timenow = `date -u +%Y%m%d%H`;
if (defined $opt_s){ 
  $startdate = $opt_s;
}else{
  $startdate = $timenow;
}
my $waittime = ${$namehash{"SRCDELAY"}}[$srcind];
my $freq = ${$namehash{"SRCCYCLE"}}[$srcind];

# If we used the system clock, we need to adjust by
# the cycle delay for this model source.  Otherwise,
# we may or may not need to adjust.
if(! $opt_s) {
  $startdate = &wrfsi_utils::compute_time($startdate,"-$waittime");
}else{
  # Determine latest available start date that could be used
  # based on actual current time
  my $latest_avail = &wrfsi_utils::compute_time($timenow,"-$waittime");
  if ($startdate gt $latest_avail) {
    print "Setting startdate ($startdate) to latest_avail ($latest_avail) 
based on actual current time.\n";
    $startdate = $latest_avail;
  }
}
  

# Parse out hour and change to nearest cycle time
if ($startdate =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)$/){
  $startyear = $1;
  $startmonth = $2;
  $startday = $3;
  $starthour = $4;
}else{
    print "Unrecognized date format. Should be YYYYMMDDHH. \n";
    exit;
}
if (! $opt_s){
  $starthour = int($starthour/$freq)*$freq;
}
$starthour = "0".$starthour while(length($starthour)<2);
$startdate = $startyear.$startmonth.$startday.$starthour;

# Get ending time.

my $fcstlen;
if (defined $opt_l){
  $fcstlen = $opt_l;
}else{
  $fcstlen = 36;
}
$enddate = &wrfsi_utils::compute_time($startdate, $fcstlen);
if ($enddate =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)$/){
  $endyear = $1;
  $endmonth = $2;
  $endday = $3;
  $endhour = $4;
}else{
    print "Unrecognized date format. Should be YYYYMMDDHH. \n";
    exit;
}

# Get interval

my $interval_hr;
if (defined $opt_t){
  $interval = $opt_t*3600;
  $interval_hr = $opt_t;
}else{
  $interval = ${$namehash{INTERVAL}}[0];
  $interval_hr = int($interval/3600);
}

# Update the namelist

print "Writing $workdir/grib_prep.nl \n";
open (NL, ">$workdir/grib_prep.nl");
my $line;
foreach $line (@nllines){
  if ($line =~ /^\s*(START_YEAR)\s*=/i)  {$line = " $1 = $startyear\n";}
  if ($line =~ /^\s*(START_MONTH)\s*=/i) {$line = " $1 = $startmonth\n";}
  if ($line =~ /^\s*(START_DAY)\s*=/i)   {$line = " $1 = $startday\n";}
  if ($line =~ /^\s*(START_HOUR)\s*=/i)  {$line = " $1 = $starthour\n";}
  if ($line =~ /^\s*(END_YEAR)\s*=/i)    {$line = " $1 = $endyear\n";}
  if ($line =~ /^\s*(END_MONTH)\s*=/i)   {$line = " $1 = $endmonth\n";}
  if ($line =~ /^\s*(END_DAY)\s*=/i)     {$line = " $1 = $endday\n";}
  if ($line =~ /^\s*(END_HOUR)\s*=/i)    {$line = " $1 = $endhour\n";}
  if ($line =~ /^\s*(INTERVAL)\s*=/i)    {$line = " $1 = $interval\n";}
  print NL "$line";
  }
close(NL);       
my $logfile = "$dataroot/log/gp_$source.$startyear$startmonth$startday$starthour.log";
my $logfileexe = "$logfile.exe";
open (LOG, ">$logfile");

# Time to link in all of the required Gribfiles in our current working
# directory.  They should be copied or linked using the file name
# GRIBFILE.AA, GRIBFILE.AB, etc.

# First, convert time to use YYJJJ format
my @t = &wrfsi_utils::convert_time($startdate);
my  $yr2_start = $t[5] - 100; 
$yr2_start = "0".$yr2_start while (length($yr2_start)<2); 
my $jday_start = $t[7] + 1;
$jday_start = "0".$jday_start while (length($jday_start)<2);
$jday_start = "0".$jday_start while (length($jday_start)<3);
my $day_start = $t[3];
$day_start = "0".$day_start while (length($day_start)<2);
my $mm_start = $t[4] + 1;
$mm_start = "0".$mm_start while (length($mm_start)<2); 

my $rawdir = ${$namehash{"SRCPATH"}}[$srcind];
opendir(GRIBDIR, $rawdir) or die 
  "Raw data directory cannot be opened: $rawdir \n";

my @allfiles = sort readdir(GRIBDIR);
my (@gribfiles, $ngribfiles, $ihour, $fhour);

$ngribfiles = 0;

if ($opt_f) {
  print LOG "Using specified filter: $opt_f\n";
  foreach(@allfiles) {
    if (/$opt_f/) {
      @gribfiles = (@gribfiles, $_);
    }
  }
  $ngribfiles = @gribfiles;
  if ($ngribfiles == 0) {
    print LOG "No files found for this filter.\n";
    close (LOG);
    exit;
  }
}

if ($ngribfiles == 0){
# Look for filenames that use the FSL convention (yyjjjhhmmffff)
my $FSLfilter = $yr2_start.$jday_start.$starthour."00";
print "FSLfilter = $FSLfilter \n";
my $foundFSL = 0;
foreach (@allfiles) {
  if ( (/^$FSLfilter(\d\d\d\d)$/)or(/^$FSLfilter(\d\d\d\d).grib$/)) {
    $foundFSL = 1;
    $fhour = $1;
    if (($fhour <= $fcstlen+$freq) and (($fhour % $interval_hr) == 0)){
      @gribfiles = (@gribfiles,$_);
} } 
  $ngribfiles = @gribfiles;
}

if ($foundFSL == 1 && $ngribfiles == 0) {
  my $msg = "FAILURE: Found FSL-type files but nothing in the specified time window.";
  print "$msg\n";
  print LOG "$msg\n";
  exit;
}
# If that didn't work try an NCEP filenaming convention
# (e.g. ???.ThhZ.??????ff.????
#   and ???.ThhZ.??????fff.????)

if ($ngribfiles == 0) {
  foreach (@allfiles) {
    if (/^$source\.T(\d\d)Z\.\w\w\w\w\w\w(\d\d+)/i) {
      $ihour = $1; $fhour = $2;
      if ($ihour == $starthour) {
        if (($fhour <= $fcstlen+$freq)and(($fhour % $interval_hr)==0)) {
          @gribfiles = (@gribfiles,$_);
} } } } 
  $ngribfiles = @gribfiles;                 
}

# Here is a second NCEP Grib file naming convention
if ($ngribfiles == 0) {
  foreach (@allfiles) {
    if (/T(\d\d)Z\.PGrbF(\d*)/i) {
      $ihour = $1; $fhour = $2;
      if ($ihour == $starthour) {
        if (($fhour <= $fcstlen+$freq)and(($fhour % $interval_hr)==0)) {
          @gribfiles = (@gribfiles,$_);
} } } } 
  $ngribfiles = @gribfiles;
}

# Here's yet another NCEP filenaming convention (???_yymmdd_hh_ff
#                                            and ???_yymmdd_hh_fff)

my $NCEPfilter = $yr2_start.$mm_start.$day_start;
if ($ngribfiles == 0) {
  foreach (@allfiles) {
    if (/^$source\_(\d\d\d\d\d\d)\_(\d\d)\_(\d+)$/i) {
      my $yymmdd = $1; $ihour = $2; $fhour = $3;
      if ($yymmdd == $NCEPfilter) {
        if ($ihour == $starthour) {
          if (($fhour <= $fcstlen+$freq)and(($fhour % $interval_hr)==0)) {
            @gribfiles = (@gribfiles,$_);
          } 
        } elsif ($source == "fnl" and $fhour == "00") {
          # Here's an NCAR mass store file naming convention (???_yymmdd_hh_00)
          # Each file, in the time series, is actually a separate analysis.  
          # There are no forecasts.  So fnl_040330_00_00 is the 00Z analysis on 3/30, 
          # while fnl_040330_06_00 is the 06Z analysis on the same day. So, when 
          # you use these data, you are using a sequence of consecutive analyses.
          @gribfiles = (@gribfiles,$_);
} } } }  
  $ngribfiles = @gribfiles;    
}

# Here is a string for AFWAs AGRMET GRIB files
if ($ngribfiles == 0) {
  foreach (@allfiles) {
    if (/agrmet\.grib\.\d*hr\.(\d\d\d\d\d\d\d\d\d\d)$/) {
      my $valtime = $1;
      if (($valtime ge $startdate) and ($valtime le $enddate)){
         @gribfiles = (@gribfiles,$_);
      }
    }
  }
  $ngribfiles = @gribfiles;
}

# Try looking for GRIBFILE.xx
if ($ngribfiles == 0) {
  foreach (@allfiles) {
    if (/GRIBFILE\.\w\w/i) {@gribfiles = (@gribfiles,$_);}
} 
  $ngribfiles = @gribfiles;
}

# One last try.  We'll link to all filenames that contain the
# name of the model.

if ($ngribfiles == 0) {
  foreach (@allfiles) {
    if (/$source/i) {@gribfiles = (@gribfiles,$_);}
} 
  $ngribfiles = @gribfiles;
}

# If no filter worked, link to all non-dotfiles.

if ($ngribfiles == 0) {
  print "Filters returned zero gribfiles; linking all.\n";
  print LOG "Filters returned zero gribfiles; linking all.\n";
  foreach (@allfiles) {if (!/^\./) {@gribfiles = (@gribfiles,$_);}}
  $ngribfiles = @gribfiles;
  if ($ngribfiles == 0)
           {print "Warning!  Gribfile directory appears empty!\n";}
} 
}  
# Create a soft link to each GRIB file.

my $id = "AA";
foreach (@gribfiles) {
  symlink "$rawdir/$_", "$workdir/GRIBFILE.$id";
  print LOG "Linking: $rawdir/$_ $workdir/GRIBFILE.$id\n";
  $id++;
}
# Run the executable
my ($command, $maxruntime, $qsubsec);
if (! $opt_q){
  $command = $gribprepexe;
}else{
  my $nodetype;
  if ($opt_c){
    $nodetype=$opt_c;
  }else{
    $nodetype="comp";
  }
  # Compute the amount of run time in seconds by parsing string
  $qsubsec = &wrfsi_utils::qsub_hms2sec($opt_q);
  print LOG "Max job time in seconds = $qsubsec\n";
  open(QS,">$workdir/qsub_grib_prep.ksh");
  print QS "#!/bin/ksh\n";
  print QS "#PBS -l walltime=$opt_q,nodes=1:$nodetype\n";
# 
# SGE syntax for ijet/jet at FSL
  print QS "#\$ -S /bin/ksh\n";
  print QS "#\$ -pe $nodetype 1\n";
  print QS "#\$ -l h_rt=$opt_q\n";

  print QS "cd $workdir\n";
  print QS "$gribprepexe > $logfileexe 2>&1\n";
  print QS "exit\n";
  close(QS);
  chmod 0777, "qsub_grib_prep.ksh";
}

my $started = `date -u`;
print LOG "Starting $gribprepexe at $started \n";
my $status;
if ($opt_q){
  my ($jobid,$jobserver);
  my $qcommand;
  if ($opt_u){
    $qcommand = "/bin/qsub -A $opt_u -V -N wrfsi_gp qsub_grib_prep.ksh";
  }else{
    $qcommand = "/bin/qsub -V -N wrfsi_gp qsub_grib_prep.ksh";
  }
  my $status = system "$qcommand > jobfile.txt";
  open(JF,"jobfile.txt");
  my @joblines = <JF>;
  close(JF);
  #unlink "jobfile.txt";
  foreach (@joblines){
    if (/(\d{1,})/) {
      $jobid = $1;
      #$jobserver=$2;
    }
  }
  print LOG "Job ID # = $jobid.$jobserver\n";
  my $stdout = "$workdir/wrfsi_gp.o$jobid";
  print LOG "Std output will be in $stdout\n";
  if (-f "/bin/wait_job"){
    my $qsubwait = $qsubsec + 120;  # Allows for 2 minutes in queue
    print LOG "Using wait_job $jobid $qsubwait -v\n";
    system("/bin/wait_job $jobid $qsubwait -v >> $logfile");
  }else{
    my $jobcheck = `/bin/qstat | grep $jobid`;
    while ( ($jobcheck) and (! -f "$stdout" ) ){
       sleep 5;
       $jobcheck = `/bin/qstat | grep $jobid`;
    }
  }
  unlink "qsub_grib_prep.ksh";
}else{
 $status = system ("$gribprepexe> $logfileexe 2>&1");
}
my $finished = `date -u`;
print LOG "Termination of grib_prep at $finished.\n";

opendir(MODELFILES,$workdir);
foreach (readdir MODELFILES) {
  if (/^FILE:(\S*)/) {rename "$workdir/$_", "$dataroot/extprd/$source:$1";}
}
closedir(MODELFILES);

# Clean up work space
opendir(WORK,$workdir);
foreach (readdir WORK) {
  if (/GRIBFILE/) {unlink "$workdir/$_";}
  if (/Vtable/)   {unlink "$workdir/$_";}
  if (/^PFILE:/)   {unlink "$workdir/$_";}
  if (/grib_prep\.nl/) { unlink "$workdir/$_";}
  if (/wrfsi_gp\.\w\d*/) {
    print LOG "\n";
    print LOG "============================================\n";
    print LOG "$_\n";
    print LOG "============================================\n";
    my $line;
    open(LF,"$_");
    foreach $line (readline *LF) {
      print LOG "$line";
    }
    close LF;
    print LOG "\n";
    unlink "$workdir/$_";}
  }
closedir(WORK);  

if ( -f "$logfileexe" ) {
  print LOG "\n";
  print LOG "============================================\n";
  print LOG "Log from program execution\n";
  print LOG "============================================\n"; 
  open (LF, "$logfileexe");
  foreach (readline *LF) {
    print LOG "$_";
  }
  close LF;
  unlink "$logfileexe";
  chmod 0666, "$logfile";
}
close LOG;
chmod 0666, "$logfile";

# Clean up old files (this should be done in a purger script eventually).

my $wrfsi_start = $startyear."-".$startmonth."-".$startday."_".$starthour;
my $wrfsi_end = $endyear."-".$endmonth."-".$endday."_".$endhour;
opendir (DATACOM, "$dataroot/extprd");
foreach (readdir DATACOM) {
  if (/^$source\D(\d\d\d\d\D\d\d\D\d\d\D\d\d)/i){
    if ( $1 lt $wrfsi_start ){
      if ($opt_P){
        unlink "$dataroot/extprd/$_";
        print "Purging $dataroot/extprd/$_\n";  
      }
    }else{
      # If this is an SST or SNOW file, link it to 
      # generic ${SOURCE}DATA file name for easier use in REGRID
      if ($source eq "SST" or $source eq "SNOW" or $source eq "AGRMET"){
        if (-l "$dataroot/extprd/$source"."DATA"){
          unlink "$dataroot/extprd/$source"."DATA";
        }
        #rename "$dataroot/extprd/$_", "$dataroot/extprd/$source"."DATA";
        symlink "$dataroot/extprd/$_", "$dataroot/extprd/$source"."DATA";
      }     
    }
  }
}
closedir(DATACOM);

exit;


