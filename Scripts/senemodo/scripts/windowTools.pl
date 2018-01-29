#perl
#ver 0.1
#author : Seneca Menard

#SCRIPT ARGUMENTS
foreach my $arg (@ARGV){
	if ($arg eq "simulationWindows")	{	spawnWindows(simulation);	}
}

#SPAWN WINDOWS SUBROUTINE (spawns the 4 windows i like when doing unity work for fates forgiven)
sub spawnWindows{
	my $layoutCount1 = lxq("layout.count ?");

	lx("!!layout.createOrClose cookie:[6] title:[UV Window] layout:[senUVWindow] x:[0] y:[5] width:[1265] height:[730] persistent:[0]");
	lx("!!layout.createOrClose cookie:[7] title:[Clips] layout:[sen_multiClip] x:[1280] y:[5] width:[1280] height:[730] persistent:[0]");
	lx("!!layout.createOrClose cookie:[12] title:[Camera] layout:[camera] x:[0] y:[800] width:[1265] height:[753] persistent:[0]");
	lx("!!layout.createOrClose cookie:[1] title:[Preview] layout:[] x:[1280] y:[800] width:[1280] height:[753] persistent:[0]");

	my $layoutCount2 = lxq("layout.count ?");

	if ($layoutCount2 > $layoutCount1){
		lx("viewport.restore \"\" false primitive");
	}
}

