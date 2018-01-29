#!perl
# jj_even version 1.0
# By Julian Johnson - A script for even spacing points and edge points#
# julian@exch.demon.co.uk



my $layer = lxq("query layerservice layers ? main");
my $symmAxis = lxq("select.symmetryAxis ?");
lx("select.symmetryAxis 3");
my $arglist = "@ARGV"; 
#-------------------------------------------------------------------------------

if(lxq( "select.typeFrom {edge;polygon;item;vertex;} ?"))
{
	my %edgehash; my %verthash;
	my @edges = map{[/(\d*),(\d*),(\d*)/]}lxq("query layerservice selection ? edge");
	if ( @edges <= 1)
	{
		lx( "dialog.setup info" );
		lx( "dialog.title {Select More Edges}" );
		lx( "dialog.msg {You need two or more edges for this to work}" );
		lx( "dialog.open" );
		die;
	}
	for(@edges)
	{
		@{$_}[1..2]=sort{$a<=>$b}@{$_}[1..2];
		push @{$edgehash{${$_}[0]}}, [@{$_}[1..2]]; 
	}
	my @verts = map{[/(\d*),(\d*)/]} lxq("query layerservice selection ? vert");
	for (@verts){push @{$verthash{${$_}[0]}}, ${$_}[1];}
	for my $layer (keys %edgehash)
	{
		lxq("query layerservice layer.name ? $layer");
		my (%vpos, %vjoin, %groupab, %edgegroups, %vc);
		my @edges = @{$edgehash{$layer}};
		for (@edges){for (@{$_}) {if ($vc{$_}){$vc{$_}++;} else {$vc{$_} = 1;}}}
		for my $vert(keys %vc)
		{
			for (@edges)
			{
				if ($vert == ${$_}[0])
				{
					push @{$vjoin{$vert}},${$_}[1];
				}
				elsif ($vert == ${$_}[1]) 
				{
					push @{$vjoin{$vert}},${$_}[0];
				}
			}
			$vpos{$vert} = [lxq("query layerservice vert.pos ? $vert")];
		}
		my @startpoints = grep {$vc{$_} == 1} keys %vc;
		my $edgegroupcount = 1;
		for (@startpoints)
		{
			my $joinpts = 1; my $apoint = $_; my $backpoint = $_;
			my $backedge = "($apoint,${$vjoin{$apoint}}[0])";
			my @startedgev = &vsub($vpos{$apoint},$vpos{${$vjoin{$apoint}}[0]});
			unless ($edgegroups{"$apoint ${$vjoin{$apoint}}[0]"})#grouped?
			{
				push @{$groupab{$edgegroupcount}},$_;
				while (@{$vjoin{$apoint}} >= $joinpts )
				{
						my @polylist = lxq("query layerservice edge.polyList ? $backedge");
						my %polyvertlist; my @verts;
						for (@polylist) {push @verts, lxq("query layerservice poly.vertList ? $_");}
						for (@verts){$polyvertlist{$_} = 1;}
						for my $vert(@{$vjoin{$apoint}})
						{
							unless ($joinpts < 2 )
							{
								if ($backpoint == $vert){next;}
								if ($polyvertlist{$vert} == 1){next;}
							}
							$backpoint = $apoint; 
							$apoint = $vert; 
							$backedge = "($apoint,$backpoint)";
							last;
						}
					push @{$groupab{$edgegroupcount}},$apoint;
					my @sortedge = sort {$a<=>$b} ($apoint, $backpoint);
					$edgegroups{"$sortedge[0] $sortedge[1]"} = $edgegroupcount;
					$joinpts = 2;
				}
				$edgegroupcount++;
			}
		}
		my %groupvec;
		for (keys %groupab)
		{
			my @temp = &vsub($vpos{${$groupab{$_}}[0]},$vpos{${$groupab{$_}}[-1]});
			my $mag = &vmag(\@temp);
			@temp = &vnorm(\@temp);
			$groupvec{$_} = [@temp,$mag];
		}
		lx("select.typeFrom {vertex;polygon;item;edge}");
		lx("select.drop vertex");
		for (keys %groupab)
		{
			my @temp = @{$groupab{$_}}[1..$#{$groupab{$_}}-1];
			my @test2 = @{$groupab{$_}};
			my $length = ${$groupvec{$_}}[-1]/(@temp+1);
			my @vector = @{$groupvec{$_}}[0..2];
			my @startpoint = @{$vpos{${$groupab{$_}}[0]}};
			my @disp = &vmult(\@vector,$length);
			for (@temp)
			{
				my @final = ($disp[0]+$startpoint[0],$disp[1]+$startpoint[1],$disp[2]+$startpoint[2]);
				#my @ptdisp = &vsub(\@final, $vpos{$_});
				@startpoint = @final;
				lx("select.element $layer vertex set index:[$_]");
				unless ($arglist =~ /lockx/){lx("vert.set x $final[0]");}
				unless ($arglist =~ /locky/){lx("vert.set y $final[1]");}
				unless ($arglist =~ /lockz/){lx("vert.set z $final[2]");}
				lx("select.drop vertex");
				
			}
		}
	}#end for layers
	lx("select.typeFrom {vertex;polygon;item;edge}");
	for my $layer(keys %verthash)
	{
		for (@{$verthash{$layer}})
		{
			lx("select.element $layer vertex set index:[$_]");
		}
	}
	lx("select.typeFrom {edge;vertex;polygon;item}");
}#end if

#-------------------------------------------------------------------------------

elsif (lxq( "select.typeFrom {vertex;edge;polygon;item} ?"))
{
	my (%verthash,%vertpos,@vertdata);
	my @verts = map{[/(\d*),(\d*)/]} lxq("query layerservice selection ? vert");
	if ( @verts <= 2)
	{
		lx( "dialog.setup info" );
		lx( "dialog.title {Select More Points}" );
		lx( "dialog.msg {You need three or more points for this to work}" );
		lx( "dialog.open" );
		die;
	}
	lx("select.drop vertex");
	for (@verts) 
	{ 
		my $layer = ${$_}[0];
		lxq("query layerservice layer.name ? [$layer]");
		my $vert = ${$_}[1];
		push @{$_}, [ lxq("query layerservice vert.pos ? $vert") ];
	}
 	my @vector = &vsub(${$verts[0]}[2], ${$verts[1]}[2]);
 	my $vmag = &vmag(\@vector);
 	my $length = $vmag/(@verts-1);
 	@vector = &vnorm(\@vector);
	for (@verts[2..$#verts])
 	{
 		my @ptvector = &vsub(${$verts[0]}[2],${$_}[2]);
		push @vertdata, [&vdot(\@vector,\@ptvector), ${$_}[0], ${$_}[1] ];# vertdata contains dot, vertlayer, vertindex
 	}
 	@vertdata = sort {$a->[0] <=> $b->[0]} @vertdata;
 	my @startpoint = @{${$verts[0]}[2]};
 	my @disp = &vmult(\@vector,$length);
	for (@vertdata)
 	{
		my @final = ($disp[0]+$startpoint[0],$disp[1]+$startpoint[1],$disp[2]+$startpoint[2]);
 		my $vert = ${$_}[2];
		my $layer = ${$_}[1];
 		lx("select.element [$layer] vertex set index:[$vert]");
		unless ($arglist =~ /lockx/){lx("vert.set x $final[0]");}
		unless ($arglist =~ /locky/){lx("vert.set y $final[1]");}
		unless ($arglist =~ /lockz/){lx("vert.set z $final[2]");}
 		lx("select.drop vertex");
 		@startpoint = @final;
 	}
 	for (@verts){lx("select.element ${$_}[0] vertex set index:${$_}[1]");}
 }

elsif (  (lxq( "select.typeFrom {polygon;item;vertex;edge} ?")) || (lxq( "select.typeFrom {item;vertex;edge;polygon} ?")) )
	{
		lx( "dialog.setup info" );
		lx( "dialog.title {You Must Be in Point or Edge Mode}" );
		lx( "dialog.msg {You must be in point or edge mode}" );
		lx( "dialog.open" );
		die;
	}
lx("select.symmetryAxis $symmAxis"); 






sub vmult
	{
		my @v = @{shift @_};
		my $f = shift @_;
		for (@v){$_= $f*$_;}
		return @v;
	}
sub vcross
	{
		my @v1 = @{shift @_}; my @v2 = @{shift @_};
		my @cross = (($v1[1]*$v2[2])-($v1[2]*$v2[1]),
		($v1[2]*$v2[0])-($v1[0]*$v2[2]),($v1[0]*$v2[1])-($v1[1]*$v2[0]));
	}
sub vdot
	{
		my @v1 = @{shift @_}; my @v2 = @{shift @_};#lxout("@v1,@v2");
		my $dot = $v1[0]*$v2[0]+$v1[1]*$v2[1]+$v1[2]*$v2[2];
	}
sub vsub
	{
		my @v1 = @{shift @_}; my @v2 = @{shift @_};
		my @v = ($v2[0]-$v1[0], $v2[1]-$v1[1], $v2[2]-$v1[2]);
	}
sub vmag
	{
		my @v = @{shift @_};
		my $v = sqrt($v[0]**2+$v[1]**2+$v[2]**2);
	}
sub vnorm
	{
		my @v = @{shift @_};
		my $mag = &vmag(\@v);
		foreach my $variable (@v[0..2]) {$variable/= $mag;}
		return @v;
	}

sub step 
	{
		my $variable = shift;
		if ($variable eq "") {$variable = "empty";}
		lx( "dialog.setup yesNo" );
		lx( "dialog.title $variable" );
		lx( "dialog.msg $variable" );
		lx( "dialog.open" );
		my $dialogVerdict = lxq( "dialog.result ?" );
		if( $dialogVerdict == 0 ){die;}
	}