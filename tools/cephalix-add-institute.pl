#!/usr/bin/perl
# Copyright 2018 Peter Varkoly <peter@varkoly.de>  Germany, Nuremberg

use strict;
use Data::Dumper;
use JSON;
use Config::IniFiles;
use Net::Netmask;

my $Defaults = "/usr/share/oss/templates/CEPHALIX/CreateOSSXML_Defaults.ini";
my $XML      = "/usr/share/oss/templates/CEPHALIX/autoyast-template.xml";

my @TO_CLEAN   = qw(
        uuid
        name
        type
        domain
        adminPW
        );

my @VARS   = qw(
        uuid
        name
        locality
        state
        type
        domain
        adminPW
        REPLACE-REGCODE
        ipTrNet
        nmTrNet
        gwTrNet
        network
        netmask
        ipAdmin
        ipMail
        ipPrint
        ipProxy
        ipBackup
        ntpServer
        nmServerNet
        anonDhcp
        firstRoom
        REPLACE-CEPHALIX
        REPLACE-zadmin
        CEPHALIX_PATH
        CEPHALIX_DOMAIN
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

write_file("/var/adm/oss/opentasks/$TASK",$reply);

my $default  = new Config::IniFiles( -file => $Defaults );
my $CEPHALIX_PATH   = $default->val('Defaults','CEPHALIX_PATH');
my $CEPHALIX_DOMAIN = $default->val('Defaults','CEPHALIX_DOMAIN');
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
                $m->setval('Defaults',$v,$reply->{$v});
        }
        else
        {
                $m->newval('Defaults',$v,$reply->{$v});
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
if( $reply->{"savenextnet"} )
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
        my $command = "$CEPHALIX_PATH/create_server_certificates.sh -P $CEPHALIX_PATH -N";
        system("$command 'schooladmin'  -D '".$reply->{'domain'}."'  -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."'");
        system("$command 'admin'        -D '".$reply->{'domain'}."'  -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."'");
        system("$command 'schoolserver' -D '".$reply->{'domain'}."'  -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."'");
        system("$command '".$reply->{'uuid'}."' -D '$CEPHALIX_DOMAIN' -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."' -s");
        #Debug the commands
        print("$command 'schooladmin'  -D '".$reply->{'domain'}."'  -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."'\n");
        print("$command 'admin'        -D '".$reply->{'domain'}."'  -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."'\n");
        print("$command 'schoolserver' -D '".$reply->{'domain'}."'  -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."'\n");
        print("$command '".$reply->{'uuid'}."' -D '$CEPHALIX_DOMAIN' -S '".$reply->{'state'}."' -L '".$reply->{'locality'}."' -O '".$reply->{'name'}."' -s\n");
}

#Create autoyast config

my $CEPHALIX_PATH   = $m->val('Defaults','CEPHALIX_PATH');
my $CEPHALIX_DOMAIN = $m->val('Defaults','CEPHALIX_DOMAIN');
my $CEPHALIX_DN     = $cephalix->{LDAP_BASE};
my $SCHOOL_DOMAIN   = $m->val('Defaults','domain');
my $SCHOOL_sn       = $m->val('Defaults','uuid');
my $SCHOOL_NET      = $m->val('Defaults','network');
my $SCHOOL_NM       = $m->val('Defaults','netmask');
my $block           = new Net::Netmask("$SCHOOL_NET/$SCHOOL_NM");
my $BITS            = $block->bits();



my $XML   = `cat /usr/share/oss/templates/CEPHALIX/autoyast-template.xml`;
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
$SSLVARS{'REPLACE-SERVER-KEY'} = `cat $CEPHALIX_PATH/CA_MGM/certs/schooladmin.$SCHOOL_DOMAIN.key.pem`;
$SSLVARS{'REPLACE-SERVER-CERT'}= `cat $CEPHALIX_PATH/CA_MGM/certs/schooladmin.$SCHOOL_DOMAIN.cert.pem`;
$SSLVARS{'REPLACE-SCHOOL-KEY'} = `cat $CEPHALIX_PATH/CA_MGM/certs/schoolserver.$SCHOOL_DOMAIN.key.pem`;
$SSLVARS{'REPLACE-SCHOOL-CERT'}= `cat $CEPHALIX_PATH/CA_MGM/certs/schoolserver.$SCHOOL_DOMAIN.cert.pem`;

my $CEPHALIX_SDN = "dc=$SCHOOL_sn,".$CEPHALIX_DN;
$XML =~ s/localityMD_CEPHALIX_SDN/$CEPHALIX_SDN/;

foreach my $sslpar ( @SSL )
{
        $XML =~ s/$sslpar/$SSLVARS{$sslpar}/g;
}
write_file("$CEPHALIX_PATH/configs/$SCHOOL_sn.xml",$XML);


