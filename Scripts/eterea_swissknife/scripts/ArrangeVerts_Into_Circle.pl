#!perl
#
#@ArrangeVerts_Into_Circle.pl (anchor) (triangulate)
# (radiusfrom) (float # as radius)
#
#---------------------------------
#A Script By Allan Kiipli (c) 2012
#---------------------------------
#
#Bug fix in vert.symmetric sentence.
#Bug fix in radius calculation when "radiusfrom" option is on.
#
#Now symmetry mode is supported.
#
#Arranges verts around selected vertexes into flat circles.
#Add "anchor" to "anchor" circle with every second vertex.
#If last anchor is "empty", first vertex in surroundverts is used.
#Without "anchor" first vertex in surroundverts is used.
#
#Add "triangulate" to triangulate surrounding polys around
#selected vertexes.
#
#Add "radiusfrom" to use distance to "anchor", as radius.
#For this to work, "anchor" is used as argument. Anchor
#vertex is used if second vertex is connected with edge,
#or is connected with edge after triangulation. Else it
#is skipped and first vertex is used to set radius.
#Else average radius from surrounding edges is used.
#
#If submitted numeric radius, numeric radius is used.

$anchor = 0;

$a_step = 1;

$triangulate = 0;

$radiusfrom = 0;

$radius2 = 0;

foreach $f(@ARGV)
{
 if($f eq "anchor")
 {
  $anchor = 1;
  $a_step = 2;
 }
 if($f eq "triangulate")
 {
  $triangulate = 1;
 }
 if($f eq "radiusfrom")
 {
  $radiusfrom = 1;
 }
 if($f =~ /(\d+\.?\d*)/)
 {
  $radius2 = $1;
 }
}

lxout("radiusfrom $radiusfrom");

lxout("radius2 $radius2");

lxout("anchor $anchor");

lxout("triangulate $triangulate");

$order = "xyz";

lxout("order $order");

$orient1 = 1;

lxout("orient1 $orient1");

sub call_sub
{
 $norm_X = $vnormal[0];
 $norm_Y = $vnormal[1];
 $norm_Z = $vnormal[2];

 $normX = $first_vec[0];
 $normY = $first_vec[1];
 $normZ = $first_vec[2];

 lxout("norm_X $norm_X norm_Y $norm_Y norm_Z $norm_Z");

 @axis = split(//, $order);

 # x.. the axis that aligns up and is free to rotate is in first position
 if($axis[0] eq "x")
 {
  # xyz first rotation is carried out with z axis, second with y axis
  # front-top-right
  #
  if($axis[1] eq "y")
  {

   $Z_rotation = atan2($norm_Y, $norm_X);
   $Y_rotation = -asin($norm_Z);

   if($orient1)
   {

    $Z1_rotation = -$Z_rotation;
    $Y1_rotation = -$Y_rotation;

    # 2d radius in front view

    $yx2d_r = sqrt($normY**2 + $normX**2);
    $z_turn1 = atan2($normY, $normX);
    $z_turn1 = -$z_turn1;

    # sum from two z rotations

    $z_turn2 = $Z1_rotation - $z_turn1;
    $new_y = sin($z_turn2) * $yx2d_r;
    $new_x = cos($z_turn2) * $yx2d_r;

    # 2d radius in top view

    $xz2d_r = sqrt($new_x**2 + $normZ**2);
    $y_turn1_2d = atan2($normZ, $new_x);
    $y_turn1_2d = -$y_turn1_2d;

    # sum from two angles in y axis

    $y_turn2 = $Y1_rotation + $y_turn1_2d;
    $new_z = sin(-$y_turn2) * $xz2d_r;

    # x axis in right view

    $X_rotation = atan2($new_z, $new_y);
   }
  }
  #
  # xzy first rotation is carried out with y axis, second with z axis
  # bottom-back-left
  #
  else
  {
   $Y_rotation = -atan2($norm_Z, $norm_X);
   $Z_rotation = asin($norm_Y);

   if($orient1)
   {

    $Y1_rotation = -$Y_rotation;
    $Z1_rotation = -$Z_rotation;

    # 2d radius in bottom view

    $zx2d_r = sqrt($normZ**2 + $normX**2);
    $y_turn1 = atan2($normZ, $normX);
    $y_turn1 = -$y_turn1;

    # sum from two y rotations

    $y_turn2 = $Y1_rotation + $y_turn1;
    $new_x = cos($y_turn2) * $zx2d_r;
    $new_z = sin($y_turn2) * $zx2d_r;

    # 2d radius in back view

    $xy2d_r = sqrt($new_x**2 + $normY**2);
    $z_turn1_2d = atan2($new_x, $normY);
    $z_turn1_2d = -$z_turn1_2d;

    # sum from two angles in z axis

    $z_turn2 = $Z1_rotation + $z_turn1_2d;
    $new_y = cos(-$z_turn2) * $xy2d_r;

    # x axis in left view

    $X_rotation = atan2($new_y, $new_z);
   }
  }
 }
 # y.. the axis that aligns up and is free to rotate is in first position
 if($axis[0] eq "y")
 {
  #
  # yxz first rotation is carried out with z axis, second with x axis
  # back-left-bottom
  #
  if($axis[1] eq "x")
  {
   $Z_rotation = -atan2($norm_X, $norm_Y);
   $X_rotation = asin($norm_Z);

   if($orient1)
   {

    $Z1_rotation = -$Z_rotation;
    $X1_rotation = -$X_rotation;

    # 2d radius in back view

    $xy2d_r = sqrt($normX**2 + $normY**2);
    $z_turn1 = atan2($normX, $normY);
    $z_turn1 = -$z_turn1;

    # sum from two z rotations

    $z_turn2 = $Z1_rotation + $z_turn1;
    $new_y = cos($z_turn2) * $xy2d_r;
    $new_x = sin($z_turn2) * $xy2d_r;

    # 2d radius in left view

    $yz2d_r = sqrt($new_y**2 + $normZ**2);
    $x_turn1_2d = atan2($new_y, $normZ);
    $x_turn1_2d = -$x_turn1_2d;

    # sum from two angles in x axis

    $x_turn2 = $X1_rotation + $x_turn1_2d;
    $new_z = cos(-$x_turn2) * $yz2d_r;

    # y axis in bottom view

    $Y_rotation = atan2($new_z, $new_x);
   }
  }
  #
  # yzx first rotation is carried out with x axis, second with z axis
  # right-front-top
  #
  else
  {
   $X_rotation = atan2($norm_Z, $norm_Y);
   $Z_rotation = -asin($norm_X);

   if($orient1)
   {

    $X1_rotation = -$X_rotation;
    $Z1_rotation = -$Z_rotation;

    # 2d radius in right view

    $zy2d_r = sqrt($normZ**2 + $normY**2);
    $x_turn1 = atan2($normZ, $normY);
    $x_turn1 = -$x_turn1;

    # sum from two x rotations

    $x_turn2 = $X1_rotation - $x_turn1;
    $new_z = sin($x_turn2) * $zy2d_r;
    $new_y = cos($x_turn2) * $zy2d_r;

    # 2d radius in front view

    $yx2d_r = sqrt($new_y**2 + $normX**2);
    $z_turn1_2d = atan2($normX, $new_y);
    $z_turn1_2d = -$z_turn1_2d;

    # sum from two angles in z axis

    $z_turn2 = $Z1_rotation + $z_turn1_2d;
    $new_x = sin(-$z_turn2) * $yx2d_r;

    # y axis in top view

    $Y_rotation = atan2($new_x, $new_z);
   }
  }
 }
 # z.. the axis that aligns up and is free to rotate is in first position
 if($axis[0] eq "z")
 {
  #
  # zxy first rotation is carried out with y axis, second with x axis
  # top-right-front
  #
  if($axis[1] eq "x")
  {
   $Y_rotation = atan2($norm_X, $norm_Z);

   $X_rotation = -asin($norm_Y);

   if($orient1)
   {
    $Y1_rotation = -$Y_rotation;
    $X1_rotation = -$X_rotation;

    # 2d radius in top view

    $xz2d_r = sqrt($normX**2 + $normZ**2);
    $y_turn1 = atan2($normX, $normZ);
    $y_turn1 = -$y_turn1;

    # sum from two y rotations

    $y_turn2 = $Y1_rotation - $y_turn1;
    $new_x = sin($y_turn2) * $xz2d_r;
    $new_z = cos($y_turn2) * $xz2d_r;

    # 2d radius in right view

    $yz2d_r = sqrt($normY**2 + $new_z**2);
    $x_turn1_2d = atan2($normY, $new_z);
    $x_turn1_2d = -$x_turn1_2d;

    # sum from two angles in x axis

    $x_turn2 = $X1_rotation + $x_turn1_2d;
    $new_y = sin(-$x_turn2) * $yz2d_r;

    # z axis in front view

    $Z_rotation = atan2($new_y, $new_x);
   }
  }
  #
  # zyx first rotation is carried out with x axis, second with y axis
  # left-bottom-back
  #
  else
  {
   $X_rotation = -atan2($norm_Y, $norm_Z);
   $Y_rotation = asin($norm_X);

   if($orient1)
   {

    $X1_rotation = -$X_rotation;
    $Y1_rotation = -$Y_rotation;

    # 2d radius in left view

    $zy2d_r = sqrt($normZ**2 + $normY**2);
    $x_turn1 = atan2($normY, $normZ);
    $x_turn1 = -$x_turn1;

    # sum from two x rotations

    $x_turn2 = $X1_rotation + $x_turn1;
    $new_z = cos($x_turn2) * $zy2d_r;
    $new_y = sin($x_turn2) * $zy2d_r;

    # 2d radius in bottom view

    $xz2d_r = sqrt($normX**2 + $new_z**2);
    $y_turn1_2d = atan2($new_z, $normX);
    $y_turn1_2d = -$y_turn1_2d;

    # sum from two angles in y axis

    $y_turn2 = $Y1_rotation + $y_turn1_2d;
    $new_x = cos(-$y_turn2) * $xz2d_r;

    # z axis in back view

    $Z_rotation = atan2($new_x, $new_y);
   }
  }
 }
 $X_degrees = $X_rotation * 180 / $pi;
 $Y_degrees = $Y_rotation * 180 / $pi;
 $Z_degrees = $Z_rotation * 180 / $pi;

 lx("tool.set xfrm.rotate on");
 lx("tool.setAttr center.auto cenX $vpos[0]");
 lx("tool.setAttr center.auto cenY $vpos[1]");
 lx("tool.setAttr center.auto cenZ $vpos[2]");

 lx("tool.setAttr axis.auto axis [0]");
 lx("tool.setAttr xfrm.rotate angle $X_degrees");
 lx("tool.doApply");

 lx("tool.setAttr axis.auto axis [1]");
 lx("tool.setAttr xfrm.rotate angle $Y_degrees");
 lx("tool.doApply");

 lx("tool.setAttr axis.auto axis [2]");
 lx("tool.setAttr xfrm.rotate angle $Z_degrees");
 lx("tool.doApply");

 lx("tool.set xfrm.rotate off");
}

sub arrangeVerts($)
{
 @polyList1 = ();
 @vertList1 = ();
 $vert = shift(@_);
 lxout("vert $vert");
 @vertList = lxq("query layerservice vert.vertList ? $vert");
 lxout("vertList @vertList");
 @polyList = lxq("query layerservice vert.polyList ? $vert");
 lxout("polyList @polyList");

 foreach $v(@vertList)
 {
  $edge = "($vert,$v)";
  @edgepolys = lxq("query layerservice edge.polyList ? $edge");
  lxout("edgepolys @edgepolys");
  @{$edgepolys{$v}} = @edgepolys;
 }

 foreach $p(@polyList)
 {
  @polyverts = lxq("query layerservice poly.vertList ? $p");
  lxout("polyverts @polyverts");
  push(@polyverts, $polyverts[0], $polyverts[1]);
  for($i = 1; $i < $#polyverts; $i ++)
  {
   if($polyverts[$i] == $vert)
   {
    $v1 = $polyverts[$i-1];
    $v2 = $polyverts[$i+1];
    lxout("v1 $v1");
    lxout("v2 $v2");
    @{$polyedges{$p}} = ($v1, $v2);
    last;
   }
  }
 }

 $p = $polyList[0];
 push(@polyList1, $p);
 $p1 = $p;

 while(@polyList1 < @polyList)
 {
  @polyedges = @{$polyedges{$p}};
  @edgepolys1 = @{$edgepolys{$polyedges[0]}};
  @edgepolys2 = @{$edgepolys{$polyedges[1]}};
  foreach $f(@edgepolys1, @edgepolys2)
  {
   if("@polyList1" !~ /\b$f\b/)
   {
    $p = $f;
    last;
   }
  }
  if($polyList1[$#polyList1] == $p)
  {
   if(@polyList1 > 1)
   {
    $p = $polyList1[0];
    @polyList1 = reverse(@polyList1); 
    @polyedges = @{$polyedges{$p}};
    @edgepolys1 = @{$edgepolys{$polyedges[0]}};
    @edgepolys2 = @{$edgepolys{$polyedges[1]}};
    foreach $f(@edgepolys1, @edgepolys2)
    {
     if("@polyList1" !~ /\b$f\b/)
     {
      $p = $f;
      last;
     }
    }   
   }
  }
  if($polyList1[$#polyList1] == $p)
  {
   foreach $p1(@polyList)
   {
    if("@polyList1" !~ /\b$p1\b/)
    {
     $p = $p1;
    }
   }
  }
  push(@polyList1, $p);
 }

 if($p1 != $polyList1[0])
 {
  @polyList1 = reverse(@polyList1);
 }

 foreach $p(@polyList1)
 {
  @polyedges = @{$polyedges{$p}};
  $v = $polyedges[0];
  if("@vertList1" =~ /\b$v\b/)
  {
   $v = $polyedges[1];
  }
  push(@vertList1, $v);
 }

 @{$data{"p"}} = @polyList1;
 @{$data{"v"}} = @vertList1;

 return %data;
}

sub triangulate($)
{
 $vert = shift(@_);
 lxout("vert $vert");
 @vertList = lxq("query layerservice vert.vertList ? $vert");
 lxout("vertList @vertList");
 @polyList = lxq("query layerservice vert.polyList ? $vert");
 lxout("polyList @polyList");
 @select = ();
 foreach $p(@polyList)
 {
  lxout("p $p");
  @polyverts = lxq("query layerservice poly.vertList ? $p");
  lxout("polyverts @polyverts");
  foreach $v(@polyverts)
  {
   if($v ne $vert)
   {
    if("@vertList" !~ /\b$v\b/)
    {
     push(@select, $v);
    }
   }
  }
 }
 foreach $v(@select)
 {
  lx("select.element $layerindex vertex set $vert");
  lx("select.element $layerindex vertex add $v");
  lx("poly.split");
  lxout("v $v");
 }
}

sub acos 
{
 atan2(sqrt(1 - $_[0] * $_[0]), $_[0]);
}

sub asin 
{
 atan2($_[0], sqrt(1 - $_[0] * $_[0]));
}

# 180 degrees

$pi = atan2(0, -1);

lxout("pi $pi");

# 90 degrees

$pi2 = atan2(1, 0);

lxout("pi2 $pi2");

# 45 degrees

$pi4 = atan2(1, 1);

lxout("pi4 $pi4");

$currentscene = lxq("query sceneservice scene.index ? current");

lxout("currentscene $currentscene");

$mainlayer = lxq("query layerservice layer.index ? main");

lxout("mainlayer $mainlayer");

$layerindex = lxq("query layerservice layer.index ? $mainlayer");

lxout("layerindex $layerindex");

@selectedVerts = lxq("query layerservice verts ? selected");

lxout("selectedVerts @selectedVerts");

$symmetry = lxq("select.symmetryState ?");

lxout("symmetry $symmetry");

if($symmetry ne "none")
{
 for($i = 0; $i < @selectedVerts; $i++)
 {
  $selectedVert = $selectedVerts[$i];
  $symmetryvertex = lxq("query layerservice vert.symmetric ? $selectedVert");
  if(($symmetryvertex ne "") && ($symmetryvertex ne $selectedVerts[$i-1]))
  {
   push(@symmetry, $symmetryvertex);
  }
 }
 lxout("symmetry @symmetry");

 foreach $v(@selectedVerts)
 {
  if("@symmetry" !~ /\b$v\b/)
  {
   push(@vert, $v);
  }
 }
 lxout("vert @vert");

 @selectedVerts = (@vert, @symmetry);
}

lx("tool.set actr.auto on 0");

lx("tool.viewType xyz");

lx("select.type vertex");

for($j = 0; $j < @selectedVerts; $j += $a_step)
{

 $selectedVert = $selectedVerts[$j];

 if($triangulate)
 {
  triangulate($selectedVert);
 }

 lx("select.drop vertex");
 $xcomp = 0;
 $ycomp = 0;
 $zcomp = 0;
 $radius = 0;

 @vpos = lxq("query layerservice vert.pos ? $selectedVert");
 lxout("vpos @vpos");
 %d = &arrangeVerts($selectedVert);
 @p = @{$d{"p"}};
 @v = @{$d{"v"}};
 lxout("p @p");
 lxout("v @v");
 @vnormal = lxq("query layerservice vert.normal ? $selectedVert");
 lxout("vnormal @vnormal");
 if($anchor)
 {
  $pusher = 0;
  @prepart = ();
  @postpart = ();
  $a_vert = $v[0];
  foreach $v(@v)
  {
   $a_vert1 = $selectedVerts[$j+1];
   if($v eq $a_vert)
   {
    $a_vert = $a_vert1;
   }
  }
  lxout("ANCHOR $a_vert");
  foreach $v(@v)
  {
   if($v eq $a_vert)
   {
    $pusher = 1;
   }
   if($pusher)
   {
    push(@prepart, $v);
   }
   else
   {
    push(@postpart, $v);
   }
  }
  @v = (@prepart, @postpart);
 }

 @firstpos = lxq("query layerservice vert.pos ? $v[0]");

 if($radius2 > 0.0)
 {
  $radius = $radius2;
 }
 elsif($radiusfrom && $anchor)
 {
  $xcomp = $firstpos[0] - $vpos[0];
  $ycomp = $firstpos[1] - $vpos[1];
  $zcomp = $firstpos[2] - $vpos[2];
  $radius = sqrt($xcomp**2 + $ycomp**2 + $zcomp**2);
 }
 else
 {
  for($i = 0; $i < @v; $i ++)
  {
   $v = $v[$i];
   @vertpos = lxq("query layerservice vert.pos ? $v");
  
   $xcomp = $vertpos[0] - $vpos[0];
   $ycomp = $vertpos[1] - $vpos[1];
   $zcomp = $vertpos[2] - $vpos[2];
   $radius1 = sqrt($xcomp**2 + $ycomp**2 + $zcomp**2);
   $radius += $radius1; 
  }
  $radius /= @v;
 }
 lxout("radius $radius");

 $first_vec[0] = $firstpos[0] - $vpos[0];
 $first_vec[1] = $firstpos[1] - $vpos[1];
 $first_vec[2] = $firstpos[2] - $vpos[2];
 $l = sqrt($first_vec[0]**2 + $first_vec[1]**2 + $first_vec[2]**2);
 $first_vec[0] /= $l;
 $first_vec[1] /= $l;
 $first_vec[2] /= $l;
 lxout("first_vec @first_vec");
 $division = ($pi*2)/@v;
 for($i = 0; $i < @v; $i ++)
 {
  $v = $v[$i];
  lx("select.element $layerindex vertex set $v");
  $y_comp = cos($division * $i) * $radius;
  $z_comp = sin($division * $i) * $radius;
  $x_comp = 0.0;
  $x_comp += $vpos[0];
  $y_comp += $vpos[1];
  $z_comp += $vpos[2];
  lx("vert.set x $x_comp");
  lx("vert.set y $y_comp");
  lx("vert.set z $z_comp");
 }
 lx("select.drop vertex");
 for($i = 0; $i < @v; $i ++)
 {
  $v = $v[$i];
  lx("select.element $layerindex vertex add $v");
 }
 call_sub();
}