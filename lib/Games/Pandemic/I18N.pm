use 5.010;
use strict;
use warnings;

package Games::Pandemic::I18N;
# ABSTRACT: internationalization utilities for pandemic

use Encode;
use Exporter::Lite;
use Locale::TextDomain 'Games-Pandemic';

our @EXPORT_OK = qw{ T };


# -- public subs

=method my $locstr = T( $string )

Performs a call to C<gettext> on C<$string>, convert it from utf8 and
return the result. Note that i18n is using C<Locale::TextDomain>
underneath, so refer to this module for more information.

=cut

sub T { return decode('utf8', __($_[0])); }


1;
__END__

=head1 DESCRIPTION

This module provides some helper subs for internationalizing pandemic.

