#!/usr/bin/perl

my $vars = {};


while(<STDIN>)
{
	if( /(REPLACE-[a-zA-Z\-]+)/ )
	{
		$vars->{$1} = 1;
	}
}

foreach $k ( sort keys %$vars )
{
	print "	'$k' => '\n";
}
