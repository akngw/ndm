#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

# ndmacroみたいな処理

binmode STDIN,  ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";

main() unless caller;

sub main {
    print( ndm( read_all() ) );
}

sub read_all {
    my @lines = <STDIN>;
    join '', @lines;
}

sub ndm {
    my $in = shift;
    my ( $found, $base, $optional, $repeated ) = search_repetition($in);
    unless ($found) {
        return $in;
    }
    repeat_string( $in, $base, $optional, $repeated );
}

sub search_repetition {
    my $str = shift;
    my $re  = derive_regexp($str);
    unless ( $re && $str =~ /$re/s ) {
        return 0, '', '', '';
    }
    1, $1, $2, $3;
}

sub derive_regexp {
    my $str = shift;
    $str =~ s/\d+/0/g;
    unless ( $str =~ /(.+)(.*?)\1$/s ) {
        return;
    }
    my $re1 = regexp_of($1);
    my $re2 = regexp_of($2);
    "($re1)($re2)($re1)";
}

sub regexp_of {
    my $s = shift;
    my $t = quotemeta($s);
    $t =~ s/\d+/\\d+/g;
    $t;
}

sub regexp_with_parens_of {
    my $s = shift;
    my $t = quotemeta($s);
    $t =~ s/\d+/(\\d+)/g;
    $t;
}

sub repeat_string {
    my ( $original, $base, $optional, $repeated ) = @_;
    if ($optional) {
        chomp $original;
        $original . $optional;
    } else {
        $original . infer_repetition( $base, $repeated );
    }
}

sub infer_repetition {
    my ( $base, $repeated ) = @_;
    unless ( $base =~ /\d/ ) {
        return $repeated;
    }
    &infer_repetition_with_number;
}

sub infer_repetition_with_number {
    my ( $base, $repeated ) = @_;
    my @nums = &infer_numbers;
    replace_numbers( $repeated, @nums );
}

sub replace_numbers {
    my ( $str, @numbers ) = @_;
    $str =~ s/\d+/shift @numbers/eg;
    $str;
}

sub infer_numbers {
    my ( $base, $repeated ) = @_;
    my $re            = regexp_with_parens_of($base);
    my @nums_base     = $base =~ /$re/s;
    my @nums_repeated = $repeated =~ /$re/s;
    map { infer(@$_) } zip( @nums_base, @nums_repeated );
}

sub infer {
    my ( $fst, $snd ) = @_;
    my $inferred = $snd + ( $snd - $fst );
    pad_zeros( $inferred < 0 ? 0 : $inferred, length($snd) );
}

sub pad_zeros {
    my ( $num, $len ) = @_;
    my $numlen = length($num);
    if ( $numlen >= $len ) {
        $num;
    } else {
        '0' x ( $len - $numlen ) . $num;
    }
}

sub zip {
    my $p = @_ / 2;
    map { [ $_[$_], $_[ $_ + $p ] ] } 0 .. $p - 1;
}

1;
