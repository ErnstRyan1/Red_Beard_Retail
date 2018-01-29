#!perl
#
#@SelectNextItem.pl add
#
#---------------------------------
#A Script By Allan Kiipli (c) 2013
#---------------------------------
#
#Uses numbers in names ends to select next
#item.
#
#Select two items with same name shape
#and number in name end. The difference
#from first to second results in next
#number. Add "add" to add to selection.
#Last two items in selection are used
#to set next number. If only one item
#is selected, "difference" is queried from
#user value. Else this user value is set
#from $difference variable calculated inside script.
#Change this variable, if you already
#use this user value to a unused name.
#
#Works on items with "locator" selection
#qualifyer.
#
#If items have parenthesis in their name
#around digital part in the end, this
#situation is also working.

$add = 0;

if("@ARGV" =~ /\badd\b/)
{
 $add = 1;
}

lxout("add $add");

@selectedItems = lxq("query sceneservice selection ? locator");

lxout("selectedItems @selectedItems");

$first = $selectedItems[$#selectedItems-1];
$last = $selectedItems[$#selectedItems];

$firstName = lxq("query sceneservice item.name ? $first");

lxout("firstName $firstName");

$lastName = lxq("query sceneservice item.name ? $last");

lxout("lastName $lastName");

$firstName =~ /\(?(\d+)\)?$/;

$first_digits = $1;

lxout("first_digits $first_digits");

$lastName =~ /\(?(\d+)\)?$/;

$last_digits = $1;

lxout("last_digits $last_digits");

if(@selectedItems == 1)
{
 $difference = lxq("user.value difference ?");
}
else
{
 $difference = $last_digits - $first_digits;
}

lxout("difference $difference");

if(!lxq("query scriptsysservice userValue.isDefined ? difference"))
{
 lx("user.defNew difference integer");
}

lx("user.value difference $difference");

if($lastName =~ /\((\d+)\)$/)
{
 $parenthese = 1;
}

$lastName =~ s/\(?(\d+)\)?$//;

$nameShape = $lastName;

lxout("nameShape $nameShape");

if($parenthese)
{
 $nextName = $nameShape."(".($last_digits + $difference).")";
}
else
{
 $nextName = $nameShape.($last_digits + $difference);
}

lxout("nextName $nextName");

if($add)
{
 lx("!select.item {$nextName} add");
}
else
{
 lx("!select.item {$nextName} set");
}

