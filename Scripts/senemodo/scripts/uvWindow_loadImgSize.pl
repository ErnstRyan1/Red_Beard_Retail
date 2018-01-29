#perl
#ver 1.0

#This script will select an image of a certain size if it's already loaded, or load it if needed.  it's for quickly displaying texel sizes when uv mapping (specifically for when creating lightmaps)


#script arguments
foreach my $arg (@ARGV){
	if		($arg == 8)		{	our $size = 8;		}
	elsif	($arg == 16)	{	our $size = 16;		}
	elsif	($arg == 32)	{	our $size = 32;		}
	elsif	($arg == 64)	{	our $size = 64;		}
	elsif	($arg == 128)	{	our $size = 128;	}
	elsif	($arg == 256)	{	our $size = 256;	}
	elsif	($arg == 512)	{	our $size = 512;	}
}

#cancel script if size cvar wasn't determined
if ($size < 1){	die("The script didn't find an image size argument (like 16 or 32 or 512) and so it's being cancelled");}

#find clip and select it
my $foundClip = -1;
my $clipCount = lxq("query layerservice clip.n ? all");

for (my $i=0; $i<$clipCount; $i++){
	my $filename = lxq("query layerservice clip.file ? $i");
	if ($filename =~ /$size\.[a-zA-Z]/i){
		$foundClip = $i;
		my $id = lxq("query layerservice clip.id ? $i");
		lx("select.subItem {$id} set mediaClip");
		lxout("selected");
		return;
	}
}


#if no clip is found, then load it.
if ($foundClip == -1){
	my %imageSizeFiles;
		$imageSizeFiles{8} = "E:\/senFiles\/seneArt\/textures\/8.jpg";
		$imageSizeFiles{16} = "E:\/senFiles\/seneArt\/textures\/16.jpg";
		$imageSizeFiles{32} = "E:\/senFiles\/seneArt\/textures\/32.jpg";
		$imageSizeFiles{64} = "E:\/senFiles\/seneArt\/textures\/64.jpg";
		$imageSizeFiles{128} = "E:\/senFiles\/seneArt\/textures\/128.jpg";
		$imageSizeFiles{256} = "E:\/senFiles\/seneArt\/textures\/256.jpg";
		$imageSizeFiles{512} = "E:\/senFiles\/seneArt\/textures\/512.jpg";

	lx("clip.addStill {$imageSizeFiles{$size}}");
	lxout("loaded");
}

