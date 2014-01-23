#!/usr/bin/perl
#
#
#Program either localizes (new) or re-localizes (existing)
#laps domains
#J.Smart 8-20-99
#   "    6-28-01 - renamed to window_domain_rt.pl: general purpose
#                  upgrade for WRFSI.
#
use strict;
use English;
use vars qw($opt_s $opt_i $opt_d $opt_t $opt_w $opt_c $opt_m $opt_h $opt_q);
use Getopt::Std;
use File::Copy 'cp';
use Cwd;

getopts('s:i:d:t:w:q:hmc');

umask 002;

# We need to make sure ncgen is accessible for gridgen_model.exe

$ENV{PATH}="$ENV{PATH}:$ENV{NETCDF}/bin";

# --------------- Notes for command line inputs -------------------------------
# opt_s is LAPS_SRC_ROOT override
# opt_i is LAPSINSTALLROOT override
# opt_d is LAPS_DATA_ROOT (eg., /data/lapb/parallel/laps/data) override.
#       if the data root does not exist, then it is created.
#
# opt_t is template subdirectory (eg., /usr/nfs/common/lapb/parallel/laps/template/"name")
#       The name should be the same as the domain name in LAPS_DATA_ROOT
#       If -t is not defined then it is assumed to be the same as
#       LAPS_SRC_ROOT and -c is disabled.
#
# opt_c controls the removal of entire data root (use command line "-c") or
# saves the log and lapsprd directories          (do not use command line "-c")
#
# opt_m controls laps_localization.pl no_ggm switch. ggm = gridgen_model.
#       if $opt_m is not defined then localize_domain updates the namelists
#       and also runs gridgen_model (producing the static file). If $opt_m
#       is defined then only the namelists are updated (no ggm).
#
# opt_w is which type (either laps or wrfsi).
#
# In some cases LAPSINSTALLROOT = LAPS_SRC_ROOT. This is made possible
# by perl module mkdatadirs in laps_tools.pm. It removes Makefile dependence.
#
# The -m and -c options cannot be used simultaneously.
#
# opt_q qsub project name command line input for localize_domain.pl
# -----------------------------------------------------------------------------


if(defined $opt_h){
   print "\n\n             Help Information:\n";
   print "   ----------------------------------------------------------\n";
   print " -s Use to override the Source Root environment variable if set. \n";
   print " -i Use to override the Install Root environment variable if set. \n";
   print " -d Use to override the Data Root environment variable if set. \n";
   print " -w Mandatory input. Set to 'laps' or 'wrfsi'. \n";
   print " -t Path to template - a subset of namelist variables specific to the domain.\n";
   print " -c Switch to control complete removal of Data Root. Use with caution. \n";
   print " -m Switch to relocalize without regenerating a new static file. Namelist updating.\n";
   print " -q Submit the localization (gridgen_model) to compute node. -q 'project-name'. \n"; 
   print " -h This list of help command descriptions.\n";
   print "\n\n";
   exit;}

if(!defined $opt_w){die "\nYou must decide and use the -w command line input to
                           specify the type of localization desired. Two options:
                           1. -w laps
                           2. -w wrfsi
                           3. -w wrfsi.rotlat\n\n";}

my $domain_type = $opt_w;
my ($LAPS_SRC_ROOT, $LAPSINSTALLROOT, $LAPS_DATA_ROOT, $DATAROOT, $DOMAIN_NAME);

$LAPS_SRC_ROOT = $opt_s if( $opt_s);
$LAPSINSTALLROOT = $opt_i if( $opt_i);
$LAPS_DATA_ROOT = $opt_d if( $opt_d);

my $logname = "log";
my $logfile;
#This should take care of laps and wrfsi. Use LAPS type variables thereafter.
if($domain_type eq "laps"){
   $LAPS_SRC_ROOT = $ENV{LAPS_SRC_ROOT} if( $ENV{LAPS_SRC_ROOT} && !defined $LAPS_SRC_ROOT);
   $LAPSINSTALLROOT = $ENV{LAPSINSTALLROOT} if( $ENV{LAPSINSTALLROOT} && !defined $LAPSINSTALLROOT);
   $LAPS_DATA_ROOT = $ENV{LAPS_DATA_ROOT} if( $ENV{LAPS_DATA_ROOT} && !defined $LAPS_DATA_ROOT);
   $logfile = "localize_domain.log";
}elsif($domain_type eq "wrfsi" || $domain_type eq "wrfsi.rotlat"){
   $LAPS_SRC_ROOT = $ENV{SOURCE_ROOT} if( $ENV{SOURCE_ROOT} && !defined $LAPS_SRC_ROOT);
   $LAPSINSTALLROOT = $ENV{INSTALLROOT} if( $ENV{INSTALLROOT} && !defined $LAPSINSTALLROOT);
   $LAPS_DATA_ROOT = $ENV{MOAD_DATAROOT} if( $ENV{MOAD_DATAROOT} && !defined $LAPS_DATA_ROOT);
}else{
   die "\nUnknown domain type entered with -w command line input: $domain_type.
          You have two options:
          1. -w laps
          2. -w wrfsi
          3. -w wrfsi.rotlat\n\n";
}

if( !-d $LAPS_SRC_ROOT){
    print "SOURCE ROOT does not exist. $LAPS_SRC_ROOT. Exiting.\n";
    exit;
}

$LAPSINSTALLROOT=$LAPS_SRC_ROOT if(! defined($LAPSINSTALLROOT));

if( !-d $LAPSINSTALLROOT){
    print "LAPS INSTALL ROOT does not exist. $LAPSINSTALLROOT. Exiting.\n";
    exit;
}

my $all_roots_equal = "F";
if(! defined($LAPS_DATA_ROOT) ){$LAPS_DATA_ROOT = "$LAPSINSTALLROOT/data";
   if($LAPS_SRC_ROOT eq $LAPSINSTALLROOT){
      $all_roots_equal = "T";
      print "WARNING: All lapsroots are equal\n";
   }
}

# RAR Add
my $domain_dir = $domain_type;
   $domain_dir = "wrfsi" if $domain_type eq "wrfsi.rotlat";
# End RAR

require "$LAPSINSTALLROOT/etc/laps_tools.pm";
$DOMAIN_NAME = &laps_tools::laps_domain_name($LAPS_DATA_ROOT);
$DATAROOT = &laps_tools::laps_data_root($LAPS_DATA_ROOT);

print "\n";

if($LAPS_SRC_ROOT eq $LAPSINSTALLROOT && $all_roots_equal ne "T"){
   my $strlen=length($DATAROOT);
   $DATAROOT = substr($DATAROOT,0,$strlen-1) if(substr($DATAROOT,$strlen,$strlen) eq "/");
   if("$DATAROOT"."$DOMAIN_NAME" eq $LAPS_SRC_ROOT){
      $all_roots_equal = "T";
      print "WARNING: All lapsroots are equal\n";
   }
}

if($all_roots_equal eq "T"){
   if($LAPS_SRC_ROOT eq "/usr/nfs/common/lapb/parallel/$domain_type"){
      print "Re-localizing FSL development area is not allowed\n";
      print "\n";
      print "Laps Src Root  = $LAPS_SRC_ROOT\n";
      print "Install_Root   = $LAPSINSTALLROOT \n";
      print "Laps_Data_Root = $LAPS_DATA_ROOT\n";
      exit;
   }
}

my ($LAPS_TEMPLATE, $CONFIG_DOMAIN);

if($opt_t){
   $LAPS_TEMPLATE = $opt_t;
   if(!-e $LAPS_TEMPLATE){
       print "Error: the template directory you specified does not exist.\n";
       print "Terminating.\n";exit;
   }
}else{
   print "WARNING! no -t (path to template) command line input.\n";
   print "Using SOURCE ROOT (possibly repository) for all namelists\n";
}

if($opt_c){
   $CONFIG_DOMAIN = "true";
}else{
#   print "-c command line not specified. Default set to false \n";
    $CONFIG_DOMAIN = "false";
    print "Generate laps_data_root directory structure\n";
# RAR Change
    &laps_tools::mkdatadirs($LAPS_DATA_ROOT,$LAPS_SRC_ROOT,$domain_dir);
}

print "Source Root    = $LAPS_SRC_ROOT\n";
print "Install Root   = $LAPSINSTALLROOT \n";
print "Data Root      = $LAPS_DATA_ROOT\n";
print "Template Path  = $LAPS_TEMPLATE \n";
print "Config Domain  = $CONFIG_DOMAIN \n";

if($opt_m && $CONFIG_DOMAIN eq "true"){
   print "\n-m and -c cannot be used simultaneously!
           Reconsider the command line inputs.
           Aborting window_domain_rt.pl\n\n";
   exit;
}

#check to see if any saved static and cdl subdirectories got moved to _err; if so, remove.
if( -e "$LAPS_DATA_ROOT/static\_err" ){
   print "removing leftover $LAPS_DATA_ROOT/static\_err\n";
   system("rm -rf $LAPS_DATA_ROOT/static\_err");
}
if( -e "$LAPS_DATA_ROOT/cdl\_err" ){
   print "removing leftover $LAPS_DATA_ROOT/cdl\_err\n";
   system("rm -rf $LAPS_DATA_ROOT/cdl\_err");
}

# WFO: 1st time - save the existing LAPS_DATA_ROOT (in $FXA_DATA/laps_data) before removing it.
#                 softlink data to laps_data appropriately (make "repository" data subdirectory..
#                 otherwise: test if softlink has been broken re-establish it.
if( defined $ENV{FXA_DATA} &&  $all_roots_equal eq "F" ) {

   my $FXA_DATA = $ENV{FXA_DATA};
   my $LAPS_HOME = $ENV{"LAPS_HOME"};

#test if first time "data" and link need to be established
   if( ! -d "$FXA_DATA/laps_data"){
       mkdir "$FXA_DATA/laps_data", 0777 or die "Can't make directory $FXA_DATA/laps_data";
       system("cp -pr $LAPS_DATA_ROOT/static $FXA_DATA/laps_data/.");
       system("cp -pr $LAPS_DATA_ROOT/cdl $FXA_DATA/laps_data/.");
       system("rm -f $FXA_DATA/laps_data/static/lvd/goes-llij\*.lut");
       system("rm -f $LAPS_HOME/data") if( -e "$LAPS_HOME/data");
       system("ln -s $FXA_DATA/laps_data $LAPS_HOME/data");

#test if "repository" (link) exists
   }elsif(!-e "$LAPS_HOME/data" ){
       print "re-establish softlink $LAPS_HOME/data -> $FXA_DATA/laps_data \n";
       system("ln -s $FXA_DATA/laps_data $LAPS_HOME/data");


#test if link directory exists but link is broken
   }elsif(!-l "$LAPS_HOME/data" ){
       print "re-establish softlink $LAPS_HOME/data -> $FXA_DATA/laps_data \n";
       if(-e "$LAPS_HOME/data" ){system("rm -rf $LAPS_HOME/data");}
       system("ln -s $FXA_DATA/laps_data $LAPS_HOME/data");

#test if link exists but is the wrong name (this has happened but not sure how)
   }else{
       my $linkname = $LAPS_HOME."/data";
       my $datalink = readlink $linkname;
       my @filename = split '/',$datalink;
       $linkname = @filename[$#filename];
       if ($linkname ne "laps_data"){
          system("rm -rf $LAPS_HOME/data");
          system("ln -s $FXA_DATA/laps_data $LAPS_HOME/data");
       }
   }

   $LAPS_DATA_ROOT = $FXA_DATA."/laps";
}

my $success;

if( $CONFIG_DOMAIN eq "true" ) {
  if( $all_roots_equal eq "F" ){

      if( -e $LAPS_DATA_ROOT ){
          if( $LAPS_DATA_ROOT ne "/data/lapb/operational/laps/data" ||
              $LAPS_DATA_ROOT ne "/data/lapb/parallel/laps/data"){
              print "Removing dataroot: $LAPS_DATA_ROOT\n";
              system("rm -rf $LAPS_DATA_ROOT");
          }else{
              print "This script will not remove this dataroot\n";
              print "dataroot = $LAPS_DATA_ROOT\n";
              exit;
          }
      } 
      if( !-e "$DATAROOT/$DOMAIN_NAME" ){
          system "mkdir -p $DATAROOT/$DOMAIN_NAME";
          die "Can not make $DATAROOT/$DOMAIN_NAME $!\n" unless -e "$DATAROOT/$DOMAIN_NAME";
#         mkdir "$DATAROOT/$DOMAIN_NAME", 0777 or die "Can't make $DATAROOT/$DOMAIN_NAME $!\n";
      }

      if( !-e $LAPS_DATA_ROOT ){
         mkdir "$LAPS_DATA_ROOT", 0777 or die "Can't make directory in $LAPS_DATA_ROOT $!\n";
      }
      print "Generate DATA_ROOT directory structure\n";
      &laps_tools::mkdatadirs($LAPS_DATA_ROOT,$LAPS_SRC_ROOT,$domain_dir);
  }else{
      print "Script will not remove DATA_ROOT when all-roots are equal\n";
      print "Reconsider your command line inputs ... do you really want -c ?\n";
      exit;}

}else{

  if(-e $LAPS_DATA_ROOT ){

     if($all_roots_equal eq "F") {

        print "\n Save static and cdl subdirectories\n";
        print " --------------------------------------\n";

#Note: some "static" directories might be busy and the constructs
#      below do not allow for a safe directory move (rename).
# First check to see if there are leftover static_save and cdl_save.

        if(-e "$LAPS_DATA_ROOT/static\_save"){
           print "Found static_save and removing\n";
           system("rm -rf $LAPS_DATA_ROOT/static_save");
        }
        if(-e "$LAPS_DATA_ROOT/cdl\_save"){
           print "Found cdl_save and removing\n";
           system("rm -rf $LAPS_DATA_ROOT/cdl_save");
        }
# Move existing static and cdl to "_save" and prepare new ones!
        $success=rename "$LAPS_DATA_ROOT/static",  "$LAPS_DATA_ROOT/static\_save";
        $success=rename "$LAPS_DATA_ROOT/cdl",  "$LAPS_DATA_ROOT/cdl\_save";
        mkdir "$LAPS_DATA_ROOT/static", 0777 or die "Can't make $LAPS_DATA_ROOT/static $!\n";
        mkdir "$LAPS_DATA_ROOT/cdl", 0777 or die "Can't make $LAPS_DATA_ROOT/cdl $!\n";

     }else{

        print "All roots are equal.\n";

        if(! -e "$DATAROOT/$DOMAIN_NAME/data_rep"){
           print "Make subdirectory data_rep and save static and cdl for save keeping\n";
           mkdir "$DATAROOT/$DOMAIN_NAME/data_rep",0777 or die "Can't make $DATAROOT/$DOMAIN_NAME/data_rep $!\n";
           system("cp -r $LAPS_DATA_ROOT/static $DATAROOT/$DOMAIN_NAME/data_rep/");
           system("cp -r $LAPS_DATA_ROOT/cdl $DATAROOT/$DOMAIN_NAME/data_rep/");
        }else{
           print "subdirectory data_rep exists! Copy data_rep/static and cdl into data\n";
#          system("rm -rf $LAPS_DATA_ROOT/static"); system("rm -rf $LAPS_DATA_ROOT/cdl");
           system("cp -rf $DATAROOT/$DOMAIN_NAME/data_rep/static $LAPS_DATA_ROOT/");
           system("cp -rf $DATAROOT/$DOMAIN_NAME/data_rep/cdl $LAPS_DATA_ROOT/");
        }

        print "Make data_loc (localized data root).
               This is a safety measure when all roots are equal\n\n";

        $LAPS_DATA_ROOT = "$DATAROOT/$DOMAIN_NAME/data_loc";

        if(! -e $LAPS_DATA_ROOT){
           mkdir $LAPS_DATA_ROOT, 0777 or die "Can't make $LAPS_DATA_ROOT $!\n";
           &laps_tools::mkdatadirs($LAPS_DATA_ROOT,$LAPS_SRC_ROOT,$domain_dir);
        }else{
           system("rm -rf $LAPS_DATA_ROOT/static"); system("rm -rf $LAPS_DATA_ROOT/cdl");
           mkdir "$LAPS_DATA_ROOT/static", 0777 or die "Can't make $LAPS_DATA_ROOT/static $!\n";
           mkdir "$LAPS_DATA_ROOT/cdl", 0777 or die "Can't make $LAPS_DATA_ROOT/cdl $!\n";
        }
     }

  }else{
     print "\nMake a new DATA_ROOT since it did not exit in first place.\n";
     mkdir "$DATAROOT/$DOMAIN_NAME", 0777 or die "Can't make $DATAROOT/$DOMAIN_NAME $!\n";
     &laps_tools::mkdatadirs($LAPS_DATA_ROOT,$LAPS_SRC_ROOT,$domain_dir);
  }

}

my @filelist;
if( defined($LAPS_TEMPLATE) ){
    print "Copy template namelist files from $LAPS_TEMPLATE to $LAPS_DATA_ROOT/static\n";
    opendir(TEMPDIR, $LAPS_TEMPLATE);
    print "LAPS_TEMPLATE is $LAPS_TEMPLATE \n";
    @filelist = readdir TEMPDIR;
    closedir TEMPDIR;
    foreach (@filelist){
    	    print "file is $_ \n";
            if( ! /^\./ && ! /dataroot/ && ! /domain/ ){
               if(-d "$LAPS_TEMPLATE/$_"){
#                 if(!-d "$LAPS_DATA_ROOT/static/$_"){
#                    mkdir "$LAPS_DATA_ROOT/static/$_", 0777 or die "Can't make directory $LAPS_DATA_ROOT/static";
#                 }
                  print "Copy $LAPS_TEMPLATE/$_ directory to $LAPS_DATA_ROOT/static \n";
                  system("cp -pr $LAPS_TEMPLATE/$_ $LAPS_DATA_ROOT/static");
               }else{
                  print "Copy $LAPS_TEMPLATE/$_ file to $LAPS_DATA_ROOT/static \n";
                  system("cp -p  $LAPS_TEMPLATE/$_ $LAPS_DATA_ROOT/static");
                  chmod 0664, "$LAPS_DATA_ROOT/static/$_";
               }
            }
    }
    if(defined $opt_m){
       $success = &restorefiles("ggm");
    }
}else{
   print "No template subdirectory. All roots equal(?): $all_roots_equal.\n";
}

require "$LAPSINSTALLROOT/etc/run_sys.pm";

if( -e $LAPSINSTALLROOT ){chdir "$LAPSINSTALLROOT/etc";
    print "Running $LAPSINSTALLROOT/etc/localize_domain.pl\n";
}elsif ( -e "LAPS_SRC_ROOT/etc") {chdir "$LAPS_SRC_ROOT/etc" or die "Can't chdir to LAPS INSTALL or SRC_ROOTs $!\n";
    print "Running $LAPS_SRC_ROOT/etc/localize_domain.pl\n";
}

#this for backwards compatibility with WRFSI dataroot
#----------------------------------------------------
my (@xdim, @ydim, @num_domains, @pieces);
my @oldWRFSI_Files=qw(static.wrfsi topography.dat topo.dat corners.dat latlon2d.dat latlon.dat);
if($domain_type eq "wrfsi")
{
   if(-e "LAPS_DATA_ROOT/static/wrfsi.nl"){
      @num_domains = &laps_tools::get_nl_value("wrfsi.nl","num_domains",$LAPS_DATA_ROOT); 
      if($#num_domains<=0 && $CONFIG_DOMAIN eq "false")
      {
         if($all_roots_equal eq "T"){
            @num_domains = &laps_tools::get_nl_value("wrfsi.nl","num_domains","$LAPS_SRC_ROOT/data_rep/static","1");
         }else{
            @num_domains = &laps_tools::get_nl_value("wrfsi.nl","num_domains","$LAPS_DATA_ROOT/static\_save","1");
         }
      @xdim        = &laps_tools::get_nl_value("wrfsi.nl","xdim",$LAPS_DATA_ROOT);
      @ydim        = &laps_tools::get_nl_value("wrfsi.nl","ydim",$LAPS_DATA_ROOT);
      }
   }
   if($#xdim > 1)
   {
      &laps_tools::update_nl($LAPS_DATA_ROOT,"wrfsi.nl","xdim",$xdim[0]);
      &laps_tools::update_nl($LAPS_DATA_ROOT,"wrfsi.nl","ydim",$ydim[0]);
   }
#remove existing dataroot files no longer needed
   foreach (@oldWRFSI_Files)
   {
      if(-e "$LAPS_DATA_ROOT/static/$_")
      {
         if( defined $opt_m)
         {
             @pieces=split(".",$_);
             `cp -p $LAPS_DATA_ROOT/static\_save/$_ $LAPS_DATA_ROOT/static/$pieces[0]."d01".pieces[1]`;
         }
         system("rm -f $LAPS_DATA_ROOT/static/$_");
      }
   }
#if num_domains becomes smaller then remove extra wrfsi.d##.cdl files.
   opendir(CDLDIR, "$LAPS_DATA_ROOT/cdl");
   @filelist = readdir CDLDIR;
   closedir CDLDIR;
   foreach (@filelist)
   {
      if(/^wrfsi\.d(\d\d)/)
      {
         if($1 > $num_domains[0])
         {
            `rm -f $LAPS_DATA_ROOT/cdl/$_`;
         }
      }
   }
}
# --------------------------------------------------------------------------------------
# ****************************** Run localize_domain.pl ******************************
# --------------------------------------------------------------------------------------
my $command;
if( $opt_m ){
   print "--no_ggm switch on\n";
   $command = "/usr/bin/perl $LAPSINSTALLROOT/etc/localize_domain.pl --dataroot=$LAPS_DATA_ROOT --srcroot=$LAPS_SRC_ROOT --install_root=$LAPSINSTALLROOT --which_type=$domain_type --no_ggm='t' > $LAPS_DATA_ROOT/$logname/localize_domain.log";

}elsif(defined $opt_q){

   $command = "/usr/bin/perl $LAPSINSTALLROOT/etc/localize_domain.pl --dataroot=$LAPS_DATA_ROOT --srcroot=$LAPS_SRC_ROOT --install_root=$LAPSINSTALLROOT --which_type=$domain_type --qspn=$opt_q > $LAPS_DATA_ROOT/$logname/localize_domain.log";

}else{

   $command = "/usr/bin/perl $LAPSINSTALLROOT/etc/localize_domain.pl --dataroot=$LAPS_DATA_ROOT --srcroot=$LAPS_SRC_ROOT --install_root=$LAPSINSTALLROOT --which_type=$domain_type > $LAPS_DATA_ROOT/$logname/localize_domain.log";

}

print "running localize_domain.pl with this command\n";
print "$command\n";

run_sys::run_sys($command);

# --------------------------------------------------

my $day = `date +%d`;
my $Mon = `date +%h`;
my $yr  = `date +%y`;
my $hr  = `date +%H`;
my $min = `date +%M`;
my $AP  = `date +%p`;
chomp ($day,$Mon,$yr,$hr,$min,$AP);
my $datestring = "$day-$Mon-$yr-$hr:$min-$AP";
my $logfilename = "localize_domain.log.$datestring";

#
# post process static files for WRFSI
# -----------------------------------
if( ($domain_type eq "wrfsi" or $domain_type eq "wrfsi.rotlat") && !defined $opt_m)
{
   $ENV{MOAD_DATAROOT}=$LAPS_DATA_ROOT;
   print "\n";
   print "Run $LAPSINSTALLROOT/bin/staticpost.exe\n";
   $command = "$LAPSINSTALLROOT/bin/staticpost.exe > $LAPS_DATA_ROOT/log/staticpost.log";
   run_sys::run_sys($command);
   print "\n";
   $command = "/usr/bin/perl $LAPSINSTALLROOT/etc/sync_wrfnl.pl $ENV{MOAD_DATAROOT}";
   run_sys::run_sys($command);
   print "\n";
   undef $ENV{MOAD_DATAROOT};
}

if( $all_roots_equal eq "T" && -e "$DATAROOT/$DOMAIN_NAME/data_loc" ){
    print "copy data_loc/static and data_loc/cdl to data\n";
    system("cp -rf $DATAROOT/$DOMAIN_NAME/data_loc/static  $DATAROOT/$DOMAIN_NAME/data/");
    system("cp -rf $DATAROOT/$DOMAIN_NAME/data_loc/cdl  $DATAROOT/$DOMAIN_NAME/data/");
    system("cp $DATAROOT/$DOMAIN_NAME/data_loc/$logname/localize_domain.log $DATAROOT/$DOMAIN_NAME/data/$logname/$logfilename");
    system("rm -rf $DATAROOT/$DOMAIN_NAME/data_loc");
    $LAPS_DATA_ROOT = "$DATAROOT/$DOMAIN_NAME/data";
}

my ($success, @staticfile, $dnum, $namelist, $i);
if($domain_type eq "laps")
{
   $staticfile[0]="static.nest7grid";
   $namelist  ="nest7grid.parms";
   $num_domains[0]=1;
}
elsif($domain_type eq "wrfsi.rotlat")
{
   $staticfile[0]="static.wrfsi.rotlat";
   $namelist  ="wrfsi.nl";
}
else
{
   $namelist  ="wrfsi.nl";
   for ($i=1; $i<=$num_domains[0]; $i++)
   {
        $dnum=$i;
        $dnum='0'.$dnum unless($dnum > 9);
        $staticfile[$i-1]="static.wrfsi.d".$dnum;
   }
}

if( $opt_m ){
    print "Did not run gridgen_model\n";
    print "Restore gridgen files: move files from static_save to static \n";

   $success = &restorefiles("ggm");

   if($success != 1){
      print "<!> Failed to restore original ggm dataroot files <!>\n";
      print "<!>  Terminating <!>\n";
      system("mv $LAPS_DATA_ROOT/$logname/localize_domain.log $LAPS_DATA_ROOT/$logname/$logfilename");
      print "\n log file: $LAPS_DATA_ROOT/$logname/$logfilename \n";
      exit;
   }
}

print "Checking for static file \n";

my $restore_files="false";
my @error_lines;
open(LOC,"$LAPS_DATA_ROOT/$logname/localize_domain.log");
my @loc=<LOC>;
close(LOC);

if( !defined $opt_m ){
  for ($i=1; $i<=$num_domains[0]; $i++){
    if(!-e "$LAPS_DATA_ROOT/static/$staticfile[$i-1]"){
       print "Error: $LAPS_DATA_ROOT/static/$staticfile[$i-1] does not exist!\n";
       $restore_files="true";
    }else{
       system ("ls -l $LAPS_DATA_ROOT/static/$staticfile[$i-1]");
    }
  }
  foreach(@loc){if( /error/i ){
                print "$_\n";}
  }
}

if($restore_files eq "false" && !defined $opt_m){
   print "checking localize_domain.log\n";

   my $world_topo_warn_lines = 0;
   foreach(@loc){if(/world/i && /warning/i){$world_topo_warn_lines = 1;}}
   my $error_lines = grep /error/i,@loc;
   my $cannot_lines = grep /cannot/i,@loc;

   if($error_lines gt 0){
      print "Lines with error found in localize_domain.log\n";
      print "Settting variable -- restore_files -- to true\n";
      $restore_files="true";
      foreach(@loc){if( /error/i ){
                    print "$_\n";}
      }
   }
   if($cannot_lines gt 0){print "Lines with cannot found in localize_domain.log\n";}
   if($world_topo_warn_lines gt 0){print "Lines with both world_topo and warning found in localize_domain.log\n";}

   system ("ls -l   $LAPS_DATA_ROOT/$logname/localize_domain.log");
   system ("tail -1 $LAPS_DATA_ROOT/$logname/localize_domain.log");
}

if( $restore_files eq "true" ) {
    print "\n";
    print "Rename static and cdl to _err for further examination.\n";
    print "***************************************************\n";
    print "   --> localization failed and is incomplete <--   \n";
    print "***************************************************\n";
    system("mv $LAPS_DATA_ROOT/static $LAPS_DATA_ROOT/static\_err");
    system("mv $LAPS_DATA_ROOT/cdl $LAPS_DATA_ROOT/cdl\_err");
    if( ! -e "$DATAROOT/$DOMAIN_NAME/data_rep"){
       system("mv $LAPS_DATA_ROOT/static\_save $LAPS_DATA_ROOT/static");
       system("mv $LAPS_DATA_ROOT/cdl\_save    $LAPS_DATA_ROOT/cdl");
    }

    if(!-e "$LAPS_DATA_ROOT/static"){
       mkdir "$LAPS_DATA_ROOT/static", 0777 or die "Can't make directory $LAPS_DATA_ROOT/static";
    }

    $success = &restorefiles("all");

#   if( defined $ENV{FXA_DATA}){
#       system("cp -p $DATAROOT/laps_data/static/$namelist $LAPS_DATA_ROOT/static/");
#       system("cp -p $DATAROOT/laps_data/static/corners.dat $LAPS_DATA_ROOT/static/");
#   }

    system("mv $LAPS_DATA_ROOT/$logname/localize_domain.log $LAPS_DATA_ROOT/$logname/$logfilename");
    print "\nlog file: $LAPS_DATA_ROOT/$logname/$logfilename \n";
    print "\n";
    print "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
    print "     Localization is Incomplete\n";
    print "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
    exit;
}

$success = &restorefiles("ncgm");

if( -e "$LAPS_DATA_ROOT/static\_save"){
    print "removing $LAPS_DATA_ROOT/static\_save\n";
    $success=system("rm -rf $LAPS_DATA_ROOT/static\_save");
    if($success != 0){
       print "Failed to remove $LAPS_DATA_ROOT/static\_save\n";
    }
}
if( -e "$LAPS_DATA_ROOT/cdl\_save"){
    print "removing $LAPS_DATA_ROOT/cdl\_save\n";
    $success=system("rm -rf $LAPS_DATA_ROOT/cdl\_save");
    if($success != 0){
       print "Failed to remove $LAPS_DATA_ROOT/cdl\_save\n";
    }
}

print "update prod subdirectory - synchronize with repository\n";
&laps_tools::mkdatadirs($LAPS_DATA_ROOT,$LAPS_SRC_ROOT,$domain_dir);

system("mv $LAPS_DATA_ROOT/$logname/localize_domain.log $LAPS_DATA_ROOT/$logname/$logfilename");

print "\n log file: $LAPS_DATA_ROOT/$logname/$logfilename \n";
print "         ********************************************** \n";
print "         *******   Domain Localization complete ****** \n";
print "         ********************************************** \n";
exit;
#-------------------------------------------------------------------------

sub restorefiles
{
    my ($type)=@_;

    if(-e "$LAPS_DATA_ROOT/static\_save")
    {
       opendir(STATICDIR, "$LAPS_DATA_ROOT/static\_save");
       @filelist = grep !/^\.\.?$/,readdir STATICDIR;
       closedir STATICDIR;
       my($subf, @subflist);
       if($type eq "all"){
          foreach (@filelist){
               if( -d "$LAPS_DATA_ROOT/static\_save/$_") {
                   opendir(SUBDIR, "$LAPS_DATA_ROOT/static\_save/$_");
                   @subflist = readdir SUBDIR;
                   closedir SUBDIR;
                   foreach $subf (@subflist){
                           `cp $LAPS_DATA_ROOT/static\_save/$_/$subf $LAPS_DATA_ROOT/static/$_/$subf`;
                   }
               }else{
                   `cp -p $LAPS_DATA_ROOT/static\_save/$_ $LAPS_DATA_ROOT/static/$_`;
               }
          }
       }elsif($type eq "ncgm"){
            foreach (@filelist){
                     if( /ncgm/){
                         `mv $LAPS_DATA_ROOT/static\_save/$_ $LAPS_DATA_ROOT/static/$_`;
                     }
            }
       }elsif($type eq "static"){
            foreach (@filelist){
                     if( /^static\./){
                         `cp $LAPS_DATA_ROOT/static\_save/$_ $LAPS_DATA_ROOT/static/$_`;
                     }
            }
       }elsif($type eq "ggm"){
           foreach (@filelist){
                    next if(/\.nl$/ || /nest7grid.parms/);
                    if( /\.dat$/ || /^static/ || /wrfstatic/){
                       `cp $LAPS_DATA_ROOT/static\_save/$_ $LAPS_DATA_ROOT/static/$_`;
                    }elsif(-d "$LAPS_DATA_ROOT/static\_save/$_"){
                       opendir(SUBDIR, "$LAPS_DATA_ROOT/static\_save/$_");
                       @subflist = grep !/^\.\.?$/, readdir SUBDIR;
                       closedir SUBDIR;
                       if(!-e "$LAPS_DATA_ROOT/static/$_/$subf"){
                          mkdir "$LAPS_DATA_ROOT/static/$_/$subf",0777 or die "cant make directory $LAPS_DATA_ROOT/static/$_/$subf";
                       }
                       foreach $subf (@subflist){
                               `cp $LAPS_DATA_ROOT/static\_save/$_/$subf $LAPS_DATA_ROOT/static/$_/$subf`;
                       }
                    }
           }
       }
    }

    if(-e "$LAPS_DATA_ROOT/cdl\_save" && $domain_type =~ /wrfsi/i)
    {
       opendir(CDLDIR, "$LAPS_DATA_ROOT/cdl\_save");
       @filelist = grep !/^\.\.?$/, readdir CDLDIR;
       closedir CDLDIR;

       my @moad_num_domains     = &laps_tools::get_nl_value("wrfsi.nl","num_domains",$LAPS_DATA_ROOT);
       my @moad_ratio_2_parent  = &laps_tools::get_nl_value("wrfsi.nl","ratio_to_parent",$LAPS_DATA_ROOT);
       my @moad_domain_orig_lli = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_lli",$LAPS_DATA_ROOT);
       my @moad_domain_orig_llj = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_llj",$LAPS_DATA_ROOT);
       my @moad_domain_orig_uri = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_uri",$LAPS_DATA_ROOT);
       my @moad_domain_orig_urj = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_urj",$LAPS_DATA_ROOT);
       my ($deltai,$deltaj,@nest_nx,@nest_ny);
       for ($i=0; $i<=$moad_num_domains[0]-1; $i++){
         $deltai  = $moad_domain_orig_uri[$i]-$moad_domain_orig_lli[$i];
         $deltaj  = $moad_domain_orig_urj[$i]-$moad_domain_orig_llj[$i];
         $nest_nx[$i] = $deltai*$moad_ratio_2_parent[$i]+1;
         $nest_ny[$i] = $deltaj*$moad_ratio_2_parent[$i]+1;
       }

       my (@cdllines,$nxwrfsi,$nywrfsi,$domnum);

       foreach (@filelist)
       {
            if(/^wrfsi\.d(\d\d)/)
            {
               next if($1 > $moad_num_domains[0]);
               $domnum = $1-1;
               open(CDL,"$LAPS_DATA_ROOT/cdl/$_");
               @cdllines=<CDL>;
               foreach (@cdllines){
                        if(/\s+x\s=\s(\d+)/){
                           $nxwrfsi=$1;
                        }
                        if(/\s+y\s=\s(\d+)/){
                           $nywrfsi=$1;
                        }
               }
               next if($nest_nx[$domnum]==$nxwrfsi && $nest_ny[$domnum]==$nywrfsi);
               print "Copy $LAPS_DATA_ROOT/cdl\_save/$_ to $LAPS_DATA_ROOT/cdl/$_\n";
               `cp $LAPS_DATA_ROOT/cdl\_save/$_ $LAPS_DATA_ROOT/cdl/$_`;
            }
       }
    }
    return 1;
}
