#! /usr/bin/env perl

# # Preamble
use strict; use warnings; use feature 'say'; use Getopt::Long; use Data::Dumper;
use List::Util 'first'; #Finds first match in an array
use DFEdataset;

# # Globar vars
my $help = undef;
my $inputFile;

# # Subroutines
usage() if (
    @ARGV < 1 or
    !GetOptions(
    'help|h|?'  =>  \$help,
    'input=s'   =>  \$inputFile,
    ) or defined $help);

sub usage {say "Usage: $0 -input <input file> [-help]"};

# # Main
open (my $inputFile_fh, "<", "$inputFile") or die "Couldn't open $inputFile $!";
my $outputFile = $inputFile . "_processed";
open (my $outputFile_fh, ">", "$outputFile") or die "Couldn't open $inputFile $!";

# Read whole file
my @file = <$inputFile_fh>;

#Clean the array from empty/void values
my @cleanFile;
foreach (@file) {
    if( ( defined $_) and !($_ =~ /^$/ ) and !($_ =~ /^\R$/) ) { #Select defined values, discard those void or having only a newline char (\R)
        push(@cleanFile, $_);
    }
}
chomp(@cleanFile);

# Parse filename
my $fileName = $file[0];
$fileName = $1 if $fileName =~ /file (.*) emailed/;

# Parse chr, xfold and chr_state
my ($chr, $chr_state, $winStart, $winEnd) = ($1, $2, $3, $4) if $fileName =~ /^(\w+)_(\w)_output_(\d+)-(\d+)/;
say "chr $chr, chr_state $chr_state, winStart $winStart, winEnd $winEnd";

# Parse $ filter headers (N1 N2 t2 f0, etc ... )
my @headers = $cleanFile[5];
my @headersSep;
foreach (@headers) {
    @headersSep = split " ";
}

#Read No. of data sets
my $numDatasets = first { /No. data sets \d+/ } @cleanFile; #Store line
$numDatasets = $1 if ( $numDatasets =~ /No. data sets (\d+)/ ); #Keep just the number of datasets
#say "numDatasets <$numDatasets>";



my $listOfObjects = createDatasetObjects();
foreach (@{ $listOfObjects }) {
    say "Dataset " . $_->datasetNumber;
    say "\tparentFilename " . $_->parentFilename;
    say "\tChromosome " . $_->chromosome;
    say "\tchr_state " . $_->chr_state;
    say "\tparentWinRange " . $_->parentWinRange;

}
#say "listofobjects<$_>" foreach (@{ $listOfObjects });

sub createDatasetObjects {
    my @listOfObjects;
    foreach (1 .. $numDatasets) {
        #say "<$_>";
        my $objectName = "dataset_$_";
        #say "\$objectName <$objectName>";
        my $objectname = DFEdataset->new (
            parentFilename => "$fileName",
            chromosome => "$chr",
            chr_state => "$chr_state",
            parentWinRange => "$winStart-$winEnd",
            datasetNumber => "$_",
            );
        push @listOfObjects, $objectname;
    }
    return (\@listOfObjects)
}


# Parse & filter param estimates
#my @paramEstimates;
my %hashParams;
for (my $i=6; $i < 6+$numDatasets; $i++ ) { #Param estimates are lines from [6] to [numdatasets-1]
    #push @paramEstimates, $cleanFile[$i];
    $hashParams{"$i"} = $cleanFile[$i];

}

## Just checking
#say "<$_>" foreach (@paramEstimates);
#foreach my $key (sort {$a <=> $b} keys(%hashParams)) {
#    say "\$key <$key>\tvalue <$hashParams{$key}>";
#}




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
#   #   
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
#   #   # Parse & filter param estimates
#   #   my @paramEstimates = $cleanFile[6];
#   #   my @paramEstimatesSep;
#   #   foreach (@paramEstimates) {
#   #       @paramEstimatesSep = split " ";
#   #   }
#   #   
#   #   # Print header
#   #   my $header_1 = "fileName\tchr\txf_1\txf_2\tchr_state\tnumSelectedDivSites\tnumSelectedDiff\tnumNeutralDivSites\tnumNeutralDiff\tnumAnalyzed\t";
#   #   print $outputFile_fh $header_1;
#   #   #print $header_1;
#   #   
#   #   foreach (0 .. $#headersSep) {
#   #       print $outputFile_fh "$headersSep[$_]\t";
#   #       #print "$headersSep[$_]\t";
#   #   }
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
