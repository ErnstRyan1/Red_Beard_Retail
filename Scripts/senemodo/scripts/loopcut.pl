#perl
#ver 1.1
#(3-13-07 bugfix) : auto activate wasn't on.  Now it is.

if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )
{
	lx("select.loop");
}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )
{
	lx("select.ring");
}
lx("tool.set poly.loopSlice on");
lx("tool.flag poly.loopSlice auto 1");
lx("tool.attr poly.loopSlice edit [0]");
lx("tool.attr poly.loopSlice mode [0]");
lx("tool.attr poly.loopSlice curr [0]");
lx("tool.attr poly.loopSlice count [1]");
lx("tool.attr poly.loopSlice select 1");
