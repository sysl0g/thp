sub ftp {
srand(time);
my $ftpuser = "anon";
my $type = I;
my @addroct = split /\./, $thpaddr;
#my @portoct = ((($shorttime % 124) + 4),($shorttime % 255));
unless (defined $pasvport){
	$pasvport = int(rand 65535) + 1025;
}
my @pasvoct = ($pasvport >> 8, $pasvport & 0xff);
my $file = "file";
%ftphash = (
	user	=>	"331 Password required for $ftpuser\x0d\x0a",
	pass	=>	"230 User $ftpuser logged in.\x0d\x0a",
	already	=>	"530 Already logged in.\x0d\x0a",
	nologin	=>	"530 Please login with USER and PASS.\x0d\x0a",
	start	=>	"220 $hostname.$domain $ftpver ready.\x0d\x0a",
	syst	=>	"215 UNIX Type: L8\x0d\x0a",
	pwd	=>	"257 \"/\" is current directory.\x0d\x0a",
	type	=>	"200 Type set to $type.\x0d\x0a",
	mkd	=>	"257 New directory created.\x0d\x0a",
	stor	=>	"150 Opening BINARY mode data connection.\x0d\x0a",
	pwd	=>	"257 \"/\" is current directory.\x0d\x0a",
	cwd	=>	"250 CWD command successful.\x0d\x0a",
	cdup	=>	"257 \"/\" is current directory.\x0d\x0a",
	port	=>	"500 Passive mode only.\x0d\x0a",
	port502	=>	"502 Illegal PORT Command\x0d\x0a",
	port200	=>	"200 PORT command successful.\x0d\x0a",
	actv425	=>	"425 Can't build data connection: Connection refused.\x0d\x0a",
	compl	=>	"226 Transfer complete.\x0d\x0a",
	rnfr	=>	"350 File exists, ready for destination name.\x0d\x0a",
	rnto	=>	"250 RNTO command successful.\x0d\x0a",
	retr	=>	qq (150 Opening ASCII mode data connection for \'$file\'.\x0d\x0a),
	list	=>	qq (150 Opening ASCII mode data connection for 'file list'.\x0d\x0a),
	pasv	=>	qq (227 Entering Passive Mode \($addroct[0],$addroct[1],$addroct[2],$addroct[3],$pasvoct[0],$pasvoct[1]\)\x0d\x0a),
	help	=>	qq (214-The following commands are recognized.
   USER    PORT    STOR    RNTO    NLST    MKD     CDUP 
   PASS    PASV    APPE    ABOR    SITE    XMKD    XCUP 
   TYPE    DELE    SYST    RMD     STOU 
   STRU    ALLO    CWD     STAT    XRMD    SIZE 
   MODE    REST    XCWD    HELP    PWD     MDTM 
   QUIT    RETR    RNFR    LIST    NOOP    XPWD 
214 Direct comments to root\@localhost.\x0d\x0a),

	"site help" =>	qq (214-The following SITE commands are recognized.
   UMASK   CHMOD   GROUP   NEWER   INDEX   ALIAS   GROUPS 
   IDLE    HELP    GPASS   MINFO   EXEC    CDPATH 
214 Direct comments to root\@localhost.\x0d\x0a),

	quit	=>	qq (221-You have transferred 0 bytes in 0 files.
221-Total traffic for this session was 2164 bytes in 0 transfers.
221 Thank you for using the FTP service on $hostname.$domain.\x0d\x0a)
);
	
  $login = 0;
  print STDERR $ftphash{start};
  while (my $commands = <STDIN>) {
    open(LOG, ">>$sesslog");
    select LOG;
    $|=1;
    print LOG $commands;
    chomp $commands;
    $commands =~ s/\r//;
    @commands=split /\s+/,($commands);

    if ($commands[0] =~ /user/i && $commands[1] =~ /[[:alnum:]]+/){
	if ($login == 1) {
	  print STDERR $ftphash{already};
	} else {
	  $ftpuser = $commands[1];
	  $ftphash{user} =~ s/anon/$ftpuser/;
	  $ftphash{pass} =~ s/anon/$ftpuser/;
	  print STDERR $ftphash{user};
	}

    } elsif ($commands[0] =~ /pass/i && $commands[1] =~ /[[:print:]]+/) {
	if ($login == 1) {
          print STDERR $ftphash{already};
        } else { 
	  if ($ftpuser) {
	    $login = 1;
	    print STDERR $ftphash{pass};
	  }
	}

    } elsif ($commands[0] =~ /list|retr|stor/i) {
        if ($login == 1) {
	  $commands[0] =~ tr/A-Z/a-z/;
		if (defined ($actvport)) {
		  $retval = active($commands[0], $commands[1]);
		  print STDERR $ftphash{$retval};
		} else {
	          print STDERR $ftphash{$commands[0]};
        	  sleep 1;
	          print STDERR $ftphash{compl};
		}
	} else {
	  print STDERR $ftphash{nologin};
        }

   } elsif ($commands[0] =~ /help|pasv|pwd|syst|rnfr|rnto|mkd|cwd|cdup|type/i) {
        if ($login == 1) {
	  $commands[0] =~ tr/A-Z/a-z/;
          print STDERR $ftphash{$commands[0]};
	} else {
	  print STDERR $ftphash{nologin};
        }
    } elsif ($commands[0] =~ /port/i) {
        if ($login == 1) {
          $success = ftpport($commands[1]) 
		if ($commands[1] =~ /(\d){1,3},(\d){1,3},(\d){1,3},(\d){1,3},(\d){1,3},(\d){1,3}/);
	  print STDERR $ftphash{$success};
	  $actvport = 1;
	} else {
	  print STDERR $ftphash{nologin};
        }

    } elsif ("$commands" =~ /\bsite help\b/i) {
        if ($login == 1) {
	  $commands =~ tr/A-Z/a-z/;
          print STDERR $ftphash{"$commands"};
	} else {
	  print STDERR $ftphash{nologin};
        }

   } elsif ($commands[0] =~ /exit\b|quit\b/i) {
	print STDERR $ftphash{quit};
        return;

    } else {
	if ($login == 1) {
	  print STDERR "500 @commands: command not understood.\x0d\x0a";
	} else {
	print STDERR $ftphash{nologin};
	}
    }
    close LOG;
  }
}

