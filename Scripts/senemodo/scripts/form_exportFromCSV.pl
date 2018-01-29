#perl
#ver 0.5
#author : Seneca Menard

#This script is to create the sen_scripts form from an excel spreadsheet database.
#NOTE : input and output files are hardcoded right now and I also delete the CSV file after the script is finished.

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#											PRINT OUT HEAD OF FORM											#
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my %excelColumn;
my $configFilePath = "C:\/Users\/Seneca Menard\/AppData\/Roaming\/Luxology\/Scripts\/senemodo\/scripts\/senemodokit.cfg";
system "p4 edit $configFilePath";
my $csvFilePath = "C:\/Users\/Seneca Menard\/Desktop\/seneca_scripts_form_data.csv";
my $hash = "senemodokit";
open (CFG, ">$configFilePath");
lxout("---------------------------------------------------");
lxout("Importing this CSV : ($csvFilePath)");
lxout("Exporting this CFG : ($configFilePath)");
lxout("---------------------------------------------------");

print CFG "<?xml version=\"1.0\"?>\n";
print CFG "<configuration>\n";
print CFG "  <atom type=\"Attributes\">\n";
print CFG "    <hash type=\"Sheet\" key=\"" . $hash . ":sheet\">\n";
print CFG "      <atom type=\"Label\">sen_Scripts and Guis</atom>\n";
print CFG "      <atom type=\"Export\">1</atom>\n";
print CFG "      <atom type=\"Layout\">vtoolbar</atom>"; #TEMP!

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#											PRINT OUT SHEET BUTTONS											#
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
open (CSV, "<$csvFilePath");
my $line = 0;
while (<CSV>) {
	if ($line != 0){
		if ($_ =~ /sheet/i){
			my $string = swapNonQuotedChars($_,",","|");
			$string =~ s/\"//g;
			chomp($string);
			my @values = split(/\|/, $string);
			my $hashNum = $values[$excelColumn{"SheetHash"}];

			if ($values[$excelColumn{"Type"}] eq "sheet"){
				printFormBlock(sheet,$values[$excelColumn{"SheetHash"}],$values[$excelColumn{"Label"}],sheetButton);
			}
		}
	}else{
		determineExcelColumnArrayOrder($_);
	}
	$line++;
}
close CSV;

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#											PRINT OUT BODY OF FORM											#
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
open (CSV, "<$csvFilePath");
readline(CSV); #skip first line
while (<CSV>) {
	$hash = "sen".int(rand(99999999));
	my $string = swapNonQuotedChars($_,",","|");
	$string =~ s/\"//g;
	chomp($string);
	my @values = split(/\|/, $string);

	#read and print command text
	if ($values[$excelColumn{"Type"}] eq ""){
		my @altCmdArray;
		if ($values[$excelColumn{"Mdfr_CtrlCmd"}] ne "")	{	push(@altCmdArray,$values[$excelColumn{"Mdfr_CtrlCmd"}],$values[$excelColumn{"Mdfr_CtrlLabel"}],"ctrl");	}
		if ($values[$excelColumn{"Mdfr_ShiftCmd"}] ne "")	{	push(@altCmdArray,$values[$excelColumn{"Mdfr_ShiftCmd"}],$values[$excelColumn{"Mdfr_ShiftLabel"}],"shift");	}
		if ($values[$excelColumn{"Mdfr_AltCmd"}] ne "")		{	push(@altCmdArray,$values[$excelColumn{"Mdfr_AltCmd"}],$values[$excelColumn{"Mdfr_AltLabel"}],"alt");		}
		printFormBlock(button,$values[$excelColumn{"Cmd/Sheet Key"}],$values[$excelColumn{"Label"}],$values[$excelColumn{"Tooltip"}],"",$values[$excelColumn{"Description"}],"",$hash,$values[$excelColumn{"Enabled 0/1"}],\@altCmdArray);
	}

	#read and print sheet text
	elsif ($values[$excelColumn{"Type"}] eq "sheet"){
		printFormBlock(sheet,$values[$excelColumn{"SheetHash"}],$values[$excelColumn{"Label"}]);
	}

	#read and print divider
	elsif ($values[$excelColumn{"Type"}] eq "divider"){
		printFormBlock(divider,$hash);
	}

	#crash script
	else{
		die("this line : ($line) has a Type value that's not 'empty', 'sheet', or 'divider'");
	}
}
close (CSV);
system "del $csvFilePath";


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#											PRINT OUT TAIL OF FORM											#
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
print CFG "    </hash>\n";
print CFG "  </atom>\n";
print CFG "</configuration>\n";
close CFG;

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#											PRINT FORM BLOCK SUB											#
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : printFormBlock(0=button,1=command,2=label,3=tooltip,4=help,5=description,6=startCollapsed,7=hashNumber,8=enable,9=\@altCmdArray,10=sheetHashNumber);
#        printFormBlock(0=divider,1=hashNumber);
#        printFormBlock(0=sheet,1=hashNumber,2=label,3=sheetButton|empty);
sub printFormBlock{
	if ($_[0] eq "button"){
								print CFG "      <list type=\"Control\" val=\"cmd ".$_[1]."\">\n";
		if ($_[2] ne "")	{	print CFG "        <atom type=\"Label\">".$_[2]."</atom>\n";			}
		if ($_[3] ne "")	{	print CFG "        <atom type=\"Tooltip\">".$_[3]."</atom>\n";			}
		if ($_[4] ne "")	{	print CFG "        <atom type=\"Help\">".$_[4]."</atom>\n";				}
		if ($_[5] ne "")	{	print CFG "        <atom type=\"Desc\">".$_[5]."</atom>\n";				}
		if ($_[6] ne "")	{	print CFG "        <atom type=\"StartCollapsed\">".$_[6]."</atom>\n";	}
		if ($_[7] ne "")	{	print CFG "        <atom type=\"Hash\">".$_[7].":control</atom>\n";		}
		if ($_[8] ne "")	{	print CFG "        <atom type=\"Enable\">0</atom>\n";					}
		if ($_[9] ne "")	{
			for (my $i=0; $i<@{$_[9]}; $i=$i+3){
				print CFG "        <list type=\"AltCmd\" val=\"".@{$_[9]}[$i]."\">\n";
				print CFG "          <atom type=\"AltCmdLabel\">".@{$_[9]}[$i+1]."</atom>\n";
				print CFG "          <atom type=\"AltCmdQualifiers\">".@{$_[9]}[$i+2]."</atom>\n";
				print CFG "        </list>\n";
			}
		}
								print CFG "        <list type=\"AltCmd\" val=\"cmds.mapKey command:&quot;".$_[1]."&quot;\">\n";
								print CFG "          <atom type=\"AltCmdLabel\">Map Hotkey</atom>\n";
								print CFG "          <atom type=\"AltCmdQualifiers\">ctrl-shift</atom>\n";
								print CFG "        </list>\n";
								print CFG "      </list>\n";
	}elsif ($_[0] eq "divider"){
		print CFG "      <list type=\"Control\" val=\"div \">\n";
		print CFG "        <atom type=\"Alignment\">full</atom>\n";
		print CFG "        <atom type=\"StartCollapsed\">0</atom>\n";
		print CFG "        <atom type=\"Hash\">" . $_[1] . ":control</atom>\n";
		print CFG "      </list>\n";
	}elsif ($_[0] eq "sheet"){
		if ($_[3] eq "sheetButton"){
			print CFG "      <list type=\"Control\" val=\"sub " . $_[1] . ":sheet\">\n";
			print CFG "        <atom type=\"Label\">" . $_[2] . "</atom>\n";
			print CFG "        <atom type=\"Style\">popover</atom>\n"; #TEMP!
			print CFG "        <atom type=\"StartCollapsed\">1</atom>\n";
			print CFG "        <atom type=\"Hash\">" . $_[1] . ":sheet</atom>\n";
			print CFG "      </list>\n";
		}else{
			print CFG "    </hash>\n";
			print CFG "    <hash type=\"Sheet\" key=\"" . $_[1] . ":sheet\">\n";
			print CFG "      <atom type=\"Label\">" . $_[2] . "</atom>\n";
			print CFG "      <atom type=\"Style\">popover</atom>\n"; #TEMP!
			print CFG "      <atom type=\"Layout\">vtoolbar</atom>\n";
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#								DETERMINE EXCEL COLUMN ARRAY ORDER SUB										#
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub determineExcelColumnArrayOrder{
	my $string = $_[0];
	chomp($string);
	my @values = split(/,/, $string);
	for (my $i=0; $i<@values; $i++){
		if		($values[$i] eq "Type")				{	$excelColumn{"Type"} = $i;				}
		elsif	($values[$i] eq "Label")			{	$excelColumn{"Label"} = $i;				}
		elsif	($values[$i] eq "Cmd/Sheet Key")	{	$excelColumn{"Cmd/Sheet Key"} = $i;		}
		elsif	($values[$i] eq "Tooltip")			{	$excelColumn{"Tooltip"} = $i;			}
		elsif	($values[$i] eq "Description")		{	$excelColumn{"Description"} = $i;		}
		elsif	($values[$i] eq "Enabled 0\/1")		{	$excelColumn{"Enabled 0\/1"} = $i;		}
		elsif	($values[$i] eq "Mdfr_CtrlCmd")		{	$excelColumn{"Mdfr_CtrlCmd"} = $i;		}
		elsif	($values[$i] eq "Mdfr_CtrlLabel")	{	$excelColumn{"Mdfr_CtrlLabel"} = $i;	}
		elsif	($values[$i] eq "Mdfr_AltCmd")		{	$excelColumn{"Mdfr_AltCmd"} = $i;		}
		elsif	($values[$i] eq "Mdfr_AltLabel")	{	$excelColumn{"Mdfr_AltLabel"} = $i;		}
		elsif	($values[$i] eq "Mdfr_ShiftCmd")	{	$excelColumn{"Mdfr_ShiftCmd"} = $i;		}
		elsif	($values[$i] eq "Mdfr_ShiftLabel")	{	$excelColumn{"Mdfr_ShiftLabel"} = $i;	}
		elsif	($values[$i] eq "Mdfr_ShiftLabel")	{	$excelColumn{"Mdfr_ShiftLabel"} = $i;	}
		elsif	($values[$i] eq "SheetHash")		{	$excelColumn{"SheetHash"} = $i;			}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#										SWAP NON QUOTED CHARS SUB											#
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : $string = swapNonQuotedChars($string,$searchTerm_old,$searchTerm_new);
sub swapNonQuotedChars{
	my $string = $_[0];
	my $quoteCounter = 0;
	for (my $i=0; $i<length($string); $i++){
		my $currentChar = substr ($string, $i, 1);
		if ($currentChar eq "\""){
			$quoteCounter++;
			if ($quoteCounter == 2){$quoteCounter = 0;}
		}elsif (($currentChar eq $_[1]) && ($quoteCounter == 0)){
			substr($string,$i,1,$_[2]);
		}
	}
	return ($string);
}


