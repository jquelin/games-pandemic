package Games::Pandemic::Tk::Constants;
# ABSTRACT: Tk constants for gui building

use 5.010;
use strict;
use warnings;

use Moose;
extends 'Exporter';

our @EXPORT = qw{
    @TOP @BOTTOM @LEFT @RIGHT
    @FILLX  @FILLY  @FILL2
    @XFILLX @XFILLY @XFILL2
    @PAD1   @PAD20 @PADX10
    @ENON   @ENOFF
};

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
our @PAD20   = ( -padx => 20, -pady => 20);
our @PADX10  = ( -padx => 10 );

# enabled state
our @ENON    = ( -state => 'normal' );
our @ENOFF   = ( -state => 'disabled' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This module just exports easy to use constants for Tk, such as C<@TOP>
to be used in place of C<-side => 'top'>. Since those are quite common,
it's easier to use those constants.

Other than that, the module does nothing.


