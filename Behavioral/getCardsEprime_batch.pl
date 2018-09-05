#!usr/bin/perl

# getCardsEprime_batch.pl
#
# This script takes in a list of eprime output files as a text file, reads them, calculates accuracy, response time, 
#   and many other ratios/stats (overall and per block and condition) and writes the tab-delimited output to the specified file, one subject per line
#
# Usage:  perl getCardsEprime_batch.pl infile.txt outfile.txt
# Input: infile.txt = list of files to parse - does not work if the file name list is generated in excel!
#  instead use "find /Volumes/Hariri/DNS.01/Data/Behavioral/Cards" (e.g. for Mac) on command line to list full path of the 
#  directory's contents and paste those to a text file
# Assumptions:
#   -The DNS id appears in the file name between to hyphens, eg in Duke_Cards_revise12-0437-1.txt, the ID is 437
#   -The string "RewardBlockProc" or "LossBlockProc" only appears once at the end of each block
#   -Block order is PF, NF, C, PF, NF, C, PF, NF, C
#   -The subject saw a response if RT!=0 (note the ACC field in the eprime file is meaningless bc the correct response is always programmed to be 1)
#   -5 trials per block
#
# Note: For some reason it is not straightforward to parse the eprime text files as they exist straight off the server.
#   Solution: in this script we convert to utf-8 format with the following command on the terminal:
#   iconv -f utf-16 -t utf-8 oldfile.txt > newfile.txt 
#
# Annchen Knodt 12/17/2011

#use warnings;

# global variables 
my $nTrials = 15;		# same for each condition

# process command line arguments
if (scalar(@ARGV) != 2) {
  print "\nSyntax: perl getCardsEprime_batch.pl infile.txt outfile.txt\n";
  print "\tinfile = text file containing list of ePrime files to parse (one per line)\n";
  print "\toutfile = desired name for output file\n\n";
  exit;
}
my $infile = $ARGV[0];
my $outfile = $ARGV[1];

open LIST, "<$infile" or die "could not open $infile";
open OUT, ">$outfile" or die "could not open $outfile";
open OUTF, ">failedFiles.txt" or die "could not open failedFiles.txt";

print "\n***Running getCardsEprime_batch.pl***\nSee failedFiles.txt for list of unreadable files.\nAlso see comments in the script if you need help.\n\n";

# print header to output file
print OUT "The order of the task blocks (and their representation here) are as follows: Win (W1), Loss (L1), Control, Win (W2), Loss (L2), Control, Win (W3), Loss (L3), Control\n";
print OUT "ID from File Name\tID from File\tFile name\tControl % Responded\tControl Avg RT\tWin % Responded\tWin Avg RT\tLoss % Responded\tLoss Avg RT\tAvg Win/Responded (Win blocks)\tAvg Loss/Responded (Lose blocks)\tAvg Win/Total (Win blocks)\tAvg Loss/Total (Loss blocks)\tWin/Responded (W1)\tWin/Responded (W2)\tWin/Responded (W3)\tLoss/Responded (L1)\tLoss/Responded (L2)\tLoss/Responded (L3)\tWin/Total (W1)\tWin/Total (W2)\tWin/Total (W3)\tLoss/Total (L1)\tLoss/Total (L2)\tLoss/Total (L3)\tWin FB count (W1)\tWin FB count (L1)\tWin FB count (W2)\tWin FB count (L2)\tWin FB count (W3)\tWin FB count (L3)\tLoss FB count (W1)\tLoss FB count (L1)\tLoss FB count (W2)\tLoss FB count (L2)\tLoss FB count (W3)\tLoss FB count (L3)\tNo FB count (W1)\tNo FB count (L1)\tNo FB count (W2)\tNo FB count (L2)\tNo FB count (W3)\tNo FB count (L3)\n";

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
  my $contRTsum = $winRTsum = $lossRTsum = 0;
  my $contRespCt = $winRespCt = $lossRespCt = 0;
  # variables to keep track of how man times the subject saw each type of feedback in each block
  # for each vector, entries 0,2,4 represent the 3 win blocks (in order), and entries 1,3,5 represent the 3 lose blocks
  my @winFB = (0,0,0,0,0,0); # one entry for each block
  my @lossFB = (0,0,0,0,0,0); # one entry for each block
  my @noFB = (0,0,0,0,0,0); # one entry for each block

  if ($converted!=2) { # go ahead and parse the file
    my $blockNum = 0;	       # to keep track of which block (out of win/loss blocks) we're in
    my $condition = ""; 
    while (my $line = <IN>) {
      chomp($line);

      if ($line=~ m/Subject:/) { 
	$subj = $';
	$subj =~ s/\D//g;
      } elsif($line=~ m/RewardBlockProc/ || $line=~m/LossBlockProc/){ # finished a win or loss block
	$blockNum++;
      } elsif($line=~ m/TrialCondition: /){
	$condition = $';
	$condition =~ s/\s//;
      } 

      elsif ($line=~ m/GamStim.RT:/) { # in Win or Loss trial
	$RT = $';
	$RT =~ s/\D//g;
	if ($RT!=0) {		# subject saw feedback on this trial
	  if ($condition eq 'Reward') { # reward trial
	    $winFB[$blockNum]++;
	  } elsif ($condition eq 'Loss') { # loss trial
	    $lossFB[$blockNum]++;
	  } else {
	    print "Unknown condition: $condition\n";
	  }			
	  if ($blockNum%2==0) { # win block
	    $winRTsum+=$RT;
	  } else {		# lose block
	    $lossRTsum+=$RT;
	  }
	} else {		# no feedback
	  $noFB[$blockNum]++;
	}
      } 
      
      elsif ($line=~ m/ControlStim.RT:/) { # in Control trial
	$RT = $';
	$RT =~ s/\D//g;
	$contRTsum+=$RT;
	if($RT!=0){
	  $contRespCt++;
	}
      } 

      elsif ($line==EOF) {	## end of file
      } else { # This doesn't make logical sense to me, but somehow it works...
	print "Invalid line:\n $line";
      }

    }

    my $totFBct = eval join '+', @noFB, @winFB, @lossFB; 
    if ($totFBct!=30) {		# 2*$nTrials
      print "\tBlast! Could only read $totFBct/30 gaming trials. Adding file $file to failedFiles.txt.\n";
      print OUTF "$file only read $totFBct/30 gaming trials\n";      
    } 

    else {  # calculate the stats, being careful not to divide by 0
      $winRespCt = $winFB[0]+$winFB[2]+$winFB[4]+$lossFB[0]+$lossFB[2]+$lossFB[4]; # sum of all feedback during win blocks
      $lossRespCt = $lossFB[1]+$lossFB[3]+$lossFB[5]+$winFB[1]+$winFB[3]+$winFB[5]; # sum of all feedback during lose blocks
      my $avgContRT = $avgWinRT = $avgLossRT = 0;
      if ($contRespCt!=0) { $avgContRT = $contRTsum/$contRespCt; }
      my $avgContResp = $contRespCt/$nTrials;
      if ($contRespCt!=0) { $avgWinRT = $winRTsum/$winRespCt; }
      my $avgWinResp = $winRespCt/$nTrials;
      if($contRespCt!=0) { $avgLossRT = $lossRTsum/$lossRespCt;}
      my $avgLossResp = $lossRespCt/$nTrials;
      my @winRespRatio = @lossRespRatio = (0,0,0);
      if ($noFB[0]!=5) { $winRespRatio[0] = $winFB[0]/($winFB[0]+$lossFB[0]); }
      if ($noFB[2]!=5) { $winRespRatio[1] = $winFB[2]/($winFB[2]+$lossFB[2]); }
      if ($noFB[4]!=5) { $winRespRatio[2] = $winFB[4]/($winFB[4]+$lossFB[4]); }
      if ($noFB[1]!=5) { $lossRespRatio[0] = $lossFB[1]/($winFB[1]+$lossFB[1]); }
      if ($noFB[3]!=5) { $lossRespRatio[1] = $lossFB[3]/($winFB[3]+$lossFB[3]); }
      if ($noFB[5]!=5) { $lossRespRatio[2] = $lossFB[5]/($winFB[5]+$lossFB[5]); }
      my @winTotRatio = ($winFB[0]/5,$winFB[2]/5,$winFB[4]/5);
      my @lossTotRatio = ($lossFB[1]/5,$lossFB[3]/5,$lossFB[5]/5);
      my $avgWinRespRatio = ($winRespRatio[0]+$winRespRatio[1]+$winRespRatio[2])/3;
      my $avgLossRespRatio = ($lossRespRatio[0]+$lossRespRatio[1]+$lossRespRatio[2])/3;
      my $avgWinTotRatio = ($winTotRatio[0]+$winTotRatio[1]+$winTotRatio[2])/3;
      my $avgLossTotRatio = ($lossTotRatio[0]+$lossTotRatio[1]+$lossTotRatio[2])/3;
      print OUT join("\t", $ID,$subj,$file,$avgContResp,$avgContRT,$avgWinResp,$avgWinRT,$avgLossResp,$avgLossRT,$avgWinRespRatio,$avgLossRespRatio,$avgWinTotRatio,$avgLossTotRatio,@winRespRatio,@lossRespRatio,@winTotRatio,@lossTotRatio,@winFB,@lossFB,@noFB," "), "\n";      
    }

    if ($converted==1) {
      `rm curfile.txt`;
    }

  }

}

print "Done!\n\n";
	
