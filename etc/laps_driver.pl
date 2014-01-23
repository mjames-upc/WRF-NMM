#!/usr/bin/perl
# Generated automatically by make_script.pl
#
# laps_driver.pl
#
# Ensures that no more than $plimit  processes with the same name exist(s)  
# exits with a warning to stderr if the limit is exceeded  
#
# Copyright (C) 1998  James P. Edwards
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
#
# Command line arguments
#
# -g                   Run for archive time, specified by number of seconds since
#                      Jan 1 1970 at 0000 UTC; used for archive time on log filename.
#
# -L                   Run for input analysis time specified as dd-mmm-yyyy-hhmm
#                      which can also substitute for archive time (Eg., 28-Aug-2002-1200)
#                      used for archive time on log filename
#
# -q  P                Use QSUB (PBS syntax on 'jet/ijet') where P is the project name
#
# -Q  P                Use QSUB (SGE syntax on 'jet/ijet') where P is the project name
#
# -n                   Node type to be used with -q (default=comp)
#
# -e  e1,e2,...        Environment variables (if any) to pass into the executable
#
# -l                   Write log files to LAPS_DATA_ROOT/log, even if on AWIPS..
#
# third to last arg    Executable name
#
# second to last arg   $LAPSINSTALLROOT, one level above bin directory
#
# last arg             $LAPS_DATA_ROOT, path to data directory
#                      purger (see call to purger.pl)
#

use strict;
use vars qw($opt_L $opt_g $opt_o $opt_e $opt_l $opt_q $opt_Q $opt_n);
use Getopt::Std;

getopts('e:lq:Q:n:L:g:');

#flush buffer; ie., prevent buffering of output
$|=1;

my $exe = shift || die "Program name and LAPS root directory required";
my $LAPSROOT=shift || die "LAPS root directory required";
require "$LAPSROOT/etc/fxa.pm";
umask 002;
my $fxa_sys =  &Get_env'fxa; #'
# RAR Changed
#$ENV{PATH}.=":/usr/local/netcdf/bin";
$ENV{PATH}.=":$ENV{'NETCDF'}/bin";
# RAR

$ENV{LAPS_DATA_ROOT} = shift ;
$ENV{LAPS_DATA_ROOT} = "$LAPSROOT/data" if ! $ENV{LAPS_DATA_ROOT};
my $LAPS_DATA_ROOT = $ENV{LAPS_DATA_ROOT};

if($opt_e){
    foreach(split(/,/,$opt_e)){
	/^(\w+)=(\w+)$/;
	$ENV{$1} = $2;
    }
}


my($LAPS_LOG_PATH);
if(($fxa_sys!=0)and(! $opt_l)){
    $LAPS_LOG_PATH = &Set_logdir'fxa; #'
}else{
    $LAPS_LOG_PATH = "$LAPS_DATA_ROOT/log";
}

#
# Make sure the requested program exists
#
unless(-x "$LAPSROOT/bin/$exe"){
    die "Program $LAPSROOT/bin/$exe not found or not executable";
}

#
# Construct 'yyjjjhhmm' for the current time
#
require "$LAPSROOT/etc/laps_tools.pm";

my $archive_time = -99;  #insures that we don't force $yyjjjhhmm to the nearest cycle
#                         when calling &laps_tools::systime below.

$archive_time = $opt_g if(defined $opt_g);

my @cycle_time=&laps_tools::get_nl_value("nest7grid.parms","laps_cycle_time_cmn",$LAPS_DATA_ROOT);
my $cycle_time = ($cycle_time[0]>0)?$cycle_time[0]:3600;

my @MON = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
my $LAPS_LOCK_PATH = $LAPS_LOG_PATH;

if(defined $opt_L){
   if(length($opt_L) != 16){
      print "USEAGE: use -L to input time with the following format\n";
      print "dd-mmm-yyyy-hhmm. Eg., 28-Aug-2002-1200 \n";
      exit;
   }
   my $mon=0;
   my ($day,$month,$year,$hoursmin)=split /\-/, $opt_L;
   my $hours   = substr($hoursmin,0,2);
   my $minutes = substr($hoursmin,2,2);
   foreach (@MON){
       if($_ eq (uc $month)){last;}
       $mon++;
   }
   $mon=$mon+1;
   $mon="0".$mon if(length($mon)<2);

   $archive_time = &laps_tools::date_to_i4time($year,$mon,$day,$hours,$minutes,"00");
   if(-e "/tmp/laps_casererun_log"){
      $LAPS_LOCK_PATH = "/tmp/laps_casererun_log";
   }

}

#this for logfile names only.
#---------------------------
my $delay_time = 0;
my $yyjjjhhmm=&laps_tools::systime($LAPS_DATA_ROOT,$delay_time,$cycle_time,$archive_time);

my $log = $exe;
#$log =~ s/\..*$/\.log\.$hhmm/;
$log =~ s/\..*$/\.log\.$yyjjjhhmm/;
open(SAVEOUT,">&STDOUT");
open(SAVEERR,">&STDERR");
open(STDOUT, ">$LAPS_LOG_PATH/$log") || die "Can't redirect stdout to $LAPS_LOG_PATH/$log";
open(STDERR, ">&STDOUT") || die "Can't dup stdout";
select(STDERR); $| = 1;
select(STDOUT); $| = 1;
#
# Look for a previous lock for this exe in the log directory
#




my(@locks);
opendir(LOCKDIR,"$LAPS_LOCK_PATH");
@locks = grep /^\.lock$exe/, readdir(LOCKDIR);
closedir(LOCKDIR);

foreach(@locks){
    $_ =~ /^\.lock$exe\.(\d+)$/;
    my $jpid = $1;
    open(LFH,"$LAPS_LOCK_PATH/$_");
    my $cid = <LFH>;
    close(LFH);
    next unless ($cid>1);
    open(PS,"ps -ef |");
    my @ps = <PS>;
    close(PS);
#
# Kill any children of the child
#
    foreach(@ps){
	if ($_ =~ /\s+(\d+)\s+$cid\s+/){
	    print "Killing process $1\n";
	    kill -9,$1;
	}
    }
#
# Kill the child
#    
    print "WARNING Found LOCK file for $exe with pid $jpid and child $cid - killing process $cid\n";
    kill -9,$cid if($cid>0);
    unlink "$LAPS_LOCK_PATH/$_";
}

my $lockfile = "$LAPS_LOCK_PATH/\.lock$exe\.$$";

#open(LOCK,">$lockfile");
#close(LOCK);

my $command;
my $t;
my $node_type = "comp";

if($opt_q || $opt_Q){
    if($opt_n){
        $node_type = $opt_n;
    }

    print $t." Opening $LAPS_LOG_PATH/run_qsub_$exe.sh starting with executable $exe\n";
    open(TFILE,">$LAPS_LOG_PATH/run_qsub_$exe.sh");
    print TFILE "#!/bin/sh\n";

    if($opt_q){
        print TFILE "#PBS -lnodes=1:$node_type,walltime=30:00 -A $opt_q\n";
    }elsif($opt_Q){ 
        print TFILE "#\$ -pe $node_type 1\n";
        print TFILE "#\$ -l h_rt=0:30:00\n";
        print TFILE "#\$ -A $opt_Q\n";
        print TFILE "#\$ -S /bin/sh\n";
        print TFILE "#\$ -cwd\n";
    }

    print TFILE "  \n";
    if($opt_q){
        print TFILE "export PBS_MODE=1\n";
    }
    print TFILE "  \n";
    print TFILE "cd $LAPS_LOG_PATH\n";
    print TFILE "  \n";
    print TFILE "export LAPS_DATA_ROOT=$LAPS_DATA_ROOT\n";

    print " Adding to $LAPS_LOG_PATH/run_qsub_$exe.sh with executable/nodes $exe $opt_q\n";
    print TFILE "  \n";
    print TFILE "$LAPSROOT/bin/$exe 1> $LAPS_LOG_PATH/$log 2>&1\n";

    print TFILE "  \n";
    print $t." Closing $LAPS_LOG_PATH/run_qsub_$exe.sh with executable $exe\n";
    close(TFILE);

    chdir($LAPS_LOG_PATH) || die "could not chdir to $LAPS_LOG_PATH";
    $command = "bin/qsub_wait $LAPS_LOG_PATH/run_qsub_$exe.sh";
    print "Executing $command\n";
    system("$command");

}else{
    my $sys = "$LAPSROOT/bin/$exe ";
#   system($sys);
#   unlink "$lockfile";
    &forksub($sys,$lockfile);

}

exit;

sub forksub{
    my($sys,$lockfile) = @_;
  FORK: {      
      my $pid;
      if($pid = fork) {
	  # parent process
	  open(LOCK,">$lockfile");
	  print LOCK "$pid\n";
	  close(LOCK);
	
	  waitpid $pid,0;
	  unlink "$lockfile";


      }elsif (defined $pid) { 
	  #child here
	  exec($sys);
	  unlink "$lockfile";
	  exit;
      }elsif ($! =~ /No more process/){
	  # EAGAIN, recoverable fork error
	  sleep 5;
	  redo FORK;
      }else{
	  die "Can't fork: $!\n";
      }
  }
}






