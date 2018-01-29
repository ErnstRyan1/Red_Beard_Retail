#perl
#ver 0.5
#author : Seneca Menard

#This script is to batch bake a lot of images to a model's self.  It's hardcoded to add the images to a certain material. I need to fix that hardcoded part if I want to use it again.
#Btw, this script was used on the huge rcbombbase door


#&fakeBake;
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FAKE BAKE SUB (this sub is to load up multiple images and do a bakeToSelfDiffuse on each
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub fakeBake{
	lx("dialog.setup fileOpenMulti");
	lx("dialog.title [Images you want to bake:]");
	lx("dialog.fileType image");
	lx("dialog.open");
	my @files = lxq("dialog.result ?");

	foreach my $file (@files){
		lx("select.subItem advancedMaterial013 set textureLayer;render;environment;mediaClip;locator");
		lx("texture.new {$file}");
		lx("texture.parent [mask012] [-1]");
		lx("texture.setUV fake");
		lx("texture.setUV bake");
		lx("select.vertexMap Texture txuv replace");

		my @words = split(/\\/,$file);
		my $filePath;
		for (my $i=0; $i<$#words; $i++){$filePath .= @words[$i]."\\";}
		$filePath .= "bake_".@words[-1];

		lx("bake filename:{$filePath} format:TGA");
	}
}
