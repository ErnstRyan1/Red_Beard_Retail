#perl
#ver 1.0
#author : Seneca Menard
#This script is to triple all the selected polys in their creation order so that pipes will look correct and not get bad speculars.

my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my @spentPolyList;
lx("select.drop polygon");
lx("select.drop vertex");
foreach my $poly (@polys){
	my @verts = lxq("query layerservice poly.vertList ? $poly");
	lx("!!select.element $mainlayer vertex add @verts[0]");
	lx("!!select.element $mainlayer vertex add @verts[2]");
}
lx("!!poly.split");
lx("select.type polygon");
