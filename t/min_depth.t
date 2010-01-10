use warnings;
use strict;

use lib 'lib';

use Test::More 'no_plan';

use Data::Leaf::Walker;

my @orig =
   (
   111,
   112,
   [ 113, 114 ],
   [ [ 115, { aaa => 116 } ] ],
   {
   aab => 117,
   aac => 118,
   aad => { aae => { aaf => [[ 119 ]] }, aag => 120 },
   aah => [ 121, 122 ],
   aai => [[]],
   aaj => [ 123, 124, { aak => 125 }, { aal => 126 } ],
   aam => { aan => {} },
   aao => 127,
   },
   128,
   );

my @exp_keys =
   (
   [ qw/ 3 0 0 / ],
   [ qw/ 3 0 1 aaa / ],
   [ qw/ 4 aad aae aaf 0 0 / ],
   [ qw/ 4 aad aag / ],
   [ qw/ 4 aah 0 / ],
   [ qw/ 4 aah 1 / ],
   [ qw/ 4 aaj 0 / ],
   [ qw/ 4 aaj 1 / ],
   [ qw/ 4 aaj 2 aak / ],
   [ qw/ 4 aaj 3 aal / ],
   );

my @exp_values =
   (
   115,
   116,
   119,
   120,
   121,
   122,
   123,
   124,
   125,
   126,
   );
   
my $walker = Data::Leaf::Walker->new( \@orig, min_depth => 3 );

EACH:
   {

   my @keys;
   my @values;

   while ( my ( $k, $v ) = $walker->each )
      {
      push @keys, $k;
      push @values, $v;
      }
      
   @keys = map  { $_->[0] }
           sort { $a->[1] cmp $b->[1] }
           map  { [ $_, join(':', @{$_}) ] } @keys;
             
   is_deeply( \@keys, \@exp_keys, "each - keys" );

   @values = sort @values;

   is_deeply( \@values, \@exp_values, "each - values" );
   
   }

KEYS:
   {

   my @keys = map  { $_->[0] }
              sort { $a->[1] cmp $b->[1] }
              map  { [ $_, join(':', @{$_}) ] } $walker->keys;
             
   is_deeply( \@keys, \@exp_keys, "keys" );

   }

VALUES:
   {

   my @values = sort $walker->values;
   is_deeply( \@values, \@exp_values, "values" );

   }