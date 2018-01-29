#perl
#This will paste the geometry into the layer you're pointing at and then turn on the tack tool
if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) 		{	our $selType = "vertex";	}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{	our $selType = "edge";	}
else													{	our $selType = "polygon";	}

lx("select.type item");
lx("select.3DElementUnderMouse set");
lx("select.type $selType");

lx("select.drop $selType");
lx("select.invert");
lx("select.paste");
lx("select.invert");
lx("tool.set prop.tool on");