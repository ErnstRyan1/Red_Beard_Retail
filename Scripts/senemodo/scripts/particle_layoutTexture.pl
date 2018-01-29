#perl
#ver 1.2
#author : Seneca Menard
#This script is for taking a series of particle images and laying them out in a horizontal row, specifically for DOOM3/RAGE's particle animation system.

#(7-19-07-fix) : noticed I was importing an unsorted image list on accident.  oops!!


lx("scene.new");
my $mainlayer = lxq("query layerservice layers ? main");
lx("dialog.setup fileOpenMulti");
lx("dialog.fileType image");
lx("dialog.title {Animation images to load:}");
lx("dialog.open");
my @files = lxq("dialog.result ?");
my @list = sort {
	($c) = ($a =~ /(.*[^0-9])/);
	($d) = ($b =~ /(.*[^0-9])/);
	if ($c eq $d) {   # Last names are the same, sort on first name
		($c) = ($a =~ /([0-9]+$)/);
		($d) = ($b =~ /([0-9]+$)/);
		if ($c > $d)		{return 1;}
		elsif ($c == $d)	{return 0;}
		else				{return -1;}
	}else{
		return $c cmp $d;
	}
} @files;



#find the image size of the first image
lx("clip.addStill {@files[0]}");
my @clips = lxq("query layerservice clips ? all");
if (@clips == 0){die("Apparently the image load failed for this image : @files[0]");}
my $clipInfo = lxq("query layerservice clip.info ? 0");
my @clipInfo =  split(/\s/,$clipInfo);
@clipInfo[1] =~ s/[^0-9]//g;
@clipInfo[2] =~ s/[^0-9]//g;
lxout("@clipInfo[1] @clipInfo[2]");

#build the polys
for (my $i=0; $i<@list; $i++){
	my $pos = $i * @clipInfo[1];
	lxout("$i : pos=$pos : file=@list[$i]");

	lx("tool.set prim.cube on");
	lx("tool.reset");
	lx("tool.setAttr prim.cube cenX $pos");
	lx("tool.setAttr prim.cube cenY 0");
	lx("tool.setAttr prim.cube cenZ 0");
	lx("tool.setAttr prim.cube sizeX @clipInfo[1]");
	lx("tool.setAttr prim.cube sizeY @clipInfo[2]");
	lx("tool.setAttr prim.cube sizeZ 0");
	lx("tool.doApply");
	lx("tool.set prim.cube off");

	lx("select.element $mainlayer polygon set $i");
	lx("material.new name:[$i] assign:[1]");

	#find the ID of the material group I just created.
	my $newMaterialID;
	my $txLayers = lxq("query sceneservice txLayer.N ?");
	for (my $u=0; $u<$txLayers; $u++){
		if (lxq("query sceneservice txLayer.type ? $u") eq "mask"){
			if (lxq("query sceneservice channel.value ? ptag") eq $i){
				$newMaterialID = lxq("query sceneservice txLayer.id ? $u");
				last;
			}
		}
	}

	#add the texture.
	lx("texture.new [@list[$i]]");
	lx("texture.parent [$newMaterialID] [-1]");
	lx("item.channel imageMap\$alpha 0");
	lx("select.type polygon");
	lx("uv.rotate");
	lx("uv.rotate");
	lx("uv.rotate");
}

lx("select.all");


#now select all materials and set their diffuse to 100% (and set the render output to be final color)
my $txLayers = lxq("query sceneservice txLayer.N ?");
my @materials;
for (my $i=0; $i<$txLayers; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "advancedMaterial"){
		push(@materials,lxq("query sceneservice txLayer.id ? $i"));
	}
}

for (my $i=0; $i<$txLayers; $i++){
	if ((lxq("query sceneservice txLayer.type ? $i") eq "renderOutput") && (lxq("query sceneservice txLayer.name ? $i") eq "Final Color Output")){
		my $renderOutputID = lxq("query sceneservice txLayer.id ? $i");
		lx("!!select.subItem {$renderOutputID} set textureLayer;render;environment;mediaClip;locator");
		lx("!!shader.setEffect mat.diffuse");
		last;
	}
}

for (my $i=0; $i<@materials; $i++){lx("select.subItem {@materials[$i]} add textureLayer;render;environment;mediaClip;locator");}
lx("item.channel advancedMaterial\$diffAmt 1.0");




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

