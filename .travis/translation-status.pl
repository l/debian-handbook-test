#!/usr/bin/perl
use strict;
use warnings;
use utf8;

# use Lingua::JA::Regular::Unicode;
use Data::Dumper;
use File::Find;
use File::Basename qw/basename dirname fileparse/;
use Encode qw/decode_utf8 encode_utf8 find_encoding/;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Time::Piece;
use XML::LibXML;
use HTML::Entities;
use IPC::Open3;
use Symbol qw(gensym);
use IO::File;
use URI;
use Scalar::Util qw(looks_like_number);

my $src_dir = './en-US';
my $pot_dir = './pot';
my $dst_dir = $ARGV[0];
my $output_path = $ARGV[1];

my $t = localtime;

my $document = XML::LibXML::Document->new();

# $document->expand_entities(0);
$document->setEncoding('utf-8');
my $dtd = $document->createInternalSubset( "html", undef, undef );
my $html = $document->createElement('html');
$document->setDocumentElement($html);

my $head = $document->createElement('head');
$html->appendChild($head);
my $meta = $document->createElement('meta');
$meta->setAttribute( 'charset', 'utf-8' );
$head->appendChild($meta);
$meta = $document->createElement('meta');
$meta->setAttribute( 'name',    'viewport' );
$meta->setAttribute( 'content', 'width=device-width, initial-scale=1.0' );
$head->appendChild($meta);
my $style = $document->createElement('style');
$head->appendChild($style);
$style->appendTextNode( << 'EOT' );
.num {text-align:right;}
.unit {text-align:right;}
.annotate {background:red;}
EOT
my $title = $document->createElement('title');
$head->appendChild($title);
$title->appendTextNode(
    qq(Translation status of $dst_dir - The Debian Administrator's Handbook));

my $body = $document->createElement('body');
$html->appendChild($body);

my $h1 = $document->createElement('h1');
$body->appendChild($h1);
$h1->appendTextNode(
    qq(Translation status of $dst_dir - The Debian Administrator's Handbook));

our @find_items;
my @xml_files;

@find_items = ();
find( \&wanted, $src_dir );
my $pot_files;
foreach ( sort @find_items ) {
    my $basename = basename $_;
    $basename =~ s/xml$/pot/;
    $pot_files->{$_} = ["$pot_dir/$basename"];
}

# print Dumper $pot_files;
my $result = _check_translation_po( $pot_files, $src_dir, $dst_dir );

# print Dumper $result;
_print_result_po( $body, $result );

# exit 0;

@find_items = ();
find( \&wanted, $src_dir );

@xml_files = sort @find_items;
my $img_files;

foreach (@xml_files) {
    my $text   = read_file($_);
    my $parser = XML::LibXML->new();
    $parser->recover(1);
    $parser->line_numbers(1);
    my $dom = $parser->load_xml( string => $text );
    $dom->setEncoding('UTF-8');
    $img_files->{$_} = [ _check_imagedata( $dom, $text ) ];
}

$result = _check_translation_img( $img_files, $src_dir, $dst_dir );

_print_result($result);

#----------------------------------------

$document->toFile($output_path);

exit 0;

sub wanted_pot {
    my $file = $File::Find::name;
    return if ( $file !~ m/.*\.pot$/ );
    push @find_items, $file;
}

sub wanted {
    my $file = $File::Find::name;
    return if ( $file !~ m/.*\.xml$/ );
    push @find_items, $file;
}

sub read_file {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    my $cont = <$fh>;
    close $fh;
    $cont = decode_utf8($cont);
    return $cont;
}

sub _check_imagedata {
    my $dom   = shift;
    my $str   = shift;
    my @nodes = $dom->findnodes('//imagedata[@fileref]');
    my @href  = ();
    foreach my $node (@nodes) {

        #print "CHECK: " . ( caller 0 )[3] . ": " . $node->nodePath . "\n";
        #print "\n" . '=' x 40 . "\n";
        #print $node->toString;
        #print "\n" . '*' x 40 . "\n";
        push @href, $node->getAttribute('fileref');

    }
    return @href;
}

sub _get_img_info {
    my $file = shift;

    return {
        width  => { format => "%d",    value => undef },
        height => { format => "%d",    value => undef },
        ratio  => { format => "%3.2f", value => undef },
      }
      if ( !-e $file );

    my $width  = undef;
    my $height = undef;

    local *CATCHERR = IO::File->new_tmpfile;
    my $pid =
      open3( gensym, \*CATCHOUT, ">&CATCHERR", "identify", "-format", "%wx%h",
        $file );
    while (<CATCHOUT>) {
        if (m/([0-9]*)x([0-9]*)/) {
            $width  = $1;
            $height = $2;
        }
    }
    waitpid( $pid, 0 );
    seek CATCHERR, 0, 0;
    while (<CATCHERR>) {
        print STDERR $_;
    }
    return {
        width  => { format => "%d",    value => $width },
        height => { format => "%d",    value => $height },
        ratio  => { format => "%3.2f", value => $width / $height },
    };
}

sub _get_po_info {
    my $file              = shift;
    my $translated        = undef;
    my $untranslated      = undef;
    my $fuzzy             = undef;
    my $total             = undef;
    my $err               = undef;
    my $child_exit_status = undef;

    if ( -e $file ) {
        $translated   = 0;
        $untranslated = 0;
        $fuzzy        = 0;
        $total        = 0;
        $err          = '';
        local *CATCHERR = IO::File->new_tmpfile;
        my $pid = open3( gensym, \*CATCHOUT, ">&CATCHERR", 'msgfmt',
            '--statistics', '--check', '--verbose', '--output-file',
            '/dev/null',    $file,
        );
        while (<CATCHOUT>) {
        }
        waitpid( $pid, 0 );
        $child_exit_status = $? >> 8;
        seek CATCHERR, 0, 0;

        while (<CATCHERR>) {
            if (m/([0-9]*) translated message(|s)/) {
                $translated = $1;
            }
            if (m/([0-9]*) untranslated message(|s)/) {
                $untranslated = $1;
            }
            if (m/([0-9]*) fuzzy translation(|s)/) {
                $fuzzy = $1;
            }
            $err .= $_;
        }
        $total = $translated + $untranslated + $fuzzy;
    }
    return {
        translated   => $translated,
        untranslated => $untranslated,
        fuzzy        => $fuzzy,
        total        => $total,
        err          => $err,
        exit_code    => $child_exit_status,
    };
}

sub _print_result_po {
    my $body     = shift;
    my $document = $body->ownerDocument;
    my $result   = shift;

    my $tr;
    my $th;
    my $td;

    # print Dumper $result;
    my $h2 = $document->createElement('h2');
    $body->appendChild($h2);
    $h2->appendTextNode('Text');

    # print "<h2>Text</h2>\n";
    my $table = $document->createElement('table');
    $body->appendChild($table);

    $tr = $document->createElement('tr');
    $table->appendChild($tr);
    foreach my $item ( 'xml', 'src pot', 'Ttl', 'Tr', 'Utr', 'Fuz', '$?', ) {
        $th = $document->createElement('th');
        $tr->appendChild($th);
        $th->appendTextNode($item);
        if (   $item eq 'Ttl'
            || $item eq 'Tr'
            || $item eq 'Utr'
            || $item eq 'Fuz' )
        {
        }
        else {
            $th->setAttribute( 'rowspan', '2' );
        }
    }
    foreach my $item ( 'dst po', 'Ttl', 'Tr', 'Utr', 'Fuz', '$?', ) {
        $th = $document->createElement('th');
        $tr->appendChild($th);
        $th->appendTextNode($item);
        if ( $item eq 'Tr' || $item eq 'Utr' || $item eq 'Fuz' ) {
            $th->setAttribute( 'colspan', '2' );
        }
        elsif ( $item eq 'Ttl' ) {
        }
        else {
            $th->setAttribute( 'rowspan', '2' );
        }
    }

    $tr = $document->createElement('tr');
    $table->appendChild($tr);
    for ( my $i = 0 ; $i < 5 ; $i++ ) {
        $th = $document->createElement('th');
        $tr->appendChild($th);
        $th->appendTextNode('[-]');
        $th->setAttribute( 'class', 'unit' );
    }
    for ( my $i = 0 ; $i < 3 ; $i++ ) {
        foreach my $item ( '[-]', '[%]', ) {
            $th = $document->createElement('th');
            $tr->appendChild($th);
            $th->appendTextNode($item);
            $th->setAttribute( 'class', 'unit' );
        }
    }

    my $src_pot = {};
    my $dst_pot = {};
    foreach ( @{$result} ) {
        $tr = $document->createElement('tr');
        $table->appendChild($tr);

        # print "<tr>";
        $td = $document->createElement('td');
        $tr->appendChild($td);
        $td->appendTextNode( $_->{ref} );

        # print "<td>$_->{ref}</td>";
        $td = $document->createElement('td');
        $tr->appendChild($td);
        $td->appendTextNode( $_->{src}->{file} );

        # print "<td>$_->{src}->{file}</td>";

        foreach my $item (qw(total translated untranslated fuzzy exit_code)) {
            $td = $document->createElement('td');
            $tr->appendChild($td);
            if ( defined $_->{src}->{$item} ) {
                $td->appendTextNode( $_->{src}->{$item} );
                $td->setAttribute( 'class', 'num' );
                $src_pot->{$item} += $_->{src}->{$item};
            }
        }

        $td = $document->createElement('td');
        $tr->appendChild($td);
        $td->appendTextNode( $_->{dst}->{file} );

        printf STDERR "%s\n", $_->{dst}->{file};

        foreach my $item (qw(total translated untranslated fuzzy exit_code)) {
            $td = $document->createElement('td');
            $tr->appendChild($td);
            if ( defined $_->{dst}->{$item} ) {
                $td->appendTextNode( $_->{dst}->{$item} );
                $td->setAttribute( 'class', 'num' );
                $dst_pot->{$item} += $_->{dst}->{$item};
            }
            if ( $item eq 'translated' ) {
                if (
                    (
                           defined $_->{dst}->{$item}
                        && defined $_->{dst}->{total}
                        && $_->{dst}->{$item} != $_->{dst}->{total}
                    )
                  )
                {
                    $td->setAttribute( 'class', 'num annotate' );
                }
                $td = $document->createElement('td');
                $tr->appendChild($td);
                if ( defined $_->{dst}->{$item} && defined $_->{dst}->{total} )
                {
                    my $goodness =
                      $_->{dst}->{total} == 0
                      ? 1
                      : $_->{dst}->{$item} / $_->{dst}->{total};
                    $td->appendTextNode( sprintf( "%4.1f", $goodness * 100 ) );
                    $td->setAttribute( 'class', 'num' );
                    $td->setAttribute(
                        'style',
                        sprintf( 'background:rgb(%d,%d,%d)',
                            &_html_color_red_yellow_green($goodness) )
                    );
                }
            }
            elsif ( $item eq 'untranslated' || $item eq 'fuzzy' ) {
                if ( ( defined $_->{dst}->{$item} && $_->{dst}->{$item} != 0 ) )
                {
                    $td->setAttribute( 'class', 'num annotate' );
                }
                $td = $document->createElement('td');
                $tr->appendChild($td);
                if (   defined $_->{dst}->{$item}
                    && defined $_->{dst}->{total} )
                {
                    my $badness =
                      $_->{dst}->{total} == 0
                      ? 0
                      : $_->{dst}->{$item} / $_->{dst}->{total};
                    $td->appendTextNode( sprintf( "%4.1f", $badness * 100 ) );
                    $td->setAttribute( 'class', 'num' );
                    $td->setAttribute(
                        'style',
                        sprintf( 'background:rgb(%d,%d,%d)',
                            &_html_color_red_yellow_green( 1 - $badness ) )
                    );
                }
            }
            elsif ( $item eq 'exit_code' ) {
                if ( ( defined $_->{dst}->{$item} && $_->{dst}->{$item} != 0 ) )
                {
                    $td->setAttribute( 'class', 'num annotate' );
                }
            }
        }
    }

    #print STDERR Dumper [ $src_pot, $dst_pot ];
    $tr = $document->createElement('tr');
    $table->appendChild($tr);
    $th = $document->createElement('th');
    $tr->appendChild($th);
    $th->setAttribute( 'colspan', '2' );
    $th->appendTextNode('Total');
    foreach my $item (qw(total translated untranslated fuzzy exit_code)) {
        $td = $document->createElement('td');
        $tr->appendChild($td);
        if ( defined $src_pot->{$item} ) {
            $td->appendTextNode( $src_pot->{$item} );
            $td->setAttribute( 'class', 'num' );
        }
    }
    $th = $document->createElement('th');
    $tr->appendChild($th);
    $th->appendTextNode('Total');
    foreach my $item (qw(total translated untranslated fuzzy exit_code)) {
        $td = $document->createElement('td');
        $tr->appendChild($td);
        if ( defined $dst_pot->{$item} ) {
            $td->appendTextNode( $dst_pot->{$item} );
            $td->setAttribute( 'class', 'num' );
        }
        if ( $item eq 'translated' ) {
            if (
                (
                       defined $dst_pot->{$item}
                    && defined $dst_pot->{total}
                    && $dst_pot->{$item} != $dst_pot->{total}
                )
              )
            {
                $td->setAttribute( 'class', 'num annotate' );
            }
            $td = $document->createElement('td');
            $tr->appendChild($td);
            if ( defined $dst_pot->{$item} && defined $dst_pot->{total} ) {
                my $goodness =
                  $dst_pot->{total} == 0
                  ? 1
                  : $dst_pot->{$item} / $dst_pot->{total};
                $td->appendTextNode( sprintf( "%4.1f", $goodness * 100 ) );
                $td->setAttribute( 'class', 'num' );
                $td->setAttribute(
                    'style',
                    sprintf( 'background:rgb(%d,%d,%d)',
                        &_html_color_red_yellow_green($goodness) )
                );
            }

            #$td = $document->createElement('td');
            #$tr->appendChild($td);
            #if ( defined $dst_pot->{$item} && defined $dst_pot->{total} ) {
            #    $td->appendTextNode(
            #        sprintf( "%5.1f",
            #            $dst_pot->{$item} / $dst_pot->{total} * 100 )
            #    );
            #    $td->setAttribute( 'class', 'num' );
            #    $td->setAttribute(
            #        'style',
            #        sprintf(
            #            'background:rgb(%d,%d,%d)',
            #            &_html_color_red_yellow_green(
            #                $dst_pot->{$item} / $dst_pot->{total}
            #            )
            #        )
            #    );
            #}
        }
        elsif ( $item eq 'untranslated' || $item eq 'fuzzy' ) {
            if ( ( defined $dst_pot->{$item} && $dst_pot->{$item} != 0 ) ) {
                $td->setAttribute( 'class', 'num annotate' );
            }
            $td = $document->createElement('td');
            $tr->appendChild($td);
            if (   defined $dst_pot->{$item}
                && defined $dst_pot->{total} )
            {
                my $badness =
                  $dst_pot->{total} == 0
                  ? 0
                  : $dst_pot->{$item} / $dst_pot->{total};
                $td->appendTextNode( sprintf( "%4.1f", $badness * 100 ) );
                $td->setAttribute( 'class', 'num' );
                $td->setAttribute(
                    'style',
                    sprintf( 'background:rgb(%d,%d,%d)',
                        &_html_color_red_yellow_green( 1 - $badness ) )
                );
            }

            #$td = $document->createElement('td');
            #$tr->appendChild($td);
            #if ( defined $dst_pot->{$item} && defined $dst_pot->{total} ) {
            #    $td->appendTextNode(
            #        sprintf( "%5.1f",
            #            $dst_pot->{$item} / $dst_pot->{total} * 100 )
            #    );
            #    $td->setAttribute( 'class', 'num' );
            #    $td->setAttribute(
            #        'style',
            #        sprintf(
            #            'background:rgb(%d,%d,%d)',
            #            &_html_color_red_yellow_green(
            #                1 - $dst_pot->{$item} / $dst_pot->{total}
            #            )
            #        )
            #    );
            #}
        }
        elsif ( $item eq 'exit_code' ) {
            if ( ( defined $dst_pot->{$item} && $dst_pot->{$item} != 0 ) ) {
                $td->setAttribute( 'class', 'num annotate' );
            }
        }
    }

    # print "</table>\n";
}

sub _print_result {
    my $result = shift;

    # print Dumper $result;
    my $h2 = $document->createElement('h2');
    $body->appendChild($h2);
    $h2->appendTextNode('Figure');

    # print "<h2>Figure</h2>\n";
    my $table = $document->createElement('table');
    $body->appendChild($table);

    # print "<table>\n";
    my $tr = $document->createElement('tr');
    $table->appendChild($tr);
    my $th = $document->createElement('th');
    $tr->appendChild($th);
    $th->appendTextNode('src xml path');
    $th->setAttribute( 'colspan', '4' );

    $tr = $document->createElement('tr');
    $table->appendChild($tr);
    foreach my $item (
        'src img path', 'width', 'height', 'ratio',
        'dst img path', 'width', 'height', 'ratio',
      )
    {
        $th = $document->createElement('th');
        $tr->appendChild($th);
        $th->appendTextNode($item);
        if ( $item eq 'src img path' || $item eq 'dst img path' ) {
            $th->setAttribute( 'rowspan', '2' );
        }
        else {
            #$th->setAttribute( 'colspan', '2' );
        }
    }

    $tr = $document->createElement('tr');
    $table->appendChild($tr);
    for ( my $i = 0 ; $i < 2 ; $i++ ) {
        foreach my $item ( '[px]', '[px]', '[-]', ) {
            $th = $document->createElement('th');
            $tr->appendChild($th);
            $th->appendTextNode($item);
            $th->setAttribute( 'class', 'unit' );
        }
    }

    $tr = $document->createElement('tr');
    $table->appendChild($tr);
    foreach my $item ( 'src img', 'dst img', ) {
        $th = $document->createElement('th');
        $tr->appendChild($th);
        $th->setAttribute( 'colspan', '4' );
        $th->appendTextNode($item);
    }

    my $td;
    my $uri;
    foreach ( @{$result} ) {
        $tr = $document->createElement('tr');
        $table->appendChild($tr);

        # print "<tr>";
        $td = $document->createElement('td');
        $tr->appendChild($td);
        $td->appendTextNode( $_->{ref} );
        $td->setAttribute( 'colspan', '4' );

        # print "<td>$_->{ref}</td>";
        # print "</tr>\n";
        $tr = $document->createElement('tr');
        $table->appendChild($tr);

      #       foreach my $item (qw(file width height ratio)) {
      #           $td = $document->createElement('td');
      #           $tr->appendChild($td);
      #           my @classes = ();
      #           if ( defined $_->{src}->{$item}->{value} ) {
      #               $td->appendTextNode( sprintf($_->{src}->{$item}->{format},
      #                   $_->{src}->{$item}->{value}) );
      #               if ( looks_like_number( $_->{src}->{$item}->{value} ) ) {
      #                   push @classes, 'num';
      #               }
      #           }
      #           if (@classes) {
      #               $td->setAttribute( 'class', join( ' ', @classes ) );
      #           }
      #       }

        foreach my $target (qw(src dst)) {
            foreach my $item (qw(file width height ratio)) {
                $td = $document->createElement('td');
                $tr->appendChild($td);
                my @classes = ();
                if ( defined $_->{$target}->{$item}->{value} ) {
                    $td->appendTextNode(
                        sprintf(
                            $_->{$target}->{$item}->{format},
                            $_->{$target}->{$item}->{value}
                        )
                    );
                    if ( looks_like_number( $_->{$target}->{$item}->{value} ) )
                    {
                        push( @classes, 'num' );
                        if (   $target ne 'file'
                            && $_->{src}->{$item}->{value} !=
                            $_->{$target}->{$item}->{value} )
                        {
                            push( @classes, 'annotate' );
                        }
                    }
                }
                if (@classes) {
                    $td->setAttribute( 'class', join( ' ', @classes ) );
                }
            }
        }

        $tr = $document->createElement('tr');
        $table->appendChild($tr);

       #       $td = $document->createElement('td');
       #       $tr->appendChild($td);
       #       $td->setAttribute( 'style',   'width:50%' );
       #       $td->setAttribute( 'colspan', '4' );
       #       my $img = $document->createElement('img');
       #       $td->appendChild($img);
       #       $img->setAttribute( 'style', 'width:100%' );
       #       $uri = URI->new_abs( $_->{src}->{file}->{value}, '../../html/' );
       #       $uri = $uri->canonical;
       #       $uri =~ s#^/##;
       #       $img->setAttribute( 'src', $uri );
       #       $img->setAttribute( 'alt', $uri );

        my $img;
        foreach my $target (qw(src dst)) {
            $td = $document->createElement('td');
            $tr->appendChild($td);
            $td->setAttribute( 'style',   'width:50%' );
            $td->setAttribute( 'colspan', '4' );
            if ( defined $_->{$target}->{file}->{value}
                && -e $_->{$target}->{file}->{value} )
            {
                $img = $document->createElement('img');
                $td->appendChild($img);
                $img->setAttribute( 'style', 'width:100%' );
                my ( $filename, $dirs, $suffix ) =
                  fileparse( $_->{$target}->{file}->{value} );
                $uri = URI->new_abs( $filename,
"../../../publish/$_->{$target}->{file}->{lang}/Debian/9/html/debian-handbook/images/"
                );
                $uri = $uri->canonical;
                $uri =~ s#^/##;
                $img->setAttribute( 'src', $uri );
                $img->setAttribute( 'alt', $uri );
            }
            else {
            }
        }

        # print "</tr>\n";
    }

    # print "</table>\n";
}

sub _check_translation_img {
    my $xml_files = shift;
    my $src_dir   = shift;
    my $dst_dir   = shift;
    my $result;

    foreach my $xml_file ( sort keys %{$xml_files} ) {
        foreach my $img_file ( @{ $xml_files->{$xml_file} } ) {
            my $img_file_src = "$src_dir/$img_file";
            my $img_file_dst = "$dst_dir/$img_file";
            push @{$result},
              {
                ref => $xml_file,
                id  => $img_file,
                src => {
                    file => {
                        format => "%s",
                        value  => $img_file_src,
                        lang   => $src_dir,
                    },
                    %{ _get_img_info($img_file_src) },
                },
                dst => {
                    file => {
                        format => "%s",
                        value  => $img_file_dst,
                        lang   => $dst_dir,
                    },
                    %{ _get_img_info($img_file_dst) },
                },
              };

            # print "$xml_file $img_file_src $img_file_dst\n";
        }
    }
    return $result;
}

sub _html_color_red_yellow_green {
    my $ratio = shift;
    my $index = int( ( 256 + 256 - 1 ) * $ratio );
    my $R     = $index < 256 ? 255 : 255 - $index % 256;
    my $G     = $index < 256 ? $index : 255;
    my $B     = 0;
    return ( $R, $G, $B );
}

sub _check_translation_po {
    my $xml_files = shift;
    my $src_dir   = shift;
    my $dst_dir   = shift;
    my $result;

    foreach my $xml_file ( sort keys %{$xml_files} ) {
        foreach my $pot_file ( @{ $xml_files->{$xml_file} } ) {
            my $basename = basename $pot_file;
            $basename =~ s/pot$/po/;
            my $po_file_src = $pot_file;
            my $po_file_dst = "$dst_dir/$basename";
            push @{$result},
              {
                ref => $xml_file,
                id  => $pot_file,
                src => {
                    file => $po_file_src,
                    %{ _get_po_info($po_file_src) },
                },
                dst => {
                    file => $po_file_dst,
                    %{ _get_po_info($po_file_dst) },
                },
              };

            # print "$xml_file $img_file_src $img_file_dst\n";
        }
    }
    return $result;
}

__END__;
