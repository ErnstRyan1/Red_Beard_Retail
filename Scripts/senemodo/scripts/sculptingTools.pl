#perl
#ver 0.5
#author : Seneca Menard
#This script will be for sculpting shortcuts.  Right now the only shortcut is so you can use the clips window to select your brushes instead of their usual browser. What's nice about this is you can load infinite clips into the clips window all at once..

#script arguments :
# "selectClipBrush" : This will apply the last selected clip to the sculpt tool.





foreach my $arg (@ARGV){
	if ($arg =~ /selectClipBrush/i)		{	&selectClipBrush;	}
}



sub selectClipBrush{
	my $clips = lxq("query layerservice clip.n ?");
	my @selectedClips;
	for (my $i=0; $i<$clips; $i++){
		if (lxq("query sceneservice clip.isSelected ? $i") == 1){
			push(@selectedClips,$i);
		}
	}
	my $fullFileName = lxq("query layerservice clip.file ? @selectedClips[-1]");
	#my $test = "tool.attr brush.preset type {brush:" . $fullFileName . "}";
	#lxout("test = $test");
	#lx("$test");
	lxout("fullFileName = $fullFileName");
	lx("tool.attr brush.preset type {brush:$fullFileName}");
	#lx("!!tool.setAttr brush.preset type {brush:$fullFileName}");
}
