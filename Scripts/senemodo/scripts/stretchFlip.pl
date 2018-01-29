#perl
#BY: Seneca Menard
#version 1.0
#This script is to flip your selection along the axis you choose. Just append the axis you want to flip with : ie: "@stretchFlip.pl X"

my $modoVer = lxq("query platformservice appversion ?");
lx("tool.setAttr xfrm.stretch fact@ARGV[0] -1");
lx("tool.doApply");
if (lxq("tool.viewType ?") eq "xyz"){
	lx("poly.flip");
}