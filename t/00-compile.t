#!perl
#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#

use strict;
use warnings;

use Test::More;



use File::Find;
use File::Temp qw{ tempdir };

my @modules;
find(
  sub {
    return if $File::Find::name !~ /\.pm\z/;
    my $found = $File::Find::name;
    $found =~ s{^lib/}{};
    $found =~ s{[/\\]}{::}g;
    $found =~ s/\.pm$//;
    # nothing to skip
    push @modules, $found;
  },
  'lib',
);

my @scripts;
if ( -d 'bin' ) {
    find(
      sub {
        return unless -f;
        my $found = $File::Find::name;
        # nothing to skip
        push @scripts, $found;
      },
      'bin',
    );
}

my $plan = scalar(@modules) + scalar(@scripts);
$plan ? (plan tests => $plan) : (plan skip_all => "no tests to run");

{
    # fake home for cpan-testers
    # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );

    like( qx{ $^X -Ilib -e "require $_; print '$_ ok'" }, qr/^\s*$_ ok/s, "$_ loaded ok" )
        for sort @modules;

    SKIP: {
        eval "use Test::Script 1.05; 1;";
        skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
        foreach my $file ( @scripts ) {
            my $script = $file;
            $script =~ s!.*/!!;
            script_compiles( $file, "$script script compiles" );
        }
    }
}
