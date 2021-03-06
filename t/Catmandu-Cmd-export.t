#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use JSON::XS;
use utf8;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd::export';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [ qw(export -v test to JSON --line-delimited 1 --fix t/myfixes.fix --total 1) ]);

my @lines = split(/\n/, $result->stdout);

ok @lines == 1 , 'test total';

my $perl = decode_json($lines[0]);

ok $perl, 'got JSON';
is $perl->{value} , 'Sol' , 'got data';
is $perl->{utf8_name} , 'ვეპხის ტყაოსანი შოთა რუსთაველი' , 'got utf8 data';
is $result->error, undef, 'threw no exceptions';

# next test can fail on buggy Perl installations
#is $result->stderr, '', 'nothing sent to sderr';

done_testing;
