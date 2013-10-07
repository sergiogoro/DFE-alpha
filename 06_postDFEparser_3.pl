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
my ($fileName, $chr, $chr_state, $parentWinStart, $parentWinEnd, $headersSep_ref, $numDatasets) = parseInitialData($inputFile_fh, \@file);
my @headersSep = @{ $headersSep_ref }; #Dereference

#Create objects
my $listOfObjects_aref = setIndividualDatasets($numDatasets);
my @listOfObjects = @{ $listOfObjects_aref }; #Dereference

#More parsing
parseParamEstimates($listOfObjects_aref, $file_aref);
    #checking parseParamEstimates
    say "checking paramEstimates (in the ARRAY attrib at the objects)";
    foreach my $object (@listOfObjects) {
        print @{ $object->paramEstimates_arr };
    }
    say "checking paramEstimates (in the HASH attrib at the objects)";
    foreach my $object (@listOfObjects) {
        while ( my ($key, $value) = each %{ $object->paramEstimates_hash } ) {
            print "$key=$value\n";
        }
        say "-"x30;
    }

getDatasetIndexes($file_aref, $numDatasets);
writeOutput($outputFile_fh);


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
    my ($chr, $chr_state, $parentWinStart, $parentWinEnd) = ($1, $2, $3, $4) if $fileName =~ /^(\w+)_(\w)_output_(\d+)-(\d+)/;
    say "chr $chr, chr_state $chr_state, parentWinStart $parentWinStart, parentWinEnd $parentWinEnd";

    # Parse $ filter headers (N1 N2 t2 f0, etc ... )
    my @headers = $file[5];
    my @headersSep;
    foreach (@headers) {
        @headersSep = split " ";
    }

    #Read No. of data sets
    my $numDatasets = first { /No. data sets \d+/ } @file; #Store line content where regex matches
    $numDatasets = $1 if ( $numDatasets =~ /No. data sets (\d+)/ ); #Keep just the number of datasets
    
    return ($fileName, $chr, $chr_state, $parentWinStart, $parentWinEnd, \@headersSep, $numDatasets);
}

sub setIndividualDatasets {
    my $numDatasets = shift;
    my @listOfObjects;
    foreach (1 .. $numDatasets) {
        my $object = DFEdataset->new (
            parentFilename => "$fileName",
            chromosome => "$chr",
            chr_state => "$chr_state",
            parentWinRange => "$parentWinStart-$parentWinEnd",
            parentWinStart => "$parentWinEnd",
            parentWinEnd => "$parentWinEnd",
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
    my %hash;
    my @paramsSep;
    for (my $i=6; $i < 6+$numDatasets; $i++ ) { #Param estimates are lines from [6] to [6 + $numdatasets]
        push @{ $listOfObjects[$i-6]->paramEstimates_arr }, $file[$i];
        
        #Below, trying with hash, to store ALL paramEstimates into a hash (that way it'll be easier to retrieve values by their key)
        push @paramsSep, (split " ", $file[$i]); 
        %hash = (
            'N1' => $paramsSep[0],
            'N2' => $paramsSep[1],
            't2' =>  $paramsSep[2],
            'f0' =>  $paramsSep[3],
            'beta' =>  $paramsSep[4],
            'E(s)' =>  $paramsSep[5],
            '-N*E(s)' =>  $paramsSep[6],
            'alpha' =>  $paramsSep[7],
            'omega_a' =>  $paramsSep[8],
            'logL' =>  $paramsSep[9],
            'proporMutants_range0_1' =>  $paramsSep[10],
            'proporMutants_range1_10' =>  $paramsSep[11],
            'proporMutants_range10_100' =>  $paramsSep[12],
            'proporMutants_range100_inf' =>  $paramsSep[13],
        );
        $listOfObjects[$i-6]->paramEstimates_hash( \%hash  );
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
    my $selectedSFS = $1 if ( $file[$datasetIndex+4] =~ /Selected SFS: (.*)/g );
    my @selectedSFS;
    push @selectedSFS, split " ", $selectedSFS;
    my $neutralSFS = $1 if ( $file[$datasetIndex+5] =~ /Neutral SFS: (.*)/g );
    my @neutralSFS;
    push @neutralSFS, split " ", $neutralSFS;

    # Parse the proportions of mutants data
    my ($proporMutants_range0_1) = $file[$datasetIndex+9] =~ /Proportion .* = (\d+.\d+)/g;
    my ($proporMutants_range1_10) = $file[$datasetIndex+10] =~ /Proportion .* = (\d+.\d+)/g;
    my ($proporMutants_range10_100) = $file[$datasetIndex+11] =~ /Proportion .* = (\d+.\d+)/g;
    my ($proporMutants_range100_inf) = $file[$datasetIndex+12] =~ /Proportion .* = (\d+.\d+)/g;

    # Save parsed data into objects
    storeDataIntoObjects($datasetNumber, $numSelectedDivSites, $numSelectedDiff, $numNeutralDivSites, $numNeutralDiff, \@selectedSFS, \@neutralSFS, $proporMutants_range0_1, $proporMutants_range1_10, $proporMutants_range10_100, $proporMutants_range100_inf);
}

sub storeDataIntoObjects {  #To-Do: Check num of parameters received
    my ($datasetNumber, $numSelectedDivSites, $numSelectedDiff, $numNeutralDivSites, $numNeutralDiff, $selectedSFS_aref, $neutralSFS_aref, $proporMutants_range0_1, $proporMutants_range1_10, $proporMutants_range10_100, $proporMutants_range100_inf) = @_;

    # Saving data into corresponding attributes of the objects
    $listOfObjects[$datasetNumber-1]->numSelectedDivSites( $numSelectedDivSites );
    $listOfObjects[$datasetNumber-1]->numSelectedDiff( $numSelectedDiff );
    $listOfObjects[$datasetNumber-1]->numNeutralDivSites( $numNeutralDivSites );
    $listOfObjects[$datasetNumber-1]->numNeutralDiff( $numNeutralDiff );

    # Saving data (selected and neutral SFS vectors) into their corresponding attributes (selectedSFS and neutralSFS; with type: ArrayRef[Int]) of the objects
    $listOfObjects[$datasetNumber-1]->selectedSFS( $selectedSFS_aref ); #We save the arrayReferences (and not the array themselves), as that's the data type declared in the module (DFEdataset.pm)
    $listOfObjects[$datasetNumber-1]->neutralSFS( $neutralSFS_aref );

    #Saving data (proportion of mutants)
    $listOfObjects[$datasetNumber-1]->proporMutants_range0_1($proporMutants_range0_1);
    $listOfObjects[$datasetNumber-1]->proporMutants_range1_10($proporMutants_range1_10);
    $listOfObjects[$datasetNumber-1]->proporMutants_range10_100($proporMutants_range10_100);
    $listOfObjects[$datasetNumber-1]->proporMutants_range100_inf($proporMutants_range100_inf);
}

sub writeOutput {
    my $outputFile_fh = shift;

    # BEFORE HERE, i should correlate every datasetNumber with its original filename, to recover the original (the one for each dataset) winStart and winEnd

    # Print header
    my $header_1 = "parentFileName\tchr\tchr_state\tparentWinStart\tparentWinEnd\tdatasetNumber\tdatasetWinStart\tdatasetWinEnd\tnumSelectedDivSites\tnumSelectedDiff\tnumNeutralDivSites\tnumNeutralDiff";
    say $outputFile_fh $header_1;
    foreach (@listOfObjects) {
        print $outputFile_fh $_->parentFilename . "\t";
        print $outputFile_fh $_->chromosome . "\t";
        print $outputFile_fh $_->chr_state . "\t";
        print $outputFile_fh $_->parentWinStart . "\t";
        print $outputFile_fh $_->parentWinEnd . "\t";
        print $outputFile_fh $_->datasetNumber . "\t";
        
#        print $outputFile_fh $_->datasetStart . "\t";           # TO DO
#        print $outputFile_fh $_->datasetEnd . "\t";             # TO DO

        print $outputFile_fh $_->numSelectedDivSites . "\t";
        print $outputFile_fh $_->numSelectedDiff . "\t";
        print $outputFile_fh $_->numNeutralDivSites . "\t";
        print $outputFile_fh $_->numNeutralDiff . "\n";    #New line
        #print $outputFile_fh $_->numAnalyzed . "\n";   #New line
    }



#   #   
#   #   foreach (0 .. $#headersSep) {
#   #       print $outputFile_fh "$headersSep[$_]\t";
#   #       #print "$headersSep[$_]\t";
#   #   }
    
}


#   #   #   #   #   #   #   #
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
