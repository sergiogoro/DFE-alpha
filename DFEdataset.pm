package DFEdataset;

use Moose;
extends 'DFEmodule';

use feature 'say'; use Data::Dumper;
use Moose::Util::TypeConstraints; #For defining subtypes

# # Attributes
# Parental attrib.
has parentFilename => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has parentWinRange => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

# Dataset attrib.
has datasetNumber => (
    is => 'rw',
    isa => 'Num',
);

has chromosome => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has chr_state => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has winStart => (
    is => 'rw',
    isa => 'Num',
);

has winEnd => (
    is => 'rw',
    isa => 'Num',
);

has paramEstimates => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub { [ ] }, #Default: new anonymous array
);

# Selected
has selectedAnalyzed => (
    is => 'rw',
    isa => 'Num',
);

has numSelectedDivSites => (
    is => 'rw',
    isa => 'Num',
);

has numSelectedDiff => (
    is => 'rw',
    isa => 'Num',
);

has selectedSFS => (
    is => 'rw',
    isa => 'ArrayRef[Int]',
);

# Neutral
has neutralAnalyzed => (
    is => 'rw',
    isa => 'Num',
);

has numNeutralDivSites => (
    is => 'rw',
    isa => 'Num',
);

has numNeutralDiff => (
    is => 'rw',
    isa => 'Num',
);

has neutralSFS => (
    is => 'rw',
    isa => 'ArrayRef[Int]',
);

# Num. sites analyzed
has numAnalyzed => (
    is => 'rw',
    isa => 'Num',
);

# Proportion of mutants
has proporMutants_range0_1 => (
    is => 'rw',
    isa => 'Num',
);
has proporMutants_range1_10 => (
    is => 'rw',
    isa => 'Num',
);
has proporMutants_range10_100 => (
    is => 'rw',
    isa => 'Num',
);
has proporMutants_range100_inf => (
    is => 'rw',
    isa => 'Num',
);


1;
