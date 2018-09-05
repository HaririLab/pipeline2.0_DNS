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
  print "\nSyntax: perl getNumLSEprime.pl infile.txt outfile.txt\n";
  print "\tinfile = full path to a single subject's eprime output txt file\n";
  print "\toutfile = full path for desired name for output file\n\n";
  exit;
}
my $infile = $ARGV[0];
my $outfile = $ARGV[1];
# my $outXL = Spreadsheet::WriteExcel->new('test.xls');
# my $worksheet = $workbook->add_worksheet();

open OUT, ">$outfile" or die "could not open $outfile";
open IN, "<$infile" or die "could not open $infile";  

$infile =~ /-(\d+)-/;
my $ID = $1; # ID from file name
my $subj = ""; # to get ID from file later

my $converted = 0;		# 0 for no, 1 for yes, 2 for fail
my $headerline = <IN>;
if ($headerline=~m/Header Start/) { # looks like we can read this file, proceed without converting
	$converted = 0;
} else {	       # can't read the file correctly, try converting
	`iconv -f utf-16 -t utf-8 $infile > curfile.txt`; # convert to utf-8 format
	open IN, "curfile.txt" or die "could not open curfile.txt"; # use this line to run with the converted file   
	$converted = 1;
	$headerline = <IN>;
	if (!$headerline=~m/Header Start/) { # still can't read the file
		print "\tBlast! Could not read file $infile in original or utf-8 format.\n";
		$converted = 2;
	}
}

# initialize variables for this subject
my $MRTsum = $JRTsum = $CJRTsum = $ERJRTsum = $ECJRTsum = $ECRJRTsum = 0;
my $MRespCt = $JRespCt = $CJRespCt = $ERJRespCt = $ECJRespCt = $ECRJRespCt = 0;
my $encCt = $restCt = $JMct = 0;
my @encFixOnsets, @encRespOnsets, @encStimOnsets, @restOnsets, @JMonsets, @encRTs, @JMRTs, @encACCs, @JMACCs, @restDurs, @text1, @text2, @text3;

if ($converted!=2) { # go ahead and parse the file
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

	  print OUT join("\t", @encFixOnsets," "), "\n";      
	  print OUT join("\t", @encRespOnsets," "), "\n";      
	  print OUT join("\t", @encStimOnsets," "), "\n";      
	  print OUT join("\t", @JMonsets," "), "\n";      
	  print OUT join("\t", @encACCs," "), "\n";      
	  print OUT join("\t", @JMACCs," "), "\n";      
	  print OUT join("\t", @restOnsets," "), "\n";      
	  print OUT join("\t", @restDurs," "), "\n";      
	  
	  # $worksheet->write(0,0, \@encFixOnsets);

	  # }

	if ($converted==1) {
	  `rm curfile.txt`;
	}

}



print "Done!\n\n";
	
