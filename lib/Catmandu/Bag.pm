package Catmandu::Bag;

use Catmandu::Sane;

our $VERSION = '1.0002';

use Catmandu::Util qw(:check is_string require_package);
use Catmandu::IdGenerator::UUID;
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';
with 'Catmandu::Pluggable';
with 'Catmandu::Iterable';
with 'Catmandu::Addable';

requires 'get';
requires 'delete';
requires 'delete_all';

has store => (is => 'ro');
has name  => (is => 'ro');
has id_generator => (
    is => 'lazy',
    coerce => sub {
        if (is_string($_[0])) {
            require_package($_[0], 'Catmandu::IdGenerator')->new;
        } else {
            $_[0];
        }
    },
);

sub _build_id_generator {
    state $uuid = Catmandu::IdGenerator::UUID->new;
}

before get => sub {
    check_value($_[1]);
};

before add => sub {
    my ($self, $data) = @_;
    check_hash_ref($data);
    check_value($data->{_id} //= $self->generate_id($data));
};

before delete => sub {
    check_value($_[1]);
};

around delete_all => sub {
    my ($orig, $self) = @_;
    $orig->($self);
    return;
};

sub generate_id {
    $_[0]->id_generator->generate;
}

sub get_or_add {
    my ($self, $id, $data) = @_;
    check_value($id);
    check_hash_ref($data);
    $self->get($id) || do {
        $data->{_id} = $id;
        $self->add($data);
    };
}

sub to_hash {
    my ($self) = @_;
    $self->reduce({}, sub {
        my ($hash, $data) = @_;
        $hash->{$data->{_id}} = $data;
        $hash;
    });
}

1;

__END__

=pod

=head1 NAME

Catmandu::Bag - A Catmandu::Store compartment to persist data

=head1 SYNOPSIS

    my $store = Catmandu::Store::DBI->new(data_source => 'DBI:mysql:database=test');

    my $store = Catmandu::Store::DBI->new(
            data_source => 'DBI:mysql:database=test',
            bags => { journals => {
                            fixes => [ ... ] ,
                            autocommit => 1 ,
                            plugins => [ ... ] ,
                            id_generator => Catmandu::IdGenerator::UUID->new ,
                      }
                    },
            bag_class => Catmandu::Bag->with_plugins('Datestamps')
            );

    # Use the default bag...
    my $bag = $store->bag;

    # Or a named bag...
    my $bag = $store->bag('journals');

    # Every bag is an iterator...
    $bag->each(sub { ... });
    $bag->take(10)->each(sub { ... });

    $bag->add($hash);
    $bag->add_many($iterator);
    $bag->add_many([ $hash, $hash , ...]);

    # Commit changes...
    $bag->commit;

    my $obj = $bag->get($id);
    $bag->delete($id);

    $bag->delete_all;

=head1 OPTIONS

=head2 fixes

An array of fixes to apply before importing or exporting data from the bag.

=head2 plugins

An array of Catmandu::Pluggable to apply to the bag items.

=head2 autocommit

When set to a true value an commit automatically gets executed when the bag
goes out of scope.

=head2 id_generator

An Catmandu::IdGenerator.

=head1 METHODS

=head2 new(OPTIONS)

Create a new Bag.

=head2 add($hash)

Add a hash to the bag or updates an existing hash by using its '_id' key. Returns
the stored hash on success or undef on failure.

=head2 add_many($array)

=head2 add_many($iterator)

Add or update one or more items to the bag.

=head2 get($id)

Retrieves the item with identifier $id from the bag.

=head2 get_or_add($id, $hash)

Retrieves the item with identifier $id from the store or adds C<$hash> with _id
C<$id> if it's not found.

=head2 delete($id)

Deletes the item with C<$id> from the bag.

=head2 delete_all

Clear the bag.

=head2 commit

Commit changes.

=head2 log

Return the current logger.

=head1 CLASS METHODS

=head2 with_plugins($plugin)

=head2 with_plugins(\@plugins)

Plugins are a kind of fixes that should be available for each bag. E.g. the Datestamps plugin will
automatically store into each bag item the fields 'date_updated' and 'date_created'. The with_plugins
accept one or an array of plugin classnames and returns a subclass of the Bag with the plugin
methods implemented.

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Searchable>, L<Catmandu::Fix>, L<Catmandu::Pluggable>

=cut
