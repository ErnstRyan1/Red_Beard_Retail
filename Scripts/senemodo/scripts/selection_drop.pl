#perl
#author : Seneca Menard
#ver. 1.0
#This script will drop your current selection. (works in vert,edge,poly, and item selection modes)

if 		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) {
	lx("!!select.drop vertex");
}elsif	( lxq( "select.typeFrom {edge;item;vertex;polygon} ?" ) ) {
	lx("!!select.drop edge");
}elsif	( lxq( "select.typeFrom {polygon;vertex;edge;item} ?" ) ) {
	lx("!!select.drop polygon");
}else{
	lx("!!select.drop item");
}
