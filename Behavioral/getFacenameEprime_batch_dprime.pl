#!usr/bin/perl

# getFacenameEprime_batch.pl
#
# This script takes in a list of eprime output files as a text file, reads them, calculates accuracy and response time (per block), 
#  and writes the output to the specified file, one subject per line
#
# Usage:  perl getFacenameEprime_batch.pl infile.txt outfile.txt
# Input: infile.txt = list of files to parse - does not work if the file name list is generated in excel!
#  instead use "find /Volumes/Hariri/Takeda.01/Data/Behavioral/Eprime\ Response\ Data/FaceRecog/*.txt" (e.g. for Mac) on command line to list full path of the 
#  directory's contents and paste those to a text file
# Assumptions:
#   -The patient id appears in the file name between to hyphens, followed by the session number, eg in HaririFaces2_revise12-407-1.txt, the ID is 407-1
#   -6 trials per block
#
# Note: For some reason it is not straightforward to parse the eprime text files as they exist straight off the server.
#   Solution: in this script we convert to utf-8 format with the following command on the terminal:
#   iconv -f utf-16 -t utf-8 oldfile.txt > newfile.txt 
#   -Total average RT is calc'd by summing the RTs across all of the blocks and then dividing by the number of responses acorss all of the blocks (rather than calc'ing for each block and then taking the average of those)
#
# Annchen Knodt 1/13/2012

# global variables
my $nTrials = 24; # same for distractor and facename trials, n trials / block hard coded as 6

# process command line arguments
if (scalar(@ARGV) != 2) {
  print "\nSyntax: getFacenameEprime_batch.pl infile.txt outfile.txt\n";
  print "\tinfile = text file containing list of ePrime files to parse (one per line)\n";
  print "\toutfile = desired name for output file\n\n";
  exit;
}
my $infile = $ARGV[0];
my $outfile = $ARGV[1];

open LIST, "<$infile" or die "could not open $infile";
open OUT, ">$outfile" or die "could not open $outfile";
open OUTF, ">failedFiles.txt" or die "could not open failedFiles.txt";

print "\n***Running getFacenameEprime_batch.pl***\nSee failedFiles.txt for list of unreadable files.\nAlso see comments in the script if you need help.\n\n";
# print header to output file
print OUT "ID from file name\tID from file\thits\tmisses\tfalseAlarms\tcorrectRejections\tFile name\n";

# read file list line-by-line
while (my $file = <LIST>) {    
  chomp($file);
  print "Reading file: $file\n";
  $file =~ /Recog-(\d+-\d+)/;
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
    if (!$headerline=~m/Header Start/) { # Still can't read the file
      print "\tBlast! Could not read file $file in original or utf-8 format.  Adding this to failedFiles.txt.\n";
      $converted = 2;
      print OUTF "$file could not be read even after converting to utf-8 format\n";
    }
  }
  # initialize variables for this subject
  my $hits = $misses = $falseAlarms = $correctRejections = 0;
  my $CRESP = $RESP = 0;
  if ($converted!=2) {
    while (my $line = <IN>) {
      chomp($line);
      if ($line=~ m/Subject:/) { 
		$subj = $';
		$subj =~ s/\D//g;
      } elsif ($line=~ m/RecallSlide2.RESP/) { 
		$RESP = $';
		$RESP =~ s/\D//g;
      } elsif ($line=~ m/RecallSlide2.CRESP:/) { 
		$CRESP = $';
		$CRESP =~ s/\D//g;
		if($CRESP==1){
			if($RESP==1){
				$hits++;
			} elsif($RESP==2) {
				$misses++;
			}
		} elsif($CRESP==2){
			if($RESP==1){
				$falseAlarms++;
			} elsif($RESP==2) {
				$correctRejections++;
			}		
		}
      } elsif ($line==EOF) {	## end of file
      } else { # This doesn't make logical sense to me, but somehow it works...
		print "Invalid line:\n $line";
      }
    }
    
    print OUT join("\t", $ID,$subj,$hits, $misses, $falseAlarms, $correctRejections,$file," "),"\n";

    if ($converted==1) {
      `rm curfile.txt`;
    }
  }
}

print "Done!\n\n"
	
