# RRT::Misc (c) 2003-2006 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
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
use IPC::Open2;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 0.03;
  @ISA = qw(Exporter);
  @EXPORT = qw(&untaint &mtime &touch &which
               &cleanPath &normalizePath
               &readFile &readText &writeFile
               &getMimeType &pipe2 &numberToSI);
}
our @EXPORT_OK;


# Untaint the given value
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

# Read the given file (or stdin if name is `-') and return its contents
# An undefined value is returned if the file can't be opened or read
sub readFile {
  my ($file, $enc) = @_;
  $enc ||= "";
  if ($file ne "-") {
    return if !cleanPath($file);
    open FILE, "<" . $enc, $file or return;
  } else {
    binmode STDIN, $enc or return;
    open FILE, "-" or return;
  }
  my $text = do {local $/, <FILE>};
  close FILE;
  return $text;
}

# Read a file as UTF-8
sub readText {
  my ($file) = @_;
  return readFile($file, ":utf8");
}

# No error is raised if the file can't be written
sub writeFile {
  my ($file, $cont, $enc) = @_;
  $enc ||= "";
  return if !cleanPath($file);
  open FILE, ">" . $enc, $file;
  print FILE $cont;
  close FILE;
}

# Write a file as UTF-8
sub writeText {
  my ($file, $cont) = @_;
  return writeFile($file, $cont, ":utf8");
}

# Return the MIME type of the given file
sub getMimeType {
  my ($file) = @_;
  open(READER, "-|", "mimetype", $file);
  my $mimetype = do {local $/, <READER>};
  chomp $mimetype;
  return $mimetype;
}

# Pipe data through a command
sub pipe2 {
  my ($cmd, $input, $in_enc, $out_enc, @args) = @_;
  my $pid = open2(*READER, *WRITER, $cmd, @args);
  binmode(*READER, $in_enc);
  binmode(*WRITER, $out_enc);
  print WRITER $input;
  close WRITER;
  my $output = do {local $/, <READER>};
  waitpid $pid, 0;
  return $output;
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
