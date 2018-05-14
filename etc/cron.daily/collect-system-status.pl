#!/usr/bin/perl
# Copyright (c) 2014 Peter Varkoly <peter@varkoly.de> Nürnberg, Germany.  All rights reserved.


my $schools = $oss->get_schools(1);

foreach my $school ( @$schools )
{
        my $secret = $oss->get_vendor_object($school->{sdn},'CEPHALIX','SECRET' );
        next if ( ! defined $secret->[0] );
	system('/root/bin/collect-system-status.pl '.$school->{sdn}.' &');
	sleep 1;
}

