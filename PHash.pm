# PHash (c) 2003 Reuben Thomas
# Distributed under the GNU General Public License

# Persistent arrays: stores hashes as text files using Data::Dumper

require 5.003;
package RRT::PHash;

use strict;
use warnings;

use Tie::Hash;
our @ISA = 'Tie::ExtraHash';
use Data::Dumper;
$Data::Dumper::Terse = 1;       # Store array as simple expression, not assignment
$Data::Dumper::Indent = 1;      # Be reasonably brief
use File::Slurp qw(read_file write_file);


sub TIEHASH {
  my ($class, $file) = @_;
  my $val = eval(untaint(read_file($file)) || "{}");
  return bless [$val, $file], $class;
}

sub DESTROY {
  my ($self) = @_;
  $self->UNTIE() if @$self[1];
}

sub UNTIE {
  my ($self) = @_;
  write_file(@$self[1], Dumper(@$self[0]));
  undef @$self[1];
}
