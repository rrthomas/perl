# Simple pickle/unpickle functions
# (Don't use these; Use Storable instead)
# Reuben Thomas   2/03

use Data::Dumper;
use File::Slurp qw(read_file write_file);

sub pickle {
  my ($file, $val) = @_;
  local $Data::Dumper::Terse = 1; # pickle as expression, not assignment
  write_file($file, Dumper($val));
}

sub unpickle {
  my ($file) = @_;
  return eval untaint(read_file($file));
}
