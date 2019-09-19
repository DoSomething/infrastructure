#!/bin/bash

# This script generates new TLS server and client certs for 
# mutual-auth AWS Client VPN.
# Instructions based on: 
# https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/authentication-authorization.html#mutual

# Get the ARN args for certs:
VPN_SERVER_CERTIFICATE_ARN="$1"
VPN_CLIENT_CERTIFICATE_ARN="$2"

if [[ -z "$VPN_SERVER_CERTIFICATE_ARN" ]] || [[ -z "$VPN_CLIENT_CERTIFICATE_ARN" ]]; then
  echo "Usage: ./scripts/generate-vpn-certs.sh <vpn_server_certificate_arn> <vpn_client_certificate_arn>" 1>&2
  exit 1
fi

# Create temp directory for cert generation.
tmp_dir=$(mktemp -d -t rsa-XXXXXXXXXX)

git clone https://github.com/OpenVPN/easy-rsa.git $tmp_dir
cd $tmp_dir
# Checkout latest good release of EasyRSA.
git checkout v3.0.6
cd $tmp_dir/easyrsa3
./easyrsa init-pki
echo "quasar-vpn" | ./easyrsa build-ca nopass
./easyrsa build-server-full quasar-vpn-server nopass
./easyrsa build-client-full quasar-vpn-client.d12g.co nopass
mkdir $tmp_dir/vpn-certs
cp $tmp_dir/easyrsa3/pki/ca.crt $tmp_dir/vpn-certs/
cp $tmp_dir/easyrsa3/pki/issued/quasar-vpn-server.crt $tmp_dir/vpn-certs/
cp $tmp_dir/easyrsa3/pki/private/quasar-vpn-server.key $tmp_dir/vpn-certs/
cp $tmp_dir/easyrsa3/pki/issued/quasar-vpn-client.d12g.co.crt $tmp_dir/vpn-certs/
cp $tmp_dir/easyrsa3/pki/private/quasar-vpn-client.d12g.co.key $tmp_dir/vpn-certs/
cd $tmp_dir/vpn-certs/
aws acm import-certificate --certificate-arn $VPN_SERVER_CERTIFICATE_ARN --certificate file://quasar-vpn-server.crt --private-key file://quasar-vpn-server.key --certificate-chain file://ca.crt --region us-east-1
aws acm import-certificate --certificate-arn $VPN_CLIENT_CERTIFICATE_ARN --certificate file://quasar-vpn-client.d12g.co.crt --private-key file://quasar-vpn-client.d12g.co.key --certificate-chain file://ca.crt --region us-east-1
rm -rf $tmp_dir