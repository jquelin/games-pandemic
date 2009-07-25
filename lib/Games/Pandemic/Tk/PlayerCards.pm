package Games::Pandemic::Tk::PlayerCards;
# ABSTRACT: window holding player cards for Games::Pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use Tk;

use Games::Pandemic::Tk::Utils;
use Games::Pandemic::Utils;


# -- initialization

#
# BUILD()
#
# called during object initialization.
#
sub BUILD {
    my $self = shift;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage
