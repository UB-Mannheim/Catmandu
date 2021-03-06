package Catmandu::Cmd::export;

use Catmandu::Sane;

our $VERSION = '1.0002';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (
        [ "verbose|v", "" ],
        [ "fix=s@", "" ],
        [ "start=i", "" ],
        [ "limit=i", "" ],
        [ "total=i", "" ],
        [ "cql-query|q=s", "" ],
        [ "query=s", "" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts) = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    my $into = Catmandu->exporter($into_args->[0], $into_opts);

    if ($opts->query // $opts->cql_query) {
        $self->usage_error("Bag isn't searchable") unless $from->can('searcher');
        $from = $from->searcher(
            cql_query => $opts->cql_query,
            query     => $opts->query,
            start     => $opts->start,
            total     => $opts->total,
            limit     => $opts->limit,
        );
    } elsif ($opts->start // $opts->total) {
        $from = $from->slice($opts->start, $opts->total);
    }
    if ($opts->fix) {
        $from = Catmandu->fixer($opts->fix)->fix($from);
    }
    if ($opts->verbose) {
        $from = $from->benchmark;
    }

    my $n = $into->add_many($from);
    $into->commit;
    if ($opts->verbose) {
        say STDERR $n == 1 ? "exported 1 object" : "exported $n objects";
        say STDERR "done";
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::export - export objects from a store

=head1 EXAMPLES

  catmandu export <STORE> <OPTIONS> to <EXPORTER> <OPTIONS>

  catmandu export MongoDB --database-name items --bag book to YAML

  catmandu help store MongoDB
  catmandu help exporter YAML

=cut
