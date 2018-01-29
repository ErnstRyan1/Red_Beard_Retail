#perl
#ver. 1.0
#author : Seneca Menard
#This script will either drop the current tool or turn the last one back on if none were on at the moment.

my $selModeOriginal = returnSelMode();
lx("select.nextMode");
if (returnSelMode() ne $selModeOriginal){
	lx("select.type $selModeOriginal");
	lx("tool.set .last on");
}

sub returnSelMode{
	if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )		{return "vertex";	}
	elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{return "edge";		}
	elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{return "polygon";	}
	elsif( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ) )	{return "item";		}
	else															{die("You're not in vert, edge, polygon, or item mode so script is being canceled");}
}
