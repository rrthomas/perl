# RRT::Misc (c) 2003-2023 Reuben Thomas
# Distributed under the GNU General Public License

# This module contains various misc code that I reuse, but don't
# consider worth packaging for others (i.e. it reflects my taste,
# laziness and ignorance more than general utility!)

require 5.8.4;
package RRT::Misc;

use strict;
use warnings;

use POSIX 'floor';
use Encode;

use File::Slurp qw(slurp);


# FIXME: Use EXPORT_OK, explicit import in callees.
use base qw(Exporter);
our $VERSION = 0.12;
our @EXPORT = qw(untaint touch readDir getMimeType numberToSI);


# Untaint the given value
sub untaint {
  my ($var) = @_;
  return if !defined($var);
  $var =~ /^(.*)$/ms;           # get untainted value in $1
  return $1;
}

# Touch the given objects, which must exist
sub touch {
  my $now = time;
  utime $now, $now, @_;
}

# Return the readable non-dot files & directories in a directory as a list
sub readDir {
  my ($dir, $test) = @_;
  $test ||= sub { return (-f shift || -d _) && -r _; };
  opendir(DIR, $dir) || return ();
  my @entries = map { decode_utf8($_) } readdir(DIR);
  @entries = grep {/^[^.]/ && &{$test}($dir . "/" . $_)} @entries;
  closedir DIR;
  return @entries;
}

# Return the MIME type of the given file
# FIXME: Need to be in a UTF-8 locale for this to work!
sub getMimeType {
  my ($file) = @_;
  local *READER;
  $file = encode_utf8($file); # FIXME: assumes file system is UTF-8-encoded
  open(READER, "-|", "xdg-mime", "query", "filetype", $file);
  my $mimetype = slurp(\*READER);
  chomp $mimetype;
  return $mimetype;
}

# Convert a number to SI (3sf plus suffix)
# If outside SI suffix range, use "e" plus exponent
sub numberToSI {
  my ($n) = shift;
  my %SIprefix = (
    -8 => "y", -7 => "z", -6 => "a", -5 => "f", -4 => "p", -3 => "n", -2 => "mu", -1 => "m",
    1 => "k", 2 => "M", 3 => "G", 4 => "T", 5 => "P", 6 => "E", 7 => "Z", 8 => "Y"
  );
  my $t = sprintf "% #.2e", $n;
  $t =~ /.(.\...)e(.+)/;
  my ($man, $exp) = ($1, $2);
  my $siexp = floor($exp / 3);
  my $shift = $exp - $siexp * 3;
  my $s = $SIprefix{$siexp} || "e" . $siexp;
  $s = "" if $siexp == 0;
  $man = $man * (10 ** $shift);
  return $man . $s;
}


1;                              # return a true value
