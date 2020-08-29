#!/usr/bin/perl
# Should be put into <repository>/

# TODO: masks to ignore
# TODO: ignore files that were indexed but deleted
# TODO: learn to /bin/bash correctly and put it back, lol

EL();

my @diffFiles = GetFiles();
my $filecount = @diffFiles;
if ( $filecount == 0 )
{
	print "* Nada para analisar\n";
	EL();
	exit 0;
}

print "* $filecount arquivos para analisar\n";

ES();

my @unicodedFiles = ();
my $unicodedCount = 0;
my $i = 0;
foreach $file (@diffFiles)
{
	$i += 1;
	print "[$i/$filecount] --- Analisando: $file";
	ConvertFile($file);
}

ES();

print "Analise de Unicode finalizada: $i arquivos analisados\n";
if ( $i != $filecount )
{
	print " ! ERROR: Nao conseguimos analisar todos os $filecount arquivos!\n";
	EL();
	exit 1;
}

if ( $unicodedCount == 0 )
{
	print " * Encoding OK\n";
	EL();
	exit 0;
}

print " * $unicodedCount arquivos foram convertidos para unicode:\n";
for $f (@unicodedFiles)
{
	print "   - $f\n";
}

ES();

print " * Analise os arquivos, se estao com os caracteres certinhos e aplique o 'git add' novamente, caso seja codigo, faça um novo build local\n";
EL();
exit 1;



###############################################################################


# get the files to encode
sub GetFiles
{
	# turn off escaping non-ascii characters so тест.файл won't turn to "\321\202\320\265\321\201\321\202.\321\204\320\260\320\271\320\273"
	my $QP = 'git config --get core.quotepath';
	'git config core.quotepath off';

	# get files to process
	my @diffResult = 'git diff --stat --cached --diff-filter=ACMR';
	'git config core.quotepath $QP';
	
	
	# skip last line "3 files changed, 1 insertion"
	pop @diffResult;
	
	my @diffFiles = ();
	
	for $d (@diffResult)
	{
		# split each string by " | " in center
		my @parts = split / \| /, $d;
		
		# skip binary files
		if (not BeginsWith(Trim($parts[1]), 'Bin'))
		{
			push @diffFiles, Trim($parts[0]);
		}
	}
	
	return @diffFiles;
}
# encode the file if needed
sub ConvertFile
{
	my ($f) = @_;
	
	# since git diff returns one file per line ending with \n
	$f =~ s/\n//;
	my $utf = '~'.$f.'.utf8';
	
	# if we can successfully convert from Utf8 to Utf8 - it's already encoded correctly, won't mess around
	'iconv -s -f utf-8 -t utf-8 $f > /dev/null';
	if ( not $? )
	{
		print "  * Conversao nao necessaria\n";
		return;
	}
	
	# otherwise, let's try to convert it
	'touch $utf';
	'iconv -s -f cp1251 -t utf-8 $f > $utf';
	if ( not $? )
	{
		'rm $f';
		'mv $utf $f';
		$unicodedCount += 1;
		push @unicodedFiles, $f;
		print "  + Convertido\n";
		return;
	}
	
	print "  - Não convertido, provavelmente um arquivo binario\n";
	'rm $utf';
}

sub EL
{
	print "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
}
sub ES
{
	print "- - - - - - - - - - - - - - - - - - - - - - - - - - -\n";
}

sub BeginsWith
{
    return substr($_[0], 0, length($_[1])) eq $_[1];
}

sub Trim
{
	my $s = shift;
	$s =~ s/^\s+|\s+$//g;
	return $s
};