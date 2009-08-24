#"""
# Fire Eagle XMPP Perl module v0.1
# by Suneel T. Chandra <suneel331@gmail.com>
#
# Source repo at http://github.com/suneel331/firexmpp
#
# Example usage:
# sample.pl
#
#
# Copyright (c) 2009, T Suneel Chandra
# All rights reserved.
#
# Unless otherwise specified, redistribution and use of this software in
# source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * The name of the author nor the names of any contributors may be
#      used to endorse or promote products derived from this software without
#      specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# """


package FireXMPP;

use OAuthXMPP;
use Net::XMPP;

warn "FireXMPP is successfully loaded...\n";

sub new {
	
	my ($classname) = shift;

	my $self = {};
	my $jid = "";
	if(@_) {
		# Server is the pubsub server i.e fireeagle.com
        	$self->{"server"} = shift;
		$jid = shift;
		$self->{"passwd"} = shift;
		$self->{"consumer_key"} = shift;
		$self->{"consumer_secret"} = shift;
	}
	$self->{"oauth"} = OAuthXMPP->new($self->{"server"}, $jid, $self->{"consumer_key"}, $self->{"consumer_secret"});        
	$self->{"xmpp_client"} = new Net::XMPP::Client(debuglevel=>0);
	$self->{"jid"} = new Net::XMPP::JID($jid);
	$self->{"idticker"} = time();

	#set up callbacks
	# defining linking closures
	my $oniq_ = sub { oniq($self, @_); };
	my $onmessage_ = sub { onmessage($self, @_); };
	my $onpresence_ = sub { onpresence($self, @_); };

	$self->{"xmpp_client"}->SetCallBacks(message=>$onmessage_);
	$self->{"xmpp_client"}->SetCallBacks(presence=>$onpresence_);
	$self->{"xmpp_client"}->SetCallBacks(iq=>$oniq_);

	bless($self, $classname);
	return $self;
}

sub getNextID {
	my ($self) = @_;
	$self->{"idticker"}++;
	return "firexmpp-".$self->{"idticker"};
}

sub Connect {
	my ($self) = @_;

	#defaulting the xmpp server port for now
	my $port = 5222;
	my ($node, $domain) = split(/\@/, $self->{"jid"}->GetJID("base"));

	$self->{"xmpp_client"}->Connect(hostname=>$self->{"jid"}->GetServer(),
					port=>$port, timeout=>60, connectiontype=>"tcpip", tls=>1);
	if($self->{"xmpp_client"}->Connected() == 1) {
		my @result = $self->{"xmpp_client"}->AuthSend(username=>$node,
                                    password=>$self->{"passwd"},
                                    resource=>"fireeagle");
		if(@result[0] == "ok") {
			$self->{"xmpp_client"}->PresenceSend(type=>"available");
			return @result[0];
		}
	}
	return "failed";
}

sub print {
	my ($self) = @_;
	print "Conf: ".$self->{"server"}.",".$self->{"jid"}."\n";
}

sub add_fireeagle_to_roster {
	my ($self) = @_;
	$self->{"xmpp_client"}->Subscription(type=>"subscribe", to=>$self->{"server"});	
}

sub ping {
	my ($self) = @_;

	my $iq = new Net::XMPP::IQ();
	$iq->SetIQ(type=>"get", from=>$self->{"jid"}->GetJID("base")."/fireeagle", to=>$self->{"server"});
	$iq->InsertRawXML("<ping xmlns='urn:xmpp:ping'/>");
	#print "==>".$iq->GetXML()."\n";
	my $result = $self->{"xmpp_client"}->SendAndReceiveWithID($iq);
	my $type = $result->GetType();
	$type = lc $type;
	if($type == "result") {
		return "ok";
	}
	return "failed";
}

sub subscribe {
	my ($self) = shift;
	my $token = shift;
	my $secret = shift;

	my $iq = new Net::XMPP::IQ();
	$iq->SetIQ(type=>"set", from=>$self->{"jid"}, to=>$self->{"server"});
	$iq->InsertRawXML($self->{"oauth"}->build_pubsub_request('subscribe', $token, $secret));
	print "==>".$iq->GetXML()."\n";
	my $result = $self->{"xmpp_client"}->SendAndReceiveWithID($iq);
	my $type = lc $result->GetType();
	if($type == "result") {
		return "ok";
	}
	return "failed";
}

sub run {
	my ($self) = shift;
	my ($sleep) = shift;

	if($sleep) {
		#sleep $sleep;
		$self->{"xmpp_client"}->Process($sleep);
	} else {		
		# todo: hold the thread
		#$self->{"xmpp_thread"}->join();
	}
}

sub Close {

	my ($self) = @_;
	# sending unavailable presence
	$self->{"xmpp_client"}->PresenceSend(type=>"unavailable");
	$self->{"xmpp_client"}->Disconnect();
	#threads->exit(0);
}

#
# XMPP Listener implementation
#

sub oniq {
	my ($self,$sid,$iq) = @_;
	print "~~~~~~~~~~~~ oniq ~~~~~~~~~~\n";
	print "[To]: ".$iq->GetTo()."\n[From]: ".$iq->GetFrom();
	print "\n[Type]: ".$iq->GetType()."\n[ID]: ".$iq->GetID();
	print "\n";
}

sub onmessage {
	print "~~~~~~~~~~~~ onmessage ~~~~~\n";
	print @_."\n";

}

sub onpresence {
	my ($self, $sid, $presence) = @_;
	print "~~~~~~~~~~~~ onpresence ~~~~~\n";
	print "[To]: ".$presence->GetTo()."\n[From]: ".$presence->GetFrom();
	print "\n[Type]: ".$presence->GetType()."\n[Status]: ".$presence->GetStatus();
	print "\n[Show]: ".$presence->GetShow();
	print "\n";
}

1;
