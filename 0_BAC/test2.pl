#!/usr/bin/perl
#
# --------------------------------------------------------------------------
# TEST2.PL
# --------------------------------------------------------------------------
# Debug program to find out where the current working directory of Perl is.
# --------------------------------------------------------------------------

print "Content-type: text/html\n\n";
print "<html>";
print "<head>";
print "<style>td, th {border: 1px solid #dddddd; text-align: left; padding: 8px;} tr:nth-child(even) {background-color: #dddddd;}</style>";
print "<title>Survey Self-Hosting Test #2</title>";
print "</head>";
print "<body style=\"font-family: verdana;\">";
print "<h1>Self-Hosting Test #2</h1>";

print "<h2>1. Runtime Environment Directories</h2>";
print "<h4>The following is the list of paths Perl is checking for included files (\@INC):</h4>";

print PrintEnvironmentDirectories();

print "\n<br>\".\" signifies the working directory.";

print "<hr>";
print "<h2>2. Working Directory</h2>";
print "<h4>Below is a listing of all the files in the current working directory (where this test2.pl perl script is running):</h4>";

opendir DATADIR, "." or {Error("Error! Please ensure the Perl envrionment configurations and file permissions are set to allow perl scripts to open the directory in which perl scripts exist.")};

my @allFiles = ();

@allFiles = readdir DATADIR;

closedir DATADIR;

print join("<br>\n",@allFiles);

print "<hr>";
print "<h2>3. Available Perl Modules</h2>";
print "<h4>The table below is a list of the Perl modules that may be used by Sawtooth Software surveys.</h4>";
print PrintAvailableModules();

print "</body>\n</html>\n";


# -------------------------------------------------------

sub PrintEnvironmentDirectories
{
	my $astrOut = "<p>";
	my $i = 0;

	for ($i = 0;$i < @INC; $i++) 
	{
		$astrOut .= "" . ($i + 1) . ")" . $INC[$i] . "<br>\n";
	}

	$astrOut .= "</p>";
	return $astrOut;
}

sub PrintWorkingDirectory
{
	my @allFiles = ();

	opendir DATADIR, "." or {Error("Error! Please ensure the Perl environment configurations and file permissions are set to allow perl scripts to open the directory in which perl scripts exist.")};
	@allFiles = readdir DATADIR;
	closedir DATADIR;

	my $strOut = join("<br>\n",@allFiles);

	return $strOut;
}

sub PrintAvailableModules
{
	my $strCode = "";
	my $strOut = "<table><tr><th>Module Name</th><th>Working?</th><th>Installed Version</th><th>Notes</th></tr>";

	$strOut .= "<tr>" . PrintCells("DBI") . "<td>This Module is required for <em><strong>all</strong></em> Sawtooth Software Surveys.</td></tr>";
	$strOut .= "<tr>" . PrintCells("DBD::mysql")  . "<td>This Module is required for running surveys that will connect to a <em><strong>MySQL</strong></em> or <em><strong>MariaDB</strong></em> database.</td></tr>";
	$strOut .= "<tr>" . PrintCells("DBD::ODBC") . "<td>This Module is required for running surveys that will connect to a <em><strong>Microsoft SQL Server</strong></em> database.</td></tr>";
	$strOut .= "<tr>" . PrintCells("JSON") . "<td>This Module is required for running surveys built with <em><strong>Lighthouse Studio 9.10</strong></em> or later.</td></tr>";
	$strOut .= "<tr>" . PrintCells("DateTime") . "<td>This Module is <em><strong>optional</strong></em>. It allows for better formatting of time stamps in the Admin Module.</td></tr>";


	$strOut .= "</table>";

	return $strOut;
}

sub PrintCells
{
    my $strModuleName = $_[0];
	$strCode = "require " . $strModuleName;
	eval $strCode;

    my $strOut .= "<td>" . $strModuleName . "</td>";
	if ($strModuleName->VERSION) 
	{
        $strOut .= "<td style='font-size:20px; text-align: center; color: green;'>&#10004;</td>";
        $strOut .= "<td>" . $strModuleName->VERSION . "</td>";
	}
    else
    {
        $strOut .= "<td style='font-size:20px; text-align: center; color: red;'>&#10006;</td>";
        $strOut .= "<td>-</td>";
    }
	return $strOut;
}


sub Error
{
	my ($strMsg) = @_;

	print "\n<br>" . $strMsg . "<br>\n";

	exit;
}
