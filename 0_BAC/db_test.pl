#!/usr/bin/perl
use strict;
use CGI;

my $ConfigHashRef = {};

#----------------------------------------------------------
#Set database settings here
#----------------------------------------------------------
$ConfigHashRef->{"database_type"} = "mysql"; #ODBC (for MS SQL) or mysql (for MySQL)
$ConfigHashRef->{"database_name"} = "SawtoothDB1";
$ConfigHashRef->{"database_username"} = "SawtoothUser";
$ConfigHashRef->{"database_password"} = "Jt535RMJx5";
$ConfigHashRef->{"database_address"} = "127.0.0.1"; #127.0.0.1 if on local machine
$ConfigHashRef->{"database_port"} = ""; #Optional.  You can leave this blank

$ConfigHashRef->{"studyname"} = ""; #Optional.  Specify the study name to have the option to download database tables.  See DownloadDatabase() below.
#----------------------------------------------------------


my $query = CGI->new;
my $intDownload = $query->param("download");

my $DB = 0;

my ($blnSuccess, $strSimpleError, $strSystemError) = ConnectToDatabase($ConfigHashRef);

if ($intDownload) 
{
	if ($ConfigHashRef->{"studyname"}) 
	{
		DownloadDatabase();
		exit();
	}
	else
	{
		print "Content-type: text/html\r\n\r\n";
		print "No studyname specified.";
		exit();
	}
	
}

print "Content-type: text/html\r\n\r\n";

print "<head>";
print "<title>Survey Self-Hosting Database Test</title>";
print "</head>";
print "<html><body style=\"font-family: verdana;\">";
print "<h1>Survey Self-Hosting Database Test</h1>";
print "<hr>";
print "<table style=\"border: 1px solid gray;\"><tr><td style=\"font-size: 20px; padding: 25px;\">Result: </td>";

if ($blnSuccess) 
{
	print "<td style=\"color: green; font-size: 20px; padding: 25px\"><strong>Success! Perl is able to connect to the database.</strong></td>";
	print "</tr></table>";
}
else
{
	print "<td style=\"color: red; font-size: 20px; padding: 25px\"><strong>Error. Perl could not connect to the database.</strong></td>";
	print "</tr></table>";
	if ($strSimpleError) 
	{
		print "<div style=\"display: inline-block; margin-top: 20px\">The perl script encountered an error: ";
		print "<div style=\"color: red; display: inline-block\">" . $strSimpleError . "</div>";
		print "</div>";
	}

	if ($strSystemError) 
	{
		print "<p>Error Details: ";
		print "<p style=\"color: red;\">" . $strSystemError . "</p>";
		print "</p>";
	}
}


print "<hr><h3>Perl Database Driver Information</h3>" . PrintDBDriverInfo();

if ($ConfigHashRef->{"studyname"}) 
{
	print "<div style=\"margin-top: 20px;\"><a href=\"?download=1\">Download Database $intDownload</a></div>";
}

print "<div style=\"margin-top: 30px;\"><span style=\"font-weight: bold; color: red;\">WARNING:</span> Make sure to remove this script off the server after you are finished testing.</div>\n";

print "</body></html>";

#----------------------------------------------
#
#----------------------------------------------
sub ConnectToDatabase
{
	my ($ConfigHashRef) = @_;

	my $blnSuccess = 0;
	my $blnError = 0;
	my $strSystemError = "";
	my $strSimpleError = "";
	my $strConnectInfo = ""; 

	eval
	{
		#Placing require DBI here helps the Setup Script show a nice error message.
		require DBI;

		if (uc($ConfigHashRef->{"database_type"}) eq uc("mysql")) 
		{
			$strConnectInfo = "dbi:" . $ConfigHashRef->{"database_type"} . ":" 
									 . $ConfigHashRef->{"database_name"} . ":" 
									 . $ConfigHashRef->{"database_address"};

			if ($ConfigHashRef->{"database_port"}) 
			{
				$strConnectInfo .= ":" . $ConfigHashRef->{"database_port"};
			}

			$DB = DBI->connect($strConnectInfo, $ConfigHashRef->{"database_username"}, $ConfigHashRef->{"database_password"},{RaiseError => 1, AutoCommit => 0, PrintError => 0});
		}
		elsif(uc($ConfigHashRef->{"database_type"}) eq uc("SQLite"))
		{
			#Table name used for SQLite database file name.  This is so that test mode will create a separate test_ SQLite file.
			$DB = DBI->connect("dbi:" . $ConfigHashRef->{"database_type"} . ":dbname=" . $authlib::GlobalPaths{'admin_path'} . $authlib::strGlobalDBTableName . ".sqlite", undef, undef, {RaiseError => 1, PrintError => 0, AutoCommit => 0});
		}
		elsif(uc($ConfigHashRef->{"database_type"}) eq uc("ODBC"))
		{
			my $strDBAddress = $ConfigHashRef->{"database_address"};

			$strConnectInfo = "DBI:" . $ConfigHashRef->{"database_type"} . ":"
									. "Driver={SQL Server};Server=" . $strDBAddress . ";"
									. "Database=" . $ConfigHashRef->{"database_name"} . ";"
									. "uid=" . $ConfigHashRef->{"database_username"} . ";"
									. "pwd=" . $ConfigHashRef->{"database_password"} . ";"
									. "port=" . $ConfigHashRef->{"database_port"};

			$DB = DBI->connect($strConnectInfo, undef, undef, {RaiseError => 1, AutoCommit => 0});	
		}
		else
		{
			$blnError = 1;
			$strSimpleError = "Failed to connect to the database.";
			$strSystemError = "Cannot find database for " . $ConfigHashRef->{"database_type"} . ".";
		}
	};
	if ($@)
	{
		$strSimpleError = "Failed to connect to the database.";
		$strSystemError = $@;

		#Cannot find database name, MySQL, MS SQL
		if ($strSystemError =~ m/Unknown database/i || $strSystemError =~ m/Cannot open database/i) 
		{
			$strSimpleError .= " Cannot find the \"" . $ConfigHashRef->{"database_name"} . "\" database.  Make sure that this database has been created and that you have access to it.";
		}
		#Access denied for db user, MySQL, MS SQL
		elsif($strSystemError =~ m/Access denied for user/i || $strSystemError =~ m/Login failed for user/i)
		{
			$strSimpleError .= " Access denied for database user \"" . $ConfigHashRef->{"database_username"} . "\".  Check the database user name and password.  Also verify that you have the database name (" . $ConfigHashRef->{"database_name"} . ") correct.";
		}
		#DB driver cannot be found. MySQL and MS SQL
		elsif($strSystemError =~ m/install_driver(.*?)failed/i) 
		{
			$strSimpleError .= " Cannot find database driver " . $ConfigHashRef->{"database_type"} . ".";
		}
	}
	elsif(!$authlib::DB)
	{
		($blnSuccess, $strSimpleError, $strSystemError) = CheckForDBDriver($ConfigHashRef->{"database_type"});

		$blnError = 1;
		$strSimpleError = "Failed to connect to the database.";
	}
	elsif(!$blnError)
	{
		($blnSuccess, $strSimpleError, $strSystemError) = CheckForDBDriver($ConfigHashRef->{"database_type"});

		$authlib::GlobalDBDriverRef->{'type'} = lc($ConfigHashRef->{"database_type"});
	}
	else
	{
		$blnSuccess = 1;
	}

	return ($blnSuccess, $strSimpleError, $strSystemError);
}

#----------------------------------------------
#
#----------------------------------------------
sub DisconnectDatabase
{
	if ($DB) 
	{
		$DB->commit();	
		$DB->disconnect;

		$DB = 0;
	}
}

#-----------------------------------------------
# 
#-----------------------------------------------
sub PrintDBDriverInfo
{
	my $strCode = "";
	my $strOut = "";

	eval "require DBI";
	$strOut .= "<div style=\"margin: 10px 10px 10px 10px\">The required Perl DBI Module is ";
	if (DBI->VERSION){
		$strOut .= "<span style=\"color: green\"><strong>installed and working</strong></span>. The current version is <span style=\"color: green;\">" . DBI->VERSION . ".</span></div>";
	}
	else 
	{
		$strOut .= "<span style=\"color: red\">not working</span>. Please ensure the module is installed and available in the Perl runtime environment.</div>";
	}

	$strOut .= "<div style=\"margin: 10px 10px 10px 10px\">The script parameters show you are trying to connect to a <strong>" . $ConfigHashRef->{"database_type"} . "</strong> database.</div>";
	if (uc($ConfigHashRef->{"database_type"}) eq uc("mysql"))
	{
		eval "require DBD::mysql";
		$strOut .= "<div style=\"margin: 10px 10px 10px 30px\">A MySQL database connection requires the <strong>DBD::mysql</strong> Perl Module. This module is ";
		if (DBD::mysql->VERSION){
			$strOut .= "<span style=\"color: green\"><strong>installed and working</strong></span>. The current version is <span style=\"color: green;\">" . DBD::mysql->VERSION . ".</span></div>";
		}
		else 
		{
			$strOut .= "<div style=\"color: red\"><strong>not working</strong></div>. Please ensure the module is installed and available in the Perl runtime environment.</div>";
		}
	}
	elsif (uc($ConfigHashRef->{"database_type"}) eq uc("ODBC"))
	{
		eval "require DBD::ODBC";
		$strOut .= "<div style=\"margin: 10px 10px 10px 30px\">A SQL Server database connection requires the <strong>DBD::ODBC</strong> Perl Module. This module is ";
		if (DBD::ODBC->VERSION){
			$strOut .= "<div style=\"color: green\"><strong>installed and working</strong></span>. The current version is <span style=\"color: green;\">" . DBD::ODBC->VERSION . ".</span></div>";
		}
		else 
		{
			$strOut .= "<div style=\"color: red\"><strong>not working</strong></div>. Please ensure the module is installed and available in the Perl runtime environment.</div>";
		}
	}
	elsif (uc($ConfigHashRef->{"database_type"}) eq uc("SQLite"))
	{
		eval "require DBD::SQLite";
		$strOut .= "<div style=\"margin: 10px 10px 10px 30px\">A SQLite database connection requires the <strong>DBD::SQLite</strong> Perl Module. This module is ";
		if (DBD::SQLite->VERSION){
			$strOut .= "<span style=\"color: green\"><strong>installed and working<strong></span>. The current version is <span style=\"color: green;\">" . DBD::SQLite->VERSION . ".</span></div>";
		}
		else 
		{
			$strOut .= "<span style=\"color: red\"><strong>not working</strong></span>. Please ensure the module is installed and available in the Perl runtime environment.</div>";
		}
	}
	else
	{
		$strOut .= "<div>Please specify a valid database type.</div>";
	}

	return $strOut;
}

#-----------------------------------------------
# 
#-----------------------------------------------
sub CheckForDBDriver
{
	my ($strDriverName) = @_;

	my @AvailableDrivers = DBI->available_drivers();
	if(grep(/$strDriverName/i, @AvailableDrivers))
	{
		return (1, "", "");
	}
	else
	{
		return (0, "", "A " . $strDriverName . " driver is not installed for Perl. Please make sure that the CPAN module DBD::" . $strDriverName . " is installed and reachable from Perl.");
	}
}

sub DownloadDatabase
{
	binmode STDOUT;
	print DownloadHeader("database.txt");

	my $strSQL = "SELECT * FROM `" . $ConfigHashRef->{"studyname"} . "_history`";
	my $DBInfoHash = $DB->selectall_arrayref(ProcessSQL($strSQL, 0));

	use Data::Dumper;

	# simple procedural interface
	print Dumper($DBInfoHash);

}

#-----------------------------------------------
#
#-----------------------------------------------
sub DownloadHeader
{
	my ($strFileName) = @_;
	my $strOut = "";
	my $blnModPerl = 0;
	my $intModPerlVersion = 0;

	my $strRegularHeaderTxt = "";
	
	$strRegularHeaderTxt .= "Content-Type: application/octet-stream dat;\n"; 
	$strRegularHeaderTxt .= "Content-Disposition: attachment; filename=\"" . $strFileName . "\"\n\n"; 

	if (exists($ENV{'MOD_PERL'}) && defined($ENV{'MOD_PERL'})) 
	{
		$blnModPerl = 1;

		$intModPerlVersion = $ENV{'MOD_PERL'};

		# Change mod_perl/1.XX to 1.X
		$intModPerlVersion =~ s/mod_perl\/(\d\.\d)(.*?)$/$1/i;
	}

	if ($ENV{'PERL_SEND_HEADER'} || ($blnModPerl == 0)) 
	{
		$strOut .= $strRegularHeaderTxt;
	}
	else
	{
		#Only call send_http_header for mod_perl versions prior to (1.9) in the 1.26 series 
		#Remember to update this in authlib.pl too
		if ($intModPerlVersion < 1.9) 
		{
			my $r = Apache->request;
		
			$r->content_type('application/octet-stream dat;');
			$r->header_out("Content-Disposition" => "attachment; filename=\"" . $strFileName . "\"");
			$r->send_http_header;
		}
		else
		{
			$strOut .= $strRegularHeaderTxt;
		}
	}

	return $strOut;
}


sub ProcessSQL
{
	my($strSQL, $blnCreatingTable) = @_;

	if(lc($ConfigHashRef->{"database_type"}) eq "odbc")
	{
		$strSQL =~ s/`/\"/g;

		if ($blnCreatingTable) 
		{
			#If change here also change below
			$strSQL =~ s/\s+TINYINT\(\d+\)([,\s\)])/ TINYINT$1/ig;
			$strSQL =~ s/\s+INTEGER([,\s\)])/ INT$1/ig;
			$strSQL =~ s/\s+LONGTEXT([,\s\)])/ nvarchar\(max\)$1/ig;
			$strSQL =~ s/\s+TEXT([,\s\)])/ nvarchar\(max\)$1/ig;
			$strSQL =~ s/\s+VARCHAR\s*\((\d+)\)([,\s\)])/ nvarchar\($1\)$2/ig;
			$strSQL =~ s/\s+DOUBLE([,\s\)])/ decimal\(38, 16\)$1/ig;
		}
	}
	elsif (lc($ConfigHashRef->{"database_type"}) eq "sqlite") 
	{
		if ($blnCreatingTable) 
		{
			$strSQL =~ s/\s+INT([,\s\)])/ INTEGER$1/ig; #SQLite needs INTEGER to do INTEGER PRIMARY KEY
			$strSQL =~ s/\s+TEXT/ TEXT COLLATE NOCASE/ig; #Make all text searches in SQLite case insensitive
		}
	}

	return $strSQL;
}
