# '''
# Sample app to test xmpp extensions to fireeagle perl library
# '''

use FireXMPP;

my $fe_client = new FireXMPP("fireeagle.com","xxxxxx\@jabber.org", "xxxxxxx", "Qi66745ktJkf", "L6KfzTgkUvsXWgbBMfrlr9Dll99Eb5Fq");
$fe_client->print();
# Connect is a blocking call
$fe_client->Connect();

print "adding fireeagle to roster...\n";
$fe_client->add_fireeagle_to_roster();

print "subscribe...\n";
$fe_client->subscribe("kMMbczWle4Rc", "aQRh9Kv7hmWMZKFOmqbAhbp77IXDdsev");

for(my $i = 0; $i < 4; $i++) {
	print ".\n";
	$fe_client->run(10);
}

#bye bye
$fe_client->Close();

print "end\n";

