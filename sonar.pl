#!/usr/bin/perl

# $Id: sonar.pl,v 1.1 2022/05/24 21:03:08 dan Exp $

# Perl script to survey level of icmp scan and emetting sound on
# different levels of scan

use strict ;
use warnings ;
use List::Util qw/min/ ;

$< == 0		||	die "$0: should be run as root" ;

my $host = `hostname` ;
chomp ($host)  ;

# printf ("%s\n", $host) ;

my $level = 0 ;

# interval of time between analysis and warning

my $delta_t = 10 ;
my $log10 = log (10) ;

# standard directory of system sounds

my $sound_dir = "/System/Library/Sounds/" ;

# array of sound increasing with the level of ping scans

my @sounds = ( "Ping.aiff", "Glass.aiff","Basso.aiff" ) ;

my $level_limit = @sounds ;

# printf ("%d\n", $level_limit ) ;

# n = number of ping received
# last_n = previous one
# alert = file of the sound to play

my $n = 0 ;
my $last_n = 0 ;
my $alert = "" ;

# compute rate, log level, make a sound and reschedule myself

sub bing {

	my $rate = abs ($n - $last_n) ;
#	printf ("rate=\t%d\n", $rate) ;

	if ( $rate ) {
#		logarithmic level of rate: 10, 100, 1000
		$level = min ( int (log ($rate) / $log10 ), $level_limit) ;
	}
#	printf ("level=\t%d\n", $level) ;

	if ( $level ) {
		$alert = $sound_dir . $sounds[$level] ;
#		printf ("%s\n", $alert) ;
		`afplay $alert`
	}
	$last_n = $n ;
	$SIG{ALRM} = \&bing ;
	alarm ($delta_t) ;
}

# schedule the next bing through signal

$SIG{ALRM} = \&bing ;
alarm ($delta_t) ;

# get the default interface toward the Internet

my $interface = `netstat -nr | grep default | awk '{printf ( "%s", \$NF ) ; exit}'` ; 

# printf ("%s\n", $interface ) ;

# command to collect the incoming icmp with tcpdump

my $command = "tcpdump -l -n -i " . $interface . " \'dst host " . $host . " and ( icmp[icmptype] != icmp-echoreply )\' 2>/dev/null" ;

$| = 1 ;
open (PIPE, "$command |")	||	die "couldn't start pipe: $! $?" ;

while (my $line = <PIPE>) {
	$n ++ ;
}

close (PIPE)	||	die "couldn't close pipe: $! $?" ;
