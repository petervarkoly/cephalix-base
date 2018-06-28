#!/usr/bin/perl
# Copyright 2018 Peter Varkoly <peter@varkoly.de>  Germany, Nuremberg

use strict;
use Data::Dumper;
use JSON::XS;
use Config::IniFiles;
use Net::Netmask;

my $Defaults = "/usr/share/cephalix/templates/Defaults.ini";
my $XMLFile  = "/usr/share/cephalix/templates/autoyast-template.xml";

my @TO_CLEAN   = qw(
        uuid
        name
        type
        domain
        adminPW
);

my $VARMAP  = {
        'REPLACE-CPW' => 'cephalixPW',
        'REPLACE-sn' => 'uuid',
        'REPLACE-CN' => 'name',
        'REPLACE-GW' => 'gwTrNet',
        'REPLACE-NET' => 'network',
        'REPLACE-NET-GW' => 'ipGateway',
        'REPLACE-NM' => 'netmask',
        'REPLACE-PW' => 'adminPW',
        'REPLACE-REGCODE' => 'registrationsCode',
        'REPLACE-TRIP' => 'ipTrNet',
        'REPLACE-TRNM' => 'nmTrNet',
        'REPLACE-admin' => 'ipAdmin',
        'REPLACE-anon' => 'anonDhcp',
        'REPLACE-backup' => 'ipBackup',
        'REPLACE-dom' => 'domain',
        'REPLACE-mail' => 'ipMail',
        'REPLACE-print' => 'ipPrint',
        'REPLACE-proxy' => 'ipProxy',
        'REPLACE-room' => 'firstRoom',
        'REPLACE-type' => 'type',
        'REPLACE-STATE' => 'state',
	uuid	=> 'REPLACE-sn',
	name    => 'REPLACE-CN',
	ipAdmin	=> 'REPLACE-admin',
	ipMail	=> 'REPLACE-mail',
	ipPrint	=> 'REPLACE-print',
	ipProxy	=> 'REPLACE-proxy',
	ipBackup=> 'REPLACE-backup',
	network	=> 'REPLACE-NET',
	netmask => 'REPLACE-NM',
	anonDhcp=> 'REPLACE-anon-net',
	firstRoom=> 'REPLACE-room',
	ipTrNet	=> 'REPLACE-TRIP',
	nmTrNet	=> 'REPLACE-TRNM',
	gwTrNet => 'REPLACE-GW',
	domain	=> 'REPLACE-dom',
	type	=> 'REPLACE-type',
	registrationsCode => 'REPLACE-REGCODE',
	adminPW => 'REPLACE-PW',
	cephalixPW=>'REPLACE-CPW',
	sate	=> 'REPLACE-STATE'
};

my @VARS   = qw(
	REPLACE-ADMIN-CERT
	REPLACE-ADMIN-KEY
	REPLACE-CA-CERT
	REPLACE-CEPHALIX
	REPLACE-CPW
	REPLACE-CN
	REPLACE-GW
	REPLACE-NET
	REPLACE-NET-GW
	REPLACE-NM
	REPLACE-NM-STRING
	REPLACE-PW
	REPLACE-REGCODE
	REPLACE-SCHOOL-CERT
	REPLACE-SCHOOL-KEY
	REPLACE-SERVER-CERT
	REPLACE-SERVER-KEY
	REPLACE-SSHKEY
	REPLACE-TRIP
	REPLACE-TRNM
	REPLACE-VPN-CERT
	REPLACE-VPN-KEY
	REPLACE-WORKGROUP
	REPLACE-admin
	REPLACE-anon
	REPLACE-anon-net
	REPLACE-backup
	REPLACE-dom
	REPLACE-mail
	REPLACE-ntp
	REPLACE-print
	REPLACE-proxy
	REPLACE-room
	REPLACE-sn
	REPLACE-type
	REPLACE-zadmin
);

my $READONLY   = {
        "REPLACE-CEPHALIX" => 1,
        "REPLACE-zadmin"   => 1,
        "CEPHALIX_PATH"    => 1,
        "CEPHALIX_DOMAIN"  => 1
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
  local $/ unless wantarray;
  print F $out;
  close F;
}
#
#############################################

while(<STDIN>) {
   $hash .= $_;
}

my $reply = decode_json($hash);
my $TASK      =`uuidgen -t`; chomp $TASK;
system("mkdir -p /var/adm/oss/opentasks/");
write_file("/var/adm/oss/opentasks/$TASK",$hash);

my $default  = new Config::IniFiles( -file => $Defaults );
my $CEPHALIX_PATH   = $default->val('Defaults','CEPHALIX_PATH');
my $CEPHALIX_DOMAIN = $default->val('Defaults','CEPHALIX_DOMAIN');
my $SAVE_NEXT = ( $default->val('Defaults','SAVE_NEXT') eq "yes" ) ? 1 : 0;
my $path = $CEPHALIX_PATH.'/configs/'.$reply->{"uuid"}.".ini";
system("mkdir -p $CEPHALIX_PATH/configs/");
system("cp $Defaults $path");
open my $fh, "+<",$path;
my $m = new Config::IniFiles( -file => $fh );
foreach my $v ( @VARS )
{
        next if defined $READONLY->{$v};
        if (defined $m->val('Defaults',$v) )
        {
		if( defined $reply->{$VARMAP->{$v}} ) {
               $m->setval('Defaults',$v,$reply->{$VARMAP->{$v}});
		} else {
			print STDERR "There is no new value for $v\n";
		}
        }
        else
        {
		if( defined $reply->{$VARMAP->{$v}} ) {
               $m->newval('Defaults',$v,$reply->{$VARMAP->{$v}});
		} else {
			print STDERR "There is no value for $v\n";
		}
        }
}
foreach my $v ( keys(%$READONLY) )
{
        if (defined $m->val('Defaults',$v) )
        {
                $m->setval('Defaults',$v,$default->val('Defaults',$v));
        }
        else
        {
                $m->newval('Defaults',$v,$default->val('Defaults',$v));
        }
}
$m->RewriteConfig();
if( $SAVE_NEXT )
{
        my $block = new Net::Netmask($reply->{"network"}."/".$reply->{"netmask"});
        my $next  = $block->next();
        $default->setval('Defaults','network',$next);
        my ( $a,$b,$c,$d ) = split /\./, $next;
        $default->setval('Defaults','ipAdmin',"$a.$b.$c.".($d+2));
        $default->setval('Defaults','ipMail',"$a.$b.$c.".($d+3));
        $default->setval('Defaults','ipPrint',"$a.$b.$c.".($d+4));
        $default->setval('Defaults','ipProxy',"$a.$b.$c.".($d+5));
        $default->setval('Defaults','ipBackup',"$a.$b.$c.".($d+6));
        $default->setval('Defaults','anonDhcp',"$a.$b.".($c+1).".0 $a.$b.".($c+1).".31");
        $default->setval('Defaults','firstRoom',"$a.$b.".($c+2).".0");
}

#Create VPN Connection
my $vpnblock = new Net::Netmask($default->val('Defaults','VPN_IP')."/255.255.255.252");
my $VPN      = "ifconfig-push ".$vpnblock->nth(2).' '.$vpnblock->nth(1)."\n";
my $IP       = $vpnblock->nth(2);
if( $reply->{'fullrouting'} )
{
        $VPN .= 'iroute '.$reply->{'network'}.' '.$reply->{'netmask'}."\n";
}
write_file('/etc/openvpn/ccd/'.$reply->{'uuid'},$VPN);

my $next     = $vpnblock->next();
$default->setval('Defaults','VPN_IP',$next);
foreach my $v ( @TO_CLEAN )
{
        $default->setval('Defaults',$v,'');
}
$default->RewriteConfig();
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
        #Debug the commands
        print("$command -D '".$reply->{'domain'}."' -N 'schooladmin'\n");
        print("$command -D '".$reply->{'domain'}."' -N 'admin'\n");
        print("$command -D '".$reply->{'domain'}."' -N 'schoolserver'\n");
        print("$command -D '$CEPHALIX_DOMAIN' -N '".$reply->{'uuid'}."' -s\n");
}

#Create autoyast config

my $SCHOOL_DOMAIN   = $m->val('Defaults','REPLACE-dom');
my $SCHOOL_sn       = $m->val('Defaults','REPLACE-sn');
my $SCHOOL_NET      = $m->val('Defaults','REPLACE-NET');
my $SCHOOL_NM       = $m->val('Defaults','REPLACE-NM');
my $block           = new Net::Netmask("$SCHOOL_NET/$SCHOOL_NM");
my $BITS            = $block->bits();

if( -e "/usr/share/cephalix/templates/autoyast-template-".$SCHOOL_sn.".xml"  )  {
	$XMLFile = "/usr/share/cephalix/templates/autoyast-template-".$SCHOOL_sn.".xml";
} elsif( -e "/usr/share/cephalix/templates/autoyast-template-".$reply->{'type'}.".xml"  )  {
	$XMLFile = "/usr/share/cephalix/templates/autoyast-template-".$reply->{'type'}.".xml";
}
my $XML   = `cat $XMLFile`;
foreach my $par ( $m->Parameters('Defaults') )
{
        next if contains($par,\@SSL);
        my $val=$m->val('Defaults',$par);
        $XML =~ s/$par/$val/g;
}
$XML =~ s/REPLACE-BIT/$BITS/g;

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
system("mkdir -p /srv/www/admin/configs/");
write_file("/srv/www/admin/configs/$SCHOOL_sn.xml",$XML);

my $tmpDir   = `mktemp /tmp/mkisoXXXXX`; chomp $tmpDir;
my $createCD = "cp /srv/www/admin/configs/$SCHOOL_sn.xml /usr/share/cephalix/templates/iso/oss.xml;\n".
	       "mkisofs --publisher 'Dipl.Ing. Peter Varkoly' -p 'CD-Team, http://www.cephalix.eu' ".
	       "-r -J -f -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/x86_64/loader/isolinux.bin ".
               "-c boot/boot.catalog -hide boot/boot.catalog -hide-joliet boot/boot.catalog -A - -V SU.001 -o /srv/www/admin/isos/$SCHOOL_sn.iso $tmpDir /usr/share/cephalix/templates/iso/";

system($createCD);
