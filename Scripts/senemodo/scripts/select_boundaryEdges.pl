#perl
#boundary edge selector script

if		(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))	{
	lx("select.drop polygon");
	lx("select.type edge");
	lx("select.boundary");
}
elsif	(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{
	lx("select.drop polygon");
	lx("select.type edge");
	lx("select.boundary");
}
else{
	lx("select.drop edge");
	lx("select.type polygon");
	lx("select.boundary");
}
