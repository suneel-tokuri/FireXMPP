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
use threads;
use Thread::Semaphore;
no warnings 'threads';

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
	#init is done, so bless the object
	bless($self, $classname);

	#set up callbacks
	# defining linking closures
	my $onauth_ = sub { onauth($self, @_); };
	my $oniq_ = sub { oniq($self, @_); };
	my $onmessage_ = sub { onmessage($self, @_); };
	my $onpresence_ = sub { onpresence($self, @_); };

	$self->{"xmpp_client"}->SetCallBacks(onauth=>$onauth_);
	$self->{"xmpp_client"}->SetCallBacks(message=>$onmessage_);
	$self->{"xmpp_client"}->SetCallBacks(presence=>$onpresence_);
	$self->{"xmpp_client"}->SetCallBacks(iq=>$oniq_);

	return $self;
}

sub Connect {
	my ($self) = @_;

	$self->{"auth_sema"} = Thread::Semaphore->new(0);
	my $xmppthread = threads->create(sub {
		#defaulting the xmpp server port for now
		my $port = 5222;
		my ($node, $domain) = split(/\@/, $self->{"jid"}->GetJID("base"));
		$self->{"xmpp_client"}->Execute(hostname=>$self->{"jid"}->GetServer(), 
						port=>$port, tls=>1, username=>$node, 
						password=>$self->{"passwd"}, resource=>"fireeagle",
						register=>0,connectiontype=>"tcpip", 
						connecttimeout=>"600",connectattempts=>1, 
						connectsleep=>5, processtimeout=>600);
	}, $self->{"auth_sema"});

	# block client's thread until auth happens
	$self->{"auth_sema"}->down();
}

sub print {
	my ($self) = @_;
	print "Conf: ".$self->{"server"}.",".$self->{"jid"}."\n";
}

sub add_fireeagle_to_roster {
	my ($self) = @_;
	$self->{"xmpp_client"}->Subscription(type=>"subscribe", to=>$self->{"server"});	
}

sub subscribe {
	my ($self) = shift;
	my $token = shift;
	my $secret = shift;

	#print "==>".$self->{"oauth"}->build_pubsub_request('subscribe', $token, $secret);

}

sub run {
	my ($self) = shift;
	my ($sleep) = shift;

	if($sleep) {
		sleep $sleep;
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

sub onauth {
	my ($self) = @_;
	print "~~~~~~~~~~~ onauth ~~~~~~~~~\n";
	# send initial presence
	$self->{"xmpp_client"}->PresenceSend(type=>"available");

	# let the client's thread run away
	$self->{"auth_sema"}->up();
}

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
