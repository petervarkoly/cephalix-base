#!/usr/bin/perl
# Copyright (c) 2014 Peter Varkoly <peter@varkoly.de> Nürnberg, Germany.  All rights reserved.
use strict;

my $DEBUG = 0;

foreach my $school ( @$schools )
{
        cmd_pipe('at now','/root/bin/licence-statistic.pl '.$school->{sdn});
        sleep(5);
}
$oss->destroy();
1;

