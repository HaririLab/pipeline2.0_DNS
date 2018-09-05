#!usr/bin/perl

# getFacesEprime_batch.pl
#
# This script takes in a list of eprime output files as a text file, reads them, calculates accuracy and response time (per block), 
#  and writes the output to the specified file, one subject per line
#
# Usage:  perl getFacesEprime_batch.pl infile.txt outfile.txt
# Input: infile.txt = list of files to parse - does not work if the file name list is generated in excel!
#  instead use "find /Volumes/Hariri/DNS.01/Data/Behavioral/Faces" (e.g. for Mac) on command line to list full path of the 
#  directory's contents and paste those to a text file
# Assumptions:
#   -The DNS id appears in the file name between to hyphens, eg in HaririFaces2_revise12-407-1.txt, the ID is 407
#   -6 trials per block
#
# Note: For some reason it is not straightforward to parse the eprime text files as they exist straight off the server.
#   Solution: in this script we convert to utf-8 format with the following command on the terminal:
#   iconv -f utf-16 -t utf-8 oldfile.txt > newfile.txt 
#   -I should add a catch for being unable to open a file (currently dies) and for any response count = 0 (currently skips subject)
#
# Annchen Knodt 12/17/2011
# 4/16/14 - added RT calc for just correct trials (ARK)

# global variables
my $nShapesTrials = 30; 
my $nExpTrials = 6;		# Same for each expression
my $nFacesTrials = 24;		# including all expressions

# process command line arguments
if (scalar(@ARGV) != 2) {
  print "\nSyntax: getFacesEprime_batch.pl infile.txt outfile.txt\n";
  print "\tinfile = text file containing list of ePrime files to parse (one per line)\n";
  print "\toutfile = desired name for output file\n\n";
  exit;
}
my $infile = $ARGV[0];
my $outfile = $ARGV[1];

open LIST, "<$infile" or die "could not open $infile";
open OUT, ">$outfile" or die "could not open $outfile";
open OUTF, ">failedFiles.txt" or die "could not open failedFiles.txt";

print "\n***Running getFacesEprime_batch.pl***\nSee failedFiles.txt for list of unreadable files.\nAlso see comments in the script if you need help.\n\n";

# print header to output file
print OUT "ID from file name\tID from file\tDNS_ID\tOrder#\tFaces accuracy\tFaces avg RT - all trials\tFaces avg RT - correct trials\tShapes accuracy\tShapes avg - all trials\tShapes avg RT - correct trials\tAnger accuracy\tAnger avg RT - all trials\tAnger avg RT - correct trials\tFear accuracy\tFear avg RT - all trials\tFear avg RT - correct trials\tNeutral accuracy\tNeutral avg RT - all trials\tNeutral avg RT - correct trials\tSurprise accuracy\tSurprise avg RT - all trials\tSurprise avg RT - correct trials\tFile name\n";

# read file list line-by-line
while (my $file = <LIST>) {    
  chomp($file);
  print "Reading file: $file\n";
  $file =~ /-(\d+)-/;
  my $ID = $1; # ID from file name
  $file =~ /HaririFaces(\d)/;
  my $order = $1; # order number
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
    if (!$headerline=~m/Header Start/) { # Still can't read the file
      print "\tBlast! Could not read file $file in original or utf-8 format.  Adding this to failedFiles.txt.\n";
      $converted = 2;
      print OUTF "$file could not be read even after converting to utf-8 format\n";
    }
  }

  # initialize variables for this subject
  my $shapesRTsum = $facesRTsum = $angerRTsum = $neutralRTsum = $surpriseRTsum = $fearRTsum = 0;
  my $shapesRTsum_correct = $facesRTsum_correct = $angerRTsum_correct = $neutralRTsum_correct = $surpriseRTsum_correct = $fearRTsum_correct = 0; # correct trials only
  my $shapesRespCt = $facesRespCt = $angerRespCt = $neutralRespCt = $surpriseRespCt = $fearRespCt = 0;
  my $shapesAccSum = $facesAccSum = $angerAccSum = $neutralAccSum = $surpriseAccSum = $fearAccSum = 0;
  if ($converted!=2) {
    while (my $line = <IN>) {

      chomp($line);
      if ($line=~ m/Subject:/) { 
	$subj = $';
	$subj =~ s/\D//g;
      } elsif ($line=~ m/ShapesTrialProbe.ACC/) { # in Shapes
	$ACC = $';
	$ACC =~ s/\D//g;
	$shapesAccSum+=$ACC;
      } elsif ($line=~ m/ShapesTrialProbe.RT:/) { # in Shapes
	$RT = $';
	$RT =~ s/\D//g;
	$shapesRTsum+=$RT;
	if ($RT!=0) {
	  $shapesRespCt++;
	}
		if ($ACC==1) { # we can do this bc the ACC line comes before the RT line
	$shapesRTsum_correct+=$RT;
	}
      } elsif ($line=~ m/FearFacesProcProbe.ACC/) { # in Fear
	$ACC = $';
	$ACC =~ s/\D//g;
	$fearAccSum+=$ACC;
	$facesAccSum+=$ACC;
      } elsif ($line=~ m/FearFacesProcProbe.RT:/) { # in Fear
	$RT = $';
	$RT =~ s/\D//g;
	$fearRTsum+=$RT;
	$facesRTsum+=$RT;
	if ($RT!=0) {
	  $fearRespCt++;
	  $facesRespCt++;
	}
	if ($ACC==1) { # we can do this bc the ACC line comes before the RT line
	$fearRTsum_correct+=$RT;
	$facesRTsum_correct+=$RT;
	}
      } elsif ($line=~ m/AngryFacesProcProbe.ACC/) { # in Angry
	$ACC = $';
	$ACC =~ s/\D//g;
	$angerAccSum+=$ACC;
	$facesAccSum+=$ACC;
      } elsif ($line=~ m/AngryFacesProcProbe.RT:/) { # in Angry
	$RT = $';
	$RT =~ s/\D//g;
	$angerRTsum+=$RT;
	$facesRTsum+=$RT;
	if ($RT!=0) {
	  $angerRespCt++;
	  $facesRespCt++;
	}
	if ($ACC==1) { # we can do this bc the ACC line comes before the RT line
	$angerRTsum_correct+=$RT;
	$facesRTsum_correct+=$RT;
	}	
      } elsif ($line=~ m/SurpriseFacesProcProbe.ACC/) { # in Surprise
	$ACC = $';
	$ACC =~ s/\D//g;
	$surpriseAccSum+=$ACC;
	$facesAccSum+=$ACC;
      } elsif ($line=~ m/SurpriseFacesProcProbe.RT:/) { # in Surprise
	$RT = $';
	$RT =~ s/\D//g;
	$surpriseRTsum+=$RT;
	$facesRTsum+=$RT;
	if ($RT!=0) {
	  $surpriseRespCt++;
	  $facesRespCt++;
	}
	if ($ACC==1) { # we can do this bc the ACC line comes before the RT line
	$surpriseRTsum_correct+=$RT;
	$facesRTsum_correct+=$RT;
	}	
      } elsif ($line=~ m/NeutralFacesProcProbe.ACC/) { # in Neutral
	$ACC = $';
	$ACC =~ s/\D//g;
	$neutralAccSum+=$ACC;
	$facesAccSum+=$ACC;
      } elsif ($line=~ m/NeutralFacesProcProbe.RT:/) { # in Neutral
	$RT = $';
	$RT =~ s/\D//g;
	$neutralRTsum+=$RT;
	$facesRTsum+=$RT;
	if ($RT!=0) {
	  $neutralRespCt++;
	  $facesRespCt++;
	}
	if ($ACC==1) { # we can do this bc the ACC line comes before the RT line
	$neutralRTsum_correct+=$RT;
	$facesRTsum_correct+=$RT;
	}	
      } elsif ($line==EOF) {	## end of file
      } else {
	print "Invalid line:\n $line";
      }
    }

    if ($shapesRespCt==0 || $facesRespCt==0 || $fearRespCt==0 || $angerRespCt==0 || $neutralRespCt==0 || $surpriseRespCt==0 || $shapesAccSum==0 || $facesAccSum==0 || $fearAccSum==0 || $neutralAccSum==0 || $surpriseAccSum==0 || $angerAccSum==0) { # nonresponder
      print "\tBlast! Could not read $file properly or subject did not respond at all for one or more trial types. Needs further investigation.\n";
      print OUTF "$file one or more trial types' response counts is equal to 0\n";
    } else {
      my $avgShapesRT = $shapesRTsum/$shapesRespCt;
      my $avgShapesAcc = $shapesAccSum/$nShapesTrials;
      my $avgFacesRT = $facesRTsum/$facesRespCt;
      my $avgFacesAcc = $facesAccSum/$nFacesTrials;
      my $avgFearRT = $fearRTsum/$fearRespCt;
      my $avgFearAcc = $fearAccSum/$nExpTrials;
      my $avgAngerRT = $angerRTsum/$angerRespCt;
      my $avgAngerAcc = $angerAccSum/$nExpTrials;
      my $avgNeutralRT = $neutralRTsum/$neutralRespCt;
      my $avgNeutralAcc = $neutralAccSum/$nExpTrials;
      my $avgSurpriseRT = $surpriseRTsum/$surpriseRespCt;
      my $avgSurpriseAcc = $surpriseAccSum/$nExpTrials;
      my $avgShapesRT_correct = $shapesRTsum_correct/$shapesAccSum;
      my $avgFacesRT_correct = $facesRTsum_correct/$facesAccSum;
      my $avgFearRT_correct = $fearRTsum_correct/$fearAccSum;
      my $avgSurpriseRT_correct = $surpriseRTsum_correct/$surpriseAccSum;
      my $avgNeutralRT_correct = $neutralRTsum_correct/$neutralAccSum;
      my $avgAngerRT_correct = $angerRTsum_correct/$angerAccSum;
	
	  my $formattedID = sprintf("DNS%04s",$ID);
      print OUT "$ID\t$subj\t$formattedID\t$order\t$avgFacesAcc\t$avgFacesRT\t$avgFacesRT_correct\t$avgShapesAcc\t$avgShapesRT\t$avgShapesRT_correct\t$avgAngerAcc\t$avgAngerRT\t$avgAngerRT_correct\t$avgFearAcc\t$avgFearRT\t$avgFearRT_correct\t$avgNeutralAcc\t$avgNeutralRT\t$avgNeutralRT_correct\t$avgSurpriseAcc\t$avgSurpriseRT\t$avgSurpriseRT_correct\t$file\n";
    }
    if ($converted==1) {
      `rm curfile.txt`;
    }
  }
}

print "Done!\n\n";
	
