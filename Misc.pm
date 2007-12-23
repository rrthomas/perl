# RRT::Misc (c) 2003-2007 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

# This module contains various misc code that I reuse, but don't
# consider worth packaging for others (i.e. it reflects my taste,
# laziness and ignorance more than general utility!)

# FIXME: Need slurp[Text] and spew[Text] to avoid needing to remember
# incantations.

require 5.8.4;
package RRT::Misc;

use strict;
use warnings;

use Perl6::Slurp;
use POSIX 'floor';
use File::Basename;
use IPC::Open2;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 0.03;
  @ISA = qw(Exporter);
  @EXPORT = qw(&untaint &mtime &touch &which
               &cleanPath &normalizePath
               &pipe2 &getMimeType &numberToSI);
}
our @EXPORT_OK;


# Untaint the given value
# FIXME: Use CGI::Untaint
sub untaint {
  my ($var) = @_;
  return if !defined($var);
  $var =~ /^(.*)$/ms;           # get untainted value in $1
  return $1;
}

# Return last modified time of the given object
sub mtime {
  my ($object) = @_;
  return 0 if !-e $object;
  return (stat $object)[9];
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

# Pipe data through a command
sub pipe2 {
  my ($cmd, $input, $in_enc, $out_enc, @args) = @_;
  my $pid = open2(*READER, *WRITER, $cmd, @args);
  binmode(*READER, $in_enc);
  binmode(*WRITER, $out_enc);
  print WRITER $input;
  close WRITER;
  my $output = slurp '<:raw', \*READER;
  waitpid $pid, 0;
  return $output;
}

# Return the MIME type of the given file
sub getMimeType {
  my ($file) = @_;
  open(READER, "-|", "mimetype", $file);
  my $mimetype = slurp \*READER;
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
