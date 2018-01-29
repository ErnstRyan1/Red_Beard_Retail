#perl
#ver 1.01
#This script uses modo's new edge split.

# 6-10-15 : changed the edge split syntax for modo 901

my $modoVer = lxq("query platformservice appversion ?");

if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
	lx("vert.split");
}elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
	if ($modoVer < 900)	{	lx("!!edge.split");				}
	else				{	lx("!!edge.split false 0.0");	}
	lx("select.drop polygon");
	lx("select.boundary");
}elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
	lx("vert.split");
}
