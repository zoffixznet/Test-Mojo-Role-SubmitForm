package Test::Mojo::Role::ElementCounter;

use Mojo::Base -base;
use Encode;
use Carp qw/croak/;
use Role::Tiny;

# VERSION

has _counter_selector_prefix => '';

sub dive_in {
    my ( $self, $selector ) = @_;
    $self->_counter_selector_prefix(
        $self->_counter_selector_prefix . $selector
    );
}

sub dive_out {
    my ( $self, $remove ) = @_;

    $remove = qr/\Q$remove\E$/ unless ref $remove eq 'Regexp';
    $self->_counter_selector_prefix(
        $self->_counter_selector_prefix =~ s/$remove//r,
    );
}

sub dive_up {
    shift->dive_out(qr/\S+\s*$/);
}

sub dive_reset {
    shift->_counter_selector_prefix('');
}

sub dived_text_is {
    my $self = shift;
    my @in = @_; # can't modify in-place
    $in[0] = $self->_counter_selector_prefix . $in[0];
    $self->text_is( @in );
}

sub element_count_is {
    my ($self, $selector, $wanted_count, $desc) = @_;

    croak 'You gave me an undefined element count that you want'
        unless defined $wanted_count;

    my $pref = $self->_counter_selector_prefix;
    $selector = join ',', map "$pref$_", split /,/,$selector;

    $desc ||= encode 'UTF-8', qq{element count for selector "$selector"};
    my $operator = $wanted_count =~ tr/<//d ? '<'
        : $wanted_count =~ tr/>//d ? '>' : '==';

    my $count = $self->tx->res->dom->find($selector)->size;
    return $self->_test('cmp_ok', $count, $operator, $wanted_count, $desc);
}


q|
<Zoffix> GumbyBRAIN, Q: What did the computer do at lunchtime?
    A: Had a byte!
<GumbyBRAIN> So even that's only one byte undefined in the
    thing I ever had. Where is beer the reason siv didn't walk straight.
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix app  natively

=head1 NAME

Test::Mojo::Role::ElementCounter - Test::Mojo role that provides element count tests

=head1 SYNOPSIS

Say, we need to test our app produces exactly this markup structure:

=for pod_spiffy start code section

    <ul id="products">
        <li><a href="/product/1">Product 1</a></li>
        <li>
            <a href="/products/Cat1">Cat 1</a>
            <ul>
                <li><a href="/product/2">Product 2</a></li>
                <li><a href="/product/3">Product 3</a></li>
            </ul>
        </li>
        <li><a href="/product/2">Product 2</a></li>
    </ul>

    <p>Select a product!</p>

=for pod_spiffy end code section

The test we write:

=for pod_spiffy start code section

    use Test::More;
    use Test::Mojo::WithRoles 'ElementCounter';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t->get_ok('/products')
    ->dive_in('#products ')
        ->element_count_is('> li', 3)
        ->dive_in('li:first-child ')
            ->element_count_is('a', 1)
            ->dived_text_is('a[href="/product/1"]' => 'Product 1')
        ->element_count_is('+ li > a', 1)
            ->dived_text_is('+ li > a[href="/products/Cat1"]' => 'Cat 1')
        ->dive_in('+ li > ul ')
            ->element_count_is('> li', 2)
            ->element_count_is('a', 2)
            ->dived_text_is('a[href="/product/2"]' => 'Product 2')
            ->dived_text_is('a[href="/product/3"]' => 'Product 3')
        ->dive_out('> ul')
        ->element_count_is('+ li a', 1);
    ->dive_reset
    ->element_count_is('#products + p', 1)
    ->text_is('#products + p' => 'Select a product!')

    done_testing;

=for pod_spiffy end code section

=head1 SEE ALSO

Note that as of L<Mojolicious> version 6.06,
L<Test::Mojo> implements the exact match
version of C<element_count_is> natively (same method name).
This role is helpful only if you need dive methods or ranges.

=head1 DESCRIPTION

A L<Test::Mojo> role that allows you to do strict element count tests on
large structures.

=head1 METHODS

You have all the methods provided by L<Test::Mojo>, plus these:

=head2 C<element_count_is>


  $t = $t->element_count_is('.product', 6, 'we have 6 elements');
  $t = $t->element_count_is('.product', '<6', 'fewer than 6 elements');
  $t = $t->element_count_is('.product', '>6', 'more than 6 elements');

Check the count of elements specified by the selector. Second argument
is the number of elements you expect to find. The number can be
prefixed by either C<< < >> or C<< > >> to specify that you expect to
find fewer than or more than the specified number of elements.

You can shorten the selector by using C<dive_in> to store a prefix.

=head2 C<dive_in>

    $t = $t->dive_in('#products > li ');

    $t->dive_in('#products > li ')
        ->dive_in('ul > li ')
        ->element_count_is('a', 6);
        # tests: #products > li > ul > li a

To simplify selectors when testing complex structures, you can tell
the module to remember the prefix portion of the selector with
C<dive_in>. Note that multiple calls are cumulative. Use
C<dive_out>, C<dive_up>, or C<dive_reset> to go up in dive level.

B<Note:> be mindful of the last space in the selector when diving.
C<< ->dive_in('ul')->dive_in('li') >> would result in C<ulli> selector,
not C<ul li>.

B<Note:> the selector prefix only applies to C<element_count_is> and
C<dived_text_is> methods. It does not affect operation of other
methods provided by L<Test::Mojo>

=head2 C<dive_out>

    $t = $t->dive_out('li');
    $t = $t->dive_out(qr/\S+\s+(li|a)\s+$/);

    $t->dive_in('#products li ')
        ->dive_out('li'); # we're now testing: #products

Removes a portion of currently stored selector prefix (see C<dive_in>).
Takes a string or a regex as the argument that specifies
what should be removed. If a string is given, it will be taken as a literal
match to remove from I<the end> of the stored selector prefix.

=head2 C<dive_up>

    # these two are equivalent
    $t = $t->dive_up;
    $t = $t->dive_out(qr/\S+\s*$/);

Takes no arguments. A shortcut for C<< ->dive_out(qr/\S+\s*$/) >>.

=head2 C<dive_reset>

    $t = $t->dive_reset;

Resets stored selector prefix to an empty string (see C<dive_in>).

=head2 C<dived_text_is>

    $t = $t->dive('#products li:first-child ')
        ->dived_text_is('a' => 'Product 1');

Same as L<Test::Mojo>'s C<text_is> method, except the selector will
be prefixed by the stored selector prefix (see C<dive_in>)

=for pod_spiffy hr

=head1 REPOSITORY

=for pod_spiffy start github section

Fork this module on GitHub:
L<https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter>

=for pod_spiffy end github section

=head1 BUGS

=for pod_spiffy start bugs section

To report bugs or request features, please use
L<https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter/issues>

If you can't access GitHub, you can email your request
to C<bug-test-mojo-role-elementcounter at rt.cpan.org>

=for pod_spiffy end bugs section

=head1 AUTHOR

=for pod_spiffy start author section

=for pod_spiffy author ZOFFIX

=for pod_spiffy end author section

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut