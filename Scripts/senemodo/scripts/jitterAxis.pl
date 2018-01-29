#perl
#author : Seneca Menard
#ver 1.5
my $axis = @ARGV[0];

if ($axis =~ /x/i){lx("tool.attr xfrm.jitter enableX 1");}  else  {lx("tool.attr xfrm.jitter enableX 0");}
if ($axis =~ /y/i){lx("tool.attr xfrm.jitter enableY 1");}  else  {lx("tool.attr xfrm.jitter enableY 0");}
if ($axis =~ /z/i){lx("tool.attr xfrm.jitter enableZ 1");}  else  {lx("tool.attr xfrm.jitter enableZ 0");}

lx("!!tool.attr xfrm.jitter rangeX 0.0");
lx("!!tool.attr xfrm.jitter rangeY 0.0");
lx("!!tool.attr xfrm.jitter rangeZ 0.0");