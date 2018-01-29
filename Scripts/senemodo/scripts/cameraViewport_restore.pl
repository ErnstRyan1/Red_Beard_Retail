#perl
#author : Seneca Menard
#ver 1.1

#This script will ask the render node in the shader tree which camera is the current render camera, then convert the viewport that the mouse is over into a camera viewport using that camera.

#10-10-14 : rewrote it to work with 801


my $renderCameraID = lxq("render.camera ?");
lx("!!view3d.projection cam");
lx("!!view3d.cameraItem {$renderCameraID}");
