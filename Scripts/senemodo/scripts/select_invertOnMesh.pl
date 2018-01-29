#perl
#ver 1.5
#author : Seneca Menard
#This script will select the inverted elements on the mesh you have selected.

my $mainlayer = lxq("query layerservice layers ? main");
if    ( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) {our $selMode = "verts"; our $selType = "vertex";}
elsif ( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ) {our $selMode = "edges"; our $selType = "edge";}
elsif ( lxq( "select.typeFrom {polygon;vertex;edge;item} ?" ) ) {our $selMode = "polys"; our $selType = "polygon";}
else  {die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

my @elems = lxq("query layerservice $selMode ? selected");
lxout("elems = @elems");
my %elemTable;
$elemTable{$_} = 1 for @elems;

lx("select.connect");
my @newElems = lxq("query layerservice $selMode ? selected");
lxout("newElems = @newElems");
foreach my $elem (@newElems){
	if ($elemTable{$elem} == 1){
		if ($selType ne "edge"){
			lx("select.element $mainlayer $selType remove $elem");
		}else{
			my @verts = split (/[^0-9]/, $elem);
			lx("select.element $mainlayer $selType remove @verts[1] @verts[2]");
		}
	}
}
