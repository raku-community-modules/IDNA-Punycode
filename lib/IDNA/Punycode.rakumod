our $DEBUG = 0;

constant BASE         = 36;
constant TMIN         = 1;
constant TMAX         = 26;
constant SKEW         = 38;
constant DAMP         = 700;
constant INITIAL_BIAS = 72;
constant INITIAL_N    = 128;

my $Delimiter = chr 0x2D;

sub digit_value($code) {
    return ord($code) - ord("A")      if $code ~~ /<[A..Z]>/;
    return ord($code) - ord("a")      if $code ~~ /<[a..z]>/;
    return ord($code) - ord("0") + 26 if $code ~~ /<[0..9]>/;
}

sub code_point($digit) {
    return $digit + ord('a')      if  0 <= $digit <= 25;
    return $digit + ord('0') - 26 if 26 <= $digit <= 36;
    die 'NOT COME HERE';
}

sub adapt($delta is copy, $numpoints, $firsttime) {
    $delta  = $firsttime ?? $delta div DAMP !! $delta div 2;
    $delta += $delta div $numpoints;
    my $k   = 0;
    while ($delta > ((BASE - TMIN) * TMAX) div 2) {
        $delta div= BASE - TMIN;
        $k     += BASE;
    }
    $k + (((BASE - TMIN + 1) * $delta) div ($delta + SKEW));
}

sub decode_punycode($code is copy) is export {
    my $n      = INITIAL_N;
    my $i      = 0;
    my $bias   = INITIAL_BIAS;
    my @output;

    return $code unless $code ~~ s/^ 'xn--' //;

    if $code ~~ s/ (.*) '-' // {
        @output = $0.Str.ords;
        fail 'non-basic code point' if @output.grep({ $_ < 0 || $_ >= INITIAL_N });
    }

    while $code {
        my $oldi = $i;
        my $w    = 1;
        LOOP:
        loop (my $k = BASE; 1; $k += BASE) {
            (my $cp, $code) = substr($code, 0, 1), substr($code, 1);
            my $digit = digit_value($cp);
            $digit.defined or fail "invalid punycode input";
            $i += $digit * $w;
            my $t = ($k <= $bias) ?? TMIN !!
                    ($k >= $bias + TMAX) ?? TMAX !!
                     $k  - $bias;
            last LOOP if $digit < $t;
            $w *= (BASE - $t);
        }
        $bias = adapt($i - $oldi, @output.elems + 1, $oldi == 0);
        warn "bias becomes $bias" if $DEBUG;
        $n += $i div (@output.elems + 1);
        $i  = $i  %  (@output.elems + 1);
        splice(@output, $i, 0, $n);
        warn @output».fmt('%04x') if $DEBUG;
        ++$i;
    }
    @output.map(*.chr).join
}

sub encode_punycode($input) is export {
    my $n     = INITIAL_N;
    my $delta = 0;
    my $bias  = INITIAL_BIAS;

    my @input      = $input.comb;
    my @input-ords = $input.ords;
    my $output     = buf8.new( @input-ords.grep: 0 <= * < INITIAL_N );
    my $h  = my $b = $output.elems;
    return $input unless @input-ords.elems > $output.elems;

    $output[$output.elems] = $Delimiter.ord if $output;
    warn "basic codepoints: ($output.decode())" if $DEBUG;

    while $h < $input.chars {
        my $m   = @input-ords.grep(* >= $n).min;
        warn sprintf "next code point to insert is %04x", $m if $DEBUG;
        $delta += ($m - $n) * ($h + 1);
        $n      = $m;
        for @input-ords -> $c {
            $delta++ if $c < $n;
            if $c == $n {
                my $q = $delta;
                LOOP:
                loop (my $k = BASE; 1; $k += BASE) {
                    my $t = ($k <= $bias) ?? TMIN !!
                            ($k >= $bias + TMAX) ?? TMAX !!
                             $k  - $bias;
                    last LOOP if $q < $t;
                    my $cp                 = code_point($t + (($q - $t) % (BASE - $t)));
                    $output[$output.elems] = $cp;
                    $q                     = ($q - $t) div (BASE - $t);
                }
                $output[$output.elems] = code_point($q);
                $bias                  = adapt($delta, $h + 1, $h == $b);
                warn "bias becomes $bias" if $DEBUG;
                $delta = 0;
                $h++;
            }
        }
        ++$delta;
        ++$n;
    }
    'xn--' ~ $output.decode
}

=begin pod

=head1 NAME

IDNA::Punycode - Punycode implementation according to RFC3492

=head1 SYNOPSIS

=begin code :lang<raku>

use IDNA::Punycode;

say encode_punycode 'nice'  # nice
say encode_punycode 'schön' # xn--schn-7qa

say decode_punycode 'nice'         # nice
say decode_punycode 'xn--schn-7qa' # schön

=end code

=head1 DESCRIPTION

The C<IDNA::Punycode> provides an easy way to encode / decode strings
according to L<RFC3492|https://www.rfc-editor.org/info/rfc3492>.

=head1 AUTHOR

Tobias Leich (FROGGS)

Source can be located at: https://github.com/raku-community-modules/IDNA-Punycode .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2015, 2016, 2017 Tobias Leich, 2023 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
