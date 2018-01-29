#perl

#author : Seneca Menard
#version : 0.55
#TEMP : this doesn't work in 501 yet!

#this script is to turn on grid snap and set it to a fixed amount.
#example : @gridSnap.pl 16 : this turns on fixed grid snap and sets it to 16 units
#example : @gridSnap.pl 0 : this turns off grid snap

my $modoVer = lxq("query platformservice appversion ?");

if (@ARGV[0] == 0){
	if ($modoVer < 500){
		lx("tool.snapState false");
		lx("tool.set snap.grid off");
	}
	else{
		lx("tool.clearTask snap");
	}
}else{
	lxout("on");
	lx("tool.snapState true");
	lx("tool.set snap.grid on");
	lx("tool.attr snap.grid fixedGrid 1");
	lx("tool.attr snap.grid gridSize {@ARGV[0]}");
}