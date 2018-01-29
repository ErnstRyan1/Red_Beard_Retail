#perl
#author : Seneca Menard
#This script is to adjust brightness/contrast for the GREYSCALE color vmap on all visible verts.

my $mainlayer = lxq("query layerservice layers ? main");
my @verts = lxq("query layerservice verts ? visible");
my $foundVmap = selectColorVmap();
my $vmapName = lxq("query layerservice vmap.name ? $foundVmap");
lxout("found vmapName = $vmapName");
my $colorMode = quickDialog("0=Black\\White\n1=White\n2=Black",integer,0,0,2);
my $multiplier = quickDialog("Multiplier value :\nhalf contrast = .5\ndouble contrast = -1",float,.5,-50,50);

lx("select.type vertex");
lx("tool.set vertMap.setColor on");
foreach my $vert (@verts){
	my @vmapValue = lxq("query layerservice vert.vmapValue ? $vert");
	if (($colorMode == 0) || (($colorMode == 1)&&(@vmapValue[0] > 0.5)) || (($colorMode == 2)&&(@vmapValue[0] < 0.5))){
		my $value = @vmapValue[0] + ((@vmapValue[0] - 0.5) * ($multiplier*-1));
		lx("select.element $mainlayer vertex set $vert");
		lx("tool.attr vertMap.setColor Color {$value $value $value}");
		lx("tool.doApply");
	}
}
lx("tool.set vertMap.setColor off");
lx("select.drop vertex");



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 1){
			lx("user.defDelete seneTempDialog");
		}
		lx("user.defNew name:[seneTempDialog] type:{$_[1]} life:[momentary]");		
		lx("user.def seneTempDialog username [$_[0]]");
		if (($_[3] != "") && ($_[4] != "")){
			lx("user.def seneTempDialog min [$_[3]]");
			lx("user.def seneTempDialog max [$_[4]]");
		}
		lx("user.value seneTempDialog [$_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT THE PROPER COLOR VMAP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selectColorVmap{
	my @colorVmaps;
	for (my $i=0; $i<lxq("query layerservice vmap.n ? all"); $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "rgb"){
			if (lxq("query layerservice vmap.selected ? $i") == 1){
				my $name = lxq("query layerservice vmap.name ? $i");
				lxout("[->] : Not selecting any color vmaps : $name");
				return($i);
			}else{
				push(@colorVmaps,lxq("query layerservice vmap.name ? $i"));
			}
		}
	}

	if (@colorVmaps == 1){
		lxout("[->] : Only one color vmap exists, so I'm selecting it : @colorVmaps[0]");
		lx("select.vertexMap @colorVmaps[0] rgb replace");
		my $index = lxq("query layerservice vmap.index ? @colorVmaps[0]");
		return($index);
	}elsif (@colorVmaps > 1){
		my $phrase = "Which one ? :";
		for (my $i=0; $i<@colorVmaps; $i++){
			$phrase .= "\n".$i." = ".@colorVmaps[$i];
		}
		my $selectedVmap = quickDialog($phrase,integer,@colorVmaps[0],0,$#colorVmaps);
		if ($selectedVmap < 0){$selectedVmap = 0;}
		elsif	($selectedVmap > $#colorVmaps){$selectedVmap = $#colorVmaps;}
		lx("select.vertexMap [@colorVmaps[$selectedVmap]] rgb replace");
		lxout("[->] : More than one color vmaps, so the user had to choose : $selectedVmap");
		my $index = lxq("query layerservice vmap.index ? [@colorVmaps[$selectedVmap]]");
		return($index);
	}else{
		lxout("[->] : No color vmaps existed, so I had to create one : Color");
		lx("vertMap.new Color rgb true {0.5 0.5 0.5} 1.0");
		my $lastVmap = lxq("query layerservice vmap.n ? all")+1;
		return($lastVmap);
	}
}