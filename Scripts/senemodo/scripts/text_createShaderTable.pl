#perl
#ver 1.0
#author : Seneca Menard

#This script will load up a C:/shaderTable.tga and build a series of rage tables from that TGA, used for particle or material effects.

#====================================
#CLIPBOARD SETUP
#====================================
BEGIN{
	my $perlDir = "C:\/Perl\/lib";
	my $perlDir2 = "H:\/Home\/Seneca Menard\/artistTools_Modo\/Perl\/lib";
	push(@INC,$perlDir);
	push(@INC,$perlDir2);
}
use Win32::Clipboard;
$CLIP = Win32::Clipboard();


#====================================
#SETUP
#====================================
my %rgbPixels;
my $file = 'c:/shaderTable.tga';
readTGARGB($file);
my $count = 0;
my $string;

foreach my $key (sort keys %rgbPixels){
	my @array;
	if ($count == 0){
		@array = returnShaderTable($key,1,5,1,0);
	}elsif ($count > 2){
		print "What size would you like to scale the gradation?\n";
		my $scalar = <STDIN>;
		print "What amount would you like to offset the gradation?\n";
		my $offset = <STDIN>;
		@array = returnShaderTable($key,0,5,$scalar,$offset);
	}else{
		@array = returnShaderTable($key,0,5,1,0);
	}
	$string .= $_ for @array;
	$count++;
}
#print $string;
$CLIP->Set($string);

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READS TGA AND WRITES TO TABLE ARRAY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : returnShaderTable($rgbPixelsKEY,$rgbChannelsOrNot,$roundToThisDecimal,$multiplier,$offset);
#requires readTGARGB to have been run
sub returnShaderTable{
	my @array;

	for (my $i=0; $i<@{$rgbPixels{@_[0]}}; $i=$i+3){
		#rgb image
		if (@_[1] == 1){
			@array[0] .= roundNumberString((@{$rgbPixels{@_[0]}}[$i] / 255 * @_[3]) + @_[4],@_[2]) . " , ";
			@array[1] .= roundNumberString((@{$rgbPixels{@_[0]}}[$i+1] / 255 * @_[3]) + @_[4],@_[2]) . " , ";
			@array[2] .= roundNumberString((@{$rgbPixels{@_[0]}}[$i+2] / 255 * @_[3]) + @_[4],@_[2]) . " , ";
		}
		#greyscale image
		else{
			@array[0] .= roundNumberString((@{$rgbPixels{@_[0]}}[$i] / 255 * @_[3]) + @_[4],@_[2]) . " , ";
		}
		#popup("sdf @array");
	}

	for (my $i=0; $i<@array; $i++){
		@array[$i] = "\{ \{ " . @array[$i];
		@array[$i] =~ s/, $/ } }\n/;
		#print "array[$i] = @array[$i]";
	}

	return @array;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READS TGA AND WRITES TO TABLE ARRAY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : readTGARGB($filePath);
#requires %rgbPixels;
sub readTGARGB{
	open (TGA, "<@_[0]") or die("I can't open this TGA : @_[0]");
	binmode(TGA); #explicitly tells it to be a BINARY file

	#read the TGA header info
	my $buffer;
	my $identSize =			readChar(TGA,1,C);
	my $palette = 			readChar(TGA,1,C);
	my $imageType = 		readChar(TGA,1,C);
	my $colorMapStart = 	readChar(TGA,2,S);
	my $colorMapLength = 	readChar(TGA,2,S);
	my $colorMapBits =		readChar(TGA,1,C);
	my $xStart =			readChar(TGA,2,S);
	my $yStart =			readChar(TGA,2,S);
	my $width =				readChar(TGA,2,S);
	my $height =			readChar(TGA,2,S);
	my $bits =				readChar(TGA,1,C);
	my $descriptor = 		readChar(TGA,1,C);
	my %pixels;
	if ($bits == 24)		{our $readLength=3;}else{our $readLength=4;}
	@currentSize = 			($width,$height);
	$bitMode = 				$bits;

	#read the TGA color info
	for (my $v=$height-1; $v>-1; $v--){ #had to flip the order because the god damn colors are supposed to be in V reverse.
		for (my $u=0; $u<$width; $u++){
			read(TGA, $buffer, $readLength);
			my @rgb = unpack("C*",$buffer);
			push(@{$rgbPixels{$v}},@rgb[2],@rgb[1],@rgb[0]);
		}
	}

	#print the TGA color info
	#lxout("identSize = $identSize\n");
	#lxout("palette = $palette\n");
	#lxout("imageType = $imageType\n");
	#lxout("colorMapStart = $colorMapStart\n");
	#lxout("colorMapLength = $colorMapLength\n");
	#lxout("colorMapBits = $colorMapBits\n");
	#lxout("xStart = $xStart\n");
	#lxout("yStart = $yStart\n");
	#lxout("width = $width\n");
	#lxout("height = $height\n");
	#lxout("bits = $bits\n");
	#lxout("descriptor = $descriptor\n");
	#foreach my $key (keys %pixels){lxout("key ($key) = @{$pixels{$key}}\n");}

	close(TGA);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READ BINARY CHARS FROM FILE (there's no offsetting. it's for reading entire file one step at a time)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : readChar(FILEHANDLE,$howManyBytes,$packCharType);
sub readChar{
	read(@_[0], $buffer, @_[1]);
	return unpack(@_[2],$buffer);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS WILL ROUND THE CURRENT NUMBER to the string length you define (and fill in empty space with 0s as well)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $roundedNumberString = roundNumberString(0.2565486158,5);
sub roundNumberString{
	$_ = "@_[0]";
	my $count = s/.//g;
	my $roundedNumber = "@_[0]";
	if ($count > @_[1])		{$roundedNumber = substr($roundedNumber, 0, @_[1]);}
	elsif ($count < @_[1])	{
		if ($roundedNumber =~ /\./)	{$roundedNumber .= 0 x (@_[1] - $count);	}
		else						{{$roundedNumber .= "." . 0 x ((@_[1] - 1) - $count);	}	}
	}
	return($roundedNumber);
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PRINT ALL THE ELEMENTS IN A HASH TABLE FULL OF ARRAYS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : printHashTableArray(\%table,table);
sub printHashTableArray{
	lxout("          ------------------------------------Printing @_[1] list------------------------------------");
	my $hash = @_[0];
	foreach my $key (sort keys %{$hash}){
		lxout("          KEY = $key");
		for (my $i=0; $i<@{$$hash{$key}}; $i++){
			lxout("             $i = @{$$hash{$key}}[$i]");
		}
	}
}