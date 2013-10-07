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

getDatasetIndexes($file_aref, $numDatasets);


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
    for (my $i=6; $i < 6+$numDatasets; $i++ ) { #Param estimates are lines from [6] to [6 + $numdatasets]
        push @{ $listOfObjects[$i-6]->paramEstimates }, $file[$i];
    }
    return 1;
}

sub getDatasetIndexes {
    my $file_aref = shift;
    my $numDatasets = shift;
    my @file = @{ $file_aref };
    # For every dataset
    for (my $datasetNumber = 1; $datasetNumber <= $numDatasets; $datasetNumber++) {
        my $datasetIndex = first_index { /Data set $datasetNumber/ } @file;   # Save first line matching our dataset
        parseIndividualDataset($file_aref, $datasetNumber, $datasetIndex);  #Call another sub (which will parse the data) with the $datasetIndex, and let the sub do the magic.
    }
}

sub parseIndividualDataset {
    my ($file_aref, $datasetNumber, $datasetIndex) = @_ ;
    my @file = @{ $file_aref };
    
    # Parse the sites data
    my ($numSelectedDivSites) = $file[ eval($datasetIndex+1) ] =~ m/selected divergence sites (\d+)/g;
    my ($numSelectedDiff) = $file[ eval($datasetIndex+1) ] =~ m/selected differences (\d+)/g;
    my ($numNeutralDivSites) = $file[ eval($datasetIndex+2) ] =~ m/neutral divergence sites (\d+)/g;
    my ($numNeutralDiff) = $file[ eval($datasetIndex+2) ] =~ m/neutral differences (\d+)/g;
    my (@selectedSFS) = $file[ eval($datasetIndex+4) ] =~ m/Selected SFS: (.*)/g;   #Match in list context ( my ($savedHere) = ... ) to save the capture groups
    my (@neutralSFS) = $file[ eval($datasetIndex+5) ] =~ m/Neutral SFS: (.*)/g;
    
    # Check sites data
    #say "\$numSelectedDivSites <$numSelectedDivSites>";
    #say "\$numSelectedDiff <$numSelectedDiff>";
    #say "\$numNeutralDivSites <$numNeutralDivSites>";
    #say "\$numNeutralDiff <$numNeutralDiff>";
    #say @selectedSFS;
    #say @neutralSFS;
    
    say "Let's check \@selectedSFS array";
    foreach my $elem (@selectedSFS) { say "Element <$elem>" }
    say "-"x30;


    # Parse the proportions of mutants data     #To-Do

    # Check proportions of mutants data     #To-Do
    
    # Save parsed data into objects
    storeDataIntoObjects($datasetNumber, $numSelectedDivSites, $numSelectedDiff, $numNeutralDivSites, $numNeutralDiff, \@selectedSFS, \@neutralSFS);
}

sub storeDataIntoObjects {  #To-Do: Check num of parameters received
    my ($datasetNumber, $numSelectedDivSites, $numSelectedDiff, $numNeutralDivSites, $numNeutralDiff, $selectedSFS_aref, $neutralSFS_aref) = @_;
   
    # Checking indexes
    #say $listOfObjects[$datasetNumber-1]->datasetNumber;
    #say "-"x30;

    # Saving data into corresponding objects
    $listOfObjects[$datasetNumber-1]->numSelectedDivSites( $numSelectedDivSites );
    $listOfObjects[$datasetNumber-1]->numSelectedDiff( $numSelectedDiff );
    $listOfObjects[$datasetNumber-1]->numNeutralDivSites( $numNeutralDivSites );
    $listOfObjects[$datasetNumber-1]->numNeutralDiff( $numNeutralDiff );
   
    # Checking ...
    #say "set\nSay: \$listOfObjects[\$datasetNumber-1]->numSelectedDivSites <" . $listOfObjects[$datasetNumber-1]->numSelectedDivSites . ">";
    
    #Now, lets save the arrays....
#    #push $listOfObjects[$datasetNumber-1]->selectedSFS, @{ $selectedSFS_aref };
#
#    $listOfObjects[$datasetNumber-1]->selectedSFS( @{ $selectedSFS_aref } );    #Doesn't works, because @{ $selectedSFS_aref } contains only one value (all the numbers in a scalar) and not a list of values
#    $listOfObjects[$datasetNumber-1]->neutralSFS( @{ $neutralSFS_aref } );
#
#    #push $listOfObjects[$datasetNumber-1]->selectedSFS, @{ $selectedSFS_aref };
#    #push $listOfObjects[$datasetNumber-1]->selectedSFS, @{ $selectedSFS_aref };

#Examples of saving data into objects
    #foreach (1 .. $numDatasets) {
    #    #say "<$_>";
    #    #my $object = "dataset_$_";
    #    #say "\$objectName <$objectName>";
    #    my $object = DFEdataset->new (
    #        parentFilename => "$fileName",
    #        chromosome => "$chr",
    #        chr_state => "$chr_state",
    #        parentWinRange => "$winStart-$winEnd",
    #        datasetNumber => "$_",
    #        );
    #    push @listOfObjects, $object;
    #}
    
}



#   #   #   #   #   #   #   #
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
