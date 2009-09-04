use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Special;
# ABSTRACT: base class for special pandemic event cards

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Card';

has description => ( is => 'ro', isa => 'Str', lazy_build => 1 );


# -- public methods


=method my $event = $special->event;

Return the special card name, from C<CamelCaseName> to
C<camel_case_name>. This will be used as the event name sent to
main window.

Eg, L<Games::Pandemic::Card::Special::OneQuietNight> objects will return
C<one_quiet_night>.

=cut

sub event {
    my $self = shift;
    my $ref  = ref $self;
    $ref =~ s/^Games::Pandemic::Card::Special:://;
    $ref =~ s/([[:upper:]])/_$1/g;
    $ref =~ s/^_//;
    return lc $ref;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package is the base class for all special event cards in
L<Games::Pandemic>. Nothing really interesting, check the
subclasses instead.
