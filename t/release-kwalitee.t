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

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


# This test is generated by Dist::Zilla::Plugin::Test::Kwalitee
use strict;
use warnings;
use Test::More;   # needed to provide plan.
eval "use Test::Kwalitee";

plan skip_all => "Test::Kwalitee required for testing kwalitee" if $@;
