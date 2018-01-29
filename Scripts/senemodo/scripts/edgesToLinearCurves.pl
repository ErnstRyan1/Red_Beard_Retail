#perl
#author : Seneca Menard
#ver 1.0
#This script will convert your selected edges into 2pt curves in a new layer.

my $mainlayer = lxq("query layerservice layers ? main");
my @edges = lxq("query layerservice edges ? selected");
lx("select.drop vertex");

foreach my $edge (@edges){
	$edge =~ s/[\(\)]//g;
	my @verts = split(/,/, $edge);
	lx("select.element $mainlayer vertex set @verts[0]");
	lx("select.element $mainlayer vertex add @verts[1]");
	lx("poly.makeCurveOpen");
}

lx("select.drop polygon");
lx("select.polygon add type curve 2");
lx("select.cut");
lx("layer.newItem mesh");
lx("select.paste");