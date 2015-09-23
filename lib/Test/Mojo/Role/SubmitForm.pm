package Test::Mojo::Role::SubmitForm;

use Mojo::Base -base;
use Role::Tiny;
use Carp qw/croak/;

# VERSION

sub click_ok {
    my ( $self, $selector, $extra_params ) = @_;
    $extra_params ||= {};

    my $el = $self->tx->res->dom->at($selector)
        or croak "Did not find element matching selector $selector";
    unless ( $el->tag eq 'form' ) {
        if ( $el->{type} eq 'image' ) {
            $extra_params->{ $el->{name} . '.x' } = 1;
            $extra_params->{ $el->{name} . '.y' } = 1;
        }
        else {
            $extra_params->{ $el->{name} } = $el->val;
        }

        $el = $el->ancestors('form')->first;
    }

    for ( sort keys %$extra_params ) {
        next unless ref $extra_params->{$_} eq 'CODE';
        ( my $name = $_ ) =~ s/"/\\"/g;
        $extra_params->{$_} = $extra_params->{$_}->(
            $el->at(qq{[name="$name"]})->val
        );
    }

    my %form = (
        $self->_get_controls($el),
        %$extra_params,
    );

    if ( $ENV{MOJO_SUBMITFORM_DEBUG} ) {
        warn "\n########## SUBMITTING FORM ##########\n";
        require Mojo::Util;
        warn Mojo::Util::dumper(\%form);
        warn "##########    END FORM     ##########\n\n";
    }

    my $tx = $self->ua->build_tx(
        $el->{method}||'GET' => $el->{action}
            => form => \%form,
    );

    $self->request_ok( $tx );
}

sub _get_controls {
    my ( $self, $form ) = @_;

    my @els = $form->find(
        'input:not([type=button]):not([type=submit]):not([type=image])'
        . ':not([type=checkbox]):not([type=radio]),'
        . '[type=checkbox]:checked, [type=radio]:checked,'
        . 'select, textarea'
    )->each;

    my %controls;
    for ( @els ) {
        defined( my $val = $_->val ) or next;
        push @{ $controls{$_->{name}} }, ref $val ? @$val : $val;
    }
    $#$_ or $_= $_->[0] for values %controls; # chage 1-el arrayrefs to strings

    return %controls;
}

q|
The fantastic element that explains the appeal of games to
many developers is neither the fire-breathing monsters nor the
milky-skinned, semi-clad sirens; it is the experience of
carrying out a task from start to finish without any change
in the user requirements.
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix app  Subrefs subrefs ENV VARS

=head1 NAME

Test::Mojo::Role::SubmitForm - Test::Mojo role that allows to submit forms

=head1 SYNOPSIS

=for pod_spiffy start code section

    use Test::More;
    use Test::Mojo::WithRoles 'SubmitForm';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    # Submit a form without clicking any buttons: pass selector to the form
    $t->get_ok('/')->status_is(200)->click_ok('form#one')->status_is(200);

    # Click a particular button
    $t->get_ok('/')->status_is(200)->click_ok('[type=submit]')->status_is(200);

    # Submit a form while overriding form data
    $t->get_ok('/')->status_is(200)
        ->click_ok('form#one', {
            input1        => '42',
            select1       => [ 1..3 ],
            other_select  => sub { my $r = shift; [ @$r, 42 ] },
            another_input => sub { shift . 'offix'}
        })->status_is(200);

    done_testing;

=for pod_spiffy end code section

=head1 DESCRIPTION

A L<Test::Mojo> role that allows you submit forms, optionally overriding
any of the values already present

=head1 METHODS

You have all the methods provided by L<Test::Mojo>, plus these:

=head2 C<click_ok>

    $t->click_ok('form');
    $t->click_ok('#button');

    $t->click_ok('#button', {
        input1        => '42',
        select1       => [ 1..3 ],
        other_select  => sub { my $r = shift; [ @$r, 42 ] },
        another_input => sub { shift . 'offix'}
    })

First parameter specifies a CSS selector matching a C<< <form> >> you want to
submit or a particular C<< <button> >>, C<< <input type="submit"> >>,
or C<< <input type="image"> >> you want to click.

Specifying a second parameter allows you to override the form control values:
the keys are C<name="">s of controls to override and values can be either
plain scalars (use arrayrefs for multiple values) or subrefs. Subrefs
will be evaluated and their first C<@_> element will be the current value
of the form control.

=head1 DEBUGGING / ENV VARS

To see what form data is being submitted, set C<MOJO_SUBMITFORM_DEBUG>
environmental variable to a true value:

    MOJO_SUBMITFORM_DEBUG=1 prove -vlr t/02-app.t

Sample output:

    ok 36 - GET /
    ok 37 - 200 OK

    ########## SUBMITTING FORM ##########
    {
      "\$\"bar" => 5,
      "a" => 42,
      "b" => "B",
      "e" => "Eoffix",
      "f" => [
        1,
        2,
        3
      ],
      "l" => [
        "L",
        42
      ],
      "m" => "M",
      "mult_a" => [
        "A",
        "B"
      ],
      "mult_b" => [
        "C",
        "D",
        "E"
      ],
      "mult_f" => [
        "I",
        "J",
        "N"
      ],
      "mult_m" => [
        "FOO",
        "BAR"
      ],
      "\x{a9}\x{263a}\x{2665}" => 55
    }
    ##########    END FORM     ##########

    [Wed Sep 23 17:34:00 2015] [debug] POST "/test"

=head BUGS AND CAVEATS

Note that you cannot override the value of buttons you're clicking on.
In those cases, simply "click" the form itself, while passing the new values
for buttons.

=head1 SEE ALSO

L<Test::Mojo>, L<Mojo::DOM>

=for pod_spiffy hr

=head1 REPOSITORY

=for pod_spiffy start github section

Fork this module on GitHub:
L<https://github.com/zoffixznet/Test-Mojo-Role-SubmitForm>

=for pod_spiffy end github section

=head1 BUGS

=for pod_spiffy start bugs section

To report bugs or request features, please use
L<https://github.com/zoffixznet/Test-Mojo-Role-SubmitForm/issues>

If you can't access GitHub, you can email your request
to C<bug-test-mojo-role-SubmitForm at rt.cpan.org>

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