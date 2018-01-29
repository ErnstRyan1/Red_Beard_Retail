#perl

#set the viewport to camera.
lx("select.viewport viewport:[0] frame:[2]");
lx("viewport.3dView cam");

lx("tool.set xfrm.move on");
lx("tool.doApply");
lx("tool.set xfrm.move off");

lx("scene.revert");
lx("render.visible");