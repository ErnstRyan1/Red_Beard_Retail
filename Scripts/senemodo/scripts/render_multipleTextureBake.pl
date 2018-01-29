#perl

#This script is to do a multiple diffuse coefficient bake.  
#Just select a group and it'll do a bake per image inside that group

my $file = "C:\/Documents and Settings\/seneca.EDEN.000\/desktop\/";
my @masks = lxq("query sceneservice selection ? mask");
my @childrenList;
my $suffix = 0;

#find all children and hide 'em all.
foreach my $mask (@masks){
	my @children = lxq("query sceneservice item.children ? $mask");
	foreach my $child (@children){
		my $type = lxq("query sceneservice item.type ? $child");
		if ($type eq "imageMap"){
			push(@childrenList,$child);
			lx("select.subItem [$child] set textureLayer;render;environment");
			lx("shader.visibleSelected off");
		}
	}
}

#now do a diffuse coefficient bake for every single image.
for (my $i=0; $i<@childrenList; $i++){
	lx("select.subItem [@childrenList[$i]] set textureLayer;render;environment");
	lx("shader.visibleSelected off");
	lx("select.subItem [@childrenList[$i]] set textureLayer;render;environment");
	lx("shader.visibleSelected on");
	lx("select.vertexMap Texture txuv replace");

	my $trueName = $file."diff_".$suffix.".tga";
	while (1){
		if (-e $trueName){
			lxout("this file already exists! : $trueName");
			$suffix++;
			$trueName = $file."diff_".$suffix.".tga";
		}else{
			$suffix++;
			last;
		}
	}

	lx("bake.obj filename:[$trueName] format:[TGA] dist:[20]");
	if (lxres != 0){	die("The user hit the cancel button");	}
}

#now put the selection back
lx("select.drop item");
foreach my $mask (@masks){
	lx("select.subItem [$mask] add textureLayer;render;environment");
}