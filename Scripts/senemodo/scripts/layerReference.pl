#perl
#ver 1.02
#This script will turn on the reference of the "main" (first selected) layer. You can also use it to turn off layer references if you use the "unreference" argument.

#script arguments :
#"unreference" : This will turn off any layer references

# (4-13-15 fix) : put in support for meshes, meshinstances, and triSurfs



if (@ARGV[0] eq "unreference"){
	lx("!!item.refSystem {}");
}else{
	my @selection = lxq("query sceneservice selection ? all");
	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if (($type eq "mesh") || ($type eq "meshInst") || ($type eq "triSurf")){
			lx("!!item.refSystem {$id}");
			last;
		}
	
	}
	
}
