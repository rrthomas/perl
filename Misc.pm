# RRT::Misc (c) 2003-2018 Reuben Thomas
# Distributed under the GNU General Public License

# This module contains various misc code that I reuse, but don't
# consider worth packaging for others (i.e. it reflects my taste,
# laziness and ignorance more than general utility!)

require 5.8.4;
package RRT::Misc;

use strict;
use warnings;

use POSIX 'floor';
use File::Basename;
use File::stat;

use File::Slurp qw(slurp);


# FIXME: Use EXPORT_OK, explicit import in callees.
use base qw(Exporter);
our $VERSION = 0.11;
our @EXPORT = qw(untaint touch attrs_get attrs_set readDir
                 getMimeType numberToSI);


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

# Get attributes of a file
# N.B. Treat return values as a list, don't rely on the actual values here
# i.e. call attrs_set($file1, attrs_get($file2)), that way the
# attributes saved can be extended without breaking the API.
# FIXME: Support extended attributes.
sub attrs_get {
  my ($file) = @_;
  my $st = stat($file);
  return $st->mode & 07777, $st->uid, $st->gid;
}

# Set attributes of a file previously saved with attrs_get
#  file: file to set attributes of
#  ...: attributes list returned by attrs_get
sub attrs_set {
  my ($file, $mode, $uid, $gid) = @_;
  chmod $mode, $file;
  chown $uid, $gid, $file;
}

# Return the readable non-dot files & directories in a directory as a list
sub readDir {
  my ($dir, $test) = @_;
  $test ||= sub { return (-f shift || -d _) && -r _; };
  opendir(DIR, $dir) || return ();
  my @entries = grep {/^[^.]/ && &{$test}($dir . "/" . $_)} readdir(DIR);
  closedir DIR;
  return @entries;
}

# Return the MIME type of the given file
sub getMimeType {
  my ($file) = @_;
  local *READER;
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
