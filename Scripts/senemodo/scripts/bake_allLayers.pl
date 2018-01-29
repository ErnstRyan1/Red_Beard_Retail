#perl
#author : Seneca Menard
#This script will go through all the layers and perform a bake on them and save the TGA with the layer name to the desktop
#note : each layer must have a UV map that matches it's layer's name.

my $path = "C:\\Documents and Settings\\seneca.EDEN.000\\Desktop\\";
my @layers = lxq("query layerservice layers ? all");
foreach my $layer (@layers){
	my $name = lxq("query layerservice layer.name ? $layer");
	if ($name ne "courtyard"){
		my $filePath = $path.$name.".tga";
		my $id = lxq("query layerservice layer.id ? $layer");
		lx("select.subItem [$id] set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
		lx("select.vertexMap $name txuv replace");
		lx("bake filename:[$filePath] format:[TGA]") or die("User canceled the bake");
	}
}
