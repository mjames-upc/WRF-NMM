#!/usr/bin/perl
# Generated automatically by make_script.pl
#
# ******** laps_localization.pl.in  ************************
# ******** localize_domain.pl.in    ************************
# Copyright (C) 1998  James P. Edwards
#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# J. Smart: 6-09-00: Added command line option no_ggm (for no gridgen_model)
#                    Switch must have a value (like 't' or 'y' or '1') such
#                    that it is defined. If no_ggm is defined laps_localization
#                    only updates namelists and cdl files.
#   "     : 6-25-01: Modified script to be more generic and adaptable to the
#                    WRFSI domain localization; thus, renamed script to
#                    localize_domain.pl.in ... -w switch to distinguish which
#                    localization (laps or wrfsi).
#   "     : 6-01-03: Added q_sub project name command line input, qspn. Directive
#                    to use laps_driver.pl and submit gridgen_model to compute
#                    node as necessary. Added construct to prevent buffering output.
use strict;
use Getopt::Long;
my($INSTALL_ROOT,$DATA_ROOT,$SOURCE_ROOT,$WHICH_TYPE,$flush_buffer);
my($quiet,$sattype,$satid,$no_ggm);
my $qspn;

my $result = GetOptions("install_root=s" => \$INSTALL_ROOT,
                        "qspn=s" => \$qspn,
                        "which_type=s" => \$WHICH_TYPE,
			"dataroot=s" => \$DATA_ROOT,
			"srcroot=s"  => \$SOURCE_ROOT,
			"sattype=s" => \$sattype,
			"satid=s" => \$satid,
                        "no_ggm=s" => \$no_ggm,
			"quiet" => \$quiet, 
			"help" => \&help_sub,
			"<>" => \&help_sub);

sub help_sub{
    print "$0 command line options (default values)\n";

# RAR Changed
#   print "   --install_root = Root directory of the installed binaries (/usr1/wrf/wrfsi)\n";
#   print "   --dataroot = Root directory of the installed data (/usr1/wrf/wrfsi/data)\n";
#   print "   --srcroot  = Root directory of the source code    (/usr1/wrf/wrfsi)\n";
    print "   --install_root = Root directory of the installed binaries ($ENV{'INSTALLROOT'})\n";
    print "   --dataroot = Root directory of the installed data ($ENV{'DATAROOT'})\n";
    print "   --srcroot  = Root directory of the source code    ($ENV{'SOURCE_ROOT'})\n";

    print "   --which_type = Specifies localization for either LAPS or WRFSI\n";
    print "   --sattype  = cdf, wfo, gvr, or gwc (guessed based on site)\n";
    print "   --satid    = g8/g12 or g10 (guessed based on -100.0W)\n";
    print "   --no_ggm   = if defined then localization does not run gridgen_model\n";
    print "   --quiet    = Do not query user for verification\n";
    print "   --qspn P   = run gridgen_model.exe using laps_driver.pl -q $qspn; P = project name\n";
    print "   --help     = print this message and exit\n";
    exit;
}

umask 002;
my $q_sub;
if(defined $qspn){
   print "using qsub: qsub project name = $qspn\n";
   if(defined $ENV{HOSTTYPE}){
      if( substr($ENV{HOSTTYPE},0,4) eq "i386" || $ENV{HOSTTYPE} eq "x86_64-linux"){
         $q_sub="Q";
      }elsif( substr($ENV{HOSTTYPE},0,5) eq "alpha"){
         $q_sub="q";
      }else{print "ERROR: not able to determine HOSTTYPE for q sub\n";
            print "Abort\n";
            exit;
      }
   }else{
      print "ERROR: Env Var HOSTTYPE not available\n";
      exit;
   }
       
}

#flush buffer; ie., prevent buffering of output
$|=1;

my $thisdir = 'pwd';
chomp($thisdir);
$WHICH_TYPE=lc $WHICH_TYPE;

# RAR Changed
#
die "SOURCE_ROOT is not defined!" unless $SOURCE_ROOT;
print "    SOURCE_ROOT defined as $SOURCE_ROOT\n\n";

#if(! $SOURCE_ROOT){
#    if(-d "/usr1/wrf/wrfsi/src/lib/"){
#	$SOURCE_ROOT="/usr1/wrf/wrfsi" ;
#    }else{
#	$SOURCE_ROOT='/dev/null';
#    }
#}

#$DATA_ROOT = "/usr1/wrf/wrfsi/data" unless($DATA_ROOT);
#$INSTALL_ROOT="/usr1/wrf/wrfsi" unless($INSTALL_ROOT);

$DATA_ROOT   = "$ENV{'WRF_RUN'}"  unless($DATA_ROOT);
$INSTALL_ROOT="$ENV{'WRF_HOME'}"  unless($INSTALL_ROOT);

# RAR END

my $namelist;

if( $WHICH_TYPE eq "laps"){

   print "Preparing a LAPS localization \n";
   $ENV{LAPS_DATA_ROOT} = $DATA_ROOT;
   $namelist = "nest7grid.parms";

}elsif( $WHICH_TYPE eq "wrfsi"){
   
   print "Preparing a WRFSI ARW localization \n";
   $ENV{MOAD_DATAROOT}=$DATA_ROOT;
   $namelist = "wrfsi.nl";

# RAR Change
} elsif( $WHICH_TYPE eq "wrfsi.rotlat"){

   print "Preparing a WRFSI NMM localization\n";
   $ENV{MOAD_DATAROOT}=$DATA_ROOT;
   $namelist = "wrfsi.nl";

# RAR END

}else{

   print "You need to use --which_type to decide\n";
   print "which localization you desire (laps or wrfsi). Terminating\n";
   exit;
}

require "$INSTALL_ROOT/etc/run_sys.pm";
require "$INSTALL_ROOT/etc/laps_tools.pm";

my $FXA_DATA = $ENV{"FXA_DATA"};
my $sys;

if(-d "$SOURCE_ROOT"){
    if(-d "$DATA_ROOT"){
        print "DATA_ROOT is here : $DATA_ROOT \n";
	&safe_cp("$SOURCE_ROOT","$DATA_ROOT");
    }else{
	unless($quiet){
	    print "Directory $DATA_ROOT not found - create from $SOURCE_ROOT? (y or n)\n";
	    my $key = getc;
	    print "$key\n";
	    exit if($key != 'y');
	}
        $sys ="cp -r $SOURCE_ROOT $DATA_ROOT";
        print $sys;
	run_sys::run_sys($sys);
    }
    &update_nl("$SOURCE_ROOT","$DATA_ROOT","$WHICH_TYPE");

}else{
    print "SRC_ROOT directory $SOURCE_ROOT not found - proceeding assuming all namelists are up to date\n";
}

### RAR STRC BEGIN
#   Update the user configuration files here.

    &update_siconf;

### END STRC


if(-d $FXA_DATA){
  print "Localizing for WFO $ENV{FXA_INGEST_SITE}\n";
  run_sys::run_sys("rm -f $DATA_ROOT/static/vxx/radar.lst");
  my $i;
  for ($i=1; $i<=9; $i++) {
    $sys = "rm -f $DATA_ROOT/lapsprd/rdr/00$i/raw/*"; 
    run_sys::run_sys($sys);
  }
  $satid = &wfo_localization($SOURCE_ROOT,$INSTALL_ROOT,$DATA_ROOT,$FXA_DATA,$satid);
  $sattype = "wfo";
}
#
# first get the info from the appropriate namelist
open(PARMS,"$DATA_ROOT/static/$namelist");
my(@xdim,@ydim,$zdim,$varx,$vary,$varz);
if($namelist eq "wrfsi.nl"){
   $varx="xdim";$vary="ydim";$varz="levels";
}else{
   $varx="NX_L_CMN";$vary="NY_L_CMN";$varz="NK_LAPS";
}

while(<PARMS>){

    $xdim[0] = $1 if(/^\s+$varx\s*=\s*(\d+),?/i);
    $ydim[0] = $1 if(/^\s+$vary\s*=\s*(\d+),?/i);
    $zdim    = $1 if(/^\s+$varz\s*=\s*(\d+),?/i);
}
close(PARMS);
$zdim = 1 if ($namelist eq "wrfsi.nl");

if($xdim[0] <=0 || $ydim[0] <= 0 || $zdim<=0){
  print "$0: Error Reading grid size from $DATA_ROOT/static/$namelist\n";
  print "nx=$xdim[0] ny=$ydim[0] nz=$zdim\n";
  exit -1;
}

my @plines;
if( $WHICH_TYPE eq "laps"){
    if(-e "$DATA_ROOT/static/pressures.nl"){
       open(PRES,"$DATA_ROOT/static/pressures.nl");
       @plines = <PRES>;
       close (PRES);
       $zdim = $#plines-2;
       &laps_tools::update_nl($DATA_ROOT,"nest7grid.parms","NK_LAPS",$zdim);
    }else{
       print " ********** WARNING ***************\n";
       print "could not find file pressures.nl in $DATA_ROOT/static\n";
       print "check nest7grid.parms to insure nk_laps is properly set\n";
    }
}
#
# Edit the cdl files for xdim and ydim
#
print "\n  Copy $SOURCE_ROOT/cdl to $DATA_ROOT/cdl\n";

unless(-d "$DATA_ROOT/cdl"){
    if(-d "$SOURCE_ROOT/cdl") {
	run_sys::run_sys("cp -r $SOURCE_ROOT/cdl $DATA_ROOT/cdl");
    }else{
	die "Could not find or create cdl directory in $DATA_ROOT/cdl";
    }
}
#
# Prepare cdl's for wrfsi in the case of nesting
#
my @num_doms;
my @moad_domain_orig_lli;
my @moad_domain_orig_llj;
my @moad_domain_orig_uri;
my @moad_domain_orig_urj;
my @moad_ratio_2_parent;
my @parent_id;
my @proj;
my ($deltai,$deltaj, $parent_id, $cstring, $dn, $i);
if($WHICH_TYPE eq "wrfsi" or $WHICH_TYPE eq "wrfsi.rotlat" ){
   @proj                 = &laps_tools::get_nl_value("wrfsi.nl","map_proj_name",$DATA_ROOT);
   @moad_domain_orig_lli = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_lli",$DATA_ROOT);
   @moad_domain_orig_llj = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_llj",$DATA_ROOT);
   @moad_domain_orig_uri = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_uri",$DATA_ROOT);
   @moad_domain_orig_urj = &laps_tools::get_nl_value("wrfsi.nl","domain_origin_urj",$DATA_ROOT);
   @moad_ratio_2_parent  = &laps_tools::get_nl_value("wrfsi.nl","ratio_to_parent",$DATA_ROOT);
   @parent_id            = &laps_tools::get_nl_value("wrfsi.nl","parent_id",$DATA_ROOT);
   @num_doms             = &laps_tools::get_nl_value("wrfsi.nl","num_domains",$DATA_ROOT);
   if($num_doms[0] > 99){
      print "Error: Number of domains > 99. Terminating. $num_doms[0]\n";
   }
   for ($i=1; $i<=$num_doms[0]; $i++){
     $cstring=$i;
     $cstring='0'.$cstring while (length $cstring < 2);
     print "  Coping $SOURCE_ROOT/cdl/wrfsi.cdl to $DATA_ROOT/cdl/wrfsi.d$cstring.cdl\n";
     run_sys::run_sys("cp $SOURCE_ROOT/cdl/wrfsi.cdl $DATA_ROOT/cdl/wrfsi.d$cstring.cdl");
   }
}

opendir(CDL_DIR,"$DATA_ROOT/cdl");
my @cdl_list = grep /\.cdl$/, readdir CDL_DIR;
closedir CDL_DIR;
sort @cdl_list;

foreach(@cdl_list){

  my $rotlat;

  print "\n  Operating on file $_\n";
  $rotlat = /rotlat/i;

# The next line was commented out on 11 Jan 01 to more closely couple LAPS and any
#   model using the files fua.cdl and fsf.cdl  fua.cdl and fsf.cdl will now be
#   edited to match the LAPS x and y dimensions each time laps_localization.pl is run.
#  \/ The following line no longer applies  \/  11 Jan 01
# Calculate the grid dimensions for wrfsi when we have more than 1 domain.
   $dn=0;
   if(/^wrfsi\.d(\d\d)/){
      if($1 < 10){
         $dn = substr($1,1,1)-1;
     }else{
         $dn = $1-1;
     }
     if($dn > 0){
        $parent_id=@parent_id[$dn]-1;  #!! subtract 1 for 0-based array indexing !!#
        $deltai  = $moad_domain_orig_uri[$dn]-$moad_domain_orig_lli[$dn];
        $deltaj  = $moad_domain_orig_urj[$dn]-$moad_domain_orig_llj[$dn];
        if($moad_domain_orig_uri[$dn] > $xdim[$parent_id]){
           print "Error: Upper right x dim of child outside of parent domain\n";
           print "       $moad_domain_orig_uri[$dn] > $xdim[$parent_id] \n";
           exit;
        }elsif($moad_domain_orig_urj[$dn] > $ydim[$parent_id]){
           print "Error: Upper right y dim of child outside of parent domain\n";
           print "       $moad_domain_orig_urj[$dn] > $ydim[$parent_id] \n";
           exit;
        }
        $xdim[$dn] = $deltai*$moad_ratio_2_parent[$dn]+1;
        $ydim[$dn] = $deltaj*$moad_ratio_2_parent[$dn]+1;
     }
     print "\n  dims for domain $1: x,y = $xdim[$dn],$ydim[$dn]\n";
   }

   open(CDL,"$DATA_ROOT/cdl/$_");
   my @cdl = <CDL>;
   close(CDL);

# RAR - The Dimensions in the CDL files are updated below.
#

   open(CDL,">$DATA_ROOT/cdl/$_");
   foreach(@cdl){
	if(/^(\s+)x\s*=/){
            if ($rotlat) {
                my $rotx = $xdim[$dn];
                print CDL "$1x = $rotx,\n";
            } else {
                print CDL "$1x = $xdim[$dn],\n" ;
            }
	}elsif(/^(\s+)y\s*=/){
	    print CDL "$1y = $ydim[$dn],\n" ;
	}elsif(/^(\s+)z\s*=\s*(\d+)/){
	    if($2>5  && $2!=42){
		print CDL "$1z = $zdim,\n" ;
	    }else{
		print CDL $_ ;
	    }
	}else{
	    print CDL $_;
	}
   }
   close(CDL);
}
#
# localize optran coefficients
#
  if($WHICH_TYPE eq "laps"){
     print "Localizing Optran Coefficients based on moisture_switch.nl namelist settings\n";
     run_sys::run_sys("/usr/bin/perl $INSTALL_ROOT/etc/localize_optran.pl $INSTALL_ROOT/bin/ $DATA_ROOT/static");
  }

#
# run gridgen model if necessary
#

my $command;
if( !defined $no_ggm ){
    if(defined $qspn && $q_sub eq "q"){
       $command = "/usr/bin/perl $INSTALL_ROOT/etc/laps_driver.pl -q $qspn -n rt gridgen_model.exe $INSTALL_ROOT $DATA_ROOT";
    }elsif(defined $qspn && $q_sub eq "Q"){
       $command = "/usr/bin/perl $INSTALL_ROOT/etc/laps_driver.pl -Q $qspn -n ncomp -w gridgen_model.exe $INSTALL_ROOT $DATA_ROOT";
    }else{
       $command = "$INSTALL_ROOT/bin/gridgen_arw.exe";
       if (@proj[0] =~ /rotlat/i) {
            $command = "$INSTALL_ROOT/bin/gridgen_nmm.exe";
       }
    }

    print "\n  Running: $command \n";
    run_sys::run_sys($command);
    print "gridgen_arw.exe is finished\n" unless @proj[0] =~ /rotlat/i;
    print "gridgen_nmm.exe is finished\n" if     @proj[0] =~ /rotlat/i;

#   &calc_nmmco2 if @proj[0] =~ /rotlat/i;

    if($WHICH_TYPE eq "laps"){
       print "build sfc lookup tables\n";
       run_sys::run_sys("$INSTALL_ROOT/bin/gensfclut.exe");
       print "gensfclut.exe complete \n";
    }

}else{
    print "\n  NOTE: not running gridgen_arw|nmm. Only updating namelists and cdl's\n";
}

#
# Clean out any pre-existing radar remapper look-up tables
#

if($WHICH_TYPE eq "laps"){
   if(-d "$DATA_ROOT/static/vxx"){
    print "cleaning out static/vxx directory of any old luts\n";
    run_sys::run_sys("rm -f $DATA_ROOT/static/vxx/*lut*");
   }else{
    print "Creating directory $DATA_ROOT/static/vxx\n";
    run_sys::run_sys("mkdir $DATA_ROOT/static/vxx");
   }
   if(-d "$DATA_ROOT/static/lvd"){
    print "cleaning out static/lvd directory of any old luts\n";
    run_sys::run_sys("rm -f $DATA_ROOT/static/lvd/*.lut");
   }else{
    print "Creating directory $DATA_ROOT/static/lvd\n";
    run_sys::run_sys("mkdir $DATA_ROOT/static/lvd");
   }
   &static_parms_to_cdl("$DATA_ROOT");
}

print "$0 complete\n";

sub update_nl{
    print "In localize_domain:update_nl\n";
    my($srcroot,$dataroot,$type) = @_;

    my $srcdir  = "$srcroot/static";
    my $datadir = "$dataroot/static";
#
# Add variables and files found in $srcroot/static but not $dataroot/static
# Retain the values of variables found in $dataroot/static for variables in both files
#
# First find all of the variable values in $dataroot/static
#

    my @nl;
    opendir(TDIR,"$srcdir");
    foreach (readdir TDIR) {
      if  (/\w*.nl$/) {
        push (@nl, "$_");
      }
    }
    closedir(TDIR);
    push(@nl,"nest7grid.parms") if(lc $type eq "laps");

    my $nl_file;

    foreach $nl_file (@nl){
    print "\n  Processing $nl_file";
        my %nl_vals;
        my %comments;
        if ( -f "$datadir/$nl_file") {
          print "\n  Found existing $nl_file in dataroot, reading...\n";
          print "  STRC: Opening for reading $datadir/$nl_file\n";
          open(FILE,"$datadir/$nl_file");
          my @template = <FILE>;
          close(FILE);

          my $var='';
          my $mark=0;
          my $line;
          foreach $line (@template){
              if($line =~ /^\s*\&/){
                  $mark=1;
                  next;
              }elsif($line =~ /^\s*\//){
                  $mark=2;
                  next;
              }elsif($line =~ /^[!cC]/){
                  $comments{$nl_file} .= $line;
                  $mark=3;
                  next;
              }elsif($line =~ /^\s*(\S+)\s*=\s*(.*)$/){
                  $var = $1;
                  $var =~ tr/a-z/A-Z/;
                  $nl_vals{$var} = $2;
                  next;
              }elsif($line =~ /^(.*)$/){
                  $nl_vals{$var} .= "\n$1";
                  next;
              }
              if($mark>0){
                  $var = '';
                  $mark=0;
              }
           }
          system("cp $datadir/$nl_file $datadir/$nl_file.bak");
      }

      print "  STRC: OPENING $srcdir/$nl_file\n";
      open(INFILE,"$srcdir/$nl_file");
      my @infile = <INFILE>;
      close(INFILE);

      print "  STRC: WRITING $datadir/$nl_file\n";
      open(OUTFILE,">$datadir/$nl_file") or
          die "Could not open $datadir/$nl_file to write";
      my($var, $val, $line, $eon);
      my @comments = split("\n",$comments{$nl_file});

      foreach $line (@infile){
          next if($line eq "\n");
          if($line =~ /^\s*\//){
              $eon = 1;
              print OUTFILE "\/\n";
              next;
          }

          if($line =~ /^\s*(\S+)\s*=\s*(.*)$/){
              $var = $1;
              $var =~ tr/a-z/A-Z/;
              $val = $2;
              if(exists $nl_vals{$var}){
                  $val = $nl_vals{$var};
              }
              $val =~ s/\n$//;
              print OUTFILE " $var = $val\n";
              next;
          }elsif($line =~ /^[!cC]/){
              chomp($line);
              my $tmpline = $line;
              $tmpline =~ s/[(\[\]\\\/\(\)\!\$\^)]/\$1/g;
              next if(grep(/$tmpline/,@comments)>0);
              push(@comments,$line);
              next;
          }elsif($line =~ /^\s*&/){
              print OUTFILE $line;
              next;
          }elsif(($line =~ /^(\s*[^&\/].*)$/) && exists $nl_vals{$var}){
              next;
          }
          print OUTFILE $line;

      }
      foreach(@comments){
          print OUTFILE "$_\n";
      }
      close(OUTFILE);

# RAR ADDITIONS - To make sure full wrfsi.nl file gets written to
#                 template directory.
#
      my @tmp     = split /\//, $dataroot;
      my $rundir = pop @tmp;
      my $tmpdir = "$ENV{DATA_DOMS}/$rundir";
      print "\n  STRC: Copy namelist file to template directory.\n";
      print "  STRC: cp $datadir/$nl_file to $tmpdir/$nl_file\n";
      system "cp $datadir/$nl_file $tmpdir/$nl_file";
#
# RAR END

  }
}

sub safe_cp{
    my($indir,$outdir) = @_;
    
    opendir(INDIR,$indir);
    my(@files) = grep !/^\.\.?$/,readdir INDIR;
    close(INDIR);
    my $file;   
    foreach $file (@files){
        next if($file =~ /^CVS$/);
	next if($file =~ /^\#/);
	next if($file =~ /~$/);

        print "\n  FILE: $indir/$file \n";

	if(-d "$indir/$file"){
	    if(-d "$outdir/$file") {
		&safe_cp("$indir/$file","$outdir/$file");
	    }else{
                print "\n  Copying Directory $indir/$file to $outdir/$file\n";
		run_sys::run_sys("cp -r $indir/$file $outdir/$file");
	    }
	    next;
	}
	next if(-e "$outdir/$file");
        print "\n  Copying file $indir/$file to $outdir/$file\n";
	run_sys::run_sys("cp $indir/$file $outdir/$file");
    }	
}

sub wfo_localization{
  my($SOURCE_ROOT,$INSTALL_ROOT,$DATA_ROOT,$FXA_DATA,$satid) = @_;
  my($root) = $ENV{"FXA_LOCALIZATION_ROOT"};
  my($site) = $ENV{"FXA_INGEST_SITE"};
  my($file1) = "$ENV{FXA_HOME}/localizationDataSets/$ENV{FXA_LOCAL_SITE}/whichSat.txt";
  my($file2) = "$root/$site/Laps_Center_Point.txt";
  my($goes) = 0;
  my($lat,$lon);  

  open(LOCFILE,$file2) or die "Can't find $file2.";
  my $line = <LOCFILE>;
  chop($line);
  $line =~ s/ +/,/;
  ($lat,$lon) = split(",",$line);

  if($satid eq "g8"){
      $goes = 8;
  }elsif($satid eq "g10"){
      $goes = 10;
# added next two lines when goes8 went away on 4-1-03 LW
  }elsif($satid eq "g12"){
      $goes = 12;
  }elsif(-r $file1){
      open(LOCFILE,$file1) or die "Can't find $file1.";
      my $line = <LOCFILE>;
      close(LOCFILE);
      $goes=10 if($line =~ /WEST/i);      
# modified next two lines when goes8 went away on 4-1-03 LW
#     $goes=8 if($line =~ /EAST/i);
      $goes=12 if($line =~ /EAST/i);
  }else{
# modified next two lines when goes8 went away on 4-1-03 LW
#     $goes = $lon>-100 ? 8:10;  # identifies the goes sat to use based on longitude
      $goes = $lon>-100 ? 12:10;  # identifies the goes sat to use based on longitude
  }
  #First files:  the namelist files.


  opendir(NL,"$DATA_ROOT/static");
  my(@templates) = grep(/\.nl/,readdir(NL));
  closedir(NL);
  push(@templates,"nest7grid.parms");
  my $template;
  foreach $template (@templates){
      $template = "$DATA_ROOT/static/$template";

      open(TEMPLATE,"$template") or die "$0: Can't find template file in $template";
      my @template = <TEMPLATE>;
      close(TEMPLATE);
      print "Using static template file $template\n";

      my $i;

      for($i=0;$i<=$#template;){
        if ($template[$i] =~ /=/){
            $i++;
            next;
        }
        if ($template[$i] =~ /^\s*\&/){
            $i++;
            next;
        }
        last if ($template[$i] =~ /^\s*\//);
        
        $template[$i-1]=join('',$template[$i-1],$template[$i]);
        splice(@template,$i,1);
      }

# ISAT = 'goes08, metsat, goes10, gmssat, goes12, goes09

      open(OUTFILE,">$template") or die "$0: Can't open $template to write";

      foreach (@template)
      {
          $_ =~ s/\$FXA_DATA/$FXA_DATA/g;
          if(/standard_latitude\s*=/i){
              print OUTFILE " standard_latitude=$lat,\n";
          }elsif(/standard_longitude\s*=/i){
              print OUTFILE " standard_longitude=$lon,\n";
          }elsif(/grid_cen_lat_cmn\s*=/i){
              print OUTFILE " grid_cen_lat_cmn=$lat,\n";
          }elsif(/grid_cen_lon_cmn\s*=/i){
              print OUTFILE " grid_cen_lon_cmn=$lon,\n";
          }elsif(/\sISATS\s*=/i){
              if($goes==8){
                  print OUTFILE " ISATS = 1,0,0,0,0,0\n";
# added next two lines when goes8 went away on 4-1-03 LW
              }elsif($goes==12){
                  print OUTFILE " ISATS = 0,0,0,0,1,0\n";
              }else{
                  print OUTFILE " ISATS = 0,0,1,0,0,0\n";
              }

          }elsif(/\sgoes_switch\s*=/i){
              print OUTFILE " goes_switch = $goes,\n";
          }elsif(/\sITYPES\s*=/i){
              if($goes==8){
                  print OUTFILE " ITYPES = 0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n";
# added next two lines when goes8 went away on 4-1-03 LW
              }elsif($goes==12){
                  print OUTFILE " ITYPES = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0\n";
              }else{
                  print OUTFILE " ITYPES = 0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n";
              }

          }else{
              print OUTFILE $_;
          }
      }
      close(OUTFILE);
  }

  $goes = "g".$goes;

# setup background.nl based on site location

  my $old_nl;
  my $new_nl;
  my $command;

# Revert to CONUS if file background.nl.CONUS exists (this assumes localization is CONUS)
  if (-s "$DATA_ROOT/static/background.nl.CONUS") {
    $old_nl = "$DATA_ROOT/static/background.nl.CONUS";
    $new_nl = "$DATA_ROOT/static/background.nl";
    $command = "cp $old_nl $new_nl";
    run_sys::run_sys($command);
  }

# OCONUS namelist setup
# Check for Alaska ingest sites AJK, AFG, AFC, ACR (rfc)
# copy background.nl.AK to background.nl

  if (($site eq "AJK") || ($site eq "AFG") ||
      ($site eq "AFC") || ($site eq "ACR")) {
    if (!-s "$DATA_ROOT/static/background.nl.CONUS") {
      # preserve background.nl if it exists as background.nl.CONUS
      $old_nl = "$DATA_ROOT/static/background.nl";
      $new_nl = "$DATA_ROOT/static/background.nl.CONUS";
      $command = "cp $old_nl $new_nl";
      run_sys::run_sys($command);
    }

    $old_nl = "$DATA_ROOT/static/background.nl.AK";
    $new_nl = "$DATA_ROOT/static/background.nl";
    $command = "cp $old_nl $new_nl";
    run_sys::run_sys($command);
  }

}

sub static_parms_to_cdl{

#J Smart 8-13-02: routine reads LAPS static.nest7grid navigation
#attributes (uses ncdump) and puts these into fua/fsf cdl's.

   my ($LAPS_DATA_ROOT) = @_ ;
   umask 002;

#  $LAPS_DATA_ROOT = $ENV{LAPS_DATA_ROOT} if(defined $ENV{LAPS_DATA_ROOT});
#  if(defined $opt_d) {$LAPS_DATA_ROOT = $opt_d;}
   if( ! defined $LAPS_DATA_ROOT) {
       print "LAPS_DATA_ROOT not defined in sub static_parms_to_cdl\n";
#      print "set env var or use -d command line input\n";
       return;}

   if( !-e "$LAPS_DATA_ROOT/static/static.nest7grid"){
       print "No static file in dataroot. Exit\n";
       exit;
   }

#  require "/usr/nfs/common/lapb/parallel/laps/etc/run_sys.pm";
   my $sys;
   open(SAVEOUT,">&STDOUT");
   select(STDOUT); $| = 1;
   my $OUT_FILE = $LAPS_DATA_ROOT."/log/nav.dat";

#find the grid type (ie., polar, lambert, mercator)
   my @nav_stuff = qw(polar lambert mercator);
   foreach (@nav_stuff) {
     $sys="ncdump -v grid_type $LAPS_DATA_ROOT/static/static.nest7grid | grep $_ 1> $OUT_FILE ";
     run_sys::run_sys($sys,1);
     if(-e "$LAPS_DATA_ROOT/log/nav.dat" && -s "$LAPS_DATA_ROOT/log/nav.dat"){ last;}
   }
#reformat the grid_type output in nav.dat
   open(NAV,"$LAPS_DATA_ROOT/log/nav.dat");
   my $nav_stuff = <NAV>;
   close NAV;
   unlink "$LAPS_DATA_ROOT/log/nav.dat";
   $nav_stuff=" grid_type = ".$nav_stuff;
   open(NAV,">$LAPS_DATA_ROOT/log/nav.dat");
   print NAV $nav_stuff;
   close NAV;
   @nav_stuff = qw(Nx Ny La1 Lo1 La2 Lo2 LoV Latin1 Latin2 Dx Dy);
   my $cdfvar;
   foreach (@nav_stuff) {
      $cdfvar = "\"$_ =\"";
#     print "cdfvar = $cdfvar\n";
      $sys="ncdump -v $_ $LAPS_DATA_ROOT/static/static.nest7grid | grep $cdfvar 1>> $OUT_FILE ";
      run_sys::run_sys($sys,1);
   }
   open(NAV,"$LAPS_DATA_ROOT/log/nav.dat");
   my @nav_stuff = <NAV>;
   close NAV;
   unlink "$LAPS_DATA_ROOT/log/nav.dat";

#now append new nav info to fua/fsf cdl files
   my @fuafsf = qw(fua fsf);
   my $cdlfile;
   foreach $cdlfile (@fuafsf){
      open(CDL,"$LAPS_DATA_ROOT/cdl/$cdlfile.cdl");
      my @fuafsf = <CDL>;
      close CDL;
      unlink "$LAPS_DATA_ROOT/cdl/$cdlfile.cdl";
      open(CDL,">$LAPS_DATA_ROOT/cdl/$cdlfile.cdl");
      my $i=0;
      my $ii=0;
      my $nav;
      my @newfuafsf;
      foreach (@fuafsf){
         if($i==$#fuafsf){
            $ii=$i;
            foreach $nav (@nav_stuff){
               @newfuafsf[$ii]="       ".$nav;
               $ii++;
            }
            $i=$ii;
         }
         @newfuafsf[$i]=$_;
         $i++;
      }
      print CDL @newfuafsf;
   }

   return;
}


sub update_siconf {

# STRC ADDITION
# Routine added by RAR to update the WRF user's configuration file in the
# STRC version of the package.
#
    my %WRFnl = ();
    my @lines = ();
    my $strc  = "wrfsi";
    my $levels;
    my $reload;

    my @confdirs = qw(wrf_post wrf_prep wrf_run wrf_autorun);

#  First read in the information from the newly created SI namelist file.
#
    print "\n  STRC: Updating the user configuration files with the namelist information\n";

    my $confd = "$DATA_ROOT/conf";
    $reload = 1 if -e "$confd";
    system "mkdir -p $confd" unless $reload;

# If the conf directory exists then do not overwrite the files.
#
    foreach (@confdirs) {
        print  "  STRC: cp -u -a $ENV{DATA_CONF}/config/$_ $confd\n";
        system "cp -u -a $ENV{DATA_CONF}/config/$_ $confd";
    }
    system "chmod -R 755 $confd" if -e $confd;

    my $nl = "$DATA_ROOT/static/wrfsi.nl";
    print "  Can not locate $nl to update user conf file! \n\n" if ! -e $nl;
    return if ( ! -e $nl );

# Determine if this is a re-localization and the previous domain was
# for a different core. If this is the case then we will need to
# make some additional changes to the namelist and configuration
# files.
#
    my $newcore;
    my $oldcore;
    if (-e "$DATA_ROOT/static/.nmm") {
        $oldcore = 'nmm';
        system "rm -f $DATA_ROOT/static/.nmm";
    } elsif (-e "$DATA_ROOT/static/.arw") {
        $oldcore = 'arw';
        system "rm -f $DATA_ROOT/static/.arw";
    }

    open  NL => "$nl"; my @lines = <NL>; close NL;
    foreach (@lines) {

        if ( s/^\s*(LEVELS)\s*=//i or $levels ) {
            $levels = 1;
            $levels = "" if /\#|\/|\&/;
            $WRFnl{LEVELS} = "$WRFnl{'LEVELS'}" . "$_" if $levels;
        }

        if (/OUTPUT_COORD/i) {
            if (/NMMH/i) {
                $newcore = 'nmm';
                system "touch $DATA_ROOT/static/.nmm";       
                print "\n  This domain will use the NMM core\n";
            } elsif (/ETAP/i) {
                $newcore = 'arw';
                system "touch $DATA_ROOT/static/.arw";
                print "\n  This domain will use the ARW core\n";
            } else {
                die "  ERROR: Unknown vertical coordinate: $_\n\n";
            }   
        }

        next unless /DIM|PARENT|DOMAIN|MOAD|PARM|PROJ|ACTIVE|PTOP/;
        if ( s/^\s*(\w*)\s*=//i ) {
            my $val = uc $1;
            s/^\s+//;
            s/,*$//;
            s/\n//;
            print "    WARNING: $val was previously defined - $WRFnl{$val}\n" if defined $WRFnl{$val};
            if ( $val =~ /URI|URJ/i ) {
               my @vals = split /,/ => $_;
               @vals[0] = $WRFnl{XDIM} if $val =~ /URI/i;
               @vals[0] = $WRFnl{YDIM} if $val =~ /URJ/i;
               $_ = join ", " => @vals
            }
            $WRFnl{$val} = "$_";
        }
    }

    system "rm -f $confd/wrf_autorun/wrf_autonest_sample.conf" if -e "$confd/wrf_autorun/wrf_autonest_sample.conf";

    unless ($reload and $newcore eq 'nmm'){
        if (-e "$confd/wrf_run/nmm_run_physics.conf") {
            system "mv $confd/wrf_run/nmm_run_physics.conf $confd/wrf_run/run_physics.conf";
            print "\n  STRC: Moving $confd/wrf_run/nmm_run_physics.conf to $confd/wrf_run/run_physics.conf\n";
        }
    }

    if ($newcore ne $oldcore) {
        system "cp -f $ENV{DATA_CONF}/config/wrf_run/run_physics.conf     $confd/wrf_run/run_physics.conf" if $newcore eq 'arw';
        system "cp -f $ENV{DATA_CONF}/config/wrf_run/nmm_run_physics.conf $confd/wrf_run/run_physics.conf" if $newcore eq 'nmm';
    }
    system "rm -f $confd/wrf_run/nmm_run_physics.conf" if -e "$confd/wrf_run/nmm_run_physics.conf";
    

# Next write it out to the user's domain information. Replacing values on the fly.
#
    print "  Can not locate $confd to update user conf file! \n\n" if ! -e $confd;

    $WRFnl{LEVELS} =~ s/,*$//;

    $confd = "$confd/wrf_prep";

    opendir DIR => "$confd";
    my @confs  = grep /$strc/ => readdir DIR;

    foreach my $conf ( @confs ) {

        next if $conf =~ /bak/;

        system "cp $confd/$conf $confd/$conf.bak";

        open CONF => "$confd/$conf"; my @lines = <CONF>;close CONF;
        open CONF => ">$confd/$conf";

        foreach (@lines) {

           s/\n//g;s/^\s+//g;
           $levels = "" if /^\s+|^#/;
           next if $levels;

           if ( s/^\s*(\w*)\s*=//i ) {
               my $val = uc($1);
               s/^\s+//; s/,*$//;
               if ( $val =~ /LEVELS/ ) { $levels = 1;}
               $_ = sprintf ( "%-10s = %s",$val,$_ );
               $_ = sprintf ( "%-10s = %s",$val,$WRFnl{$val} ) if defined $WRFnl{$val};
           }
           print CONF "$_\n";
        }
    }

# Create a copy of the original namelist file in the template directory.
# Clean up existing directory is relocalization.
    my @tmp     = split /\//, $DATA_ROOT;
    my $rundir = pop @tmp;

    system "rm -f $ENV{DATA_DOMS}/$rundir/wrfsi.nl.strc" if -e "$ENV{DATA_DOMS}/$rundir/wrfsi.nl.strc";
    system "rm -f $ENV{DATA_DOMS}/$rundir/wrf.nl.strc"   if -e "$ENV{DATA_DOMS}/$rundir/wrf.nl.strc";
    system "rm -f $DATA_ROOT/static/wrfsi.nl.*"          if -e "$DATA_ROOT/static/wrfsi.nl.strc";
    system "rm -f $DATA_ROOT/static/wrf.nl.*"            if -e "$DATA_ROOT/static/wrf.nl.strc";

    print "\n  STRC Copy wrfsi file to template directory.\n";
    print "\n  STRC cp $nl to $ENV{DATA_DOMS}/$rundir/wrfsi.nl.strc\n";

    system "cp -f $nl $ENV{DATA_DOMS}/$rundir/wrfsi.nl.strc";

# Nest create the links from the strc script directory to the run-time
#
    my @scripts  = qw (wrf_prep wrf_run wrf_autorun wrf_post);
    foreach ( @scripts ) {
       system("rm -f $DATA_ROOT/$_") if -e "$DATA_ROOT/$_";
       symlink "$ENV{'WRF_STRC'}/$_.pl" => "$DATA_ROOT/$_";
    }

# Copy bufr_stations.parm file to the user's static directory.
#
    system "cp -f $ENV{DATA_CONF}/tables/bufr_stations.parm $DATA_ROOT/static/bufr_stations.parm";

# Delete some of the README files and directories that either
# will be created later or are not necessary.
#
    system "rm -f  $DATA_ROOT/README" if -e "$DATA_ROOT/README";
    system "mkdir  $DATA_ROOT/grib"   if ! -e "$DATA_ROOT/grib";
    system "rm -fr $DATA_ROOT/siprd"  if -e "$DATA_ROOT/siprd";
    system "rm -fr $DATA_ROOT/wrfprd" if -e "$DATA_ROOT/wrfprd";

# Do some additional housekeeping of files are are not needed. No reason
# why this code needs to here but it should be somewhere and this seems
# as good a place as any.
#
   system "rm -f  $DATA_ROOT/static/grib_prep.*";

return;
}


sub calc_nmmco2 {
#
# STRC ADDITION
# This routine generated the co2_trans file needed by the NMM core.
# A unique co2_trans file is created for each NMMH level configuration.
#
    my $status;

    print "\n\nSTRC: Updating CO2 files for the NMM core.\n";

# Do the work in the static directory. Much easier than creating
# all the necessary links. the wrfsi.nl file must exist in the
# directory since that is where the routines obtain the model
# top pressure and the model levels.
#
    chdir "$DATA_ROOT/static";

# Do some clean up
#
    system  "rm -f co2_trans" if -e "co2_trans";

# Create necessary links to the radiation files
#
    symlink "$ENV{DATA_CONF}/tables/tr49t85" => "fort.61";
    symlink "$ENV{DATA_CONF}/tables/tr49t67" => "fort.62";
    symlink "$ENV{DATA_CONF}/tables/tr67t85" => "fort.63";

# Run the genpress program to create the "pressures.out" file
#
    system "$ENV{WRF_BIN}/genpress > $DATA_ROOT/log/co2_trans.log";

# Run the gfdlco2 to create the co2_trans file
#
    system "$ENV{WRF_BIN}/gfdlco2 >> $DATA_ROOT/log/co2_trans.log";

# Was the program successful?
#
    print "ERROR: Creation of co2_trans file failed but maybe you do not care.\n",
          "       Look in $DATA_ROOT/log/co2_trans.log for more information.\n\n" unless -e "co2_trans";

# House keeping - Do some clean up of files that are no longer needed or were never needed
# by the NMM core.
#
    system "rm -f fort.* pressure.out corners.dat created_wrf_static.dat nest_info.txt";

return $status;
}

