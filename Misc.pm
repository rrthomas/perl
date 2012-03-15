# RRT::Misc (c) 2003-2011 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

# This module contains various misc code that I reuse, but don't
# consider worth packaging for others (i.e. it reflects my taste,
# laziness and ignorance more than general utility!)

# FIXME: Need slurpText and spewText to avoid needing to remember
# incantations.

require 5.8.4;
package RRT::Misc;

use strict;
use warnings;

use POSIX 'floor';
use File::Basename;
use Encode;

use Perl6::Slurp;


# FIXME: Use EXPORT_OK, explicit import in callees.
use base qw(Exporter);
our $VERSION = 0.06;
our @EXPORT = qw(untaint touch which cleanPath normalizePath
                 attrs_get attrs_set readDir
                 getMime getMimeType getMimeEncoding numberToSI);


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

# Find an executable on the PATH
sub which {
  my ($prog) = @_;
  my @progs = grep { -x $_ } map { "$_/$prog" } split(/:/, $ENV{PATH});
  return shift @progs;
}

# Check the given path is clean (no ".." components)
sub cleanPath {
  my ($path) = @_;
  $path = "" if !$path;
  return $path !~ m|^\.\./| && $path !~ m|/\.\.$| && $path !~ m|/\.\./|;
}

# Normalize a path possibly relative to another
# FIXME: Use built-in functions
sub normalizePath {
  my ($file, $currentDir) = @_;
  return "" if !cleanPath($file);
  my $path = "";
  $path = (fileparse($currentDir))[1] if $currentDir && $currentDir ne "";
  if ($file !~ m|^/|) {
    $file = "$path$file";
  } else {
    $file =~ s|^/||;
  }
  $file =~ s|^\./||;
  return $file;
}

# Get attributes of a file
# N.B. Treat return values as a list, don't rely on the actual values here
# i.e. call attrs_set($file1, attrs_get($file2)), that way the
# attributes saved can be extended without breaking the API.
# FIXME: Support extended attributes.
sub attrs_get {
  my ($file) = @_;
  my ($mode, $uid, $gid) = (stat($file))[2, 4, 5];
  $mode = $mode & 07777;
  return $mode, $uid, $gid;
}

# Set attributes of a file previously saved with attrs_save
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
  my @entries = grep {/^[^.]/ && &{$test}(decode_utf8($dir) . "/" . decode_utf8($_))} readdir(DIR);
  closedir DIR;
  return @entries;
}

# Return the MIME type, and possibly encoding, of the given file
sub getMime {
  my ($file) = @_;
  local *READER;
  # Until https://freedesktop.org/show_bug.cgi?id=47358 is fixed, keep this, to use --brief
  open(READER, "-|", "file", "--mime", "--brief", "--dereference", "--", $file);
  my $mimetype = slurp \*READER;
  chomp $mimetype;
  return $mimetype;
}

# Return the MIME type of the given file
sub getMimeType {
  my ($file) = @_;
  # Until https://freedesktop.org/show_bug.cgi?id=39923 is fixed, symlinks are not dereferenced, so use getMime instead of xdg-mime
  #local *READER;
  #open(READER, "-|", "xdg-mime", "query", "filetype", $file);
  #my $mimetype = slurp \*READER;
  my $mimetype = getMime($file);
  $mimetype =~ s/;.*$//; # Cope with result of getMime, or with xdg-mime using file -i (https://bugs.freedesktop.org/show_bug.cgi?id=39166)
  #chomp $mimetype;
  return $mimetype;
}

# Return the MIME encoding of the given file, or "binary" if none
sub getMimeEncoding {
  my ($file) = @_;
  my $mime = getMime($file);
  $mime =~ s/.*; charset=//;
  $mime = "binary" if $mime eq "";
  return $mime;
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
