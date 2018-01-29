#perl
#ver 1.08
#author : Seneca Menard

#This is just a sped up command to unhide geometry or items.  The default modo one is really slow because it's unhiding the Texture Group and that takes forever.

#SCRIPT ARGUMENTS :
#"namePatternCheck" : Use this if you want it to ignore unhiding items with certain names.  The patterns are hardcoded, but here they are (if name has 'delete' or 'temp' in it) (if name starts with 'del' or 'bak' or 'ref' or '_')

#(1-12-11 fix) : it now ignores groups that have the special names as well.
#(10-16-14 fix) : it used to hide layers with a name of "ref*".  now it hides layers called "ref" or "ref_" because it was hiding my layer called "reflection". :)

#args
foreach my $arg (@ARGV){
	if ($arg =~ /namePatternCheck/i)	{our $namePatternCheck = 1;}
}

if( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" )){
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		my $itemType = lxq("query sceneservice item.type ? $i");

		if (($itemType eq "mesh") || ($itemType eq "meshInst") || ($itemType eq "triSurf") || ($itemType eq "light") || ($itemType eq "sunLight") || ($itemType eq "replicator")){
			my $id = lxq("query sceneservice item.id ? $i");
			if ($namePatternCheck == 1){
				my $name = lxq("query sceneservice item.name ? $i");
				if (($name =~ /delete/i) || ($name =~ /^del_/i) || ($name =~ /^_/) || ($name =~ /^bak_/i) || ($name =~ /^ref$/i) || ($name =~ /^ref_/i)){
					lx("layer.setVisibility {$id} 0");
					next;
				}
			}
			lx("layer.setVisibility {$id} 1");
		}elsif ($itemType eq "groupLocator"){
			my $id = lxq("query sceneservice item.id ? $i");
			my $name = lxq("query sceneservice item.name ? $i");

			if ($name =~ /texture group/i){
				lx("layer.setVisibility {$id} 0");
				next;
			}elsif ($namePatternCheck == 1){
				my $name = lxq("query sceneservice item.name ? $i");
				if (($name =~ /delete/i) || ($name =~ /^del_/i) || ($name =~ /^_/) || ($name =~ /^bak_/i) || ($name =~ /^ref/i)){
					lx("layer.setVisibility {$id} 0");
					next;
				}
			}
			lx("layer.setVisibility {$id} 1");
		}
	}
}else{
	lx("unhide");
}





sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

