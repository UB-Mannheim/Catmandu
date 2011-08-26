package Catmandu::Sane;
use 5.010;
use strict;
use warnings;
use feature ();
use utf8;
use mro ();
use Scalar::Util ();
use Carp ();

sub import {
    my $pkg = caller;

    strict->import;
    warnings->import;
    feature->import(':5.10');
    utf8->import;
    mro::set_mro($pkg, 'c3');
    Scalar::Util->export_to_level(1, $pkg, qw(blessed));
    Carp->export_to_level(1, $pkg, qw(confess));
}

1;