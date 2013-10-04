#!/usr/bin/env perl

use lib './';
use DFEmodule; use DFEmodule_2; use feature 'say';

my $modulo = DFEmodule->new(
    name => 'nombre'
);
say $modulo->name;
