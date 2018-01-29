#perl
#ver 1.0
#author : Seneca Menard

#To use this script, just type in the script name followed by the action center name.  If you want the same center and axis, just type in the name.  If you want a different center and axis, put a comma (with no spaces) inbetween those two names
#Here's some examples :
#@actr.pl element
#@actr.pl element,auto


if (@ARGV[0] =~ ","){
	my @actr = split/,/,@ARGV[0];
	lxout("[->] Turning on (@actr[0],@actr[1])");
	lx("tool.set center.@actr[0] on");
	lx("tool.set axis.@actr[1] on");
}
else{
	lxout("[->] Turning on (@ARGV[0])");
	lx("tool.set actr.@ARGV[0] on");
}

if (@ARGV[1] ne ""){
	my $string = @ARGV[1];
	for (my $i=2; $i<@ARGV; $i++){
		$string = $string ." ". @ARGV[$i];
	}
	lx("$string");
}











sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
