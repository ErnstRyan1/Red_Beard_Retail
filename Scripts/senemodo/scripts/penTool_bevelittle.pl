#perl
#author : Seneca Menard
#This script is to drop the pen tool, select the last vert, and turn on the move tool.

my $mainlayer = lxq("query layerservice layers ? main");
my $vertCount = lxq("query layerservice vert.n ? all") - 1;
lx("select.drop vertex");
lx("select.element $mainlayer vertex add $vertCount");
lx("tool.set xfrm.move on");
