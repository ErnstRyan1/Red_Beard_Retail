#perl

if(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))
{
	lx("attr.formPopover {31825971949:sheet}");
}
elsif(lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ))
{
	lx("attr.formPopover {11100973566:sheet}");
}
elsif(lxq( "select.typeFrom {polygon;vertex;edge;item} ?" ))
{
	lx("attr.formPopover {65747972865:sheet}");
}