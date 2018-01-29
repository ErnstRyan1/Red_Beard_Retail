#perl
#ver 1.0
#author : Seneca Menard
#This script is for setting relax presets

my $modoVer = lxq("query platformservice appversion ?");

if ($modoVer > 700){
	if ($ARGV[0] eq "lock"){
		lx("tool.set uv.relax on");
		lx("tool.reset");
		lx("tool.attr uv.relax mode abf");
		lx("tool.attr uv.relax iter 0");
		lx("tool.attr uv.relax lock 1");
	}elsif ($ARGV[0] eq "interactive"){
		lx("tool.set uv.relax on");
		lx("tool.attr uv.relax mode abf");
		lx("tool.attr uv.relax live 1");
	}else{
		lx("tool.set uv.relax on");
		lx("tool.reset");
		lx("tool.attr uv.relax mode adaptive");
		lx("tool.attr uv.relax iter 150");
		lx("tool.attr uv.relax lock 0");
	}
}else{
	if ($ARGV[0] eq "lock"){
		lx("tool.set uv.relax on");
		lx("tool.reset");
		lx("tool.attr uv.relax mode unwrap");
		lx("tool.attr uv.relax iter 50");
		lx("tool.attr uv.relax lock 1");
	}elsif ($ARGV[0] eq "interactive"){
		lx("tool.set uv.relax on");
		lx("tool.reset");
		lx("tool.attr uv.relax mode unwrap");
		lx("tool.attr uv.relax live 1");
	}else{
		lx("tool.set uv.relax on");
		lx("tool.reset");
		lx("tool.attr uv.relax mode adaptive");
		lx("tool.attr uv.relax iter 150");
		lx("tool.attr uv.relax lock 0");
	}
}
