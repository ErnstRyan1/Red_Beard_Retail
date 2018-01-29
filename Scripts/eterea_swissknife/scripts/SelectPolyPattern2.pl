#!perl
#
#@SelectPolyPattern2.pl
#
#---------------------------------
#A Script By Allan Kiipli (c) 2012
#---------------------------------
#
#Polygon connection based sorting added for selected polygons.
#
#Now edges are put into internal hash both ways, no more lxquery and
#edgeselecting through command system.
#
#Select polys to operate on. Works across foreground layers.
#When no selection is made, all polys are tested for script.
#Deselects polys from established selection based on polygon
#shared edge selecting.
#When even number of poly edges are met, that had more than five edges,
#a coeficent is used to skip every second edge.
#
#Selects checkerboard poly pattern on quadrangluar polygon surfaces.
#This script is useful for placing two surfaces for checkerboard pattern 
#and in render output enabling "line rendering" for "surface boundaries".
#Material for mesh is assigned as "item mask" and placed above two surfaces
#in "Shader Tree". This mask may be set also at group level, or part or
#selection set level. Sometimes surfaces do not solve into checkerboard.

$currentscene = lxq("query sceneservice scene.index ? current");

lxout("currentscene $currentscene");

$mainlayer = lxq("query layerservice layers ? main");

lxout("mainlayer $mainlayer");

if(!$mainlayer)
{
 die("please select a visible layer!");
}

@fglayers = lxq("query layerservice layers ? fg");

lxout("fglayers @fglayers");

lx("select.type polygon");

@Polys = lxq("query layerservice selection ? poly");

lxout("Polys @Polys");

if(!@Polys)
{
 lx("select.invert");
}

foreach $fglayer(@fglayers)
{
 $layerindex = lxq("query layerservice layer.index ? $fglayer");
 @polys = lxq("query layerservice polys ? selected");
 lxout("polys @polys");
 @{$polys{$layerindex}} = @polys;
}

foreach $fglayer(@fglayers)
{
 %verts = ();
 %edge = ();
 @select = ();
 @polyquads = ();
 @selected = ();

 $layerindex = lxq("query layerservice layer.index ? $fglayer");
 lxout("layerindex $layerindex");
 @polys = @{$polys{$layerindex}};
 lxout("polys @polys");
 foreach $poly(@polys)
 {
  $type = lxq("query layerservice poly.type ? $poly");
  lxout("$type");
  if($type !~ /face|subdiv|psubdiv|spatch/)
  {
   next;
  }
  @verts = lxq("query layerservice poly.vertList ? $poly");
  lxout("verts @verts");
  if(@verts < 3)
  {
   next;
  }
  
  if(@verts > 2)
  {
   push(@polyquads, $poly);
   @{$verts{$poly}} = @verts;
  }
 }

 $currentpoly = $polyquads[0];

 push(@selected, $polyquads[0]);

 lxout("selected @selected");

 A1:
 {
  do
  {
   push(@selected, $currentpoly);
   @polyverts = lxq("query layerservice poly.vertList ? $currentpoly");
   @polyverts3 = ();
   foreach $polyvert(@polyverts)
   {
    if(($polyvert eq $polyvert1) || ($polyvert eq $polyvert2))
    {
     next;
    }
    push(@polyverts3, $polyvert);
   }
   $polyvert1 = $polyverts3[0];
   $polyvert2 = $polyverts3[1];
   $edge = "(".$polyvert1.",".$polyvert2.")";
   lxout("edge $edge");
   @poly1 = lxq("query layerservice edge.polyList ? $edge");
   lxout("poly @poly1");
   if(@poly1 == 1)
   {
    last A1;
   }
   if($poly1[0] == $currentpoly)
   {
    $currentpoly = $poly1[1];
   }
   else
   {
    $currentpoly = $poly1[0];
   }
   if("@selected" =~ /\b$currentpoly\b/)
   {
    last A1;
   }
  }
  while((@polyverts == 4) && (@selected < @polyquads));
 }


 while(@selected < @polyquads)
 {
  $currentpoly1 = $currentpoly;
  $currentpoly = $selected[$#selected];
  if($currentpoly == $currentpoly1)
  {
   lxout("currentpoly == currentpoly1");
   if(@selected < @polyquads)
   {
    foreach $poly(@polyquads)
    {
     A2:
     {
      if("@selected" !~ /\b$poly\b/)
      {
       lxout("next shell found");
       $currentpoly = $poly;
       do
       {
        push(@selected, $currentpoly);
        @polyverts = lxq("query layerservice poly.vertList ? $currentpoly");
        @polyverts3 = ();
        foreach $polyvert(@polyverts)
        {
         if(($polyvert eq $polyvert1) || ($polyvert eq $polyvert2))
         {
          next;
         }
         push(@polyverts3, $polyvert);
        }
        $polyvert1 = $polyverts3[0];
        $polyvert2 = $polyverts3[1];
        $edge = "(".$polyvert1.",".$polyvert2.")";
        lxout("edge $edge");
        @poly1 = lxq("query layerservice edge.polyList ? $edge");
        lxout("poly @poly1");
        if(@poly1 == 1)
        {
         last A2;
        }
        if($poly1[0] == $currentpoly)
        {
         $currentpoly = $poly1[1];
        }
        else
        {
         $currentpoly = $poly1[0];
        }
        if("@selected" =~ /\b$currentpoly\b/)
        {
         last A2;
        }
       }
       while((@polyverts == 4) && (@selected < @polyquads));

      }
     }
    }
   }
   else
   {
    last;
   }
  }
 }

 lxout("selected @selected");

 foreach $poly(@selected)
 {
  if("@select" =~ /\b$poly\b/)
  {
   next;
  }
  lxout("poly $poly");
  @v = @{$verts{$poly}};
  @polycaller = ();
  push(@polycaller, $poly);
  for($i = 0; $i < @v; $i += 2)
  {
   $v = $v[$i];
   @polylist = lxq("query layerservice vert.polyList ? $v");
   lxout("polylist @polylist");
   foreach $p(@polylist)
   {
    if("@select" =~ /\b$p\b/)
    {
     next;
    }
    if("@polycaller" !~ /\b$p\b/)
    {
     push(@polycaller, $p);
    }
   }
  }
  lxout("polycaller @polycaller");
  foreach $p(@polycaller)
  {
   if("@select" =~ /\b$p\b/)
   {
    goto B;
   }
   @v1 = @{$verts{$p}};
   push(@v1, $v1[0]);
   for($i = 0; $i < $#v1; $i ++)
   {
    $v1 = $v1[$i];
    $v2 = $v1[$i+1];
    if($edge{"$v1 $v2"} || $edge{"$v2 $v1"})
    {
     push(@select, $p);
     goto B;
    }
   }
   $coeficent = 1;
   if((@v1 > 5) && (@v1%2))
   {
    $coeficent = 2;
   }
   for($i = 0; $i < $#v1; $i += $coeficent)
   {
    $v1 = $v1[$i];
    $v2 = $v1[$i+1];
    $edge{"$v1 $v2"} = 1;
    $edge{"$v2 $v1"} = 1;
   }
   if($p)
   {
    lx("select.element $layerindex polygon remove $p");
    push(@select, $p);
   }
   B:
  }
 }
}