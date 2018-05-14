#!/usr/bin/perl
# Copyright (c) 2014 Peter Varkoly <peter@varkoly.de> Nürnberg, Germany.  All rights reserved.
BEGIN{ push @INC,"/usr/share/oss/lib/"; }

use strict;
use oss_base;
use oss_utils;

my $oss  = oss_base->new();

my $schools = $oss->get_schools(1);
my $DEBUG = 0;

foreach my $school ( @$schools )
{
        cmd_pipe('at now','/root/bin/licence-statistic.pl '.$school->{sdn});
        sleep(5);
}
$oss->destroy();
1;

