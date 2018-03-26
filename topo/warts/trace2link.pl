#!/usr/bin/perl
#
# trace2link -- extract IP-level links from a batch of traceroute data files
# =============================================================================
# USAGE: see Usage below (./trace2link.pl -h) 
# INPUT: a batch of traceroute data file names from STDIN or @ARGV
#        the file format is .warts.gz or warts2text
# OUTPUT: CSV text
#         1.in 2.out 3.is_dest 4.star 5.delay 6.freq 7.ttl 8.monitor
#         1. the IP address of the ingress interface, e.g., 1.2.3.4
#         2. the IP address of the outgress interface, e.g., 5.6.7.8
#         3. whether the outgress node is the destination, e.g., Y or N
#         4. the number of anonymous (*) hops inbetween, e.g., 0 for directed link
#         5. the minimal delay in ms > 0, e.g., 10
#         6. the cumulative frequence of link observed, e.g., 5000
#         7. the minimal TTL of the ingress interface, e.g., 7
#         8. the monoitor which observed the link at the minimal TTL, e.g., 9.0.1.2 
#
# AUTHORS:
# - yuzhang at hit.edu.cn 2017.8.28
#
# CHANGE LOG:
# - 2017.8.28 - Alpha
#
# Examples of input
#
#
# Examples of output
#

use strict;
use warnings;
use Data::Dumper;

my $HELP = '
  Usage: trace2link.pl [OPTIONS] [files]

  When [files] is empty, read file names from STDIN
  OPTIONS:
  -    read txt-format warts2text data from STDIN
  -h   print this help message
  -p   the prefix of output file names
  -z   output with gzip
';

sub getoption();      # get options and open output files
sub openfile($$);     # open [un]compressed file (and pipe to warts2text if set 1)
sub filetype($);      # guess type: TXT (warts2text) or BIN (warts)
sub process($);       # process traceroute data file 
sub addlink($);       # add links to LINK hashtable 

my $WARTSCMD = "sc_warts2text";  # warts2text command
my %LINKS;            # link hashtable

# MAIN =========================================================================
# GET OPTIONS AND OPEN OUTPUT FILES
my $output_cmd = &getoption();
my $fh;
open($fh, $output_cmd) || die "Can not open links file: $!";

# PROCESSING FILES
unless (@ARGV) { while (<STDIN>) { chomp; &process($_); } }
foreach (@ARGV) { &process($_); }

# OUTPUT AND CLOSE FILES
print $fh join("\n", map{join(" ", $_, @{$LINKS{$_}})} sort keys %LINKS) . "\n";
close($fh);
exit 0;

# SUBROUTINES ==================================================================

sub getoption() {
  my %options;
  use Getopt::Std;
  Getopt::Std::getopts("hp:z", \%options);
  defined $options{h} && die $HELP;
  my $out_cmd = ((defined $options{z}) ? "| gzip -c " : " ") . "> ";
  my $out_sfx = (defined $options{z}) ? ".gz" : "" ;
  $options{p} ||= "trace";
  return "$out_cmd $options{p}.links$out_sfx";
}

sub process($) {           # process a traceroute data file
  my $filename = shift;
  my $fh =  ($filename eq '-')? \*STDIN : &openfile($filename, &filetype($filename));
  
  my ($dest, $start, @last, %node, @link, $is_loop);
  @last = (); %node = (); @link = (); $is_loop = 0;
# 1.in 2.out 3.is_dest 4.star 5.delay 6.freq 7.ttl 8.monitor
  my ($in, $out, $is_dest, $star, $delay, $ttl, $monitor);

# Traceroute  from        ...  to   ...
# hop#        IP_address  RTT  ms
# $f[0]       [1]         [2]  [3]  [4]

  while(<$fh>) { 
    #print "in: $_";
    chmod;
    $_ =~ s/^\s+//;
    my @f = split /\s+/, $_;
    if ($f[1] eq "*") {
      $star++;
      next;
    } 
    if ($f[0] =~ /^t/) {
      &addlink(\@link) unless ($is_loop);
      ($monitor, $dest, $start) = @f[2,4,5];
      %node = (); @link = (); $is_loop=0;
    } elsif (defined $last[1] and $last[1] ne "from" and $f[1] ne $last[1]) {
      $is_loop=1 if (exists $node{$f[1]});
      $node{$f[1]}=1;
      $in = $last[1]; $out = $f[1];
      $is_dest = $out eq $dest ? 'Y' : 'N';
      $delay = ($f[2] - $last[2]) / 2; $delay = $delay > 0? $delay : 0;
      $delay = sprintf("%.3f",$delay);
      $ttl = $last[0];
      push @link, ($in, $out, $is_dest, $star, $delay, 1, $ttl, $monitor, $start, $start); #debug
      #push @link, ($in, $out, $is_dest, $star, $delay, 1, $ttl, $monitor); #debug
    }
    $star = 0;
    @last = @f;
  }
  &addlink(\@link) unless ($is_loop);
  close $fh;
}

sub addlink($) { # add link into LINK hashtable
  my $link = shift;
  while ($#$link > 0) {
    my ($in, $out, @l) = splice(@$link, -10);
    if (exists $LINKS{"$in $out"}) {
      my $a = $LINKS{"$in $out"}; 
      # 0.is_dest 1.star 2.delay 3.freq 4.ttl 5.monitor 6.firstseen 7.lastseen
      $a->[0] = "N" if $l[0] eq "N";
      $a->[1] = $l[1] if $a->[1] > $l[1]; 
      $a->[2] = $l[2] if $a->[2] > $l[2]; 
      $a->[3]++; 
      ($a->[4], $a->[5]) = @l[4,5] if ($a->[4] > $l[4] or ($a->[4] == $l[4] and $l[5] lt $a->[5])); 
      $a->[6] = $l[6] if $a->[6] > $l[6];
      $a->[7] = $l[7] if $a->[7] < $l[7];
    } else {
      $LINKS{"$in $out"} = [@l];
    } 
  }
}

sub openfile($$) {         # just open, remember to close later 
  my ($filename, $filetype) = @_;
  my $openstr = $filetype eq "BIN" ? "$filename | $WARTSCMD" : $filename;
  my $fh;
  if ($filename =~ /\.g?z$/) {         # .gz or .z
    $openstr = "gzip -dc $openstr";
  } else {                         # expect it is uncompressed 
    $openstr = "cat $openstr";
  } 
  open($fh, '-|', $openstr) or die "Can not open file $openstr: $!";
  return $fh;
}

sub filetype($) {     # guess the file type according to the % of printable ...
  my $file = shift;   # or whitespace chars. If > 90%, it is TXT, otherwise BIN.
  my $fh = &openfile($file, "TXT");   # just open file without bgpdump
  my $string="";
  my $num_read = read($fh, $string, 1000);
  close $fh;
  return "TXT" unless ($num_read);       # if nothing, guess "TXT" 
  my $num_print = $string =~ s/[[:print:]]|\s//g;
  return ($num_print/$num_read > 0.9 ? "TXT" : "BIN");
}

# END MARK
