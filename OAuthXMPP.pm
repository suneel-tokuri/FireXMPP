#"""
# Fire Eagle XMPP Perl module v0.1
# by Suneel T. Chandra <suneel331@gmail.com>
#
# Source repo at http://github.com/suneel331/firexmpp
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

package OAuthXMPP;

warn "OAuthXMPP is successfully loaded...\n";

my $FIREEAGLE_JABBER_NODE_PREFIX = '/api/1.0/user/';
sub new {
	
	my ($classname) = shift;

	my $self = {};
	if(@_) {
		$self->{"server"} = shift;
		$self->{"from_jid"} = shift;
		$self->{"consumer_key"} = shift;
		$self->{"consumer_secret"} = shift;
	}

	bless($self, $classname);
	return $self;
}

sub __build_oauth_params_xml {
	my ($self) = shift;
	my %oauth_params = @_;
	
	my $retval = '<oauth xmlns="urn:xmpp:oauth:0">';
	while((my $key, my $value) = each %oauth_params) {
		$retval = $retval.'<'.$key.'>'.$value.'</'.$key.'>';
	}
	$retval = $retval.'</oauth>';
	return $retval;
}

sub __build_signature {
	my ($self) = shift;

	return "dummy signature";
}
 
sub build_pubsub_request {
	my ($self) = shift;
	my $request = shift;
	my $token = shift;
	$self->{"token_secret"} = shift;

	
	my %oauth_params = ( "oauth_consumer_key" => $self->{"consumer_key"},
			     "oauth_nonce" => int(rand(999999999)) + 100000000,
	                     "oauth_signature_method" => "HMAC-SHA1",
	                     "oauth_timestamp" => time(),
	                     "oauth_token" => $token,
	                     "oauth_version" => "1.0");

	my $signature = $self->__build_signature(%oauth_params);
	$oauth_params{"oauth_signature"} = $signature;

	my $request_str = '<pubsub xmlns="http://jabber.org/protocol/pubsub">';
	if($request == "subscribe" || $request == "unsubscribe") {
		$request_str = $request_str.'<'.$request.' '.'node="'.$FIREEAGLE_JABBER_NODE_PREFIX.$oauth_params{"oauth_token"}.'" '.'jid="'.$self->{"from_jid"}.'"/>';
		$request_str = $request_str.$self->__build_oauth_params_xml(%oauth_params);	
	}

	$request_str = $request_str.'</pubsub>';
	return $request_str;
}

1;
