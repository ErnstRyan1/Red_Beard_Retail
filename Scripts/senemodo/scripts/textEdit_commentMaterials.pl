#perl
#ver 0.5
#author : Seneca Menard
#This script will comment out a series of shaders.

BEGIN {push @INC,'C:/Perl/lib';}
use Tie::File;

lxout("eh?");
my %shaderLineTable;
#my %brokenMaterialsTable;
#@{$brokenMaterialsTable{"C:\/Documents and Settings\/seneca\/Desktop\/testShader.m2"}} = ('models/mapobjects/test/bumpNormal','textures/test/orientation');



my %brokenMaterialsTable;
my $textFile = "C:\/Documents and Settings\/seneca\/Desktop\/bad_material_list.txt";
open (textFile, $textFile) or die("couldn't find $textFile");
while (<textFile>){
	my @words = split(/,/,$_);
	chomp(@words[-1]);
	@words[-1] =~ s/\s//;
	@words[-1] = "W:\/Rage\/base\/".@words[-1];
	push(@{$brokenMaterialsTable{@words[-1]}},@words[0]);
}









foreach my $m2File (keys %brokenMaterialsTable){
	tie @textFile, 'Tie::File', $m2File or die("I couldn't find the file : $m2File");
	findShaderLines($m2File);

	foreach my $shader (@{$brokenMaterialsTable{$m2File}}){
		$shader = lc($shader);
		$shader =~ s/\\/\//;
		my @lines = @{$shaderLineTable{$shader}};
		@textFile[$_] = "//".@textFile[$_] for @lines;
	}
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#FIND SHADER LINES SUB (opens an M2 and writes all the shaders to a hash table)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : findShaderLines(W:\Rage\base\m2\senedark.m2);
#requires a global %shaderLineTable;
sub findShaderLines{
	my $currentLine = 0;
	my $bracketCount = 0;
	my $currentMaterial = "";

	open (m2File, "<@_[0]") or die("I couldn't find the material file : @_[0]");
	while (<m2File>){
		$_ =~ s/\/\/.*//;
		$_ =~ s/\\/\//g;
		my $bracketLCount = tr/\{//;
		my $bracketRCount = tr/\}//;
		$bracketCount += $bracketLCount;

		if ($bracketCount == 0){
			if ($_ =~ /[a-zA-Z0-9]/){
				$_ =~ s/material//i;
				$_ =~ s/^\s*//g;
				$_ =~ s/^\t*//g;
				$_ =~ s/\s*$//g;
				$_ =~ s/\t*$//g;
				$currentMaterial = lc($_);
				#popup("material name = $currentMaterial");
				push(@{$shaderLineTable{$currentMaterial}},$currentLine);
			}
		}else{
			#lxout("$currentLine : $bracketCount : adding line $_ to $currentMaterial table");
			push(@{$shaderLineTable{$currentMaterial}},$currentLine);
		}

		$bracketCount -= $bracketRCount;
		$currentLine++;
	}

	close(m2File);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

