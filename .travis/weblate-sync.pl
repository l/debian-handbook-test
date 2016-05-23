#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
binmode STDIN  => ":encoding(utf8)";
binmode STDOUT => ":encoding(utf8)";
binmode STDERR => ":encoding(utf8)";

use Data::Dumper;
use File::Basename;
use File::Find;
use IO::File;
use LWP::UserAgent ();
use List::Util qw(first);
use URI;

our $table = {
    lang => [
        {    # Arabic (Morocco)
            file    => 'ar-MA',
            weblate => 'ar_MA',
        },
        {    # Croatian
            file    => 'hr-HR',
            weblate => 'hr',
        },
        {    # Danish
            file    => 'da-DK',
            weblate => 'da',
        },
        {    # French
            file    => 'fr-FR',
            weblate => 'fr',
        },
        {    # German
            file    => 'de-DE',
            weblate => 'de',
        },
        {    # Greek
            file    => 'el-GR',
            weblate => 'el',
        },
        {    # Indonesian
            file    => 'id-ID',
            weblate => 'id',
        },
        {    # Italian
            file    => 'it-IT',
            weblate => 'it',
        },
        {    # Japanese
            file    => 'ja-JP',
            weblate => 'ja',
        },
        {    # Korean
            file    => 'ko-KR',
            weblate => 'ko',
        },
        {    # Norwegian Bokmål (nb_NO)
            file    => 'nb-NO',
            weblate => 'nb_NO',
        },
        {    # Persian
            file    => 'fa-IR',
            weblate => 'fa',
        },
        {    # Polish
            file    => 'pl-PL',
            weblate => 'pl',
        },
        {    # Portuguese (Brazil)
            file    => 'pt-BR',
            weblate => 'pt_BR',
        },
        {    # Romanian
            file    => 'ro-RO',
            weblate => 'ro',
        },
        {    # Russian
            file    => 'ru-RU',
            weblate => 'ru',
        },
        {    # Simplified Chinese
            file    => 'zh-CN',
            weblate => 'zh_Hans',
        },
        {    # Spanish
            file    => 'es-ES',
            weblate => 'es',
        },
        {    # Traditional Chinese
            file    => 'zh-TW',
            weblate => 'zh_Hant',
        },
        {    # Turkish
            file    => 'tr-TR',
            weblate => 'tr',
        },
    ],
};

sub update_file {
    my $ua     = shift;
    my $local  = shift;
    my $remote = shift;
    return 1 if ( !-e $local );
    printf "%-40s %s\n", $local, $remote;
    my $req = HTTP::Request->new();
    $req->method('GET');
    $req->uri($remote);
    my $res = $ua->request($req);

    if ( !$res->is_success ) {
        print Dumper $remote;
        print Dumper $ua;
        print Dumper $req;
        print Dumper $res;
    }
    my $fh = IO::File->new();
    if ( $fh->open( $local, 'w' ) ) {
        print $fh $res->content;
        $fh->close;
    }
    return 0;
}

sub file_find_preprocess {
    return file_find_preprocess_exclude_hidden(@_);
}

sub file_find_preprocess_exclude_hidden {
    return grep { $_ !~ m/^\..+/ } @_;
}

sub file_find_wanted {
    my $list = shift;
    my $name = shift;
    return 0 if ( !-f $name );
    my ( $filename, $dirs, $suffix ) = fileparse( $name, qr/\.[^.]*/ );
    return 0 if ( $suffix ne '.po' );
    push @{$list}, $File::Find::name;
    return 0;
}

sub to_weblate {
    my $lang     = shift;
    my $file     = shift;
    my $language = first { $lang eq $_->{file} } @{ $table->{lang} };
    $language = $language->{weblate};
    my ( $component, $dirs, $suffix ) = fileparse( $file, qr/\.[^.]*/ );
    return URI->new(
"https://hosted.weblate.org/download/debian-handbook/$component/$language/"
    );
}

sub download_list {
    my $search_dir = shift;
    $search_dir = './' if ( !defined $search_dir );
    my $local = [];
    find(
        {
            preprocess => \&file_find_preprocess,
            wanted     => sub { return &file_find_wanted( $local, $_ ) },
        },
        $search_dir
    );
    my $list = [];
    foreach my $local ( @{$local} ) {
        $local = File::Spec->canonpath($local);
        my @dirs   = File::Spec->splitdir( File::Spec->rel2abs($local) );
        my $lang   = $dirs[-2];
        my $file   = $dirs[-1];
        my $remote = to_weblate( $lang, $file );
        push @{$list},
          {
            local  => $local,
            remote => $remote,
          };
    }
    return [ sort { $a->{local} cmp $b->{local} } @{$list} ];
}

sub usage {
    my $bin = basename($0);
    print <<"EOS";
Synopics:

	\$ $bin SEARCH_PATHs

Discription:

	Search po files under SEARCH_PATHs and download them from Weblate.
	Hidden dierctory and file are ignored.

Examples;

	1. updates po files under './'.
	\$ $bin ./

	2. updates po files under './nb-NO/' and './zh-TW/'.
	\$ $bin ./nb-NO/ ./zh-TW/

	3. updates './zh-CN/00a_preface.po' only.
	\$ $bin ./zh-CN/00a_preface.po

	4. nothing updated, because no seach path passed. this help is shown.
	\$ $bin

	5. nothing updated, because po files are not under './en-US/'.
	\$ $bin ./en-US/

	6. nothing updated, because './foober' does not exists.
	\$ $bin ./foobar

EOS
    return 0;
}

sub main {
    if ( !defined $_[0] ) {
        &usage();
        return 1;
    }
    my $ua = LWP::UserAgent->new();
    foreach (@_) {
        my $list = &download_list($_);
        foreach ( @{$list} ) {
            &update_file( $ua, $_->{local}, $_->{remote} );
        }
    }
    return 0;
}

main(@ARGV);

exit 0;

__END__
