use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Utils;
# ABSTRACT: Tk utilities for gui building

use File::Spec::Functions qw{ catfile };
use Moose;
use POE;
extends 'Exporter';

use Games::Pandemic::Utils;

our @EXPORT = qw{ image pandemic_icon };

# -- public subs

=method my $img = image( $path [, $toplevel ] );

Return a tk image loaded from C<$path>. If the photo has already been
loaded, return a handle on it. If C<$toplevel> is given, it is used as
base window to load the image.

=cut

sub image {
    my ($path, $toplevel) = @_;
    $toplevel //= $poe_main_window; # //FIXME: padre
    my $img = $poe_main_window->Photo($path);
    return $img if $img->width;
    return $toplevel->Photo("$toplevel-$path", -file=>$path);
}


=method my $img = pandemic_icon( [$toplevel] );

Return a tk image to be used as C<$toplevel> icon throughout the game.

=cut

sub pandemic_icon {
    return image( catfile($SHAREDIR, 'icon.png'), @_ );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This module exports some useful subs for tk guis.

