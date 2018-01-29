#perl
#AUTHOR: Seneca Menard
#version 1.2 (it now has tool.reset in it so it always uses the default settings)

#(6-26-14) : if you're using 801, it now turns off the CONTINUOUS and CONNECT options of the bridge tool.

#When bridging edges:
     #-it deselects non border edges for you
     #-it does the bridge then drops the tool, so it's only one click.
     #-it also converts verts to edges for you so you can bridge in vert mode

#When bridging polygons:
     #-it's EXACTLY like the regular bridge tool.
     
my $modoVer = lxq("query platformservice appversion ?");

#just use normal bridge tool if in poly mode
if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )
	{
		lx("tool.set edge.bridge on");
	}
else
	{ #do special bridge if in edge mode  (and do an edge convert if in vert mode)
		my $vertMode;
		if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )
			{
			$vertMode = 1;
			lx("select.convert edge");
			}
		lx("select.edge remove poly more 1"); #will deselect non border edges
		lx("tool.set edge.bridge on");
		lx("tool.reset");
		if ($modoVer > 800){
			lx("tool.attr edge.bridge connect false");
			lx("tool.attr edge.bridge continuous false");
		}
		lx("tool.doApply");
		lx("tool.set edge.bridge off");
		if ($vertMode == 1)
		{
			lx("select.typeFrom {vertex;edge;polygon;item} [1]");
		}
	}
