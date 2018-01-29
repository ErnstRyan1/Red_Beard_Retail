#perl
#This script will copy the selected object (mesh=instance) (instance=duplicate) and copy over it's translations to the new object.
#(3-2-12 fix) : 601 changed item.duplicate syntax so it's now updated


my $pi=3.1415926535897932384626433832795;
my $itemCount = lxq("query sceneservice item.n ?");

#remember tool
lx("!!tool.makePreset name:tool.previous");
lx("!!tool.set tool.previous off");


for (my $i=0; $i<$itemCount; $i++){
	my $id = lxq("query sceneservice item.id ? $i");
	my $selected = lxq("query sceneservice item.isSelected ? $i");
	my $name = lxq("query sceneservice item.name ? $i");
	my $type = lxq("query sceneservice item.type ? $i");

	lxout("selected = $selected <> name=$name <> type=$type");

	if ( ($selected == 1) && (($type eq "mesh") || ($type eq "meshInst")) ){
		my @pos =		lxq("query sceneservice item.pos ? $id");
		my @scale =	lxq("query sceneservice item.scale ? $id");
		my @rot =		lxq("query sceneservice item.rot ? $id");
		@rot = 			( (@rot[0]*180)/$pi , (@rot[1]*180)/$pi , (@rot[2]*180)/$pi);

		#make an instance of mesh
		if ($type eq "mesh"){
			lx("item.duplicate instance:[1]");
		}
		#duplicate instance
		else{
			lx("item.duplicate instance:[0] type:[locator]");
		}

		#set the transforms of the parent
		lx("item.channel locator\$pos.X @pos[0]");
		lx("item.channel locator\$pos.Y @pos[1]");
		lx("item.channel locator\$pos.Z @pos[2]");

		lx("item.channel locator\$rot.X @rot[0]");
		lx("item.channel locator\$rot.Y @rot[1]");
		lx("item.channel locator\$rot.Z @rot[2]");

		lx("item.channel locator\$scl.X @scale[0]");
		lx("item.channel locator\$scl.Y @scale[1]");
		lx("item.channel locator\$scl.Z @scale[2]");

		lx("tool.set xfrm.transform on");
		last;  #TEMP TEMP
	}
}

#turn the tool back on
lx("!!tool.set tool.previous on");