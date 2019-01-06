#!/usr/bin/perl
# Copyright 2018 Peter Varkoly <peter@varkoly.de>  Germany, Nuremberg

use strict;
use Data::Dumper;
use JSON::XS;
use Net::Netmask;
use Encode qw(encode decode);
binmode STDIN,  ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
use utf8;

my $Defaults = "/usr/share/cephalix/templates/Defaults.ini";

my @TO_CLEAN   = qw(
        uuid
        name
        type
        domain
        adminPW
);

my $READONLY   = {
        "CEPHALIX" => 1,
        "CEPHALIX_PATH"    => 1,
        "CEPHALIX_DOMAIN"  => 1,
	"CCODE" => 1,
	"LANGUAGE" => 1,
	"NTP" => 1,
        "ZADMIN"   => 1
};

my @SSL = qw(
        REPLACE-SSHKEY
        REPLACE-CA-CERT
        REPLACE-VPN-CERT
        REPLACE-VPN-KEY
        REPLACE-SERVER-KEY
        REPLACE-SERVER-CERT
        REPLACE-ADMIN-CERT
        REPLACE-ADMIN-KEY
        REPLACE-SCHOOL-KEY
        REPLACE-SCHOOL-CERT
);

my %SSLVARS = ();

my $hash = "";

#############################################
# Some helper functions

sub hash_to_json($) {
    my $hash = shift;
    my $json = '{';
    foreach my $key ( keys %{$hash} ) {
        my $value = $hash->{$key};
        $json .= '"'.$key.'":';
        if( $value eq 'true' ) {
       $json .= 'true,';
        } elsif ( $value eq 'false' ) {
       $json .= 'false,';
        } elsif ( $value =~ /^\d+$/ ) {
       $json .= $value.',';
        } else {
                $value =~ s/"/\\"/g;
                $json .= '"'.$value.'",';
        }
    }
    $json =~ s/,$//;
    $json .= '}';
}

sub convert_json_to_hash($)
{
   my $res = shift;
   $res =~ s/:false/:0/g;
   $res =~ s/:true/:1/g;
   $res =~ s/:null/:""/g;
   $res =~ s/":/"=>/g;
   return eval($res);
}


sub contains {
    my $a = shift;
    my $b = shift;
    foreach(@{$b}){
        if($a eq $_) {
                return 1;
        }
    }
    return 0;
}

sub write_file($$) {
  my $file = shift;
  my $out  = shift;
  local *F;
  open F, ">$file" || die "Couldn't open file '$file' for writing: $!; aborting";
  binmode F, ':encoding(utf8)';
  local $/ unless wantarray;
  print F $out;
  close F;
}

sub get_file($) {
    my $file     = shift;
    return undef if( ! -e $file );
    my $content  = '';
    local *F;
    open F, $file || return undef;
    binmode F, ':encoding(utf8)';
    while( <F> )
    {
       $content .= $_;
    }
    return $content;
}


#
#############################################

while(<STDIN>) {
   $hash .= $_;
}
my $TASK      =`uuidgen -t`; chomp $TASK;
system("mkdir -p /var/adm/oss/opentasks/");
write_file("/var/adm/oss/opentasks/$TASK",$hash);

my $reply = convert_json_to_hash($hash);

my $default  = decode_json(`cat $Defaults`);
my $CEPHALIX_PATH   = $default->{'CEPHALIX_PATH'};
my $CEPHALIX_DOMAIN = $default->{'CEPHALIX_DOMAIN'};
my $SAVE_NEXT = ( $default->{'SAVE_NEXT'} eq "yes" ) ? 1 : 0;
my $path = $CEPHALIX_PATH.'/configs/'.$reply->{"uuid"}.".ini";
my $AY_TEMPLATE = $reply->{"ayTemplate"} || "default";
my $XMLFile  = "/usr/share/cephalix/templates/autoyast-".$AY_TEMPLATE.".xml";

system("mkdir -p $CEPHALIX_PATH/configs/");

#Add the read only variables to the reply 
foreach my $k ( keys(%$READONLY) )
{
       $reply->{$k} = $default->{$k};
}

#Handle VPN
if( $reply->{'ipAdmin'} ne $reply->{'ipVPN'} ) {
	my $vpnblock = new Net::Netmask($reply->{'ipVPN'}."/255.255.255.252");
	my $VPN      = "ifconfig-push ".$vpnblock->nth(2).' '.$vpnblock->nth(1)."\n";
	$reply->{'ipVPN'} = $vpnblock->nth(2);
	if( $reply->{'fullrouting'} )
	{
		my $block = new Net::Netmask($reply->{"network"});
		$VPN .= 'iroute '.$block->base().' '.$block->mask()."\n";
	}
	write_file('/etc/openvpn/ccd/'.$reply->{'uuid'},$VPN);

	my $next     = $vpnblock->next();
	$default->{'ipVPN'} = $next;
}
if( $SAVE_NEXT )
{
        my $block = new Net::Netmask($reply->{"network"});
        my $next  = $block->next();
        $default->{'network'} = $next;
        my ( $a,$b,$c,$d ) = split /\./, $next;
        $default->{'ipAdmin'}	= "$a.$b.$c.".($d+2);
        $default->{'ipMail'}	= "$a.$b.$c.".($d+3);
        $default->{'ipPrint'}	= "$a.$b.$c.".($d+4);
        $default->{'ipProxy'}	= "$a.$b.$c.".($d+5);
        $default->{'ipBackup'}	= "$a.$b.$c.".($d+6);
        $default->{'anonDhcp'}	= "$a.$b.".($c+1).".0 $a.$b.".($c+1).".31";
        $default->{'firstRoom'}	= "$a.$b.".($c+2).".0";
}

foreach my $v ( @TO_CLEAN )
{
        $default->{$v} = '';
}
if( ! -e "$CEPHALIX_PATH/CA_MGM/certs/admin.".$reply->{"domain"}.".key.pem" ) {
        my $command = "$CEPHALIX_PATH/create_server_certificates.sh -P $CEPHALIX_PATH -O '".$reply->{'name'};
	if( defined $reply->{'state'} ) {
		$command .= "'  -S '".$reply->{'state'}."'";
	}
	if( defined $reply->{'locality'} ) {
		$command .= "'  -S '".$reply->{'locality'}."'";
	}
        system("$command -D '".$reply->{'domain'}."' -N 'schooladmin'");
        system("$command -D '".$reply->{'domain'}."' -N 'admin'");
        system("$command -D '".$reply->{'domain'}."' -N 'schoolserver'");
        system("$command -D '$CEPHALIX_DOMAIN' -N '".$reply->{'uuid'}."' -s");
}

#Create autoyast config

my $SCHOOL_DOMAIN   = $reply->{'domain'};
my $SCHOOL_sn       = $reply->{'uuid'};
my $block           = new Net::Netmask($reply->{'network'});
my $BITS            = $block->bits();

# In 4.0 it was changed:
$reply->{'network'}       = $block->base();
$reply->{'netmask'}       = $block->bits();
$reply->{'netmaskString'} = $block->mask();
my $dhcpBlock           = new Net::Netmask($reply->{'anonDhcpNetwork'});
my $dhcpLast = $dhcpBlock->broadcast();
my $serverBlock           = new Net::Netmask($reply->{'serverNetwork'});
$reply->{'serverNetworkmask'} = $serverBlock->bits();
if( $dhcpBlock->broadcast() eq $block->broadcast() ) {
   my @tmp  = split /\./, $dhcpBlock->broadcast();
   $dhcpLast = $tmp[0].'.'.$tmp[1].'.'.$tmp[2].'.'.( $tmp[3] - 1 );
}

$reply->{'anonDhcpRange'} = $dhcpBlock->base()." ".$dhcpLast;

# Evaluate WORKGROUP
my @ltmp = split /\./, $reply->{'domain'};
$reply->{'WORKGROUP'} = uc($ltmp[0]);

my $XML   = `cat $XMLFile`;
foreach my $par ( keys %{$reply} )
{
        my $val = $reply->{$par};
	Encode::_utf8_on($val);
	my $ph  = '###'.$par.'###';
        $XML =~ s/$ph/$val/g;
}

$SSLVARS{'REPLACE-SSHKEY'}     = `cat /root/.ssh/id_dsa.pub`;
$SSLVARS{'REPLACE-CA-CERT'}    = `cat $CEPHALIX_PATH/CA_MGM/cacert.pem`;
$SSLVARS{'REPLACE-VPN-KEY'}    = `cat $CEPHALIX_PATH/CA_MGM/certs/$SCHOOL_sn.$CEPHALIX_DOMAIN.key.pem`;
$SSLVARS{'REPLACE-VPN-CERT'}   = `cat $CEPHALIX_PATH/CA_MGM/certs/$SCHOOL_sn.$CEPHALIX_DOMAIN.cert.pem`;
$SSLVARS{'REPLACE-ADMIN-KEY'}  = `cat $CEPHALIX_PATH/CA_MGM/certs/admin.$SCHOOL_DOMAIN.key.pem`;
$SSLVARS{'REPLACE-ADMIN-CERT'} = `cat $CEPHALIX_PATH/CA_MGM/certs/admin.$SCHOOL_DOMAIN.cert.pem`;
$SSLVARS{'REPLACE-SCHOOL-KEY'} = `cat $CEPHALIX_PATH/CA_MGM/certs/schoolserver.$SCHOOL_DOMAIN.key.pem`;
$SSLVARS{'REPLACE-SCHOOL-CERT'}= `cat $CEPHALIX_PATH/CA_MGM/certs/schoolserver.$SCHOOL_DOMAIN.cert.pem`;

foreach my $sslpar ( @SSL )
{
        $XML =~ s/$sslpar/$SSLVARS{$sslpar}/g;
}
system("mkdir -p /srv/www/admin/{configs,isos}");
write_file("/srv/www/admin/configs/$SCHOOL_sn.xml",$XML);
write_file($Defaults,hash_to_json($default));

my $apache = "        ProxyPass          /$SCHOOL_sn http://".$reply->{'ipVPN'}."/api
        ProxyPassReverse   /$SCHOOL_sn http://".$reply->{'ipVPN'}."/api
";
write_file("/etc/apache2/vhosts.d/admin-ssl/$SCHOOL_sn.conf",$apache);
system("systemctl restart apache2");

my $tmpDir   = `mktemp /tmp/mkisoXXXXX`; chomp $tmpDir;
my $createCD = "cp /srv/www/admin/configs/$SCHOOL_sn.xml /usr/share/cephalix/templates/iso/oss.xml;\n".
	       "mkisofs --publisher 'Dipl.Ing. Peter Varkoly' -p 'CD-Team, http://www.cephalix.eu' ".
	       "-r -J -f -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/x86_64/loader/isolinux.bin ".
               "-c boot/boot.catalog -hide boot/boot.catalog -hide-joliet boot/boot.catalog -A - -V SU.001 -o /srv/www/admin/isos/$SCHOOL_sn.iso $tmpDir /usr/share/cephalix/templates/iso/ >/dev/null 2>&1";

system($createCD);
