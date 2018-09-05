#!usr/bin/perl

# getNumLSEprime_batch.pl
#
# This script takes in a list of eprime output files as a text file, reads them, calculates accuracy, response time, 
#   and many other ratios/stats (overall and per block and condition) and writes the tab-delimited output to the specified file, one subject per line
#
# Usage:  perl getNumLSEprime_batch.pl infile.txt outfile.txt
# Input: infile.txt = list of files to parse - does not work if the file name list is generated in excel!
#  instead use "find /Volumes/Hariri/DNS.01/Data/Behavioral/Cards" (e.g. for Mac) on command line to list full path of the 
#  directory's contents and paste those to a text file
# Assumptions:
#   -The DNS id appears in the file name between to hyphens, eg in Duke_Cards_revise12-0437-1.txt, the ID is 437

#
# Note: For some reason it is not straightforward to parse the eprime text files as they exist straight off the server.
#   Solution: in this script we convert to utf-8 format with the following command on the terminal:
#   iconv -f utf-16 -t utf-8 oldfile.txt > newfile.txt 
#
# Annchen Knodt 9/8/2014

#use warnings;
# use Spreadsheet::WriteExcel;
use List::Util qw(sum);

# process command line arguments
if (scalar(@ARGV) != 2) {
  print "\nSyntax: perl getNumLSEprime_batch.pl infile.txt outfile.txt\n";
  print "\tinfile = text file containing list of ePrime files to parse (one per line)\n";
  print "\toutfile = desired name for output file\n\n";
  exit;
}
my $infile = $ARGV[0];
my $outfile = $ARGV[1];
# my $outXL = Spreadsheet::WriteExcel->new('test.xls');
# my $worksheet = $workbook->add_worksheet();

open LIST, "<$infile" or die "could not open $infile";
open OUT, ">$outfile" or die "could not open $outfile";
open OUTF, ">failedFiles.txt" or die "could not open failedFiles.txt";

print "\n***Running getNumLSEprime_batch.pl***\nSee failedFiles.txt for list of unreadable files.\nAlso see comments in the script if you need help.\n\n";

print OUT "ID\tfile\tTOTAL_acc\tECJ_acc\tECRJ_acc\tERJ_acc\tCJ_acc\tJ_acc\tM_acc\tTOTAL_RT\tECJ_RT\tECRJ_RT\tERJ_RT\tCJ_RT\tJ_RT\tM_RT\n";

# order of trial types is the same for every subject, even though the ITI between them differ
my @ECJ_ind=(	1,8,14,16,17,19,21,24,28,29	);
my @ECRJ_ind=(	2,5,11,13,15,18,22,23,26,27	);
my @ERJ_ind=(	0,3,4,6,7,9,10,12,20,25	);
my @CJ_ind=	(	2,7,8,15,18,20,25,26,27,28	);
my @J_ind=	(	0,4,9,10,11,14,19,21,24,29	);
my @M_ind=	(	1,3,5,6,12,13,16,17,22,23	);


# print header to output file
# print OUT "The order of the task blocks (and their representation here) are as follows: Win (W1), Loss (L1), Control, Win (W2), Loss (L2), Control, Win (W3), Loss (L3), Control\n";
# print OUT "ID from File Name\tID from File\tFile name\tControl % Responded\tControl Avg RT\tWin % Responded\tWin Avg RT\tLoss % Responded\tLoss Avg RT\tAvg Win/Responded (Win blocks)\tAvg Loss/Responded (Lose blocks)\tAvg Win/Total (Win blocks)\tAvg Loss/Total (Loss blocks)\tWin/Responded (W1)\tWin/Responded (W2)\tWin/Responded (W3)\tLoss/Responded (L1)\tLoss/Responded (L2)\tLoss/Responded (L3)\tWin/Total (W1)\tWin/Total (W2)\tWin/Total (W3)\tLoss/Total (L1)\tLoss/Total (L2)\tLoss/Total (L3)\tWin FB count (W1)\tWin FB count (L1)\tWin FB count (W2)\tWin FB count (L2)\tWin FB count (W3)\tWin FB count (L3)\tLoss FB count (W1)\tLoss FB count (L1)\tLoss FB count (W2)\tLoss FB count (L2)\tLoss FB count (W3)\tLoss FB count (L3)\tNo FB count (W1)\tNo FB count (L1)\tNo FB count (W2)\tNo FB count (L2)\tNo FB count (W3)\tNo FB count (L3)\n";

# read file list line-by-line
while (my $file = <LIST>) {    
  chomp($file);
  print "Reading file: $file\n";
  $file =~ /-(\d+)-/;
  my $ID = $1; # ID from file name
  my $subj = ""; # ID from file

  open IN, "<$file" or die "could not open $file";  
  my $converted = 0;		# 0 for no, 1 for yes, 2 for fail
  my $headerline = <IN>;
  if ($headerline=~m/Header Start/) { # looks like we can read this file, procede without converting
    $converted = 0;
  } else {	       # can't read the file correctly, try converting
    `iconv -f utf-16 -t utf-8 $file > curfile.txt`; # convert to utf-8 format
    open IN, "curfile.txt" or die "could not open curfile.txt"; # use this line to run with the converted file   
    $converted = 1;
    $headerline = <IN>;
    if (!$headerline=~m/Header Start/) { # still can't read the file
      print "\tBlast! Could not read file $file in original or utf-8 format. Adding this to failedFiles.txt.\n";
      $converted = 2;
      print OUTF "$file could not be read even after converting to utf-8 format\n";
    }
  }

  # initialize variables for this subject
  my $MRTsum = $JRTsum = $CJRTsum = $ERJRTsum = $ECJRTsum = $ECRJRTsum = 0;
  my $MRespCt = $JRespCt = $CJRespCt = $ERJRespCt = $ECJRespCt = $ECRJRespCt = 0;
  
  my $encCt = $restCt = $JMct = 0;
  my @encFixOnsets, @encRespOnsets, @encStimOnsets, @restOnsets, @JMonsets, @encRTs, @JMRTs, @encACCs, @JMACCs, @restDurs, @text1, @text2, @text3;
  
  if ($converted!=2) { # go ahead and parse the file
    my $blockNum = 0;	       # to keep track of which block (out of win/loss blocks) we're in
    my $condition = ""; 
    while (my $line = <IN>) {
      chomp($line);

       if ($line=~ m/Subject:/) { 
	 $subj = $';
	 $subj =~ s/\D//g;
       } elsif($line=~ m/EncStimulus.OnsetTime: /){ 
			$encStimOnsets[$encCt] = $';
			$encStimOnsets[$encCt] =~ s/\D//;
	   } elsif($line=~ m/EncFixation.OnsetTime: /){ 
			$encFixOnsets[$encCt] = $';
			$encFixOnsets[$encCt] =~ s/\D//;
	   } elsif($line=~ m/EncResponse.OnsetTime: /){ 
			$encRespOnsets[$encCt] = $';
			$encRespOnsets[$encCt] =~ s/\D//;
	   } elsif($line=~ m/EncResponse.ACC: /){ 
			$encACCs[$encCt] = $';
			$encACCs[$encCt] =~ s/\D//;
	   } elsif($line=~ m/EncResponse.RT: /){ 
			$encRTs[$encCt] = $';
			$encRTs[$encCt] =~ s/\D//;
			$encCt++; # finished an encoding block
	   } elsif($line=~ m/FixDuration: /){ 
			$restDurs[$restCt] = $';
			$restDurs[$restCt] =~ s/\D//;
	   } elsif($line=~ m/Fixation.OnsetTime: /){ 
			$restOnsets[$restCt] = $';
			$restOnsets[$restCt] =~ s/\D//;
			$restCt++;
	   } elsif($line=~ m/Stimulus.OnsetTime: /){ 
			$JMonsets[$JMct] = $';
			$JMonsets[$JMct] =~ s/\D//;
	   } elsif($line=~ m/Stimulus.ACC: /){ 
			$JMACCs[$JMct] = $';
			$JMACCs[$JMct] =~ s/\D//;
	   } elsif($line=~ m/Stimulus.RT: /){ 
			$JMRTs[$JMct] = $';
			$JMRTs[$JMct] =~ s/\D//;
			$JMct++; # finished an encoding block
	   }
      elsif ($line==EOF) {	## end of file
      } else { # This doesn't make logical sense to me, but somehow it works...
	print "Invalid line:\n $line";
      }

    }

	#my $numerator = sum @encACCs;#, @JMACCs;
	my $totalAcc = (sum( @encACCs, @JMACCs))/60;
	my $ECJacc = (sum @encACCs[@ECJ_ind])/10;
	my $ECRJacc = (sum @encACCs[@ECRJ_ind])/10;
	my $ERJacc = (sum @encACCs[@ERJ_ind])/10;
	my $CJacc = (sum @JMACCs[@CJ_ind])/10;
	my $Jacc = (sum @JMACCs[@J_ind])/10;
	my $Macc = (sum @JMACCs[@M_ind])/10;
	my $totalRT = (sum @encRTs, @JMRTs)/60;
	my $ECJRT = (sum @encRTs[@ECJ_ind])/10;
	my $ECRJRT = (sum @encRTs[@ECRJ_ind])/10;
	my $ERJRT = (sum @encRTs[@ERJ_ind])/10;
	my $CJRT = (sum @JMRTs[@CJ_ind])/10;
	my $JRT = (sum @JMRTs[@J_ind])/10;
	my $MRT = (sum @JMRTs[@M_ind])/10;
	
	print OUT "$subj\t$file\t$totalAcc\t$ECJacc\t$ECRJacc\t$ERJacc\t$CJacc\t$Jacc\t$Macc\t$totalRT\t$ECJRT\t$ECRJRT\t$ERJRT\t$CJRT\t$JRT\t$MRT\n";
	
    if ($converted==1) {
      `rm curfile.txt`;
    }

  }

}

print "Done!\n\n";
	
