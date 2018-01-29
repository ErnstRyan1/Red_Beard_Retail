#perl
# curveSpan.pl - Curves between curves (or polys)
# Dion Burgoyne
# 6-9-06

#Next Version Catmull Rom placement of curves (smoother effect)
#Version .1 Adds X number of curves between two curves in a linear fashion

#lxtrace(1);
@masterX,@masterY,@masterZ;
$segments = $ARGV[0];
$type = $ARGV[1];
if($type < 1)
  {
    $type = 1;
  }
@layers = lxq("query layerservice layers ? fg");
$layer = lxq("query layerservice layer.index ? selected");
@polys = lxq("query layerservice polys ? selected");
lx("select.drop polygon");
if($#polys < 1)
  {
    die("Not enough selected polys!");
  }

sub MakePsuedo
    {
        $A=$_[0];
        $B=$_[1];

        @pA = split (/\s+/, $A);
        @pB = split (/\s+/, $B);

        $count = 0;
        @Point = ();

        $Vector;

        foreach $pointA(@pA)
            {
                $Vector = ($pB[$count] - $pointA);
                $Result = ($pointA-$Vector);
                push (@Point, $Result);
                $count++;
            }

        $Point[3] = $pA[3];
        $Point[4] = $pA[4];
        $Point[5] = $pA[5];
        return(@Point);

    }


sub LinearDivision #A position, B position, # of splits, position of this split
  {

    $A = $_[0];
    $B = $_[1];
    $Frames = $_[2];
    $Position = $_[3];

    $SubPX = ($B - $A);

    $MathPX = ($SubPX / $Frames);
    $MathPX *= $Position;
    $NewPx = ($A+$MathPX);

    return ($NewPx);

  }

sub CatmullRomDivision
    {
        $SourceA = $_[0];
        $SourceB = $_[1];
        $SourceC = $_[2];
        $SourceD = $_[3];
        $Frames = $fpk;

        @sA = split (/\s+/, $SourceA);
        @sB = split (/\s+/, $SourceB);
        @sC = split (/\s+/, $SourceC);
        @sD = split (/\s+/, $SourceD);

        $count = 0;

        @segment = ();
        $LookAhead = 0;
        $RotateY = 0;
        foreach $p0(@sA)
            {
                $p1 = $sB[$count];
                $p2 = $sC[$count];
                $p3 = $sD[$count];

                $subcount = 0;

                $count++;
                @channel = ();
            for($t=0; $t<$Frames; $t++)
                {
                    $rT = 1/$Frames;
                    $rT *= $t;

                    $Channel[$t] = 0.5 * ( (2*$p1) +
                                   (-$p0 + $p2) * $rT +
                                   (2*$p0 - 5*$p1 + 4*$p2 - $p3) *$rT**2 +
                                   (-$p0 + 3*$p1 - 3*$p2 + $p3) * $rT**3);

                }

            push(@segment,"@Channel");
            }
        return (@segment);
    }

foreach $poly(@polys)
  {
    $polyArray = "poly$poly";
    @verts = lxq("query layerservice poly.vertList ? $poly");

    foreach $vert(@verts)
      {
        @positions = lxq("query layerservice vert.pos ? $vert");
        push (@$polyArray,"@positions $vert");
      }

  }
$count = 1;
lxmonInit($#polys);
for($i=0;$i<$#polys;$i++)#for each of the polys without using the last poly (as it's the cap)
  {
    if(!lxmonStep(1)){return;}
    $thispoly = $polys[$i];
    $nextpoly = $polys[$count];
    
    $polyArray = "poly$thispoly";
    $nextPolyArray = "poly$nextpoly";
    
    @startPoly = @$polyArray;
    @endPoly = @$nextPolyArray;
    
    for($vert=0;$vert<=$#startPoly;$vert++) #for each vert of each of the two polys
      {
        $startPosition = $startPoly[$vert];
        $endPosition = $endPoly[$vert];
        
        @splitStart = split(/ /,$startPosition);
        @splitEnd = split(/ /,$endPosition);

        $thisLevelX = "masterX$vert";
        $thisLevelY = "masterY$vert";
        $thisLevelZ = "masterZ$vert";
        if($type eq "cat")
          {
            if($i == 0)
              {
                @basePos = MakePsuedo("@splitStart","@splitEnd");
                if (($#polys < 2) || (($i + 1) == $#polys))
                  {
                    @dropPos = MakePsuedo("@splitEnd","@splitStart");
                  }
                else
                  {

                  }
              }
            @$thisLevelX = CatmullRomDivision();
            @$thisLevelY = CatmullRomDivision();
            @$thisLevelZ = CatmullRomDivision();
          }
        else
          {
            for($spanVert = 1;$spanVert < $segments; $spanVert++)
              {
                @$thisLevelX[$spanVert] = LinearDivision($splitStart[0],$splitEnd[0],$segments,$spanVert);
                @$thisLevelY[$spanVert] = LinearDivision($splitStart[1],$splitEnd[1],$segments,$spanVert);
                @$thisLevelZ[$spanVert] = LinearDivision($splitStart[2],$splitEnd[2],$segments,$spanVert);
              }
          }
      }

    $count++;

    for($segspan=1;$segspan<$segments;$segspan++)#for each of the segements make a curve
      {
        push(@masterList, "dummy");
        for($vertlevel = 0;$vertlevel <= $#startPoly;$vertlevel++)
          {
            $thisLevelX = "masterX$vertlevel";
            $thisLevelY = "masterY$vertlevel";
            $thisLevelZ = "masterZ$vertlevel";
            
            if($#masterList < 0)
              {
                $x = @$thisLevelX[0];
                $y = @$thisLevelY[0];
                $z = @$thisLevelZ[0];
              }

            $x = @$thisLevelX[$segspan];
            $y = @$thisLevelY[$segspan];
            $z = @$thisLevelZ[$segspan];
            if($x eq ""){die;}
            push(@masterList,"$x $y $z");
          }
        $curveCount = 0;
        foreach $position(@masterList)
          {

            @pos = split(/ /,$position);

            if($curveCount == 0)
              {
                lx("tool.set prim.curve on 0");
                lx("tool.setAttr prim.curve mode add");
                lx("tool.setAttr prim.curve number 0");
                $curveCount++;
                next;
              }
             lx("tool.setAttr prim.curve number $curveCount");
             lx("tool.setAttr prim.curve ptX $pos[0]");
             lx("tool.setAttr prim.curve ptY $pos[1]");
             lx("tool.setAttr prim.curve ptZ $pos[2]");
            $curveCount++;
          }
          @masterList = ();
          lx("tool.doApply");
          lx("tool.set prim.curve off 0");
      }
  }
