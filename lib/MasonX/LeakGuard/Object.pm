package MasonX::LeakGuard::Object;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(HTML::Mason::Plugin);

use Devel::LeakGuard::Object::State;
use Data::Dumper;

our %BEEN_IN;

our %OPTIONS;

=head1 NAME

MasonX::LeakGuard::Object - report memory leaks (objects) per request

=head1 SYNOPSIS

    use MasonX::LeakGuard::Object;
    %MasonX::LeakGuard::Object::OPTIONS = (
        exclude => [
            'utf8',
            'HTML::Mason::*',
            'Devel::StackTrace',
        ],
    );
    my @MasonParameters = (
        ...
        plugins => [qw(MasonX::LeakGuard::Object)],
    );

=head1 DESCRIPTION

This is plugin for L<HTML::Mason> applications that helps you find
memory leaks in OO applications. It uses L<Devel::LeakGuard::Object>
framework for that.

Leaks are reported using perl's C<warn> function. Report is very simple,
shows request path, arguments (using L<Data::Dumper>) and counts
of objects that leaked with groupping by class.

It's possible that false positives to be reported, for example if
a compontent has ONCE block where you cache some values. Most caches
will generate false positive reports, but it's possible to use
options of L<function leakguard in Devel::LeakGuard::Object|Devel::LeakGuard::Object/leakguard>.
Look at L</SYNOPSIS> for details.

To avoid many false positives the module as well B<ignores> first
request to a path.

=cut

sub start_request_hook {
    my ($self, $context) = @_;
    $self->{'path'} = $context->request->request_comp->path;
    if ( $BEEN_IN{ $self->{'path'} } ) {
        $self->{'args'} = Dumper( scalar $context->args );
        $self->{'state'} = Devel::LeakGuard::Object::State->new(
            %OPTIONS
        );
    }
}

sub end_request_hook {
    my ($self, $context) = @_;

    my $path = $self->{'path'};
    unless ( $BEEN_IN{ $path } ) {
        $BEEN_IN{ $path } = 1;
        return;
    }

    my $state = $self->{'state'};
    my $args = $self->{'args'};

    my $old_sub = $state->{'on_leak'};
    $state->{'on_leak'} = sub {
        warn "Leak in $path with args '$args'";
        return $old_sub->(@_)
    };
    $state->done;
}

1;

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

-cut
