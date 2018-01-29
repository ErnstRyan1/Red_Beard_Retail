#perl
#ver 0.8
#author : Seneca Menard
#This script is to select all the polys in the scene that use any of the same [[file textures]] as those on the materials of the currently selected polys.

my %clipIDTable;
my %maskPtagsFromClipIDTable;
my %ptagToTextureChildrenTable;

my $mainlayer = lxq("query layerservice layers ? main");
my @layers = lxq("query layerservice layers ? all");
my @polys = lxq("query layerservice polys ? selected");

#build the table that lets you get clipIDs from texture names
foreach my $layer (@layers){
	my $layerName = lxq("query layerservice layer.name ? $layer");
	my $textureCount = lxq("query layerservice texture.n ? all");

	for (my $i=0; $i<$textureCount; $i++){
		if (lxq("query layerservice texture.type ? $i") eq "imageMap"){
			my $name = lxq("query layerservice texture.name ? $i");
			my $clipIndex = lxq("query layerservice texture.clip ? $i");
			my $clipID = lxq("query layerservice clip.id ? $clipIndex");
			$clipIDTable{$name} = $clipID;
		}
	}
}

#build the table that lets you get the ptags of the materials that are using the texture
#...and...
#build the table that lets you get the texture names from each mask group
my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
for (my $i=0; $i<$txLayerCount; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
		my $maskID = lxq("query sceneservice txLayer.id ? $i");
		my @children = lxq("query sceneservice txLayer.children ? $i");
		my $ptag = lxq("query sceneservice channel.value ? ptag");

		foreach my $child (@children){
			my $type = lxq("query sceneservice txLayer.type ? $child");
			if (lxq("query sceneservice txLayer.type ? $child") eq "imageMap"){
				my $name = lxq("query sceneservice txLayer.name ? $child");
				my $clipID = $clipIDTable{$name} || popup("Doh. The ($name) texture's clip ID couldn't be found in the table");

				push(@{$maskPtagsFromClipIDTable{$clipID}},$ptag);
				push(@{$ptagToTextureChildrenTable{$ptag}},$name);
			}
		}
	}
}

#go through all the foreground layers and query the selected polys' ptags
my @polys = lxq("query layerservice selection ? poly");
my %polyTable;
foreach my $poly (@polys){
	$poly =~ tr/()//d;
	my @poly = split/,/,$poly;
	push(@{$polyTable{@poly[0]}},@poly[1]);
}

my %selectedPolyPtags;
foreach my $key (keys %polyTable){
	my $layerName = lxq("query layerservice layer.name ? $key");
	lxout("layerName = $layerName");

	foreach my $poly (@{$polyTable{$key}}){
		my $material = lxq("query layerservice poly.material ? $poly");
		$selectedPolyPtags{$material} = 1;
	}
}

#now report the materials that are using the textures that are applied to the selected polys
foreach my $ptag (keys %selectedPolyPtags){
	foreach my $textureName (@{$ptagToTextureChildrenTable{$ptag}}){
		my @masks = @{$maskPtagsFromClipIDTable{$clipIDTable{$textureName}}};

		lxout("The texture ($textureName) is used in these materials : @masks");
		foreach my $mask (@masks){
			lx("!!select.polygon add material face {$mask}");
		}
	}
}

#foreach my $key (keys %maskPtagsFromClipIDTable){
	#lxout("key = $key");
	#foreach my $id (@{$maskPtagsFromClipIDTable{$key}}){
		#lxout("   id = $id");
	#}
#}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");

sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

