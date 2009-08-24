# '''
# Sample app to test xmpp extensions to fireeagle perl library
# '''

use FireXMPP;

#Parameters: FireEagle pubsub server, user JID(intermediate server), password, FireEagle Consumer Key, FireEagle Consumer Secret
my $fe_client = new FireXMPP("fireeagle.com","xxxxxxx\@jabber.org", "xxxxxxxxxx", "xxxxxx", "xxxxxxxxxxxxxxxxxxx");
$fe_client->print();

my $result = $fe_client->Connect();
print "Connect result: ".$result."\n";

#print "adding fireeagle to roster...\n";
$fe_client->add_fireeagle_to_roster();

#ping is a blocking call
$result = $fe_client->ping();
print "Ping: ".$result."\n";

#parameters: oauth.token, oauth.token_secret
$result = $fe_client->subscribe("xxxxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
print "Subscribe: ".$result."\n";

for(my $i = 0; $i < 7; $i++) {
	print ".\n";
	$fe_client->run(10);
}

#bye bye
$fe_client->Close();

print "end\n";

