#perl

my %rgbaPixels;
my $file = "C:\/Users\/Seneca Menard\/Desktop\/test.tga";
my @specs = readTGARGBA($file);
if ($specs[0] != 32){die("This image is not 32bit and so I'm cancelling the script");}
#my $foundPixelWithZeroAlpha = 1;

#print "sdf\n";

my $counter;
for (my $v=0; $v<$specs[2]; $v++){
	for (my $u=0; $u<$specs[1]; $u++){
		if (${$rgbaPixels{$v}}[$u*4] == 0){
			$counter++;
		}
	}
}
		
		
		
while ($counter > 0){
	#$foundPixelWithZeroAlpha = 0;
	print "$counter pixels left\n";

	for (my $v=0; $v<$specs[2]; $v++){
	#lxout("V : $v---------");
		for (my $u=0; $u<$specs[1]; $u++){
			#lxout("($u,$v) = ${$rgbaPixels{$v}}[$u*4] , ${$rgbaPixels{$v}}[$u*4+1] , ${$rgbaPixels{$v}}[$u*4+2] , ${$rgbaPixels{$v}}[$u*4+3] ");
			#lxout("U : $u---");
			my @legalNeighbors = areNeighborsLegal($u,$v);

			#if neither black or white alpha, set alpha to white
			if ((${$rgbaPixels{$v}}[$u*4] > 0) && (${$rgbaPixels{$v}}[$u*4] < 255)){
				#lxout("$u,$v : fixing alpha");
				${$rgbaPixels{$v}}[$u*4] = 255;
			}elsif (${$rgbaPixels{$v}}[$u*4] == 0){
				#$foundPixelWithZeroAlpha = 1;
				#print "[$u,$v] : 0 alpha\n";
				next;
			}

			#bleed color and alpha to neighboring pixels
			#topleft
			if (($legalNeighbors[0] == 1) && ($legalNeighbors[2] == 1)){
				if (${$rgbaPixels{$v-1}}[($u-1)*4] == 0){
					#print "[$u,$v] : topleft\n";
					${$rgbaPixels{$v-1}}[($u-1)*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v-1}}[($u-1)*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v-1}}[($u-1)*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v-1}}[($u-1)*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;
				}
			}

			#top
			if ($legalNeighbors[2] == 1){
				if (${$rgbaPixels{$v-1}}[$u*4] == 0){
					#print "[$u,$v] : top\n";
					${$rgbaPixels{$v-1}}[$u*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v-1}}[$u*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v-1}}[$u*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v-1}}[$u*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;
				}
			}

			#topright
			if (($legalNeighbors[1] == 1) && ($legalNeighbors[2] == 1)){
				if (${$rgbaPixels{$v-1}}[($u+1)*4] == 0){
					#print "[$u,$v] : topright\n";
					${$rgbaPixels{$v-1}}[($u+1)*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v-1}}[($u+1)*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v-1}}[($u+1)*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v-1}}[($u+1)*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;
				}
			}

			#left
			if ($legalNeighbors[0] == 1){
				if (${$rgbaPixels{$v}}[($u-1)*4] == 0){
					#print "[$u,$v] : left\n";
					${$rgbaPixels{$v}}[($u-1)*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v}}[($u-1)*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v}}[($u-1)*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v}}[($u-1)*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;
				}
			}

			#right
			if ($legalNeighbors[1] == 1){
				if (${$rgbaPixels{$v}}[($u+1)*4] == 0){
					#print "[$u,$v] : right\n"; 
					${$rgbaPixels{$v}}[($u+1)*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v}}[($u+1)*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v}}[($u+1)*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v}}[($u+1)*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;
				}
			}

			#bottomleft
			if (($legalNeighbors[0] == 1) && ($legalNeighbors[3] == 1)){
				if (${$rgbaPixels{$v+1}}[($u-1)*4] == 0){
					#print "[$u,$v] : bottomleft\n";
					${$rgbaPixels{$v+1}}[($u-1)*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v+1}}[($u-1)*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v+1}}[($u-1)*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v+1}}[($u-1)*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;
				}

			}

			#bottom
			if ($legalNeighbors[3] == 1){
				if (${$rgbaPixels{$v+1}}[$u*4] == 0){
					#print "[$u,$v] : bottom\n";
					${$rgbaPixels{$v+1}}[$u*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v+1}}[$u*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v+1}}[$u*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v+1}}[$u*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;
				}
			}

			#bottomright
			if (($legalNeighbors[1] == 1) && ($legalNeighbors[3] == 1)){
				if (${$rgbaPixels{$v+1}}[($u+1)*4] == 0){
					#print "[$u,$v] : bottomright\n";		
					${$rgbaPixels{$v+1}}[($u+1)*4] =   ${$rgbaPixels{$v}}[$u*4];
					${$rgbaPixels{$v+1}}[($u+1)*4+1] = ${$rgbaPixels{$v}}[$u*4+1];
					${$rgbaPixels{$v+1}}[($u+1)*4+2] = ${$rgbaPixels{$v}}[$u*4+2];
					${$rgbaPixels{$v+1}}[($u+1)*4+3] = ${$rgbaPixels{$v}}[$u*4+3];
					$counter--;

					#lxout("${$rgbaPixels{$v}}[$u*4] , ${$rgbaPixels{$v}}[$u*4+1] , ${$rgbaPixels{$v}}[$u*4+2] , ${$rgbaPixels{$v}}[$u*4+3]");
				}
			}
		}
	}
}
saveTGA("C:\/Users\/Seneca Menard\/Desktop\/test2.tga",$specs[1],$specs[2],\%rgbaPixels);


#left, right, up, down
sub areNeighborsLegal{
	#lxout("$_[0] <> $_[1] <> $specs[1] <> $specs[2]");
	my @legalities = (1,1,1,1);
	if ($_[0] == 0)				{$legalities[0] = 0;}
	if ($_[0] == $specs[1]-1)	{$legalities[1] = 0;}
	if ($_[1] == 0)				{$legalities[2] = 0;}
	if ($_[1] == $specs[2]-1)	{$legalities[3] = 0;}
	#lxout("legalities = @legalities");
	return (@legalities);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SAVE TGA (deletes alpha)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : saveTGA($filePath,width,height,\%rgbaPixels);
sub saveTGA{
	#$buf = pack("C", 255);				#for packing 0-255
	#$buf = pack("A*", "Hello World!");	#for packing strings
	#$buf = pack("S", 666);				#for packing unsigned shorts (higher than 255, but not by that much i guess)
	if (@_[3] == ""){die("You can't run the newTGA sub without arguments!");}

	my $file = $_[0];
	my @size = ($_[1],$_[2]);

	#lxout("[->] Creating a new TGA here : $file");
	open (TGA, ">$file") or die("I can't open the TGA");
	binmode(TGA);

	my $identSize = 		pack("C", 0);
	my $palette = 			pack("C", 0);
	my $imageType = 		pack("C", 2);
	my $colorMapStart = 	pack("S", 0);
	my $colorMapLength = 	pack("S", 0);
	my $colorMapBits =		pack("C", 0);
	my $xStart =			pack("S", 0);
	my $yStart =			pack("S", 0);
	my $width =				pack("S", $size[0]);
	my $height =			pack("S", $size[1]);
	my $bits =				pack("C", 24);
	my $descriptor =		pack("C", 0);
	my $black =				pack("CCC",0,0,0);

	print TGA $identSize;
	print TGA $palette;
	print TGA $imageType;
	print TGA $colorMapStart;
	print TGA $colorMapLength;
	print TGA $colorMapBits;
	print TGA $xStart;
	print TGA $yStart;
	print TGA $width;
	print TGA $height;
	print TGA $bits;
	print TGA $descriptor;
	
	for (my $v=$size[1]-1; $v>=0; $v--){
		for (my $u=0; $u<$size[0]; $u++){
			my $color = pack("CCC", ${$rgbaPixels{$v}}[$u*4+3], ${$rgbaPixels{$v}}[$u*4+2], ${$rgbaPixels{$v}}[$u*4+1]);
			print TGA $color;
		}
	}
	#for (my $i=0; $i<(@size[0]*@size[1]); $i++){
	#	print TGA $black;
	#}

	close(TGA);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READS TGA AND WRITES TO TABLE ARRAY  
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : readTGARGBA($filePath);
#requires %rgbaPixels;
#returns bit depth, width, and height
#it also stores the values in ABGR order because i think that's how tgas store it...
sub readTGARGBA{
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
			push(@{$rgbaPixels{$v}},$rgb[3],$rgb[2],$rgb[1],$rgb[0]);
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
	
	return($bits,$width,$height);
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

