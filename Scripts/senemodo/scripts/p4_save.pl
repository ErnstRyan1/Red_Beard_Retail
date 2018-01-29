#perl
#ver 1.1
#author : Seneca Menard

#6-18-04 : hijacked to work with FBX files instead of LWO.

#this script will save your current scene and check out all the files that are related to this LXO (ie, all models that could be exported with teh freezemodel2 or exportFrozenHPModel scripts.

my $file = lxq("query sceneservice scene.file ? current");
my $runCounter=0;

my %itemTypes;
	$itemTypes{"mesh"} = 1;
	$itemTypes{"meshInst"} = 1;
	$itemTypes{"triSurf"} = 1;
	$itemTypes{"groupLocator"} = 1;

if (@ARGV[0] eq "checkoutAll"){
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		my $type = lxq("query sceneservice item.type ? $i");
		if ($itemTypes{$type} == 1){
			my $name = lxq("query sceneservice item.name ? $i");
			my $currentFileName = $file;
			$currentFileName =~ s/\\/\//g;
			#if ($currentFileName =~ ".lwo")		{$currentFileName =~ s/.lwo/_$name.lwo/;}
			#elsif($currentFileName =~ ".lxo")	{$currentFileName =~ s/.lxo/_$name.lwo/;}
			if ($currentFileName =~ ".lwo")		{$currentFileName =~ s/.lwo/_$name.fbx/;}
			elsif($currentFileName =~ ".lxo")	{$currentFileName =~ s/.lxo/_$name.fbx/;}
			if (-e $currentFileName){
				if (-w $currentFileName){
					lxout("[->] YES : the file is checked out ($currentFileName)");
				}else{
					lxout("[->] NO : the file is NOT checked out ($currentFileName)");
					checkout($currentFileName);
				}
			}
		}
	}
}

if (-e $file){
	if (-w $file){
		lx("scene.save");
	}else{
		checkout($file);
		lx("scene.save");
	}
}else{
	lx("scene.save");
}

sub checkout{
lxout("p4 edit \"@_[0]\"");
	system("p4 edit \"@_[0]\"");
}


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
