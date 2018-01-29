#perl
# arc.pl - Author: Takumi - http://www.modomode.jp

# argument
# 'c' : Catenary

if (lxq("query platformservice appversion ?") < 401) {
  lx("dialog.setup warning");
  lx("dialog.title {Warning}");
  lx("dialog.msg {This script must be run on modo 401.\nwww.modomode.jp}");
  lx("dialog.open");
  return;
}

my @verts = lxq("query layerservice verts ? selected");

if (@verts == 3) {
  if (!lxq("query scriptsysservice userValue.isDefined ? Arc.count")) {
    lx("user.defNew Arc.count integer temporary");
    lx("user.def Arc.count username {Count}");
    lx("user.def Arc.count dialogname {Count of Points}");
    lx("user.def Arc.count min 1");
    lx("user.value Arc.count 1");
  }
  if (lx("user.value Arc.count")) {
    my $startvert = $verts[0];
    my $endvert = $verts[1];
    my $guidevert = $verts[2];
    my $nextvert = $endvert;
    my $count = lxq("user.value Arc.count ?");
    my $layer = lxq("query layerservice layer.index ? main");
    my @allverts = lxq("query layerservice verts ? all");
    my $lastvert = $allverts[$#allverts];

    lx("select.drop vertex");
    lx("tool.set edge.knife on");
    lx("tool.attr edge.knife inside false");
    lx("tool.attr edge.knife middle 0");
    lx("tool.attr edge.knife split 0");
    for (my $i = 0; $i < $count; $i++) {
      my $pos = 1 - (1 / ($count + 1 - $i));
      lx("tool.setAttr edge.knife count " . ($i + 1));
      lx("tool.setAttr edge.knife vert0 " . ($layer - 1) . ",$startvert");
      if ($i != 0) {$nextvert = $lastvert}
      lx("tool.setAttr edge.knife vert1 " . ($layer - 1) . ",$nextvert");
      lx("tool.setAttr edge.knife pos $pos");
      lx("tool.doApply");
      $lastvert++;
    }
    lx("tool.set edge.knife off 0");
    lx("select.element $layer vertex add $startvert");
    while($count > 0) {
      lx("select.element $layer vertex add $lastvert");
      $lastvert--;
      $count--;
    }
    lx("select.element $layer vertex add $endvert");
    lx("select.element $layer vertex add $guidevert");
    @verts = lxq("query layerservice verts ? selected");
  }
}

if (@verts > 3) {
  my @startpos = lxq("query layerservice vert.pos ? $verts[0]");
  my @endpos = lxq("query layerservice vert.pos ? $verts[$#verts - 1]");
  my $width = sqrt(($startpos[0] - $endpos[0]) ** 2 +
                   ($startpos[1] - $endpos[1]) ** 2 +
                   ($startpos[2] - $endpos[2]) ** 2);
  my @guidepos = lxq("query layerservice vert.pos ? $verts[$#verts]");
  my @vec_start_end = _getAtoBvec(\@startpos, \@endpos);
  my @vec_guide_end = _getAtoBvec(\@guidepos, \@endpos);
  my @cross = _cross(\@vec_start_end, \@vec_guide_end);
  my $len = sqrt($cross[0] ** 2 + $cross[1] ** 2 + $cross[2] ** 2);
  if ($len == 0) {$len = 1}
  my @normal = ($cross[0] / $len, $cross[1] / $len, $cross[2] / $len);
  my $arg = shift || "";

  if ($arg eq 'c') {
    my $OREC = 10 ** -6;
    my $default = sprintf("%d", $width);
    if ($default > 0) {
      my $pow = _format2digit($default);
      if ($pow > 0) {$default = $default * 10 ** $pow}
    }
    else {
      $default = sprintf("%f", $width);
      my @string = split(/\./, $default);
      _format2digit($string[1]);
      $default = "0." . $string[1];
    }

    my $height = 0;
    while ($height == 0) {
      if (!lxq("query scriptsysservice userValue.isDefined ? Arc.height")) {
        lx("user.defNew Arc.height distance momentary");
        lx("user.def Arc.height username {Height}");
        lx("user.def Arc.height dialogname {Height}");
        lx("user.def Arc.height min 0");
      }
      lx("user.value Arc.height " . $default);
      if (lx("user.value Arc.height")) {
        $height = lxq("user.value Arc.height ?");
        if ($height == 0) {
          lx("dialog.setup warning");
          lx("dialog.title {Warning}");
          lx("dialog.msg {zero height}");
          lx("dialog.open");
        }
      }
      else {return}
    }

    my $max = 100;
    my $x = -0.5;
    my $a;
    my $low = 0;
    my $high = $max;
    my $nextloop = 1;
    lxmonInit(10 ** 6);
    while($nextloop) {
      $nextloop = 0;
      while ($low <= $high) {
        if(!lxmonStep) {return}
        $a = ($low + $high) / 2;
        my $diff = (($a * _cosh($x / $a)) - $a) * $width;
        if ($diff > $height) {
          $low = $a + $OREC;
          if ($low > $high) {
            $nextloop = 1;
            $high += $max;
          }
        }
        elsif ($diff < $height) {$high = $a - $OREC}
        else {last}
      }
    }

    if (_curvedialog()) {
      if (lxq("user.value Arc.curve ?") eq 'convex') {$a *= -1}
    }
    else {return}

    my @xynormal = (0, 0, 1);
    if ($normal[0] * $xynormal[0] + $normal[1] *
        $xynormal[1] + $normal[2] * $xynormal[2] == -1) {
      my $guidevert = pop(@verts);
      @verts = reverse(@verts);
      push(@verts, $guidevert);

      @startpos = lxq("query layerservice vert.pos ? $verts[0]");
      @endpos = lxq("query layerservice vert.pos ? $verts[$#verts - 1]");
      @vec_start_end = _getAtoBvec(\@startpos, \@endpos);
      @normal = (-$normal[0], -$normal[1], -$normal[2]);
    }

    my $y = $a * _cosh($x / $a);
    my $zoomx = $startpos[0] - $x * $width;
    my $zoomy = $startpos[1] - $y * $width;
    my @cross = _cross(\@normal, \@xynormal);
    my $len = sqrt($cross[0] ** 2 + $cross[1] ** 2 + $cross[2] ** 2);
    if ($len == 0) {$len = 1}
    @cross = ($cross[0] / $len, $cross[1] / $len, $cross[2] / $len);
    my $angle;

    if (!($cross[0] == 0 and $cross[1] == 0 and $cross[2] == 0)) {
      $angle = $normal[0] * $xynormal[0] + $normal[1] *
        $xynormal[1] + $normal[2] * $xynormal[2] /
          sqrt(($normal[0] ** 2 + $normal[1] ** 2 + $normal[2] ** 2) *
               ($xynormal[0] ** 2 + $xynormal[1] ** 2 + $xynormal[2] ** 2));
      $angle = _acos($angle);
      $angle *= -1;
    }

    my @arr;
    my @endpos_new;

    for (my $i = 0; $i < $#verts; $i++) {
      my @pos = (($x * $width) + $zoomx, ($y * $width) + $zoomy, $startpos[2]);
      if (defined($angle)) {
        @pos = _vrot(\@cross, \@pos, \$angle, \@startpos);
      }
      push(@arr, [@pos]);
      if ($i == $#verts - 1) {@endpos_new = ($pos[0], $pos[1], $pos[2])}
      $x += 1 / ($#verts - 1);
      $y = $a * _cosh($x / $a);
    }

    my @vec_start_end_unit_old = ($vec_start_end[0] / $width,
                                  $vec_start_end[1] / $width,
                                  $vec_start_end[2] / $width);

    my @vec_start_end_unit_new = (($endpos_new[0] - $startpos[0]) / $width,
                                  ($endpos_new[1] - $startpos[1]) / $width,
                                  ($endpos_new[2] - $startpos[2]) / $width);

    $angle = ($vec_start_end_unit_old[0] * $vec_start_end_unit_new[0] +
              $vec_start_end_unit_old[1] * $vec_start_end_unit_new[1] +
              $vec_start_end_unit_old[2] * $vec_start_end_unit_new[2]) /
      sqrt(($vec_start_end_unit_old[0] ** 2 +
            $vec_start_end_unit_old[1] ** 2 +
            $vec_start_end_unit_old[2] ** 2) *
           ($vec_start_end_unit_new[0] ** 2 +
            $vec_start_end_unit_new[1] ** 2 +
            $vec_start_end_unit_new[2] ** 2));
    $angle = _acos($angle);

    my @checkpos = ($arr[$#verts - 1][0], $arr[$#verts - 1][1], $arr[$#verts -1][2]);
    @checkpos = _vrot(\@normal, \@checkpos, \$angle, \@startpos);

    if ((sprintf("%.5f", $checkpos[0]) != sprintf("%.5f", $endpos[0])) or
        (sprintf("%.5f", $checkpos[1]) != sprintf("%.5f", $endpos[1])) or
        (sprintf("%.5f", $checkpos[2]) != sprintf("%.5f", $endpos[2]))) {
      $angle *= -1;
    }

    for (my $i = 0; $i < $#arr; $i++) {
      my @pos = ($arr[$i][0], $arr[$i][1], $arr[$i][2]);
      @pos = _vrot(\@normal, \@pos, \$angle, \@startpos);
      lx("vert.move $verts[$i] $pos[0] $pos[1] $pos[2] 0 0 0");
    }
  }
  else {
    my $r;
    my $i = $#verts;
    my $minimumr = sprintf("%f", $width / 2);
    my $mintitle = int($minimumr * (10 ** 4) + 0.5) / (10 ** 4);

    lx("!user.defNew Arc.radius distance momentary");
    lx("user.def Arc.radius min $minimumr");
    lx("user.def Arc.radius username {Radius}");
    lx("user.def Arc.radius dialogname {Minimum Radius: $mintitle m}");
    lx("user.value Arc.radius $minimumr");

    if (lx("user.value Arc.radius")) {
      $r = lxq("user.value Arc.radius ?");
      if (!defined($r)) {return}
    }
    else {return}

    if (_curvedialog()) {
      if (lxq("user.value Arc.curve ?") eq 'concave') {$r *= -1}
      my @midpos = (($endpos[0] + $startpos[0]) / 2,
                    ($endpos[1] + $startpos[1]) / 2,
                    ($endpos[2] + $startpos[2]) / 2);
      my $halflen = sqrt(($startpos[0] - $midpos[0]) ** 2 +
                         ($startpos[1] - $midpos[1]) ** 2 +
                         ($startpos[2] - $midpos[2]) ** 2);
      my $perlen = $r ** 2 - $halflen ** 2;
      if ($perlen > 0) {$perlen = sqrt($r ** 2 - $halflen ** 2)}
      my $coe = $perlen / $halflen;
      my @centerpos = ($midpos[0] + $coe * ($midpos[0] - $startpos[0]),
                       $midpos[1] + $coe * ($midpos[1] - $startpos[1]),
                       $midpos[2] + $coe * ($midpos[2] - $startpos[2]));
      my $angle = (atan2(1, 1) * 4) / 2;

      if ($r > 0) {$angle *= -1}
      @centerpos = _vrot(\@normal, \@centerpos, \$angle, \@midpos);
      $angle = atan2($halflen, $perlen) * 2;
      $angle /= ($i - 1);

      if ($r < 0) {$angle *= -1}
      $i -= 2;
      my @pos = lxq("query layerservice vert.pos ? $verts[$i + 1]");

      while($i > 0) {
        @pos = _vrot(\@normal, \@pos, \$angle, \@centerpos);
        lx("vert.move $verts[$i] $pos[0] $pos[1] $pos[2] 0 0 0");
        $i--;
      }
    }
  }
}

sub _getAtoBvec {
  my ($vecA, $vecB) = @_;
  ($$vecB[0] - $$vecA[0], $$vecB[1] - $$vecA[1], $$vecB[2] - $$vecA[2]);
}

sub _cross {
  my ($vecA, $vecB) = @_;
  ($$vecA[1] * $$vecB[2] - $$vecA[2] * $$vecB[1],
   $$vecA[2] * $$vecB[0] - $$vecA[0] * $$vecB[2],
   $$vecA[0] * $$vecB[1] - $$vecA[1] * $$vecB[0]);
}

sub _vrot {
  my ($vec, $pos, $radian, $center) = @_;
  $$pos[0] -= $$center[0];
  $$pos[1] -= $$center[1];
  $$pos[2] -= $$center[2];
  my $inp = $$vec[0] * $$pos[0] + $$vec[1] * $$pos[1] + $$vec[2] * $$pos[2];
  my @cross = _cross($pos, $vec);  
  my $cosr = cos($$radian);
  my $sinr = sin($$radian);
  my @newpos = ($$pos[0] * $cosr + $$vec[0] * $inp * (1 - $cosr) - $cross[0] * $sinr,
                $$pos[1] * $cosr + $$vec[1] * $inp * (1 - $cosr) - $cross[1] * $sinr,
                $$pos[2] * $cosr + $$vec[2] * $inp * (1 - $cosr) - $cross[2] * $sinr);
  $newpos[0] += $$center[0];
  $newpos[1] += $$center[1];
  $newpos[2] += $$center[2];
  
  @newpos;
}

sub _curvedialog {
  lx("user.defNew Arc.curve integer momentary");
  lx("user.def Arc.curve list {convex;concave}");
  lx("user.def Arc.curve listnames {Convex;Concave;THIS_IS_A_DUMMY_VALUE_FOR_MODO_401}");
  lx("user.def Arc.curve username {Curve}");
  lx("user.def Arc.curve dialogname {Curve}");
  lx("user.value Arc.curve {convex}");
  lx("user.value Arc.curve");
}

sub _format2digit {
  my $number = $_[0];
  my $stlen = length($number);
  if ($stlen > 1) {
    for (my $i = 0; $i < $stlen; $i++) {
      my $n = substr($number, 0, $i) || 0;
      if ($n > 0) {
        $_[0] = substr($number, 0, $i + 1);
        last;
      }
    }
  }
  $stlen - 2;
}

sub _cosh {
  (exp($_[0]) + exp(-$_[0])) / 2;
}

sub _acos {
  atan2(sqrt(1 - $_[0] * $_[0]), $_[0]);
}
