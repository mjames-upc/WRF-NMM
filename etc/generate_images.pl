#!/usr/bin/perl
##################################################################################
# generate_images.pl *** ORIGINAL AUTHOR: Thomas Helman, NOAA FSL FRD *** ########
##################################################################################
# CHANGE HISTORY INFORMATION:
# 
# DATE-		AUTHOR-			DESCRIPTION OF MODIFICATIONS-
# --------------------------------------------------------------------------------
# 04/15/2003	thomas.helman@noaa.gov	CREATION OF INITIAL SCRIPT DESIGN
# 11/22/2003    john.r.smart@noaa.gov   ADDED DOMAIN NESTING CAPABILITY
# 
##################################################################################
# USAGE INFORMATION:
#
# EXAMPLE-
# generate_images.pl -domain=/wrfsi/domains/japan -type=avc -type=use -mode=meta -grid=01
#
# REQUIRED-
# [-domain]  	// FULL path to domain containing data for image processing
#
# OPTIONAL-
# [-type]	// DEFAULT: 
#		// if no "-type" specified, script generates default image set
#		// defined by the @DEFAULT_TYPES array in this script.
#		//
#		// OPTION(S):
#		// will process N-number of user defined "-type" values
#		//
#			
# [-mode]	// DEFAULT: 
#		// -mode=single <-generates ONLY individual *.ncgm files for
#		//		  type(s) requested.
#		//
#		// OPTION(S):
#		// -mode=meta   <-generates individual AND aggregate *.ncgm files
#		//
#
# [-grid]       // OPTION(S):
#               // specify grid (1, 2, etc., up to NUM_DOMAINS [wrfsi.nl]) or do
#               // all domains (1 to NUM_DOMAINS) if -grid omitted.
#
# HELP-
# [-h, -help]	// DEFAULT:
# 		// prints out the above usage information.
#
##################################################################################
##################################################################################

use strict;
use Getopt::Long;
use Env qw(NCARG_ROOT);
use Env qw(NCL_COMMAND);

my @DEFAULT_TYPES = ("avc", "use", "lnd", "stl", "sbl", "gnn", "gnx", "tmp", "slp", "alb", "albint");
my @OPTION_TYPES;
my @ACTIVE_TYPES;

my $DOMAIN;
my $MODE;
my $GRID;
my $HELP;
my $CURRENT_TYPE;
my @NUM_DOMAINS;
my ($i,$dom);
my $type_name;
my $num_requested = 0;
my $num_generated = 0;
my $exitcode = -1;
my $addncgm;

&GetOptions("domain=s" => \$DOMAIN, 
            "type=s" =>   \@OPTION_TYPES,
            "mode=s" =>   \$MODE,
            "grid=s" =>   \$GRID,
            "h" =>        \&printHelpMessage,
            "help" =>     \&printHelpMessage,
            "<>"  =>      \&printHelpMessage);

my $ncarg_version = ncarg_working_version();

if($ncarg_version == 1)
{
   print "Acceptable version of NCAR graphics: $ncarg_version\n\n";
}
else
{
   print "*!* Maybe you can change your NCARG_ROOT and NCL_COMMAND Environment Variables *!*\n";
   print "*!* The NCL scripts recommend NCARG-4.1.1 or higher. *!*\n\n";
   exit;
}

my $STATIC_PATH;

if(defined $DOMAIN)
{
        $STATIC_PATH = "$DOMAIN/static";
}
elsif(defined $ENV{MOAD_DATAROOT})
{
        $DOMAIN=$ENV{MOAD_DATAROOT};
        $STATIC_PATH = "$DOMAIN/static";
}
else
{
	printHelpMessage(); 
        exit;
}

my $NCL = "$NCARG_ROOT/bin/ncl";

# RAR - Changed
#require "/usr1/wrf_build/wrfsi/etc/laps_tools.pm";
require "$ENV{'WRF_ETC'}/laps_tools.pm";


print "\n\n>>> PROGRAM START: generate_images.pl <<<\n\n";
if (validateOptions() && validatePaths() )      #&& generateStaticLink())
{
	print "<*> INITIALIZATION: OK\n\n";
	
	print "<*> GENERATING IMAGES FOR DOMAIN: $DOMAIN\n";
	print "<*> DATA WILL BE CREATED IN: $DOMAIN/static\n\n";

	@NUM_DOMAINS = &laps_tools::get_nl_value("wrfsi.nl","num_domains",$DOMAIN);

        if(defined $GRID)
	{
		if($GRID > $NUM_DOMAINS[0])
		{	print "<*> GRID NUMBER ENTERED EXCEEDS NUM_DOMAINS IN wrfsi.nl\n";
                        print "<*> Grid Number = $GRID; Num_domains = $NUM_DOMAINS[0]\n\n";
			exit;
		}
		$NUM_DOMAINS[0]=$GRID;
	}else{
		$GRID=1;
        }

	if ($OPTION_TYPES[0] eq "GENERATE_DEFAULT")
	{
		print "<*> NO SPECIFIC TYPE(S) REQUESTED, GENERATING DEFAULT IMAGE SET\n\n";
		@ACTIVE_TYPES = @DEFAULT_TYPES;
	}
	else
	{
		@ACTIVE_TYPES = @OPTION_TYPES;
	}

        for ($i=$GRID; $i<=$NUM_DOMAINS[0]; $i++) {

             if(generateStaticLink())
             {

	     	foreach $type_name (@ACTIVE_TYPES)
		{
          		$CURRENT_TYPE = $type_name;
			#print "### DEBUG: \$CURRENT_TYPE = $CURRENT_TYPE\n";
                	albint() if($CURRENT_TYPE  eq "albint");
			runNCL();
			$num_requested++;
		}
                if ($MODE eq "meta")
                {
                        generateMetaNCGM();
                }

	     }
             else
             {
                #EXIT STATUS: ERROR
                print "*!* INITIALIZATION: FAILED\n";
                $exitcode = 0;
                programExit();
             }

	}

	reportSuccessRate();
}
else
{
	#EXIT STATUS: ERROR
       	print "*!* INITIALIZATION: FAILED\n\n";
        printHelpMessage();
       	$exitcode = 0;
       	programExit();
}
#EXIT STATUS: OK
$exitcode = 1;
programExit();
##################################################################################
# END MAIN PROGRAM LOGIC##########################################################
##################################################################################




sub reportSuccessRate
{
	$num_generated = 0;

        for ($i=$GRID; $i<=$NUM_DOMAINS[0]; $i++) {
             if($i<10)
             {
                $dom="d0$i";
             }
             else
             {
                $dom="d$i";
             }
             foreach $type_name (@ACTIVE_TYPES)
             {
                     $CURRENT_TYPE = $type_name;
		     $CURRENT_TYPE =~ s/.ncl//g;
                if (-e "$STATIC_PATH/$CURRENT_TYPE.$dom.ncgm")
                {
                        $num_generated++;
                }
             }
	     print "\n[*] SUCCESSFULLY GENERATED $num_generated OF $num_requested NCGM FILE(S) REQUESTED\n";
	     if ($MODE eq "meta")
             {
	         if (-e "$STATIC_PATH/meta.$dom.ncgm")
	 	 {
			print "[*] SUCCESSFULLY GENERATED FILE: meta.$dom.ncgm\n";
		 }
		 else
		 {
			print "*!* FAILED TO GENERATE FILE: meta.ncgm\n";
			$exitcode = 0;
        		programExit();
		 }
	     }
        }
}




sub generateMetaNCGM
{
        my $META_STRING = "med";
	$num_generated = 0;
        if($i<10)
        {
           $dom="d0$i";
        }
        else
        {
           $dom="d$i";
        }

	print "\n<*> META - BUILDING LIST FOR AGGREGATE FILE: meta.$dom.ncgm\n";
	
	if (-e "$STATIC_PATH/meta.$dom.ncgm")
        {
		`rm -f $STATIC_PATH/meta.$dom.ncgm`;
	}

	foreach $type_name (@ACTIVE_TYPES)
	{
		$CURRENT_TYPE = $type_name;
		$CURRENT_TYPE =~ s/.ncl//g;
		if (-e "$STATIC_PATH/$CURRENT_TYPE.$dom.ncgm") 
		{
			$addncgm = system("med -e 'r $STATIC_PATH/$CURRENT_TYPE.$dom.ncgm'");
			if($addncgm == 0)
			{
				print "<*> META - ADDING FILE: $CURRENT_TYPE.$dom.ncgm\n";
				$META_STRING = $META_STRING . " -e 'r $CURRENT_TYPE.$dom.ncgm'";
				$num_generated++;
			}
			else
			{
				print ">!< WARNING: META FILE not readable -> $CURRENT_TYPE.$dom.ncgm\n";
				print ">!< WARNING: Not adding $CURRENT_TYPE.$dom.ncgm to meta ncgm\n";
			}
		}
	}

	if ($num_generated > 0)
	{
		print "<*> META - GENERATING AGGREGATE NCGM FILE: meta.$dom.ncgm\n";
		$META_STRING = $META_STRING . " -e 'w meta.$dom.ncgm'";
		#print "###DEBUG: \$META_STRING = $META_STRING\n";
		
		`cd $STATIC_PATH;$META_STRING`;

		if (!(-e "$STATIC_PATH/meta.$dom.ncgm"))
		{
			print "*!* META - FAILED TO CREATE FILE: meta.$dom.ncgm\n";
		     	$exitcode = 0;
       			programExit();
		}
	}
	else
	{
		print "*!* META - CANNOT CREATE meta.$dom.ncgm FILE, ZERO REQUESTED NCGM FILES FOUND\n";
		$exitcode = 0;
                programExit();
	}
}




sub runNCL
{
	$CURRENT_TYPE =~ s/.ncl//g;
	if (-e "$CURRENT_TYPE.ncl")
	{
                if($i<10)
                {
                   $dom="d0$i";
                }
                else
                {
                   $dom="d$i";
                }

		if (-e "$CURRENT_TYPE.$dom.ncgm")
		{
			`rm $CURRENT_TYPE.$dom.ncgm`;
		}
        	print "<*> RUNNING NCL SCRIPT: $CURRENT_TYPE.ncl\n";
		
		$num_generated++;
		
		`$NCL_COMMAND < $CURRENT_TYPE.ncl > ncl.out`;
		`rm -f $STATIC_PATH/$CURRENT_TYPE.$dom.ncgm`;
			
		if (-e "$CURRENT_TYPE.ncgm")
                {
                        `mv $CURRENT_TYPE.ncgm $STATIC_PATH/$CURRENT_TYPE.$dom.ncgm`;
                }
		else
		{
			print ">!< WARNING: $CURRENT_TYPE.ncl FAILED TO GENERATE NCGM FILE: $CURRENT_TYPE.$dom.ncgm\n";
		}
        }
        else
        {
        	print ">!< REQUESTED NCL FILE NOT FOUND: $CURRENT_TYPE.ncl <-SKIPPING: $CURRENT_TYPE\n";
        }
}



sub generateStaticLink
{
        if($i<10)
        {  
           $dom="d0$i";
        }
        else
        {
           $dom="d$i";
        }
	#CHECK FOR STATIC FILE
        if (-e "$STATIC_PATH/static.wrfsi.$dom")
	{
		if (-e "static.cdf")
		{
			#REMOVE OLD .CDF LINK
			`rm -f static.cdf`;
		}
		#CREATE NEW .CDF LINK
		`ln -fs $STATIC_PATH/static.wrfsi.$dom static.cdf`;
	
		#CHECK FOR SUCCESSFUL .CDF LINK CREATION
                if (-e "static.cdf")
                {
			return 1;
                }
                else
		{
			print "*!* UNABLE TO CREATE LINK: static.cdf\n";
			return 0;
		}
        }
	else
        {
                print "*!* REQUIRED: static.wrfsi.$dom FILE NOT FOUND\n"; return 0;
	}
}




sub validateOptions
{
	if (!$DOMAIN)
	{
		print "*!* REQUIRED: DOMAIN VALUE NOT SET\n";
		return 0;
	}

	if (!$OPTION_TYPES[0])
	{
		#IF TYPE NOT SET, GENERATE DEFAULT IMAGES
		$OPTION_TYPES[0] = "GENERATE_DEFAULT";
	}
	
	if (!$MODE)
	{
		$MODE = "single";
	}

	return 1;
}




sub validatePaths
{
#print "### DEBUG: \$STATIC_PATH = $STATIC_PATH\n";
#print "### DEBUG: \$NCARG_ROOT = $NCARG_ROOT\n\n";

	if (!(-e "$STATIC_PATH"))
	{
		print "*!* REQUIRED: PATH DOES NOT EXIST $STATIC_PATH\n";
		return 0;
	}
        elsif (!$NCARG_ROOT)
        {
                print "*!* REQUIRED: ENVIRONMENT VARIABLE NOT SET - \$NCARG_ROOT\n";
                return 0;
        }
        elsif (!(-e "$NCARG_ROOT"))
        {
                print "*!* REQUIRED: PATH DOES NOT EXIST $NCARG_ROOT\n";
                return 0;
        }
	elsif (!$NCL_COMMAND)
        {
                print "*!* REQUIRED: ENVIRONMENT VARIABLE NOT SET - \$NCL_COMMAND\n";
                return 0;
        }
        elsif (!(-e "$NCL_COMMAND"))
        {
                print "*!* REQUIRED: COMMAND DOES NOT EXIST \$NCL_COMMAND: $NCL_COMMAND\n";
                return 0;
        }
	return 1;
}




sub printHelpMessage
{
	print "\n";
        print "##################################################################################\n";
	print "# USAGE INFORMATION: generate_images.pl\n";
	print "#\n";
	print "# EXAMPLE-\n";
	print "# generate_images.pl -domain=/wrfsi/domains/japan -type=avc -type=use -mode=meta\n";
	print "#\n";
	print "# REQUIRED-\n";
	print "# [-domain]     // FULL path to domain containing data for image processing\n";
	print "#\n";
        print "# NCAR Graphics // Version 4.3.0 or higher required for NCL scripts\n";
        print "#\n";
	print "# OPTIONAL-\n";
	print "# [-type]       // DEFAULT:\n";
	print "#               // if no '-type' specified, script generates default image set\n";
	print "#               // defined by the \@DEFAULT_TYPES array in this script.\n";
	print "#               //\n";
	print "#               // OPTION(S):\n";
	print "#               // will process N-number of user defined '-type' values\n";
	print "#               //\n";
	print "#\n";
	print "# [-mode]       // DEFAULT:\n";
	print "#               // -mode=single <-generates ONLY individual *.ncgm files for\n";
	print "#               //                type(s) requested.\n";
	print "#               //\n";
	print "#               // OPTION(S):\n";
	print "#               // -mode=meta   <-generates individual AND aggregate *.ncgm files\n";
	print "#               //\n";
        print "#\n";
        print "# [-grid]       // OPTION(S):\n";
        print "#               // specify grid (1, 2, etc up to NUM_DOMAINS [wrfsi.nl]) or do\n";
        print "#               // all domains (1 to NUM_DOMAINS) if -grid omitted.\n";
	print "#\n";
	print "##################################################################################\n\n";
        exit;
}


#-------------------------------------------------------------------
sub albint
{

       my $timetext = gmtime();
       my $timestring = "climatological albedo for $timetext"; 
#print "timestring is $timestring\n";
       my $i4time = time;
       my ($yr,$mo,$dy,$hr,$mn,$sc) = &laps_tools::i4time_to_date($i4time);
#print "after calling sub,
#       yr is $yr
#       mo is $mo
#       dy is $dy
#       hr is $hr
#       mn is $mn
#       sc is $sc\n";
#$yr = 2003;
#$mo = 1;
#$dy = 12;
#$hr = 12;
#$mn = 0;
#$sc = 0;
#($i4time) = &laps_tools::date_to_i4time($yr,$mo,$dy,$hr,$mn,$sc);

#print "i4time is $i4time\n";

# Compute i4times for 18Z the 15th of each month, and put in the
# array midtime.  Indexes of the midtime array are zero-based
# (i.e. January is $midtime[0], December is $midtime[11]

       $mo = 1;
       $dy = 15;
       $hr = 18;
       $mn = 0;
       $sc = 0;

       my @midtime;
       my ($time1,$time2,$calb1,$calb2);
       my ($month1,$month2,$weight1,$weight2);
       while ($mo <= 12) {
             ($midtime[$mo-1]) = &laps_tools::date_to_i4time($yr,$mo,$dy,$hr,$mn,$sc);
              $mo++;
       }

# Find bounding times and create weights and strings to be used by NCL code

       if ($i4time < $midtime[0]) {
           $yr--;
           $mo = 12;
          ($time1) = &laps_tools::date_to_i4time($yr,$mo,$dy,$hr,$mn,$sc);
           $time2 = $midtime[0];
           $calb1 = "a12";
           $calb2 = "a01";
       } elsif ($i4time > $midtime[11]) {
           $yr++;
           $mo = 1;
           $time1 = $midtime[11];
          ($time2) = &laps_tools::date_to_i4time($yr,$mo,$dy,$hr,$mn,$sc);
           $calb1 = "a12";
           $calb2 = "a01";
       } else {
           $mo = 1;
           while ($i4time >= $midtime[$mo-1] && $mo <= 12) {
                  $mo++;
       }
       $month1 = $mo-1;
       $month2 = $mo;
       $time1 = $midtime[$mo-2];
       $time2 = $midtime[$mo-1];
       if ($month1 < 10) {
           $month1 = "0" . $month1;
       }
       if ($month2 < 10) {
           $month2 = "0" . $month2;
       }
       $calb1 = "a$month1";
       $calb2 = "a$month2";
       }

#print "bounding times are $time1 and $time2\n";

       $weight1 = ($time2 - $i4time) / ($time2 - $time1);
       $weight2 = ($i4time - $time1) / ($time2 - $time1);

#print "weights are $weight1 and $weight2\n"; 
#print "fields are $calb1 and $calb2\n";

       open (PARMFILE, ">albintparms.txt");
       print PARMFILE "$weight1\n$weight2\n$calb1\n$calb2\n$timestring\n";
       close PARMFILE;

}

#-------------------------------------------------------------------
sub cleanUp
{
	#NOTHING TO DO
}




#-------------------------------------------------------------------
sub programExit
{
	print "\n>>> PROGRAM EXIT -- STATUS: ";
	if ($exitcode eq 1)
	{
		print "OK";	
	}
	elsif ($exitcode eq 0)
	{
		print "ERROR";
	}
	else
	{
		print "UNDEFINED";
	}
	print " <<<\n\n\n";
	cleanUp();
	exit;
}
sub ncarg_working_version
{
    my @ncgv=`$NCARG_ROOT/bin/ncargversion`;
    my ($ncargversion,$ncgv);
    my $lowestversion="411";
    foreach (@ncgv)
    {
             if($_ =~ /(\d.\d.\d)/){
                @ncgv = split /\./, $1;
                $ncargversion = $1;
                $ncgv = $ncgv[0].$ncgv[1].$ncgv[2];
                last;
             }
    }
    print "\n";
    if($ncgv < $lowestversion){
       print "*!* NCARG Version $ncargversion DOES NOT work *!*\n";
       return 0;
    }else{
       print ">>> Using NCARG Version: $ncargversion <<< \n";
       return 1;
    }
}
