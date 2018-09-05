#!usr/bin/perl

# getNumLSEprime.pl - for single subjects as a part of the SPM processing pipeline
#
# This script takes the name of a single subject's eprime output file, reads it, reformats the accuracy and onset time fields 
#	and stores them to a text file on Munin to be read by the MATLAB SPM script.
#
# Usage:  perl getNumLSEprime_batch.pl infile.txt outfile.txt
# Input: infile.txt = full path to a single subject's eprime output txt file
#  
# Assumptions:
#   -The EXAM id appears in the file name between two hyphens, eg in NumLS-12345-1.txt the id is 12345

#
# Note: For some reason it is not straightforward to parse the eprime text files as they exist straight off the server. (they're in a weird binary-type format)
#   Solution: in this script we convert to utf-8 format with the following command on the terminal:
#   iconv -f utf-16 -t utf-8 oldfile.txt > newfile.txt 
#
# Annchen Knodt 9/8/2014

#use warnings;
# use Spreadsheet::WriteExcel;

print "\n***Running getNumLSEprime.pl***\n\n";

# process command line arguments
if (scalar(@ARGV) != 2) {
  print "\nSyntax: perl getNumLSEprime.pl infile.txt outdir\n";
  print "\tinfile = full path to a single subject's eprime output txt file\n";
  print "\toutdir = full path for desired dir for output files to go in\n\n";
  exit;
}
my $infile = $ARGV[0];
my $outdir = $ARGV[1];
# my $outXL = Spreadsheet::WriteExcel->new('test.xls');
# my $worksheet = $workbook->add_worksheet();

open IN, "<$infile" or die "could not open $infile";  
open OUT_M, ">$outdir/M_onsets.txt" or die "could not open $outdir/M_onsets.txt";
open OUT_J, ">$outdir/J_onsets.txt" or die "could not open $outdir/J_onsets.txt";
open OUT_CJ, ">$outdir/CJ_onsets.txt" or die "could not open $outdir/CJ_onsets.txt";
open OUT_EC, ">$outdir/EC_onsets.txt" or die "could not open $outdir/EC_onsets.txt";
open OUT_ECRJ, ">$outdir/EC_RJ_onsets.txt" or die "could not open $outdir/EC_RJ_onsets.txt";
open OUT_E, ">$outdir/E_onsets.txt" or die "could not open $outdir/E_onsets.txt";
open OUT_ERCJ, ">$outdir/E_RCJ_onsets.txt" or die "could not open $outdir/E_RCJ_onsets.txt";
open OUT_ERJ, ">$outdir/E_RJ_onsets.txt" or die "could not open $outdir/E_RJ_onsets.txt";
open OUT_inc, ">$outdir/Incorrect_onsets.txt" or die "could not open $outdir/Incorrect_onsets.txt";
open OUT_maint, ">$outdir/Maintenance_onsets.txt" or die "could not open $outdir/Maintenance_onsets.txt";

$infile =~ /-(\d+)-/;
my $ID = $1; # ID from file name
my $subj = ""; # to get ID from file later

my $converted = 0;		# 0 for no, 1 for yes, 2 for fail
my $headerline = <IN>;
if ($headerline=~m/Header Start/) { # looks like we can read this file, proceed without converting
	$converted = 0;
} else {	       # can't read the file correctly, try converting
	`iconv -f utf-16 -t utf-8 $infile > $outdir/curfile.txt`; # convert to utf-8 format
	open IN, "$outdir/curfile.txt" or die "could not open $outdir/curfile.txt"; # use this line to run with the converted file   
	$converted = 1;
	$headerline = <IN>;
	if (!$headerline=~m/Header Start/) { # still can't read the file
		print "\tBlast! Could not read file $infile in original or utf-8 format.\n";
		$converted = 2;
	}
}

# initialize variables for this subject
# my $MRTsum = $JRTsum = $CJRTsum = $ERJRTsum = $ECJRTsum = $ECRJRTsum = 0;
# my $MRespCt = $JRespCt = $CJRespCt = $ERJRespCt = $ECJRespCt = $ECRJRespCt = 0;
# my $encCt = $restCt = $JMct = 0;
# my @encFixOnsets, @encRespOnsets, @encStimOnsets, @restOnsets, @JMonsets, @encRTs, @JMRTs, @encACCs, @JMACCs, @restDurs, @text1, @text2, @text3;

# my %RTsums = ('M' => 0, 'J' => 0, 'CJ' => 0, 'ERJ' => 0, 'ECJ' => 0, 'ECRJ' => 0);
# my %RespCts = ('M' => 0, 'J' => 0, 'CJ' => 0, 'ERJ' => 0, 'ECJ' => 0, 'ECRJ' => 0);
my %stimOnsets, %respOnsets, %fixOnsets; 
my @incorrectOnsets;

my $stimOnset = $fixOnset = $respOnset = $acc = $RT = 0;

if ($converted!=2) { # go ahead and parse the file
	while (my $line = <IN>) {
	  chomp($line);

	   if ($line=~ m/Subject:/) { 
			$subj = $';
			$subj =~ s/\D//g;
	   } elsif($line=~ m/Stimulus.OnsetTime: /){ 
			$stimOnset = $';
			$stimOnset =~ s/\D//;
	   } elsif($line=~ m/EncFixation.OnsetTime: /){ 
			$fixOnset = $';
			$fixOnset =~ s/\D//;
	   } elsif($line=~ m/Response.OnsetTime: /){ 
			$respOnset = $';
			$respOnset =~ s/\D//;
	   } elsif($line=~ m/.ACC: /){ 
			$acc = $';
			$acc =~ s/\D//;
			# print "acc: $acc\n";
			# print "line: $line\n";
	   } elsif($line=~ m/.RT: /){ 
			$RT = $';
			$RT =~ s/\D//;
	   } elsif($line=~ /Procedure: (.*)proc/){ 
			$cond = $1;
			if ($subj=='28193' || $subj=='20469' ) { # these two subjects seem to have misunderstood the motor instructions
				if ($cond=='M') {
					$acc = 1;
				}
			}
			if ($acc==0){
				push(@incorrectOnsets,$stimOnset);
			} else {
				push(@{$fixOnsets{$cond}}, $fixOnset)  ;
				push(@{$stimOnsets{$cond}}, $stimOnset) ; 		
				if ($cond=='ECJ' || $cond=='ERJ' || $cond=='ECRJ') { 
					push(@{$respOnsets{$cond}}, $respOnset) ; 
				}
			}
	   } elsif($line=~ m/FixDuration: /){ 
			# $restDurs[$restCt] = $';
			# $restDurs[$restCt] =~ s/\D//;
	   } 
	  elsif ($line==EOF) {	## end of file
	  } else { # This doesn't make logical sense to me, but somehow it works...
			print "Invalid line:\n $line";
	  }

	}
	
	my $startTime = @{$stimOnsets{'ERJ'}}[0] - 4000; # first actual ITI is 4 seconds, so subtract that from first actual trial (which is a $1 cue) to get start time
	# print "startTime: $startTime\n";
	foreach $k (keys %respOnsets) { @{$respOnsets{$k}}=map { ($_-$startTime)/1000 } @{$respOnsets{$k}};	}
	foreach $k (keys %stimOnsets) { @{$stimOnsets{$k}}=map { ($_-$startTime)/1000 } @{$stimOnsets{$k}};	}
	foreach $k (keys %fixOnsets) { @{$fixOnsets{$k}}=map { ($_-$startTime)/1000 } @{$fixOnsets{$k}}; }	
	@incorrectOnsets = map { ($_ - $startTime)/1000 } @incorrectOnsets; 	
	
	# print "fixOnsets content\n";
	# foreach $k (keys %fixOnsets) {
	  # @{$fixOnsets{$k}}=map { ($_-$startTime)/1000 } @{$fixOnsets{$k}};
		# print "$k";
	   # foreach (@{$fixOnsets{$k}}) {
		  # print " : $_";
	   # }
	   # print "\n";
	# }	

	print OUT_E join("\t", @{$stimOnsets{'ERJ'}}, @{$stimOnsets{'ECJ'}}," "), "\n";
	print OUT_EC join("\t", @{$stimOnsets{'ECRJ'}}," "), "\n";
	print OUT_M join("\t", @{$stimOnsets{'M'}}," "), "\n";
	print OUT_J join("\t", @{$stimOnsets{'J'}}," "), "\n";
	print OUT_CJ join("\t", @{$stimOnsets{'CJ'}}," "), "\n";
	print OUT_ECRJ join("\t", @{$respOnsets{'ECRJ'}}," "), "\n";
	print OUT_ERCJ join("\t", @{$respOnsets{'ECJ'}}," "), "\n";
	print OUT_ERJ join("\t", @{$respOnsets{'ERJ'}}," "), "\n";
	print OUT_maint join("\t", @{$fixOnsets{'ERJ'}}, @{$fixOnsets{'ECRJ'}}, @{$fixOnsets{'ECJ'}}," "), "\n";
	print OUT_inc join("\t", @incorrectOnsets," "), "\n";
	################### incorrect
	
	  # print OUT join("\t", @encFixOnsets," "), "\n";      
	  # print OUT join("\t", @encRespOnsets," "), "\n";      
	  # print OUT join("\t", @encStimOnsets," "), "\n";      
	  # print OUT join("\t", @JMonsets," "), "\n";      
	  # print OUT join("\t", @encACCs," "), "\n";      
	  # print OUT join("\t", @JMACCs," "), "\n";      
	  # print OUT join("\t", @restOnsets," "), "\n";      
	  # print OUT join("\t", @restDurs," "), "\n";      
	  
	  # $worksheet->write(0,0, \@encFixOnsets);

	  # }

	if ($converted==1) {
	  `rm $outdir/curfile.txt`;
	}

}



print "Done!\n\n";
	
