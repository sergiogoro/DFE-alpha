#!/usr/bin/env perl

# # Preamble
use strict; use feature 'say'; use Getopt::Long; use List::Util qw(sum); use Data::Dumper;
use POSIX; # For ceil() & floor() subroutines
use Storable;

# # Global vars
my $path = "/home/sergio/chromatin/analysis/inputs_DFE-alpha/tests/orth/";
my @chromosomes = ( "2R", "2L", "3L", "3R", "X");
my @states=( "A", "B", "C", "D", "E", "F", "G", "H", "I" );

my %HoA;

# # MAIN
read_and_store();
order_files_by_window();
main();
create_index();

# # Subroutines
sub main {
    foreach my $key (sort (keys %HoA)) {
        #say "-"x30;
        #say "Key <$key>";
        my $numElements = scalar (@{ $HoA{$key}{'win'} });
        #say "numElements $numElements";
        if ( $numElements <= 20 ) { open_for_minus20( $key, $numElements) }
        elsif ( ($numElements > 20) and ($numElements <=40) ) { open_for_21_40( $key, $numElements) }
        else { say "Current version only supports up to 40 datasets" }
    }
}

sub create_index {
    my $outputFile = "Index_of_Datasets_and_Windows";
    open my $outputFile_fh, '>', $outputFile or die "Couldn't open $outputFile $!";
    print $outputFile_fh "chromState\tdatasetNumber\twinStart\twinEnd\n";
    foreach my $chromState ( sort( keys %HoA ) ) {
        #my $numWindows = scalar @{ $HoA{$chromState}->{win} };  #How many windows?
        #say "\$numWindows <$numWindows>";
        for (my $i=0; $i < scalar @{ $HoA{$chromState}->{win} }; $i++) {
            print $outputFile_fh "$chromState" . "\t" . eval($i+1) . "\t";
            my $win = @{ $HoA{$chromState}->{win} }[$i];
            my ($winStart, $winEnd) = split "-", $win;
            print $outputFile_fh "$winStart\t$winEnd\n";
        }
        #if ($numWindows <= 20) {
        #    for (my $i=0; $i < 20; $i++) {
        #        print $outputFile_fh $chromState . "\t" . eval($i+1) . "\t";
        #        my $win = @{ $HoA{$chromState}->{win} }[$i];
        #        my ($winStart, $winEnd) = split "-", $win;
        #        print $outputFile_fh "$winStart\t$winEnd\n";
        #    }
        #} elsif ($numWindows <= 40) {
        #    for (my $i=20; $i < 40; $i++) {
        #        print $outputFile_fh $chromState . "\t" . eval($i+1) . "\t";
        #        my $win = @{ $HoA{$chromState}->{win} }[$i];
        #        my ($winStart, $winEnd) = split "-", $win;
        #        print $outputFile_fh "$winStart\t$winEnd\n";
        #    }
        #} else {say "Current version only supports up to 40 datasets"}
    }

    say "Index saved at $outputFile";
}


sub read_and_store {
    foreach my $chrom (@chromosomes) {
        #say $chrom;
        foreach my $state (@states) {
            #say $state;
            my $chromState = $chrom . "_" .$state;
            foreach my $file (`ls $path | grep $chrom | grep "\.$state\.SFSK" | grep orth | grep 0y4 | grep DFE-alpha_ `) {
                chomp ($file);
                #say "Storing <$file>";
                my ( $fileNameHeader, $win ) = ( $1, $2 ) if ($file =~ /^(.*_)(\d+-\d+)$/ );
                $HoA{$chromState}->{'name'} = $fileNameHeader;
                push @{ $HoA{$chromState}->{'win'} }, $win;

            }
        }
    }
}

sub order_files_by_window {
    foreach my $key ( (keys %HoA)  ) {
        #say "Ordering key <$key>";
        my @orderedWins = ();
        push @orderedWins, (sort {$a <=> $b} (@{ $HoA{$key}{'win'} }) );    #Push in a sorted way
        undef @{ $HoA{$key}{'win'} };   #Delete previous array
        @{ $HoA{$key}{'win'} } = @orderedWins;  #Copy the sorted array into the original position of the unsorted one
    }
}


sub open_for_minus20 {
    my ($key, $numElements) = @_;
    #say "subroutine (open_for_minus_20) for key <$key>";
    
    my @files = ();
    my @winArray = ();

    foreach my $windows ( @{ $HoA{$key}{'win'} }  ) {
        push @winArray, $windows;
        #say "Pushed at \@winArray <$windows>";
        #say "NAME <$HoA{$key}{'name'}>";
        push @files, $HoA{$key}{'name'}.$windows;
    }

    ## Checking
    my ( $winMin, $winMax ) = ( (split "-" , $winArray[0])[0], (split "-" , $winArray[$#winArray])[1] );
    #say "\$winArray[0] <$winArray[0]>\t\$winArray[$#winArray] <$winArray[$#winArray]>";
    #say "\$winMin <$winMin> \$winMax <$winMax>";

    ## Open output
    my $outputName = $key . "_output_" . $winMin . "-" . $winMax;
    open my $outputFile_fh, '>', $outputName or die "Couldn't open output file $outputName $!";

    ## PRINT HEADER to OUTPUT
    print $outputFile_fh "$numElements\n"; #Print 'number of datasets (n)'
    print $outputFile_fh "1\n"; #Print 'Nº SFS with != numbers of alleles sampled (m)'
    print $outputFile_fh "128\n"; # Print 'Nº alleles sampled in SFS i (xi)'

    ## Read ALL input files in slurp mode
    for (my $i = 0; $i < $numElements; $i++) {
        my $fileContent;
        {   #Local block for $/ (slurp mode)
            open my $fh, '<', $files[$i];
            local $/ = undef;
            $fileContent = <$fh>;
            #chomp $fileContent;
            close $fh;
        } 
        #Clean $fileContent from old headers, and insert line of nºdataset($numElements)
        my $numDataset = $i+1;
        $fileContent =~ s/1\n1\n128\n1/$numDataset/g;
        ## Print body
        print $outputFile_fh $fileContent;
    }
}

sub open_for_21_40 {
    my ($key, $numElements) = @_;
    #say "subroutine (open_for_21_40) for key <$key>";

    my @files = ();
    my @winArray = ();

    foreach my $windows ( @{ $HoA{$key}{'win'} }  ) {
        push @winArray, $windows;
        #say "Pushed at \@winArray <$windows>";
        #say "NAME <$HoA{$key}{'name'}>";
        push @files, $HoA{$key}{'name'}.$windows;
    }

    ## Checking
    my ( $winMin_1, $winMax_1 ) = ( (split "-" , $winArray[0])[0], (split "-" , $winArray[19])[1] );
    my ( $winMin_2, $winMax_2 ) = ( (split "-" , $winArray[20])[0], (split "-" , $winArray[$#winArray])[1] );
    #say "\$winArray[0] <$winArray[0]>\t\$winArray[$#winArray] <$winArray[$#winArray]>";
    #say "\$winMin_1 <$winMin_1> \$winMax_1 <$winMax_1>";
    #say "\$winMin_2 <$winMin_2> \$winMax_2 <$winMax_2>";

    ## Open outputs
    my $outputName_1 = $key . "_output_" . $winMin_1 . "-" . $winMax_1;
    my $outputName_2 = $key . "_output_" . $winMin_2 . "-" . $winMax_2;
    open my $outputFile_fh_1, '>', $outputName_1 or die "Couldn't open output file $outputName_1 $!";
    open my $outputFile_fh_2, '>', $outputName_2 or die "Couldn't open output file $outputName_2 $!";

    ## PRINT HEADER to OUTPUT
    print $outputFile_fh_1 "20\n"; #Print 'number of datasets (n)'
    print $outputFile_fh_1 "1\n"; #Print 'Nº SFS with != numbers of alleles sampled (m)'
    print $outputFile_fh_1 "128\n"; # Print 'Nº alleles sampled in SFS i (xi)'

    print $outputFile_fh_2 $numElements - 20 . "\n"; #Print 'number of datasets (n)'
    print $outputFile_fh_2 "1\n"; #Print 'Nº SFS with != numbers of alleles sampled (m)'
    print $outputFile_fh_2 "128\n"; # Print 'Nº alleles sampled in SFS i (xi)'


    ## Read ALL input files in slurp mode
    # First output file
    for (my $i = 0; $i < 20; $i++) {
        my $fileContent;
        {   #Local block for $/ (slurp mode)
            open my $fh, '<', $files[$i];
            local $/ = undef;
            $fileContent = <$fh>;
            #chomp $fileContent;
            close $fh;
        } 
        #Clean $fileContent from old headers, and insert line of nºdataset($numElements)
        my $numDataset = $i+1;
        $fileContent =~ s/1\n1\n128\n1/$numDataset/g;
        ## Print body
        print $outputFile_fh_1 $fileContent;
    }
    # Second output file
    for (my $i = 20; $i < $numElements; $i++) {
        my $fileContent;
        {   #Local block for $/ (slurp mode)
            open my $fh, '<', $files[$i];
            local $/ = undef;
            $fileContent = <$fh>;
            close $fh;
        } 
        #Clean $fileContent from old headers, and insert line of nºdataset($numElements)
        my $numDataset = $i-19;
        $fileContent =~ s/1\n1\n128\n1/$numDataset/g;
        ## Print body
        print $outputFile_fh_2 $fileContent;
    }
}

#Editing below

#sub open_for_41_60 {
#    my ($key, $numElements) = @_;
#    #say "subroutine (41_60) for key <$key>";
#
#    my @files = ();
#    my @winArray = ();
#
#    foreach my $windows ( @{ $HoA{$key}{'win'} } ) {
#        push @winArray, $windows;
#        push @files, $HoA{$key}{'name'}.$windows;
#    }
#
#    ## Checking
#    my ( $winMin_1, $winMax_1 ) = ( (split "-" , $winArray[0])[0], (split "-" , $winArray[19])[1] );
#    my ( $winMin_2, $winMax_2 ) = ( (split "-" , $winArray[20])[0], (split "-" , $winArray[39])[1] );
#    my ( $winMin_3, $winMax_3 ) = ( (split "-" , $winArray[40])[0], (split "-" , $winArray[$#winArray])[1] );
#    #say "\$winArray[0] <$winArray[0]>\t\$winArray[$#winArray] <$winArray[$#winArray]>";
#    #say "\$winMin_1 <$winMin_1> \$winMax_1 <$winMax_1>";
#    #say "\$winMin_2 <$winMin_2> \$winMax_2 <$winMax_2>";
#    #say "\$winMin_3 <$winMin_3> \$winMax_3 <$winMax_3>";
#
#    ## Open outputs
#    my $outputName_1 = $key . "_output_" . $winMin_1 . "-" . $winMax_1;
#    my $outputName_2 = $key . "_output_" . $winMin_2 . "-" . $winMax_2;
#    my $outputName_3 = $key . "_output_" . $winMin_3 . "-" . $winMax_3;
#    open my $outputFile_fh_1, '>', $outputName_1 or die "Couldn't open output file $outputName_1 $!";
#    open my $outputFile_fh_2, '>', $outputName_2 or die "Couldn't open output file $outputName_2 $!";
#    open my $outputFile_fh_3, '>', $outputName_3 or die "Couldn't open output file $outputName_3 $!";
#
#    ## PRINT HEADER to OUTPUTS
#    print $outputFile_fh_1 "20\n"; #Print 'number of datasets (n)'
#    print $outputFile_fh_1 "1\n"; #Print 'Nº SFS with != numbers of alleles sampled (m)'
#    print $outputFile_fh_1 "128\n"; # Print 'Nº alleles sampled in SFS i (xi)'
#
#    print $outputFile_fh_2 20 . "\n"; #Print 'number of datasets (n)'
#    print $outputFile_fh_2 "1\n"; #Print 'Nº SFS with != numbers of alleles sampled (m)'
#    print $outputFile_fh_2 "128\n"; # Print 'Nº alleles sampled in SFS i (xi)'
#
#    print $outputFile_fh_3 $numElements - 40 . "\n"; #Print 'number of datasets (n)'
#    print $outputFile_fh_3 "1\n"; #Print 'Nº SFS with != numbers of alleles sampled (m)'
#    print $outputFile_fh_3 "128\n"; # Print 'Nº alleles sampled in SFS i (xi)'
#
#    ## Read ALL input files in slurp mode
#    # First output file
#    for (my $i = 0; $i < 20; $i++) {
#        my $fileContent;
#        {   #Local block for $/ (slurp mode)
#            open my $fh, '<', $files[$i];
#            local $/ = undef;
#            $fileContent = <$fh>;
#            close $fh;
#        } 
#        #Clean $fileContent from old headers, and insert line of nºdataset($numElements)
#        my $numDataset = $i+1;
#        $fileContent =~ s/1\n1\n128\n1/$numDataset/g;
#        # Print body
#        print $outputFile_fh_1 $fileContent;
#    }
#
#    # Second output file
#    for (my $i = 20; $i < 40; $i++) {
#        my $fileContent;
#        {   #Local block for $/ (slurp mode)
#            open my $fh, '<', $files[$i];
#            local $/ = undef;
#            $fileContent = <$fh>;
#            close $fh;
#        } 
#        #Clean $fileContent from old headers, and insert line of nºdataset($numElements)
#        my $numDataset = $i-19;
#        $fileContent =~ s/1\n1\n128\n1/$numDataset/g;
#        # Print body
#        print $outputFile_fh_2 $fileContent;
#    }
#
#    # Third output file
#    for (my $i = 40; $i < $numElements; $i++) {
#        my $fileContent;
#        {   #Local block for $/ (slurp mode)
#            open my $fh, '<', $files[$i];
#            local $/ = undef;
#            $fileContent = <$fh>;
#            close $fh;
#        } 
#        #Clean $fileContent from old headers, and insert line of nºdataset($numElements)
#        my $numDataset = $i-39;
#        $fileContent =~ s/1\n1\n128\n1/$numDataset/g;
#        # Print body
#        print $outputFile_fh_3 $fileContent;
#    }
#}

