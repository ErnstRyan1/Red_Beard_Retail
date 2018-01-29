#!perl
#
#@EdgeDivide4.pl (optimize/digit)
#
#--------------------------------------
#A Script By Allan Kiipli (c) 2010 2012
#--------------------------------------
#
#Now divides also bezier curve edges.
#Add multiply of three as digit to place inbetween
#triples(handles). Like: @EdgeDivide4.pl 3
#10:13 24.09.2012
#
#Now closed curves are closed. 11:20 23.09.2012
#
#Added fglayer check outside not optimized loop.
#This solves not the multilayer case, but skips it
#leaving the maps unrecreated for other layers.
#12:23 4.01.2012
#Development in progress..added uv-s evaluation
#..added normals.. added morph.. added rgb..
#..added rgba.. added subdiv evaluation.. added
#..weights. Added discos for rgba.. Added edgepick..
#..Fixed rgba map
#Note: when unused vmaps exist, and over multiple
#layers, they may mess up others..
#Divides selected edges with a vertex at middle.
#New verts calculate uv, morph, weight, rgb
#and rgba data, interpolating between old edges
#ends. Also normal map is reconstructed.
#And also edges creasing, (subdivision weight).
#Subd data is connected to edges and handled per edge.
#rgb maps try to evaluate also discontinuous.
#When multiple fg layers are used, uv maps may
#not yield. Only with some selected edges it
#yields over few layers. Also normals may yield
#occasionally incorrectly. Fix this, by tripling
#and reunifying these polys manually.
#Some tests show that EdgeDivide2.pl works also
#with curves, dividing selected curve segments
#as edges, distributing the change over morph
#and weight type maps.
#When 'optimize' is on, vMaps are not calculated,
#only new polys and verts are placed.
#There is attempt to restore materials, but
#again with more than one edge it may misyield.
#Restoring materials happens also when
#'optimize' is used. For materials polys are
#sorted to place more surrounded polys last.
#Also for every edge two edges are selected
#to simulate edges original selection.
#This happens across layers. Add digit number to change
#number of divisions per edge. These divisions are
#then iterpolated into vmaps in times of division.
#Also when you have a spot morph, where all vcoords
#per vert point to zero, you miss interpolation.
#Position vmap is used to support zerosized spot
#type vmaps (absolute morphs).
#EdgeDivide4.pl detects poly types connected to
#edges, else it is set to 'auto'.
#You could edgedivide curves, (but not patches).
#If curves border patches, unweld them first.

$appversion = lxq("query platformservice appversion ?");

lxout("$appversion");

if($appversion <= 401)
{
 $texture_type = "1";
 $normal_type = "1";
 $weight_type = "1";
 $morph_type = "1";
 $auto = "face";
}
else
{
 $texture_type = "texture";
 $normal_type = "normal";
 $weight_type = "weight";
 $morph_type = "morph";
 $auto = "auto";
}

$currentscene = lxq("query sceneservice scene ? current");

lxout("currentscene $currentscene");

@selection = lxq("query layerservice selection ? edge");

lxout("selection @selection");

if(!@selection)
{
 die("no edges");
}

$optimize = 0;

if("@ARGV" =~ /\boptimize\b/)
{
 $optimize = 1;
}

$pointscount = 1;

if("@ARGV" =~ /(\d+)/)
{
 $pointscount = $1;
}

$d = $pointscount + 1;

lx("select.type edge");

@fglayers = lxq("query layerservice layers ? fg");

lxout("fglayers @fglayers");

if(!$optimize)
{
 @vMaps = lxq("query layerservice vmaps ? all");
 lxout("vMaps @vMaps");

 foreach $fglayer(@fglayers)
 {
  foreach $vMap(@vMaps)
  {
   $layer = lxq("query layerservice vmap.layer ? $vMap");
   lxout("layer $layer");
   $layer ++;
   if($fglayer == $layer)
   {
    push(@{$vMapsLayer{"$layer"}}, $vMap);
   }
  }
 }
}

foreach $fg(@fglayers)
{
 lx("select.layer $fg");
 $layername = lxq("query layerservice layer.name ? $fg");
 lxout("layername $layername");
 $layername =~ s/[()]//g;
 lx("item.name {$layername}");
}

$lxSymmetry = lxq("select.symmetryState ?");

lxout("lxSymmetry $lxSymmetry");

lx("select.symmetryState none");

lx("select.drop polygon");

if($optimize)
{
 foreach $fglayer(@fglayers)
 {
  if(!@selection)
  {
   last;
  }
  @indicated = ();
  %indicated = ();
  lx("select.layer $fglayer");
  $layerindex = lxq("query layerservice layer.index ? $fglayer");
  %edgePos = ();
  @edges = ();
  @remain = ();
  %polygonhash = ();
  foreach $selected(@selection)
  {
   $selected =~ /\((\d+),(\d+),(\d+)\)/;
   if($1 == $fglayer)
   {
    push(@edges,"\($2,$3\)");
   }
   else
   {
    push(@remain,$selected);
   }
  }
  lxout("edges @edges");
  lxout("remain @remain");
  @selection = ();
  @selection = @remain;
  @Polys = ();
  foreach $edges(@edges)
  {
   @buf = split(/\,/,$edges);
   $buf[0] =~ s/\(//;
   $buf[1] =~ s/\)//;
   lxout("buf @buf");
   @vertpos1 = lxq("query layerservice vert.pos ? $buf[0]");
   @vertpos2 = lxq("query layerservice vert.pos ? $buf[1]");
   @{$edgePos{"$buf[0] $buf[1]"}} = ();
   @{$edgePos{"$buf[1] $buf[0]"}} = ();
   @pos = @vertpos1;
   @step = (($vertpos1[0]-$vertpos2[0])/$d, ($vertpos1[1]-$vertpos2[1])/$d, ($vertpos1[2]-$vertpos2[2])/$d);
   for($i = 0; $i < $pointscount; $i ++)
   {
    @pos = ($pos[0]-$step[0], $pos[1]-$step[1], $pos[2]-$step[2]);
    unshift(@{$edgePos{"$buf[0] $buf[1]"}}, @pos);
    push(@{$edgePos{"$buf[1] $buf[0]"}}, @pos);
   }
   @polys = lxq("query layerservice edge.polyList ? $edges");
   lxout("polys @polys");
   foreach $poly(@polys)
   {
    $polytype = lxq("query layerservice poly.type ? $poly");
    lxout("polytype $polytype");
    $polygonhash{$poly} = $polytype;
   }
  }
  @Polys = sort{$polygonhash{$a} <=> $polygonhash{$b}} keys(%polygonhash);
  lxout("Polys @Polys");
  if(!@Polys)
  {
   next;
  }
  foreach $poly(@Polys)
  {
   $material{$poly} = lxq("query layerservice poly.material ? $poly");
   lxout("material $poly $material{$poly}");
  }
  foreach $poly(@Polys)
  {
   @verts = lxq("query layerservice poly.vertList ? $poly");
   lxout("verts @verts");
   $polytype = $polygonhash{$poly};
   $close = "";
   if($polytype eq "curve")
   {
    if(@verts > 2)
    {
     if($verts[0]==$verts[$#verts-2] && $verts[1]==$verts[$#verts-1] && $verts[2]==$verts[$#verts])
     {
      shift(@verts);
      pop(@verts);
      pop(@verts);
      lxout("closed curve");
      $close = "true";
     }
    }
   }
   if($polytype eq "bezier")
   {
    if(@verts > 4)
    {
     if($verts[0]==$verts[$#verts])
     {
      pop(@verts);
      lxout("closed curve");
      $close = "true";
     }
    }
   }
   push(@verts, $verts[0]);
   lx("select.drop vertex");
   $previous = "A";
   $a = 0;
   foreach $vert(@verts)
   {
    if($polytype ne "bezier")
    {
     $vert1 = $vert;
    }
    lxout("$vert1 $previous");
    @pos = @{$edgePos{"$vert1 $previous"}};
    lxout("pos @pos");
    if(@pos)
    {
     if(!@{$indicated{"$vert1 $previous"}})
     {
      $indicated = lxq("query layerservice vert.index ? last");
      lxout("indicated $indicated");
      for($i = 0; $i < $pointscount; $i ++)
      {
       $indicated ++;
       $v[0] = shift(@pos);
       $v[1] = shift(@pos);
       $v[2] = shift(@pos);
       lx("vert.new  $v[0] $v[1] $v[2]");
       unshift(@{$indicated{"$previous $vert"}},$indicated);
       lx("select.element $layerindex vertex add $indicated");
       push(@{$vertList{$poly}}, $indicated);
       push(@indicated, $indicated);
      }
     }
     else
     {
      for($i = 0; $i < $pointscount; $i ++)
      {
       $indicated = ${$indicated{"$vert $previous"}}[$i];
       lx("select.element $layerindex vertex add $indicated");
      }
      push(@{$vertList{$poly}}, @{$indicated{"$vert $previous"}});
     }
    }
    if($polytype eq "bezier")
    {
     $previous = $verts[$a-1];
     $vert1 = $verts[$a+2];
     $a ++;
    }
    else
    {
     $previous = $vert;
    }
    lx("select.element $layerindex vertex add $vert");
    push(@{$vertList{$poly}},$vert);
   }
   if($polytype eq "bezier")
   {
    if($pointscount%3)
    {
     $polytype = "auto";
    }
    if($close)
    {
     @pos = lxq("query layerservice vert.pos ? $verts[0]");
     lx("vert.new  $pos[0] $pos[1] $pos[2]");
     $indicated = lxq("query layerservice vert.index ? last");
     lx("select.element $layerindex vertex add $indicated");
     $close = "";
    }
   }
   lx("poly.make $polytype $close");
   $polyindex = lxq("query layerservice poly.index ? last");
   lxout("polyindex $polyindex");
   $indexList{$poly} = $polyindex;
  }
  foreach $poly(@Polys)
  {
   $previous = "A";
   for($i = 0; $i < @{$vertList{$poly}}; $i ++)
   {
    $vert = ${$vertList{$poly}}[$i];
    if("@indicated" =~ /\b$vert\b/)
    {
     lxout("indicated");
     lx("select.element $layerindex edge add $previous $vert");
     lxout("selects for $previous $vert");
     $previous = $vert;
    }
    else
    {
     $previous = $vert;
    }
   }
  }
  @{$edgeselection{$fglayer}} = lxq("query layerservice edges ? selected");
  lx("select.drop polygon");
  foreach $poly(@Polys)
  {
   $index = $indexList{$poly};
   $material = lxq("query layerservice poly.material ? $index");
   $polymaterial = $material{$poly};
   if($polymaterial)
   {
    if($material ne $polymaterial)
    {
     lx("select.element layer:$layerindex type:polygon mode:set index:$index");
     if(lxok())
     {
      lx("poly.setMaterial {$polymaterial}");
      if(lxok())
      {
       lxout("ASSIGNEMENT from $poly to $index of $polymaterial");
      }
     }
    }
   }
  }
  lx("select.drop polygon");
  foreach $poly(@Polys)
  {
   lx("select.element layer:$layerindex type:polygon mode:add index:$poly");
  }
  $poly = lxq("query layerservice poly.N ? selected");
  lxout("poly $poly");
  if($poly)
  {
   lxout("executing delete");
   lx("select.delete");
  }
 } 
 lx("select.drop polygon");

 foreach $fglayer(@fglayers)
 {
  lx("select.layer $fglayer add");
 }

 foreach $fglayer(@fglayers)
 {
  $layerindex = lxq("query layerservice layer.index ? $fglayer");
  foreach $edge(@{$edgeselection{$fglayer}})
  {
   $edge =~ /\((\d+),(\d+)\)/;
   lx("select.element $layerindex edge add $1 $2");
  }
 }

}
else
{

 lx("tool.set uv.create on");
 
 lx("tool.attr uv.create proj barycentric");
 
 lx("tool.set uv.create off");

 $maptype{texture} = "txuv";
 $maptype{morph} = "morf";
 $maptype{weight} = "wght";
 $maptype{subvweight} = "subd";
 $maptype{edgepick} = "epck";
 $maptype{normal} = "norm";
 foreach $fglayer(@fglayers)
 {
  if(!@selection)
  {
   last;
  }
  @indicated = ();
  %indicated = ();
  lx("select.layer $fglayer");
  $layerindex = lxq("query layerservice layer.index ? $fglayer");
  %edgePos = ();
  %subdValue = ();
  %vmapList = ();
  %normList = ();
  %morfList = ();
  %rgbList = ();
  %wghtList = ();
  %rgbaList = ();
  %epckValue = ();
  %discos_rgba = ();
  %discos = ();
  %spotList = ();
  @vMaps = ();
  @vMapname = ();
  @vMapindex = ();
  @morfname = ();
  @morfindex = ();
  @wghtname = ();
  @wghtindex = ();
  @subdname = ();
  @subdindex = ();
  @rgbname = ();
  @rgbindex = ();
  @normalname = ();
  @normindex = ();
  @rgbaname = ();
  @rgbaindex = ();
  @epckname = ();
  @epckindex = ();
  @value = ();
  @spotname = ();
  @spotindex = ();
  @vMaps = @{$vMapsLayer{"$fglayer"}};
  lxout("vMaps @vMaps");
  foreach $vMap(@vMaps)
  {
   $vMapLayer = lxq("query layerservice vmap.layer ? $vMap");
   $vMapLayer ++;
   lxout("vMapLayer $vMapLayer");
   if($vMapLayer != $layerindex)
   {
    next;
   }
   $vMaptype = lxq("query layerservice vmap.type ? $vMap");
   lxout("vMaptype $vMaptype");
   $vMapname = lxq("query layerservice vmap.name ? $vMap");
   lxout("vMapname $vMapname");
   $selected = lxq("query layerservice vmap.selected ? $vMap");
   lxout("selected $selected");
   if($selected)
   {
    $type = $maptype{$vMaptype};
    if(!$type)
    {
     $type = $vMaptype;
    }
    lx("select.vertexMap name:\"$vMapname\" type:{$type} mode:{remove}");
    push(@{$selectedvMapName{$layerindex}},$vMapname);
    push(@{$selectedvMapType{$layerindex}},$type);
   }
   if($vMaptype eq "texture")
   {
    push(@vMapname,$vMapname);
    push(@vMapindex,$vMap);
   }
   elsif($vMaptype eq "morph")
   {
    push(@morfname,$vMapname);
    push(@morfindex,$vMap);
   }
   elsif($vMaptype eq "weight")
   {
    push(@wghtname,$vMapname);
    push(@wghtindex,$vMap);
   }
   elsif($vMaptype eq "subvweight")
   {
    push(@subdname,$vMapname);
    push(@subdindex,$vMap);
   }
   elsif($vMaptype eq "rgb")
   {
    push(@rgbname,$vMapname);
    push(@rgbindex,$vMap);
   }
   elsif($vMaptype eq "normal")
   {
    push(@normalname,$vMapname);
    push(@normindex,$vMap);
   }
   elsif($vMaptype eq "rgba")
   {
    push(@rgbaname,$vMapname);
    push(@rgbaindex,$vMap);
   }
   elsif($vMaptype eq "edgepick")
   {
    push(@epckname,$vMapname);
    push(@epckindex,$vMap);
   }
   elsif($vMaptype eq "spot")
   {
    push(@spotname,$vMapname);
    push(@spotindex,$vMap);
   }
   elsif($vMaptype eq "position")
   {
    push(@positname,$vMapname);
    push(@positindex,$vMap);
   }
  }
  lxout("vMapname @vMapname");
  lxout("morfname @morfname");
  lxout("wghtname @wghtname");
  lxout("subdname @subdname");
  lxout("rgbname @rgbname");
  lxout("normalname @normalname");
  lxout("rgbaname @rgbaname");
  lxout("epckname @epckname");
  lxout("spotname @spotname");
  lxout("positname @positname");
  @edges = ();
  @remain = ();
  foreach $selected(@selection)
  {
   $selected =~ /\((\d+),(\d+),(\d+)\)/;
   if($1 == $fglayer)
   {
    push(@edges,"\($2,$3\)");
   }
   else
   {
    push(@remain,$selected);
   }
  }
  lxout("edges @edges");
  lxout("remain @remain");
  @selection = ();
  @selection = @remain;
  @Polys = ();
  %polygonhash = ();
  foreach $edges(@edges)
  {
   @buf = split(/\,/,$edges);
   $buf[0] =~ s/\(//;
   $buf[1] =~ s/\)//;
   lxout("buf @buf");
   @vertpos1 = lxq("query layerservice vert.pos ? $buf[0]");
   @vertpos2 = lxq("query layerservice vert.pos ? $buf[1]");
   @{$edgePos{"$buf[0] $buf[1]"}} = ();
   @{$edgePos{"$buf[1] $buf[0]"}} = ();
   @pos = @vertpos1;
   @step = (($vertpos1[0]-$vertpos2[0])/$d, ($vertpos1[1]-$vertpos2[1])/$d, ($vertpos1[2]-$vertpos2[2])/$d);
   for($i = 0; $i < $pointscount; $i ++)
   {
    @pos = ($pos[0]-$step[0], $pos[1]-$step[1], $pos[2]-$step[2]);
    unshift(@{$edgePos{"$buf[0] $buf[1]"}}, @pos);
    push(@{$edgePos{"$buf[1] $buf[0]"}}, @pos);
   }
   @polys = lxq("query layerservice edge.polyList ? $edges");
   lxout("polys @polys");
   foreach $poly(@polys)
   {
    $polytype = lxq("query layerservice poly.type ? $poly");
    lxout("polytype $polytype");
    $polygonhash{$poly} = $polytype;
   }
   $c = 0;
   foreach $vMap(@subdname)
   {
    lx("select.vertexMap \"$vMap\" subd replace");
    $index = $subdindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    $subdValue = lxq("query layerservice edge.creaseWeight ? $edges");
    lxout("CREASE subdValue $subdValue");
    $subdValue{"$buf[0] $buf[1]"} = $subdValue;
    $subdValue{"$buf[1] $buf[0]"} = $subdValue;
    lx("select.vertexMap \"$vMap\" subd remove");
    $c ++;
   }
   if(@epckname)
   {
    @epckValues = lxq("query layerservice edge.selSets ? $edges");
    lxout("epckValues @epckValues");
    @{$epckValue{"$buf[0] $buf[1]"}} = @epckValues;
    @{$epckValue{"$buf[1] $buf[0]"}} = @epckValues;
   }
  }
  @Polys = sort{$polygonhash{$a} <=> $polygonhash{$b}} keys(%polygonhash);
  lxout("Polys @Polys");
  if(!@Polys)
  {
   next;
  }
  foreach $poly(@Polys)
  {
   $material{$poly} = lxq("query layerservice poly.material ? $poly");
   lxout("material $poly $material{$poly}");
  }
  foreach $poly(@Polys)
  {
   @verts = lxq("query layerservice poly.vertList ? $poly");
   lxout("verts @verts");
   $polytype = $polygonhash{$poly};
   $close = "";
   if($polytype eq "curve")
   {
    if(@verts > 2)
    {
     if($verts[0]==$verts[$#verts-2] && $verts[1]==$verts[$#verts-1] && $verts[2]==$verts[$#verts])
     {
      shift(@verts);
      pop(@verts);
      pop(@verts);
      lxout("closed curve");
      $close = "true";
     }
    }
   }
   if($polytype eq "bezier")
   {
    if(@verts > 4)
    {
     if($verts[0]==$verts[$#verts])
     {
      pop(@verts);
      lxout("closed curve");
      $close = "true";
     }
    }
   }
   push(@verts, $verts[0]);
   
   $c = 0;
   foreach $vMap(@vMapname)
   {
    lxout("vMap $vMap");
    lx("select.vertexMap \"$vMap\" txuv replace");
    $index = $vMapindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
    lxout("vmapValues @vmapValues");
    if(@vmapValues)
    {
     push(@vmapValues,$vmapValues[0],$vmapValues[1]);
     @{$vmapList{"$vMap $poly"}} = @vmapValues;
    }
    lx("select.vertexMap \"$vMap\" txuv remove");
    $c ++;
   }
   $c = 0;
   foreach $vMap(@normalname)
   {
    lxout("vMap $vMap");
    lx("select.vertexMap \"$vMap\" norm replace");
    $index = $normindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    @normalValues = lxq("query layerservice poly.vertNormals ? $poly");
    lxout("normalValues @normalValues");
    if(@normalValues)
    {
     push(@normalValues,$normalValues[0],$normalValues[1],$normalValues[2]);
     @{$normList{"$vMap $poly"}} = @normalValues;
    }
    lx("select.vertexMap \"$vMap\" norm remove");
    $c ++;
   }
   $c = 0;
   foreach $vMap(@morfname)
   {
    lxout("vMap $vMap");
    lx("select.vertexMap \"$vMap\" morf replace");
    $index = $morfindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    @morfValues = lxq("query layerservice poly.vmapValue ? $poly");
    lxout("morfValues @morfValues");
    if(@morfValues)
    {
     push(@morfValues,$morfValues[0],$morfValues[1],$morfValues[2]);
     @{$morfList{"$vMap $poly"}} = @morfValues;
    }
    lx("select.vertexMap \"$vMap\" morf remove");
    $c ++;
   }
   $c = 0;
   foreach $vMap(@rgbname)
   {
    lxout("vMap $vMap");
    lx("select.vertexMap \"$vMap\" rgb replace");
    $index = $rgbindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    @discos = lxq("query layerservice poly.discos ? $poly");
    if(@discos)
    {
     $discos{"$vMap $poly"} = 1;
    }
    @rgbValues = lxq("query layerservice poly.vmapValue ? $poly");
    lxout("rgbValues @rgbValues");
    if(@rgbValues)
    {
     push(@rgbValues,$rgbValues[0],$rgbValues[1],$rgbValues[2]);
     @{$rgbList{"$vMap $poly"}} = @rgbValues;
    }
    lx("select.vertexMap \"$vMap\" rgb remove");
    $c ++;
   }
   $c = 0;
   foreach $vMap(@wghtname)
   {
    lxout("vMap $vMap");
    lx("select.vertexMap \"$vMap\" wght replace");
    $index = $wghtindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    @wghtValues = lxq("query layerservice poly.vmapValue ? $poly");
    lxout("wghtValues @wghtValues");
    if(@wghtValues)
    {
     push(@wghtValues,$wghtValues[0]);
     @{$wghtList{"$vMap $poly"}} = @wghtValues;
    }
    lx("select.vertexMap \"$vMap\" wght remove");
    $c ++;
   }
   $c = 0;
   foreach $vMap(@rgbaname)
   {
    lxout("vMap $vMap");
    lx("select.vertexMap \"$vMap\" rgba replace");
    $index = $rgbaindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    @discos_rgba = lxq("query layerservice poly.discos ? $poly");
    if(@discos_rgba)
    {
     $discos_rgba{"$vMap $poly"} = 1;
    }
    @rgbaValues = lxq("query layerservice poly.vmapValue ? $poly");
    lxout("rgbaValues @rgbaValues");
    if(@rgbaValues)
    {
     push(@rgbaValues,$rgbaValues[0]..$rgbaValues[3]);
     @{$rgbaList{"$vMap $poly"}} = @rgbaValues;
    }
    lx("select.vertexMap \"$vMap\" rgba remove");
    $c ++;
   }
   if(@spotname)
   {
    $vMap = $positname[0];
    lxout("vMap $vMap");
    $index = $positindex[0];
    lxq("query layerservice vmap.layer ? $index");
    @positValues = lxq("query layerservice poly.vmapValue ? $poly");
    lxout("positValues @positValues");
    if(@positValues)
    {
     push(@positValues,$positValues[0],$positValues[1],$positValues[2]);
     @{$positList{"$vMap $poly"}} = @positValues;
    }
   }
   $c = 0;
   foreach $vMap(@spotname)
   {
    lxout("vMap $vMap");
    lx("select.vertexMap \"$vMap\" spot replace");
    $index = $spotindex[$c];
    lxq("query layerservice vmap.layer ? $index");
    @spotValues = lxq("query layerservice poly.vmapValue ? $poly");
    lxout("spotValues @spotValues");
    if(@spotValues)
    {
     for($s = 0; $s < @spotValues; $s ++)
     {
      if(!$spotValues[$s])
      {
       $spotValues[$s] = ${$positList{"position $poly"}}[$s];
       lxout("changed spotValues $spotValues[$s]");
      }
     }
     push(@spotValues,$spotValues[0],$spotValues[1],$spotValues[2]);
     @{$spotList{"$vMap $poly"}} = @spotValues;
    }
    lx("select.vertexMap \"$vMap\" spot remove");
    $c ++;
   }
   lx("select.drop vertex");
   $previous = "A";
   $a = 0;
   foreach $vert(@verts)
   {
    if($polytype ne "bezier")
    {
     $vert1 = $vert;
    }
    lxout("$vert1 $previous");
    @pos = @{$edgePos{"$vert1 $previous"}};
    lxout("pos @pos");
    if(@pos)
    {
     if(!@{$indicated{"$vert1 $previous"}})
     {
      $indicated = lxq("query layerservice vert.index ? last");
      lxout("indicated $indicated");
      for($i = 0; $i < $pointscount; $i ++)
      {
       $indicated ++;
       $v[0] = shift(@pos);
       $v[1] = shift(@pos);
       $v[2] = shift(@pos);
       lx("vert.new  $v[0] $v[1] $v[2]");
       unshift(@{$indicated{"$previous $vert"}},$indicated);
       lx("select.element $layerindex vertex add $indicated");
       push(@{$vertList{$poly}}, $indicated);
       push(@indicated, $indicated);
      }
     }
     else
     {
      for($i = 0; $i < $pointscount; $i ++)
      {
       $indicated = ${$indicated{"$vert $previous"}}[$i];
       lx("select.element $layerindex vertex add $indicated");
      }
      push(@{$vertList{$poly}}, @{$indicated{"$vert $previous"}});
     }
    }
    if($polytype eq "bezier")
    {
     $previous = $verts[$a-1];
     $vert1 = $verts[$a+2];
     $a ++;
    }
    else
    {
     $previous = $vert;
    }
    lx("select.element $layerindex vertex add $vert");
    push(@{$vertList{$poly}},$vert);
   }
   if($polytype eq "bezier")
   {
    if($pointscount%3)
    {
     $polytype = "auto";
    }
    if($close)
    {
     @pos = lxq("query layerservice vert.pos ? $verts[0]");
     lx("vert.new  $pos[0] $pos[1] $pos[2]");
     $indicated = lxq("query layerservice vert.index ? last");
     lx("select.element $layerindex vertex add $indicated");
     $close = "";
    }
   }
   lx("poly.make $polytype $close");
   $polyindex = lxq("query layerservice poly.index ? last");
   lxout("polyindex $polyindex");
   $indexList{$poly} = $polyindex;
  }
  lx("select.type polygon");
  $poly = lxq("query layerservice poly.N ? selected");
  lxout("poly $poly");
  if($poly)
  {
   lx("tool.set uv.create on");
   foreach $vMap(@vMapname)
   {
    lx("select.vertexMap \"$vMap\" txuv replace");
    lx("tool.doApply");
   }
   lx("tool.set uv.create off");
  }
  lx("select.drop polygon");
  foreach $poly(@Polys)
  {
   $polytype = $polygonhash{$poly};
   lx("select.type vertex");
   foreach $vMap(@vMapname)
   {
    if(defined @{$vmapList{"$vMap $poly"}})
    {
     lx("select.vertexMap \"$vMap\" txuv replace");
     if(!lxok())
     {
      next;
     }
     $indicated = 0;
     foreach $vert(@{$vertList{$poly}})
     {
      lx("select.element $layerindex vertex set $vert 1 $indexList{$poly}");
      if("@indicated" =~ /\b$vert\b/)
      {
       lxout("indicated");
       if(!$indicated)
       {
        $nextu = ${$vmapList{"$vMap $poly"}}[0];
        $nextv = ${$vmapList{"$vMap $poly"}}[1];
        $stepu = ($uvalue - $nextu)/$d;
        $stepv = ($vvalue - $nextv)/$d;
        $indicated = 1;
       }
       $uvalue -= $stepu;
       lx("vertMap.setValue type:$texture_type comp:0 value:$uvalue");
       $vvalue -= $stepv;
       lx("vertMap.setValue type:$texture_type comp:1 value:$vvalue");
      }
      else
      {
       $uvalue = shift @{$vmapList{"$vMap $poly"}};
       lxout("uvalue $uvalue");
       lx("vertMap.setValue type:$texture_type comp:0 value:$uvalue");
       $vvalue = shift @{$vmapList{"$vMap $poly"}};
       lxout("vvalue $vvalue");
       lx("vertMap.setValue type:$texture_type comp:1 value:$vvalue");
       if($indicated)
       {
        $indicated = 0;
       }
      }
     }
     lx("select.vertexMap \"$vMap\" txuv remove");
    }
   }
   foreach $vMap(@normalname)
   {
    if(defined @{$normList{"$vMap $poly"}})
    {
     lx("select.vertexMap \"$vMap\" norm replace");
     if(!lxok())
     {
      next;
     }
     $indicated = 0;
     foreach $vert(@{$vertList{$poly}})
     {
      lx("select.element $layerindex vertex set $vert 1 $indexList{$poly}");
      if("@indicated" =~ /\b$vert\b/)
      {
       lxout("indicated");
       if(!$indicated)
       {
        $nextx = ${$normList{"$vMap $poly"}}[0];
        $nexty = ${$normList{"$vMap $poly"}}[1];
        $nextz = ${$normList{"$vMap $poly"}}[2];
        $stepx = ($xvalue - $nextx)/$d;
        $stepy = ($yvalue - $nexty)/$d;
        $stepz = ($zvalue - $nextz)/$d;
        $indicated = 1;
       }
       $xvalue -= $stepx;
       lx("vertMap.setValue type:$normal_type comp:0 value:$xvalue");
       $yvalue -= $stepy;
       lx("vertMap.setValue type:$normal_type comp:1 value:$yvalue");
       $zvalue -= $stepz;
       lx("vertMap.setValue type:$normal_type comp:2 value:$zvalue");
      }
      else
      {
       $xvalue = shift @{$normList{"$vMap $poly"}};
       lxout("xvalue $xvalue");
       lx("vertMap.setValue type:$normal_type comp:0 value:$xvalue");
       $yvalue = shift @{$normList{"$vMap $poly"}};
       lxout("yvalue $yvalue");
       lx("vertMap.setValue type:$normal_type comp:1 value:$yvalue");
       $zvalue = shift @{$normList{"$vMap $poly"}};
       lxout("zvalue $zvalue");
       lx("vertMap.setValue type:$normal_type comp:2 value:$zvalue");
       if($indicated)
       {
        $indicated = 0;
       }
      }
     }
     lx("select.vertexMap \"$vMap\" norm remove");
    }
   }
   foreach $vMap(@morfname)
   {
    if(defined @{$morfList{"$vMap $poly"}})
    {
     lx("select.vertexMap \"$vMap\" morf replace");
     if(!lxok())
     {
      next;
     }
     $indicated = 0;
     foreach $vert(@{$vertList{$poly}})
     {
      lx("select.element $layerindex vertex set $vert");
      if("@indicated" =~ /\b$vert\b/)
      {
       lxout("indicated");
       if(!$indicated)
       {
        $nextx = ${$morfList{"$vMap $poly"}}[0];
        $nexty = ${$morfList{"$vMap $poly"}}[1];
        $nextz = ${$morfList{"$vMap $poly"}}[2];
        $stepx = ($xvalue - $nextx)/$d;
        $stepy = ($yvalue - $nexty)/$d;
        $stepz = ($zvalue - $nextz)/$d;
        $indicated = 1;
       }
       $xvalue -= $stepx;
       lx("vertMap.setValue type:$morph_type comp:0 value:$xvalue");
       $yvalue -= $stepy;
       lx("vertMap.setValue type:$morph_type comp:1 value:$yvalue");
       $zvalue -= $stepz;
       lx("vertMap.setValue type:$morph_type comp:2 value:$zvalue");
      }
      else
      {
       $xvalue = shift @{$morfList{"$vMap $poly"}};
       $yvalue = shift @{$morfList{"$vMap $poly"}};
       $zvalue = shift @{$morfList{"$vMap $poly"}};
       if($indicated)
       {
        $indicated = 0;
       }
      }
     }
     lx("select.vertexMap \"$vMap\" morf remove");
    }
   }
   if(@rgbname)
   {
    lx("tool.set vertMap.setColor on");
   }
   foreach $vMap(@rgbname)
   {
    if(defined @{$rgbList{"$vMap $poly"}})
    {
     lx("select.vertexMap \"$vMap\" rgb replace");
     if(!lxok())
     {
      next;
     }
     if($discos{"$vMap $poly"})
     {
      lx("select.type polygon");
      lx("select.element $layerindex polygon set $indexList{$poly}");
      $rvalue = ${$rgbList{"$vMap $poly"}}[0];
      $gvalue = ${$rgbList{"$vMap $poly"}}[1];
      $bvalue = ${$rgbList{"$vMap $poly"}}[2];
      lx("tool.attr vertMap.setColor Color {$rvalue $gvalue $bvalue}");
      lx("tool.doApply");
      lx("select.type vertex");
     }
     else
     {
      $indicated = 0;
      foreach $vert(@{$vertList{$poly}})
      {
       lx("select.element $layerindex vertex set $vert");
       if("@indicated" =~ /\b$vert\b/)
       {
        lxout("indicated");
        if(!$indicated)
        {
         $nextr = ${$rgbList{"$vMap $poly"}}[0];
         $nextg = ${$rgbList{"$vMap $poly"}}[1];
         $nextb = ${$rgbList{"$vMap $poly"}}[2];
         $stepr = ($rvalue - $nextr)/$d;
         $stepg = ($gvalue - $nextg)/$d;
         $stepb = ($bvalue - $nextb)/$d;
         $indicated = 1;
        }
        $rvalue -= $stepr;
        $gvalue -= $stepg;
        $bvalue -= $stepb;
        lx("tool.attr vertMap.setColor Color {$rvalue $gvalue $bvalue}");
        lx("tool.doApply");
       }
       else
       {
        $rvalue = shift @{$rgbList{"$vMap $poly"}};
        $gvalue = shift @{$rgbList{"$vMap $poly"}};
        $bvalue = shift @{$rgbList{"$vMap $poly"}};
        if($indicated)
        {
         $indicated = 0;
        }
       }
      }
     }
     lx("select.vertexMap \"$vMap\" rgb remove");
    }
   }
   if(@rgbname)
   {
    lx("tool.set vertMap.setColor off");
   }
   foreach $vMap(@wghtname)
   {
    if(defined @{$wghtList{"$vMap $poly"}})
    {
     lx("select.vertexMap \"$vMap\" wght replace");
     if(!lxok())
     {
      next;
     }
     $indicated = 0;
     foreach $vert(@{$vertList{$poly}})
     {
      lx("select.element $layerindex vertex set $vert");
      if("@indicated" =~ /\b$vert\b/)
      {
       lxout("indicated");
       if(!$indicated)
       {
        $next = ${$wghtList{"$vMap $poly"}}[0];
        $step = ($value - $next)/$d;
        $indicated = 1;
       }
       $value -= $step;
       lx("vertMap.setValue type:$weight_type comp:0 value:$value");
      }
      else
      {
       $value = shift @{$wghtList{"$vMap $poly"}};
       if($indicated)
       {
        $indicated = 0;
       }
      }
     }
     lx("select.vertexMap \"$vMap\" wght remove");
    }
   }
   if(@rgbaname)
   {
    lx("select.vertexMap {$rgbaname[0]} rgba replace");
    lx("tool.set vertMap.setColor on");
    if(!lxq("tool.attr vertMap.setColor UseAlpha ?"))
    {
     lx("tool.attr vertMap.setColor UseAlpha 1");
    }
   }
   foreach $vMap(@rgbaname)
   {
    if(defined @{$rgbaList{"$vMap $poly"}})
    {
     lx("select.vertexMap \"$vMap\" rgba replace");
     if(!lxok())
     {
      next;
     }
     if($discos_rgba{"$vMap $poly"})
     {
      lx("select.type polygon");
      lx("select.element $layerindex polygon set $indexList{$poly}");
      $rvalue = ${$rgbaList{"$vMap $poly"}}[0];
      $gvalue = ${$rgbaList{"$vMap $poly"}}[1];
      $bvalue = ${$rgbaList{"$vMap $poly"}}[2];
      lx("tool.attr vertMap.setColor Color {$rvalue $gvalue $bvalue}");
      lx("tool.doApply");
      lx("select.type vertex");
     }
     else
     {
      $indicated = 0;
      foreach $vert(@{$vertList{$poly}})
      {
       lx("select.element $layerindex vertex set $vert");
       if("@indicated" =~ /\b$vert\b/)
       {
        lxout("indicated");
        if(!$indicated)
        {
         $nextr = ${$rgbaList{"$vMap $poly"}}[0];
         $nextg = ${$rgbaList{"$vMap $poly"}}[1];
         $nextb = ${$rgbaList{"$vMap $poly"}}[2];
         $nexta = ${$rgbaList{"$vMap $poly"}}[3];
         $stepr = ($rvalue - $nextr)/$d;
         $stepg = ($gvalue - $nextg)/$d;
         $stepb = ($bvalue - $nextb)/$d;
         $stepa = ($avalue - $nexta)/$d;
         $indicated = 1;
        }
        $rvalue -= $stepr;
        $gvalue -= $stepg;
        $bvalue -= $stepb;
        $avalue -= $stepa;
        lx("tool.attr vertMap.setColor Alpha {$avalue}");
        lx("tool.attr vertMap.setColor Color {$rvalue $gvalue $bvalue}");
        lx("tool.doApply");
       }
       else
       {
        $rvalue = shift @{$rgbaList{"$vMap $poly"}};
        $gvalue = shift @{$rgbaList{"$vMap $poly"}};
        $bvalue = shift @{$rgbaList{"$vMap $poly"}};
        $avalue = shift @{$rgbaList{"$vMap $poly"}};
        if($indicated)
        {
         $indicated = 0;
        }
       }
      }
     }
     lx("select.vertexMap \"$vMap\" rgba remove");
    }
   }
   if(@rgbaname)
   {
    lx("tool.set vertMap.setColor off 0");
   }
   lx("select.type edge");
   if(@subdname)
   {
    lx("tool.set vertMap.setWeight on 0");
   }
   foreach $vMap(@subdname)
   {
    lx("select.vertexMap \"$vMap\" subd replace");
    if(!lxok())
    {
     next;
    }
    $previous = "A";
    $indicated = 0;
    for($i = 0; $i < @{$vertList{$poly}}; $i ++)
    {
     $vert = ${$vertList{$poly}}[$i];
     if("@indicated" =~ /\b$vert\b/)
     {
      lxout("indicated");
      if(!$indicated)
      {
       $edge0 = ${$vertList{$poly}}[$i-1];
       $edge1 = ${$vertList{$poly}}[$i+$pointscount];
       $value = $subdValue{"$edge0 $edge1"};
       lxout("value $value");
       $indicated = 1;
      }
      if($value)
      {
       $edge0 = ${$vertList{$poly}}[$i-1];
       $edge1 = ${$vertList{$poly}}[$i+1];
       lx("select.element $layerindex edge set $edge0 $vert");
       lx("select.element $layerindex edge add $vert $edge1");
       lxout("select to CREASE $edge0 $vert $edge1");
       lx("tool.setAttr vertMap.setWeight weight $value");
       lx("tool.doApply");
      }
     }
     else
     {
      $previous = $vert;
      if($indicated)
      {
       $indicated = 0;
      }
     }
    }
    lx("select.vertexMap \"$vMap\" subd remove");
   }
   if(@subdname)
   {
    lx("tool.set vertMap.setWeight off");
   }
   foreach $vMap(@spotname)
   {
    if(defined @{$spotList{"$vMap $poly"}})
    {
     lx("select.vertexMap \"$vMap\" spot replace");
     if(!lxok())
     {
      next;
     }
     $indicated = 0;
     foreach $vert(@{$vertList{$poly}})
     {
      lx("select.drop vertex");
      lx("select.element $layerindex vertex set $vert");
      lxout("selected $vert");
      if("@indicated" =~ /\b$vert\b/)
      {
       lxout("indicated");
       if(!$indicated)
       {
        $nextx = ${$spotList{"$vMap $poly"}}[0];
        $nexty = ${$spotList{"$vMap $poly"}}[1];
        $nextz = ${$spotList{"$vMap $poly"}}[2];
        $stepx = ($xvalue - $nextx)/$d;
        $stepy = ($yvalue - $nexty)/$d;
        $stepz = ($zvalue - $nextz)/$d;
        $indicated = 1;
       }
       $xvalue -= $stepx;
       $yvalue -= $stepy;
       $zvalue -= $stepz;
       if($xvalue || $yvalue || $zvalue)
       {
        lx("vert.set axis:x value:$xvalue");
        lx("vert.set axis:y value:$yvalue");
        lx("vert.set axis:z value:$zvalue");
       }
      }
      else
      {
       $xvalue = shift @{$spotList{"$vMap $poly"}};
       $yvalue = shift @{$spotList{"$vMap $poly"}};
       $zvalue = shift @{$spotList{"$vMap $poly"}};
       if($indicated)
       {
        $indicated = 0;
       }
      }
     }
     lx("select.vertexMap \"$vMap\" spot remove");
    }
   }
   if(@epckname)
   {
    $previous = "A";
    $indicated = 0;  
    for($i = 0; $i < @{$vertList{$poly}}; $i ++)
    {
     $vert = ${$vertList{$poly}}[$i];
     if("@indicated" =~ /\b$vert\b/)
     {
      lxout("EDGE PICK indicated");
      if(!$indicated)
      {
       if($polytype eq "bezier")
       {
        $edge0 = ${$vertList{$poly}}[$i-3];
        $edge1 = ${$vertList{$poly}}[$i+$pointscount+1];
       }
       else
       {
        $edge0 = ${$vertList{$poly}}[$i-1];
        $edge1 = ${$vertList{$poly}}[$i+$pointscount];
       }
       @value = @{$epckValue{"$edge0 $edge1"}};
       lxout("EDGE PICK value @value");
       $indicated = 1;
      }
      if(@value)
      {
       if($polytype eq "bezier")
       {
        $edge0 = ${$vertList{$poly}}[$i-3];
        $edge1 = ${$vertList{$poly}}[$i+3];
       }
       else
       {
        $edge0 = ${$vertList{$poly}}[$i-1];
        $edge1 = ${$vertList{$poly}}[$i+1];
       }

       lx("select.element $layerindex edge set $edge0 $vert");
       lx("select.element $layerindex edge add $vert $edge1");
       lxout("select to EDGE PICK $edge0 $vert $edge1");
       @selected = lxq("query layerservice edges ? selected");
       if(@selected)
       {
        foreach $vMap(@value)
        {
         lx("select.editSet \"$vMap\" add");
         lxout("EDGE PICK $vMap");
        }
       }
      }
     }
     else
     {
      $previous = $vert;
      if($indicated)
      {
       $indicated = 0;
      }
     }
    }
   }
  }
  lx("select.drop polygon");
  foreach $poly(@Polys)
  {
   $index = $indexList{$poly};
   $material = lxq("query layerservice poly.material ? $index");
   $polymaterial = $material{$poly};
   if($polymaterial)
   {
    if($material ne $polymaterial)
    {
     lx("select.element layer:$layerindex type:polygon mode:set index:$index");
     if(lxok())
     {
      lx("poly.setMaterial {$polymaterial}");
      if(lxok())
      {
       lxout("ASSIGNEMENT from $poly to $index of $polymaterial");
      }
     }
    }
   }
  }

  foreach $poly(@Polys)
  {
   for($i = 0; $i < @{$vertList{$poly}}; $i ++)
   {
    $vert = ${$vertList{$poly}}[$i];
    if("@indicated" =~ /\b$vert\b/)
    {
     lxout("indicated");
     @verts = lxq("query layerservice vert.vertList ? $vert");
     if(@verts)
     {
      foreach $verts(@verts)
      {
       lx("select.element $layerindex edge add $vert $verts");
      }
     }
    }
   }
  }
  @{$edgeselection{$fglayer}} = lxq("query layerservice edges ? selected");
  lx("select.drop polygon");
  foreach $poly(@Polys)
  {
   lx("select.element layer:$layerindex type:polygon mode:add index:$poly");
  }
  $poly = lxq("query layerservice poly.N ? selected");
  lxout("poly $poly");
  if($poly)
  {
   lxout("executing delete");
   lx("select.delete");
  }
 }
 
 lx("select.drop polygon");

 foreach $fglayer(@fglayers)
 {
  lx("select.layer $fglayer add");
 }

 foreach $fglayer(@fglayers)
 {
  $layerindex = lxq("query layerservice layer.index ? $fglayer");
  foreach $edge(@{$edgeselection{$fglayer}})
  {
   $edge =~ /\((\d+),(\d+)\)/;
   lx("select.element $layerindex edge add $1 $2");
  }
 }

 foreach $fglayer(@fglayers)
 {
  $layerindex = lxq("query layerservice layer.index ? $fglayer");
  foreach $selectedvMap(@{$selectedvMapName{$layerindex}})
  {
   $selectedvMaptype = shift @{$selectedvMapType{$layerindex}};
   lxout("selectedvMaptype $selectedvMaptype");
   lx("!select.vertexMap {$selectedvMap} {$selectedvMaptype} add");
  }
 }
}

lx("select.type edge");

lx("select.symmetryState $lxSymmetry");