package Data::Leaf::Walker;

use warnings;
use strict;

=head1 NAME

Data::Leaf::Walker - Walk the leaves of arbitrarily deep nested data structures.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

   $data   = {
      a    => 'hash',
      or   => [ 'array', 'ref' ],
      with => { arbitrary => 'nesting' },
      };

   $walker = Data::Leaf::Walker->new( $data );
   
   while ( my ( $k, $v ) = $walker->each )
      {
      print "@{ $k } : $v\n";
      }
      
   ## output might be
   ## a : hash
   ## or 0 : array
   ## or 1 : ref
   ## with arbitrary : nesting

=head1 DESCRIPTION

C<Data::Leaf::Walker> provides simplified access to nested data structures. It
operates on key paths in place of keys. A key path is a list of HASH and ARRAY
indexes which define a path through your data structure. For example, in the
following data structure, the value corresponding to key path C<[ 0, 'foo' ]> is
'bar': 

   $aoh = [ { foo => 'bar' } ];

You can get and set that value like so:

   $walker = Data::Leaf::Walker->new( $aoh );      ## create the walker
   $bar    = $walker->fetch( [ 0, 'foo' ] );       ## get the value 'bar'
   $walker->store( [ 0, 'foo'], 'baz' );           ## change value to 'baz'

=head1 FUNCTIONS

=head2 new( $data )

Construct a new C<Data::Leaf::Walker> instance.

   $data   = {
      a    => 'hash',
      or   => [ 'array', 'ref' ],
      with => { arbitrary => 'nesting' },
      };

   $walker = Data::Leaf::Walker->new( $data );

=cut

sub new
   {
   my $class = shift;
   return bless
      {
      _data       => shift(),
      _data_stack => [],
      _key_path   => [],
      }, $class;
   }

=head2 each()

Iterates over the leaf values of the nested HASH or ARRAY structures. Much like
the built-in C<each %hash> function, the iterators for individual structures are
global and the caller should be careful about what state they are in. Invoking
the C<keys()> or C<values()> methods will reset the iterators.

   while ( my ( $key_path, $value ) = $walker->each )
      {
      ## do something
      }

=cut

sub each
   {
   my ( $self ) = @_;
   
   if ( ! @{ $self->{_data_stack} } )
      {
      push @{ $self->{_data_stack} }, $self->{_data};
      }
      
   return $self->_iterate;
   }

=head2 keys()

Returns the list of all key paths.

   @key_paths = $walker->keys;

=cut

sub keys
   {
   my ( $self ) = @_;

   my @keys;

   while ( defined( my $key = $self->each ) )
      {
      push @keys, $key;
      }
   
   return @keys;
   }
   
=head2 values()

Returns the list of all leaf values.

   @leaf_values = $walker->values;

=cut

sub values
   {
   my ( $self ) = @_;

   my @values;

   while ( my ($key, $value) = $self->each )
      {
      push @values, $value;
      }

   return @values;
   }

=head2 fetch( $key_path )

Lookup the value corresponding to the given key path. If an individual key
attempts to fetch from an invalid the fetch method dies.

   $leaf = $walker->fetch( [ $key1, $index1, $index2, $key2 ] );

=cut

sub fetch
   {
   my ( $self, $key_path ) = @_;

   my $data = $self->{_data};
   
   for my $key ( @{ $key_path } )
      {

      my $type = ref $data;
      
      if ( $type eq 'ARRAY' )
         {
         $data = $data->[$key];
         }
      elsif ( $type eq 'HASH' )
         {
         $data = $data->{$key};
         }
      else
         {
         die "Error: cannot lookup key ($key) in invalid ref type ($type)";
         }
         
      }
      
   return $data;
   }

=head2 store( $key_path, $value )

Set the value for the corresponding key path.

   $walker->store( [ $key1, $index1, $index2, $key2 ], $value );

=cut

sub store
   {
   my ( $self, $key_path, $value ) = @_;
   
   my @store_path = @{ $key_path };
   
   my $twig_key = pop @store_path;
   
   my $twig = $self->fetch( \@store_path );
   
   if ( ! defined $twig )
      {
      die "Error: cannot autovivify arbitrarily";
      }
   
   my $type = ref $twig;
   
   if ( $type eq 'HASH' )
      {
      return $twig->{ $twig_key } = $value;
      }
   elsif  ( $type eq 'ARRAY' )
      {
      return $twig->[ $twig_key ] = $value;
      }
   
   }

=head2 delete( $key_path )

Delete the leaf key in the corresponding key path. Only works for a HASH leaf,
dies otherwise. Returns the deleted value.

   $walker->delete( [ $key1, $index1, $index2, $key2 ] );

=cut

sub delete
   {
   my ( $self, $key_path ) = @_;

   my @delete_path = @{ $key_path };
   
   my $twig_key = pop @delete_path;
   
   my $twig = $self->fetch( \@delete_path );
   
   defined $twig || return;
   
   my $type = ref $twig;
   
   if ( $type eq 'HASH' )
      {
      return delete $twig->{ $twig_key };
      }
   elsif  ( $type eq 'ARRAY' )
      {
      die "Error: cannot delete() from an ARRAY leaf";
      }
   
   }

=head2 exists( $key_path )

Returns true if the corresponding key path exists.

   $walker->exists( [ $key1, $index1, $index2, $key2 ] );

=cut

sub exists
   {
   my ( $self, $key_path ) = @_;

   my @exists_path = @{ $key_path };
   
   my $twig_key = pop @exists_path;
   
   my $twig = $self->fetch( \@exists_path );
   
   defined $twig || return;
   
   my $type = ref $twig;
   
   if ( $type eq 'HASH' )
      {
      return exists $twig->{ $twig_key };
      }
   elsif  ( $type eq 'ARRAY' )
      {
      return exists $twig->[ $twig_key ];
      }
   
   }

{
   
my %array_tracker;
   
sub _each
   {
   my ( $data ) = @_;
   
   if ( ref $data eq 'HASH' )
      {
      return CORE::each %{ $data };
      }
   elsif ( ref $data eq 'ARRAY' )
      {
      $array_tracker{ $data } ||= 0;
      if ( exists $data->[ $array_tracker{ $data } ] )
         {
         my $index = $array_tracker{ $data };
         ++ $array_tracker{ $data };
         return( $index, $data->[ $index ] );
         }
      else
         {
         $array_tracker{ $data } = 0;
         return;
         }
      
      }
   else
      {
      die "Error: cannot call _each() on non-HASH/non-ARRAY data record";
      }
   
   }
   
}

sub _iterate
   {
   my ( $self ) = @_;

   ## find the top of the stack   
   my $data = ${ $self->{_data_stack} }[-1];
   
   ## iterate on the stack top
   my ( $key, $val ) = _each($data);

   ## if we're at the end of the stack top
   if ( ! defined $key )
      {
      ## remove the stack top
      pop @{ $self->{_data_stack} };
      pop @{ $self->{_key_path} };

      ## iterate on the new stack top if available
      if ( @{ $self->{_data_stack} } )
         {
         return $self->_iterate;
         }
      ## mark the stack as empty
      ## return empty/undef
      else
         {
         return;
         }

      }
   
   ## _each() succeeded

   ## if the value is a HASH, add it to the stack and iterate
   if ( defined $val && ( ref $val eq 'HASH' || ref $val eq 'ARRAY' ) )
      {
      push @{ $self->{_data_stack} }, $val;
      push @{ $self->{_key_path} }, $key;
      return $self->_iterate;
      }
      
   my $key_path = [ @{ $self->{_key_path} }, $key ];

   return wantarray ? ( $key_path, $val ) : $key_path;   
   }

=head1 AUTHOR

Dan Boorstein, C<< <danboo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Data-Leaf-Walker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Leaf-Walker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 PLANS

=over 3

=item * add max_depth, min_depth, type and twig limiters for C<each>, C<keys>, C<values>

=item * optional autovivification (Data::Peek, Scalar::Util, String::Numeric)

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Leaf::Walker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Leaf-Walker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Leaf-Walker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Leaf-Walker>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Leaf-Walker/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Boorstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Leaf::Walker