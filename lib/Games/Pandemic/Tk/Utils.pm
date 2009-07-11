package Games::Pandemic::Tk::Utils;
# ABSTRACT: Tk utilities for gui building

use 5.010;
use strict;
use warnings;

use File::Spec::Functions qw{ catfile };
use Moose;
use POE;
extends 'Exporter';

use Games::Pandemic::Utils;

our @EXPORT = qw{
    @TOP @BOTTOM @LEFT @RIGHT
    @FILLX  @FILLY  @FILL2
    @XFILLX @XFILLY @XFILL2
    @PAD1   @PAD10 @PAD20 @PADX10
    @IPAD10
    @ENON   @ENOFF
    image   pandemic_icon
};

# -- exported constants (variables, since tk doesn't play nice with readonly)

# pack sides
our @TOP     = ( -side => 'top'    );
our @BOTTOM  = ( -side => 'bottom' );
our @LEFT    = ( -side => 'left'   );
our @RIGHT   = ( -side => 'right'  );

# pack fill / expand
our @FILLX   = ( -fill => 'x'    );
our @FILLY   = ( -fill => 'y'    );
our @FILL2   = ( -fill => 'both' );
our @XFILLX  = ( -expand => 1, -fill => 'x'    );
our @XFILLY  = ( -expand => 1, -fill => 'y'    );
our @XFILL2  = ( -expand => 1, -fill => 'both' );

# padding
our @PAD1    = ( -padx => 1, -pady => 1);
our @PAD10   = ( -padx => 10, -pady => 10);
our @PAD20   = ( -padx => 20, -pady => 20);
our @PADX10  = ( -padx => 10 );

# internal padding
our @IPAD10   = ( -ipadx => 10, -ipady => 10);

# enabled state
our @ENON    = ( -state => 'normal' );
our @ENOFF   = ( -state => 'disabled' );


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

This module exports easy to use constants for Tk, such as C<@TOP> to be
used in place of C<-side => 'top'>. Since those are quite common, it's
easier to use those constants.

It also provides some useful subs for tk guis.

