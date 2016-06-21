#!/usr/bin/perl
#
# mibbit_decloak.pl by duper [super (at) blackcatz (dot) org]
#
# Unpacks the hexadecimal IPv4 addresses in Mibbit client user names
# (Mibbit is a web-based IRC client that relies on browser-side JavaScript)
#
# Put this file in your ~/.irssi/scripts/autorun directory
#

use vars qw($VERSION %IRSSI); 
no strict;
no warnings;
use English;
use POSIX;
use Socket;
#use v5.14;
use Irssi;

$VERSION = q[1.0.0];

%IRSSI = (
  authors =>     'duper from GNY (Go NULL Yourself!)',
  contact =>     'super@blackcatz.org',
  name =>        'mibbit_uncloak',
  description => 'Uncloak & save IP addresses of Mibbit users joining the IRC channel',
  license =>     'GPLv2',
  url =>         'https://blackcatz.org/codez',
  changed =>     'Sun Jul 26 07:23:21 UTC 2015'
);

##TODO: show current uncloaks from %address and separate sub for showing data file

my(%servers, %address);
my $data_file = Irssi::settings_get_str('mibbit_uncloak_path');
my($succ_color, $fail_color, $othr_color, $none_color) = ("\00314", "\00315", "\00316", '');

sub irssi_echo {
  Irssi::active_win()->print(join('', @_));

  1;
}

sub mibbit_touch_data {
  open(MU_DATA, '>' . $data_file) or (warn($OS_ERROR) and return 0);

  my $comment = 'mibbit_uncloak.pl irssi script data file created on';

  $comment .= asctime(time);

  print(MU_DATA "# $comment\n");

  close(MU_DATA);

  &irssi_echo('*** ', $succ_color, $comment); 

  1;
}

sub mibbit_save {
  my $arec = join(' ', @_) . "\n";

  open(MU_DATA, '>>', $data_file) or warn($OS_ERROR) and return 0;

  print(MU_DATA $arec);

  close(MU_DATA);

  1;
}

sub show_mibbit {
  open(MU_DATA, '<' . $data_file) or warn($OS_ERROR);

  if(!-f MU_DATA) {
    &irssi_echo("*** $data_file not found, creating a new instance!");
    &mibbit_touch_data();
  }

  my(@mu_data) = <MU_DATA>;

  close(MU_DATA);

  foreach my$l (@mu_data) {
    &irssi_echo('*** ', $succ_color, $l); 
  }

  1;
}

sub event_join {
  my($server, $data, $nick, $host) = @_;

  if(Irssi::settings_get_bool('mibbit_uncloak_host') and $host !~ /mibbit[.]com/i) { return 0; }

  my(@usermask) = split /[@]/, $host;

  if($usermask[0] =~ /^[[:xdigit:]]+/i) {
    Irssi::print($usermask[0]);
    
    if(Irssi::settings_get_bool('mibbit_uncloak_enabled')) {
      $address{qq{$host}} = inet_ntoa(pack(q{H*},qq{$usermask[0]})) if(!defined($address{qq{$host}}));

      if(Irssi::settings_get_bool('mibbit_uncloak_save')) {
        my $afile = Irssi::settings_get_str('mibbit_uncloak_path');

        &mibbit_save($server, $channel, $nick, $account, $host, $address{qq{$host}});
      }

      &irssi_echo(q{*** }, $succ_color, "${nick}'s IP address is: $address{qq{$host}}");
    }
  }

  1;
}

sub uncloak_mibbit {
  my($data, $server, $witem) = @_;
  my $astr = q{Mibbit uncloaking is }; 
  
  $astr .= Irssi::settings_get_bool('mibbit_uncloak_enabled') ? q{enabled} : q{disabled};
  $astr .= q{!};

  &irssi_echo(q{*** }, $succ_color, $astr);
  
  1;
}

sub help_mibbit {
  &irssi_echo(q{*** }, $othr_color, 
    "This is mibbit_uncloak.pl irssi script version: ${VERSION}!");

  &irssi_echo(q{*** }, $none_color, 
    "================================================" . 
      ('=' x (1 + (length $VERSION))));

  &irssi_echo(q{*** }, $succ_color, 
    'To view script settings: /set mibbit_uncloak');

  &irssi_echo(q{*** }, $succ_color, 
    'To enable uncloaking of addresses: /set mibbit_uncloak_enabled');

  &irssi_echo(q{*** }, $succ_color, 
    'To check clients with or without mibbit.com hosts: /set mibbit_uncloak_host');

  &irssi_echo(q{*** }, $succ_color, 
    'To check the "real name" (gecos) field: /set mibbit_uncloak_gecos');

  &irssi_echo(q{*** }, $succ_color, 
    'To save uncloaked address info and client data: /set mibbit_uncloak_save');

  &irssi_echo(q{*** }, $succ_color, 
    'To change the pathname of data storage flat file: /set mibbit_uncloak_path');

  1;
}

Irssi::command_bind(mu_show, &show_mibbit);
Irssi::command_bind(mu_uncloak, &uncloak_mibbit);
Irssi::command_bind(mu_help, &help_mibbit);

Irssi::settings_add_bool('mibbit_uncloak', 'mibbit_uncloak_enabled', 1);
Irssi::settings_add_bool('mibbit_uncloak', 'mibbit_uncloak_host', 1);
Irssi::settings_add_bool('mibbit_uncloak', 'mibbit_uncloak_gecos', 0);
Irssi::settings_add_bool('mibbit_uncloak', 'mibbit_uncloak_save', 1);
Irssi::settings_add_str ('mibbit_uncloak', 'mibbit_uncloak_path', 'mibbit-ipaddrs.dat');

Irssi::signal_add( { 'event join' => \&event_join } );

Irssi::print( q{*** Loaded irssi script mibbit_uncloak.pl!} );
