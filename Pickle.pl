# Simple pickle/unpickle functions
# (Don't use these; Use Storable instead)
# Reuben Thomas   2/03

use Data::Dumper;

sub pickle {
  my ($file, $val) = @_;
  local $Data::Dumper::Terse = 1; # pickle as expression, not assignment
  writeFile($file, Dumper($val));
}

sub unpickle {
  my ($file) = @_;
  return eval untaint(readFile($file));
}
