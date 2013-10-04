package DFEmodule_2;

use Moose;
use lib './';
extends 'DFEmodule';
use Moose::Util::TypeConstraints; #For defining subtypes

# # Subtypes
subtype 'chromosome',
    => as 'Str',
    => where { '2L' | '2R' | '3L' | '3R' | 'X' },
    => message { 'Not a valid chromosome (2L, 2R, 3L, 3R, X accepted)' };

subtype 'state',
    => as 'Str',
    => where { 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G' | 'H' | 'I' },
    => message { 'Not a valid chromatin state ([A-I] accepted)' };

# # Attributes

has name => (
    required => 1,
    isa => 'Str',
    is => 'rw',
);

has chromosome => (
    isa => 'ArrayRef[Str]',
    is => 'rw',
    default => sub { [ ] }, 
);

has state => (
    isa => 'ArrayRef[Str]',
    is => 'rw',
    default => sub { [ ] }, 
);

has files => (
    is => 'rw',
    isa => 'HashRef[Str]',
);


# # Subroutines
#



# # Ending
1;
