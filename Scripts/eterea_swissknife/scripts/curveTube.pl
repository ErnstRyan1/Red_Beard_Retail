#perl
# curveTube.pl
# Dion Burgoyne 5-26-06
@args = @ARGV;
@layers = lxq("query layerservice layers ? fg");
if ($#args < 0)
  {
    @args = (3,7,.08);
  }
foreach $layer(@layers)
  {
    lx("select.drop polygon");
    lx("select.polygon add type curve 2");
    @polys = lxq("query layerservice polys ? selected");
    foreach $poly(@polys)
      {
        @verts = lxq("query layerservice poly.vertlist ? $poly");
        foreach $vert(@verts)
          {
            @vertpos = lxq("query layerservice vert.pos ? $vert");
            $arraybuild = "curve$poly";
            push(@$arraybuild, "@vertpos");
          }
      }
    lx("select.drop polygon");
    foreach $poly(@polys)
      {
        $arraybuild = "curve$poly";
        @loop = @$arraybuild;
        @topvert = split(/ /,$loop[0]);
        lx("tool.set prim.tube on");
        lx("tool.setAttr prim.tube mode add");
        lx("tool.setAttr prim.tube sides $args[0]");
        lx("tool.setAttr prim.tube segments $args[1]");
        lx("tool.setAttr prim.tube radius $args[2]");
        lx("tool.setAttr prim.tube number 1");
        lx("tool.setAttr prim.tube ptX $topvert[0]");
        lx("tool.setAttr prim.tube ptY $topvert[1]");
        lx("tool.setAttr prim.tube ptZ $topvert[2]");
        
        for($i=1;$i<$#loop;$i++)
          {
            $tubevert = $i+1;
            @thisvert = split(/ /,$loop[$i]);
            lx("tool.setAttr prim.tube number $tubevert");
            lx("tool.setAttr prim.tube ptX $thisvert[0]");
            lx("tool.setAttr prim.tube ptY $thisvert[1]");
            lx("tool.setAttr prim.tube ptZ $thisvert[2]");
          }
        @lastvert = split(/ /,$loop[$#loop]);
        $lastvert = $#loop+1;
        lx("tool.setAttr prim.tube number $lastvert");
        lx("tool.setAttr prim.tube ptX $lastvert[0]");
        lx("tool.setAttr prim.tube ptY $lastvert[1]");
        lx("tool.setAttr prim.tube ptZ $lastvert[2]");
        lx("tool.doApply");
        lx("tool.set prim.tube off");
      }
  }
