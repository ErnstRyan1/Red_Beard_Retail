#perl
#ver 1.01
#author : Seneca Menard

#This script is to toggle the viewport between the 3 ortho views in wireframe and to perspective in textured.

lx("select.viewport fromMouse:1");
my $viewport = lxq("query view3dservice mouse.view ?");
my $projType = lxq("view3d.projection type:?");

if		($projType eq "top"){
	lx("view3d.projection fnt");
	lx("view3d.shadingStyle wire");
	lx("viewport.3dView background:wire");
}elsif	($projType eq "fnt"){
	lx("view3d.projection rgt");
	lx("view3d.shadingStyle wire");
	lx("viewport.3dView background:wire");
}elsif	($projType eq "rgt"){
	lx("view3d.projection psp");
	lx("view3d.shadingStyle tex");
	lx("viewport.3dView background:flat");
}else{
	lx("view3d.projection top");
	lx("view3d.shadingStyle wire");
	lx("viewport.3dView background:wire");
}

lx("!!viewport.fitSelected");