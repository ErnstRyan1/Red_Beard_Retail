#!perl
#by Allan Kiipli ©2005
#polyMerge merges equally oriented polygons that share edges
#variable $err can be set via script argument and means the number of decimals in precision. The bigger it is the equal polys that must be merged are.

$mlayer=lxq("query layerservice layers ? main");
$layer=$mlayer+1000;
 lxq("layerservice layer.index ? $layer");


$err=3.5;
if(@ARGV){$err=$ARGV[0]}

lx("select.type polygon");

lx("select.cut");
lx("select.layer $layer [set] [0] [0] [-1]");
lx("select.paste");

lx("select.drop polygon");
lxq("query layerservice layer.index ? $layer");

$all=lxq("query layerservice polys ? all"); lxout("lx has $all polys");

#if($all>50){die};

for($i=0; $i<$all; $i++){
 lx("select.drop polygon");
 lx("select.element $layer polygon set 0");
 $sel=lxq("query layerservice polys ? selected");

 @normal=lxq("query layerservice poly.normal ? $sel");
 $normal[0]=int($normal[0]*$err)/$err;  $normal[1]=int($normal[1]*$err)/$err; $normal[2]=int($normal[2]*$err)/$err;

 for($j=1; $j<=$all; $j++){
  @pnorm=lxq("query layerservice poly.normal ? $j");
  $pnorm[0]=int($pnorm[0]*$err)/$err;  $pnorm[1]=int($pnorm[1]*$err)/$err; $pnorm[2]=int($pnorm[2]*$err)/$err; 
  if( $pnorm[0]==$normal[0] && $pnorm[1]==$normal[1] && $pnorm[2]==$normal[2]){

   lx("select.element $layer polygon add $j");
  }  
 }

 lx("poly.merge");
 $all=lxq("query layerservice polys ? all"); lxout("there is $all");
}
lx("select.drop polygon");
lx("select.cut");
lx("select.layer $mlayer [set] [0] [0] [-1]");
lx("select.paste");