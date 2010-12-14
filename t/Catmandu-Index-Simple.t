use Test::Exception;
use Test::Moose;
use Test::More tests => 22;
use File::Temp;

BEGIN { use_ok 'Catmandu::Index::Simple'; }
require_ok 'Catmandu::Index::Simple';

my $tmp = File::Temp->newdir;

my $index = Catmandu::Index::Simple->new(path => $tmp->dirname);
note "index path is " . $tmp->dirname;

 isa_ok $index, Catmandu::Index::Simple;
does_ok $index, Catmandu::Index;

$obj1 = {_id => "001", title => "the third man"};
$obj2 = {_id => "002", title => "the tenth man"};

my $hits;
my $total_hits;

is_deeply $index->save($obj1), $obj1;

$index->save($obj2);

($hits, $total_hits) = $index->search("man");
is scalar @$hits, 2;
is $total_hits, 2;
($hits, $total_hits) = $index->search("third");
is scalar @$hits, 1;
is $total_hits, 1;
($hits, $total_hits) = $index->search("tenth");
is scalar @$hits, 1;
is $total_hits, 1;
($hits, $total_hits) = $index->search("third OR tenth");
is scalar @$hits, 2;
is $total_hits, 2;
($hits, $total_hits) = $index->search("third AND tenth");
is scalar @$hits, 0;
is $total_hits, 0;

($hits, $total_hits) = $index->search("_id : 001");
is scalar @$hits, 1;
is $total_hits, 1;

($hits, $total_hits) = $index->search({_id => "001"});
is scalar @$hits, 1;
is $total_hits, 1;

throws_ok { $index->delete({missing => '_id'}) } qr/Missing/;

$index->delete({_id => "001"});
($hits, $total_hits) = $index->search("_id : 001");
is $total_hits, 0;
$index->delete("002");
($hits, $total_hits) = $index->search("_id : 002");
is $total_hits, 0;

done_testing;

