#perl
#SPLIT EVERY OTHER VERT ver 1.0
#AUTHOR : Seneca Menard
#This script will take every 2 verts that are selected and poly.split with them

my $mainlayer = lxq("query layerservice layers ? main");
my @verts =  lxq("query layerservice verts ? selected");

for(my $i=0; $i<@verts; $i+=2)
{
	lx("select.drop vertex");
	lx("select.element $mainlayer vertex add @verts[$i]");
	lx("select.element $mainlayer vertex add @verts[$i+1]");
	lx("poly.split");
}

lx("select.drop vertex");