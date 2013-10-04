#Package for working with DFE-alpha server formats

#use lib './';

package DFEmodule;
use Moose; use feature 'say';

# # Attributes
has name => (
    is => 'rw',
    isa => 'Str',
);



# # Subroutines



# # Ending
no Moose;   #Remove Moose exports from your namespace
__PACKAGE__->meta->make_immutable;  #No more changes to class definition.
1;
