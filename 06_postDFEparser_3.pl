#! /usr/bin/env perl

# # # Preamble
use strict; use warnings; use feature 'say'; use Getopt::Long; use Data::Dumper;
use List::Util 'first'; #Finds first match in an array  #my $match = first { /pattern/ } @list_of_strings;
use List::MoreUtils 'first_index';  #Finds index of the first match     #my $index = first_index { /pattern/ } @list_of_strings;
use DFEdataset;

# # # Globar vars
my $help = undef;
my $inputFile;

# # # Main
usage() if (
    @ARGV < 1 or
    !GetOptions(
    'help|h|?'  =>  \$help,
    'input=s'   =>  \$inputFile,
    ) or defined $help);

#Open input
my $inputFile_fh_ref = openInput($inputFile);
my $inputFile_fh = $$inputFile_fh_ref; #Dereference

#Open output
my $outputFile_fh_ref = openOutput($inputFile);
my $outputFile_fh = $$outputFile_fh_ref; #Dereference

#Read input
my $file_aref = readFile($inputFile_fh); #Dereference
my @file = @{ $file_aref };

#1st parse
my ($fileName, $chr, $chr_state, $winStart, $winEnd, $headersSep_ref, $numDatasets) = parseInitialData($inputFile_fh, \@file);
my @headersSep = @{ $headersSep_ref }; #Dereference

#Create objects
my $listOfObjects_aref = setIndividualDatasets($numDatasets);
my @listOfObjects = @{ $listOfObjects_aref }; #Dereference

#More parsing
parseParamEstimates($listOfObjects_aref, $file_aref);
    #checking parseParamEstimates
    #foreach my $a (@listOfObjects) {
    #    print @{ $a->paramEstimates };
    #    #print Dumper \$a;
    #    #say $a->paramEstimates;
    #}

moreParsing($listOfObjects_aref, $file_aref, $numDatasets);


# # # Subroutines
sub usage {say "Usage: $0 -input <input file> [-help]"};

sub openInput {
    my $inputFile = shift;
    open (my $inputFile_fh, "<", "$inputFile") or die "Couldn't open $inputFile $!";
    return (\$inputFile_fh);
}

sub openOutput {
    #my $outputFile = (shift (@_)) . "_processed";
    my $outputFile = shift;
    $outputFile = $outputFile . "_processed";
    open (my $outputFile_fh, ">", "$outputFile") or die "Couldn't open $outputFile $!";
    return (\$outputFile_fh);
}

sub readFile {
    my $inputfile_fh = shift;
    my @file;
    while (my $line = <$inputFile_fh>) {
        push @file, $line;
    }
    #Clean the array from empty/void values
    my @cleanFile;
    foreach (@file) {
        if( ( defined $_) and !($_ =~ /^$/ ) and !($_ =~ /^\R$/) ) { #Select defined values, discard those void or having only a newline char (\R)
            push(@cleanFile, $_);
        }
    }
    return (\@cleanFile);
}

sub parseInitialData {
    my $inputFile_fh = shift;
    my $file_arr_ref = shift;
    my @file = @$file_arr_ref;
    #say "\$inputFile_fh es < " . $inputFile_fh . " >";
    #say "\@file";
    #foreach (@file) {say "<$_>"};

    # Parse filename
    my $fileName = $file[0];
    $fileName = $1 if $fileName =~ /file (.*) emailed/;

    # Parse chr, xfold and chr_state
    my ($chr, $chr_state, $winStart, $winEnd) = ($1, $2, $3, $4) if $fileName =~ /^(\w+)_(\w)_output_(\d+)-(\d+)/;
    say "chr $chr, chr_state $chr_state, winStart $winStart, winEnd $winEnd";

    # Parse $ filter headers (N1 N2 t2 f0, etc ... )
    my @headers = $file[5];
    my @headersSep;
    foreach (@headers) {
        @headersSep = split " ";
    }

    #Read No. of data sets
    my $numDatasets = first { /No. data sets \d+/ } @file; #Store line content where regex matches
    $numDatasets = $1 if ( $numDatasets =~ /No. data sets (\d+)/ ); #Keep just the number of datasets
    #say "numDatasets <$numDatasets>";
    
    return ($fileName, $chr, $chr_state, $winStart, $winEnd, \@headersSep, $numDatasets);
}

sub setIndividualDatasets {
    my $numDatasets = shift;
    my @listOfObjects;
    foreach (1 .. $numDatasets) {
        #say "<$_>";
        #my $object = "dataset_$_";
        #say "\$objectName <$objectName>";
        my $object = DFEdataset->new (
            parentFilename => "$fileName",
            chromosome => "$chr",
            chr_state => "$chr_state",
            parentWinRange => "$winStart-$winEnd",
            datasetNumber => "$_",
            );
        push @listOfObjects, $object;
    }
    return (\@listOfObjects)
}

sub parseParamEstimates {
    my $listOfObjects_aref = shift;
    my $file_aref = shift;
    my @listOfObjects = @{ $listOfObjects_aref };
    my @file = @{ $file_aref };
    #my @paramEstimates;
    #my %hashParams;
    for (my $i=6; $i < 6+$numDatasets; $i++ ) { #Param estimates are lines from [6] to [6 + $numdatasets]
        push @{ $listOfObjects[$i-6]->paramEstimates }, $file[$i];

        #$hashParams{"$i"} = $cleanFile[$i];
    }
    return 1;
}

sub moreParsing {
    my $listOfObjects_aref = shift;
    my $file_aref = shift;
    my $numDatasets = shift;
    my @listOfObjects = @{ $listOfObjects_aref };
    my @file = @{ $file_aref };
    # For every dataset
    for (my $dataset = 1; $dataset <= $numDatasets; $dataset++) {
        my $datasetIndex = first_index { /Data set $dataset/ } @file;   # Save first line matching our dataset
        #say $file[$datasetIndex];
        #say $file[eval($datasetIndex+13)];
        #last;
        for (my $i = $datasetIndex ; $i <= eval($datasetIndex+12) ; $i++ ) {
            say "Dataset <$dataset>";
            say "\tdatasetIndex <$i>";
            say "\t Line <" . $file[$i] . ">";
            say "-"x30;
        }
    }

    # Save first line matching our dataset

    # Read lines matching this dataset
    #for (my $i =

#   #   # Parse & filter info of input data
#   #   my $selectedAnalyzed = $cleanFile[12];
#   #   my $numSelectedDivSites = $1 and my $numSelectedDiff = $2 if ($selectedAnalyzed =~ /(\d+)\D*(\d+)/);
#   #   
#   #   # Parse & filter neutral sites analyzed
#   #   my $neutralAnalyzed = $cleanFile[13];
#   #   my $numNeutralDivSites = $1 and my $numNeutralDiff = $2 if ($neutralAnalyzed =~ /(\d+)\D*(\d+)/);
#   #   
#   #   # Parse & filter num of sites analyzed
#   #   my $numAnalyzed = $cleanFile[14];
#   #   #$numAnalyzed = $1 if ($numAnalyzed =~ /(\d+)\n/);
#   #   $numAnalyzed = 128;
#   #   

}

#   #   #   #   #   #   #   #
#   #   
#   #   # Parse & filter info of input data
#   #   my $selectedAnalyzed = $cleanFile[12];
#   #   my $numSelectedDivSites = $1 and my $numSelectedDiff = $2 if ($selectedAnalyzed =~ /(\d+)\D*(\d+)/);
#   #   
#   #   # Parse & filter neutral sites analyzed
#   #   my $neutralAnalyzed = $cleanFile[13];
#   #   my $numNeutralDivSites = $1 and my $numNeutralDiff = $2 if ($neutralAnalyzed =~ /(\d+)\D*(\d+)/);
#   #   
#   #   # Parse & filter num of sites analyzed
#   #   my $numAnalyzed = $cleanFile[14];
#   #   #$numAnalyzed = $1 if ($numAnalyzed =~ /(\d+)\n/);
#   #   $numAnalyzed = 128;
#
#
#
#
#   #   # Parse & filter proportions of mutants
#   #   my $proporMutants_range0_1 = $cleanFile[20];
#   #   $proporMutants_range0_1 = $1 if ($proporMutants_range0_1 =~ /(\d+\.?\d+)/); #This will match numbers like '12'
#   #   my $proporMutants_range1_10 = $cleanFile[21];
#   #   $proporMutants_range1_10 = $1 if ($proporMutants_range1_10 =~ /\D*(\d+\.\d+)/); #This won't, but otherwise it'll match '10' from 'range 10 ..10'
#   #   my $proporMutants_range10_100 = $cleanFile[22];
#   #   $proporMutants_range10_100 = $1 if ($proporMutants_range10_100 =~ /(\d+\.\d+)/);
#   #   my $proporMutants_range100_inf = $cleanFile[23];
#   #   $proporMutants_range100_inf = $1 if ($proporMutants_range100_inf =~ /(\d+\.\d+)/);
#   #   
#
#
#
#
#   #   # Parse & filter param estimates
#   #   my @paramEstimates = $cleanFile[6];
#   #   my @paramEstimatesSep;
#   #   foreach (@paramEstimates) {
#   #       @paramEstimatesSep = split " ";
#   #   }
#   #   
#
#
#
#
#   #   # Print header
#   #   my $header_1 = "fileName\tchr\txf_1\txf_2\tchr_state\tnumSelectedDivSites\tnumSelectedDiff\tnumNeutralDivSites\tnumNeutralDiff\tnumAnalyzed\t";
#   #   print $outputFile_fh $header_1;
#   #   #print $header_1;
#   #   
#   #   foreach (0 .. $#headersSep) {
#   #       print $outputFile_fh "$headersSep[$_]\t";
#   #       #print "$headersSep[$_]\t";
#   #   }
#   
#
#
#
#   #   
#   #   print $outputFile_fh "\n";
#   #   my $data_1 = "$fileName\t$chr\t$xf1\t$xf2\t$chr_state\t$numSelectedDivSites\t$numSelectedDiff\t$numNeutralDivSites\t$numNeutralDiff\t$numAnalyzed\t";
#   #   print $outputFile_fh $data_1;
#   #   #print $data_1;
#   #   
#   #   foreach (0 .. $#paramEstimatesSep) {
#   #       if ($_ != $#paramEstimatesSep) {
#   #           print $outputFile_fh "$paramEstimatesSep[$_]\t";
#   #           #print "$paramEstimatesSep[$_]\t";
#   #       } elsif ($_ == $#paramEstimatesSep) {
#   #           print $outputFile_fh "$paramEstimatesSep[$_]";
#   #           #print "$paramEstimatesSep[$_]";
#   #       }
#   #   }
#   #   
#   #   #print $outputFile_fh "\n";
