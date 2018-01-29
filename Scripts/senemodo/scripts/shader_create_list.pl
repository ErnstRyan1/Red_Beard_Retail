#perl
#this script is a quick hack to create (n) shaders in a linear order.  just change the material name and the number of materials needed.

BEGIN{
	my $perlDir = "C:\/Perl\/lib";
	my $perlDir2 = "H:\/Home\/Seneca Menard\/artistTools_Modo\/Perl\/lib";
	push(@INC,$perlDir);
	push(@INC,$perlDir2);
}


#win32 clipboard
use Win32::Clipboard;
my $material = Win32::Clipboard::GetText();
print "Creating this material : $material\n\n";
#---------------------
my @materialTypes = (surfType_Cardboard,surfType_Concrete,surfType_Dirt,surfType_Fabric,surfType_Flesh,surfType_Foliage,surfType_Glass,surfType_Linoleum,surfType_Liquid,surfType_Metal,surfType_None,surfType_Plastic,surfType_Asphalt,surfType_Rubber,surfType_Stone,surfType_Wood,surfType_Rock,surfType_SteamPipe,surfType_WaterPipe);
print "These are the material types : \n";
print "=====================================\n";
for (my $i=0; $i<@materialTypes; $i++){
	my $roundedIndice = roundIntString($i,2,"space");
	print "$roundedIndice : $materialTypes[$i]\n";
}
print "=====================================\n\nChoose one:";
my $response = <STDIN>;
if ($response !~ /[0-9]/){die;}
my $surfType = $materialTypes[$response];
#---------------------
my @specularTypes = ("none","powermip 0","powermip 1","powermip 2","powermip 3","powermap");
print "\nThese are the specular types?:\n";
print "=====================================\n";
for (my $i=0; $i<@specularTypes; $i++){	print "$i : $specularTypes[$i]\n";}
print "=====================================\n\nChoose one:";
my $specular = <STDIN>;
if ($specular !~ /[0-5]/){die;}
my $specularType = $specularTypes[$specular];
#---------------------
print "\nShould this material use HQSpecularNormal?:";
my $hqSpecNormal = <STDIN>;
if ($hqSpecNormal !~ /[yn]/){die;}
#---------------------
print "\nHow many materials do we need to create?:";
my $materialCount = <STDIN>;
if ($materialCount !~ /[0-9]/){die;}


chomp($materialCount);

my @array;
for (my $i=$materialCount; $i>0; $i--){
	push(@array,$material."_".$i);
	push(@array,"{");
	push(@array,"\tsurfaceType\t\t\t\t".$surfType);

	if ($specularType =~ /mip/i){
		my $amount = $specularType;
		$amount =~ s/[^0-9]//g;
		if ($amount > 3){$amount = 3;}
		push(@array,"\tpowermip\t\t\t\t".$amount."\n");
	}

	if ($hqSpecNormal =~ /y/i){
		push(@array,"\tHQSpecularNormal\t\t1\n");
	}


	push(@array,"\tbumpmap\t\t\t\t\t".$material."_".$i."_local");
	push(@array,"\tdiffusemap\t\t\t\t".$material."_".$i);

	if ($specularType !~ /none/i){
		push(@array,"\tspecularmap\t\t\t\t".$material."_".$i."_s");
	}

	if ($specularType =~ /map/i){
		push(@array,"\tpowermap\t\t\t\t".$material."_".$i."_pm");
	}

	push(@array,"\n\tinteractionProgram\t\tinterTwoSide");
	push(@array,"\tcovermap\t\t\t\t".$material."_".$i);
	push(@array,"}\n");
}

my $newLine;
foreach my $line (@array){
	$newLine .= $line . "\n";
}
Win32::Clipboard::Set($newLine);


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 1){
			lx("user.defDelete seneTempDialog");
		}
		lx("user.defNew name:[seneTempDialog] type:{$_[1]} life:[momentary]");		
		lx("user.def seneTempDialog username [$_[0]]");
		if (($_[3] != "") && ($_[4] != "")){
			lx("user.def seneTempDialog min [$_[3]]");
			lx("user.def seneTempDialog max [$_[4]]");
		}
		lx("user.value seneTempDialog [$_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS WILL ROUND THE CURRENT INTEGER to the string length you define (will fill in empty space with 0s)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $roundedIntegerString = roundIntString(1,3,0|space);  #outputs "001";
#note : arg "0|space" is so you can pad the number with either zeroes or spaces.
sub roundIntString{
	my $padChar = "0";
	if ($_[2] eq "space"){$padChar = " ";}
	my $roundedNumber = int($_[0] + .5);
	$_ = $roundedNumber;
	my $count = s/.//g;

	if  ($count < @_[1]){
		$roundedNumber  = $padChar x ((@_[1]) - $count) . $roundedNumber;
	}
	return($roundedNumber);
}

