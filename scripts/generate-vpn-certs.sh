#!/bin/bash

# This script generates new TLS server and client certs for 
# mutual-auth AWS Client VPN.
# Instructions based on: 
# https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/authentication-authorization.html#mutual
# Make sure you have the EXISTING server and client cert ARN's passed in as the 
# first and second arguments, respectively, or you will upload/generate new certificates
# that aren't associated with the Client VPN endpoint.

# Remove old dirs for a fresh start
rm -rf ~/easy-rsa ~/vpn-certs

cd ~/
git clone https://github.com/OpenVPN/easy-rsa.git
cd ~/easy-rsa/easyrsa3
./easyrsa init-pki
echo "quasar-vpn" | ./easyrsa build-ca nopass
./easyrsa build-server-full quasar-vpn-server nopass
./easyrsa build-client-full quasar-vpn-client.d12g.co nopass
mkdir ~/vpn-certs
cp ~/easy-rsa/easyrsa3/pki/ca.crt ~/vpn-certs/
cp ~/easy-rsa/easyrsa3/pki/issued/quasar-vpn-server.crt ~/vpn-certs/
cp ~/easy-rsa/easyrsa3/pki/private/quasar-vpn-server.key ~/vpn-certs/
cp ~/easy-rsa/easyrsa3/pki/issued/quasar-vpn-client.d12g.co.crt ~/vpn-certs/
cp ~/easy-rsa/easyrsa3/pki/private/quasar-vpn-client.d12g.co.key ~/vpn-certs/
cd ~/vpn-certs/
aws acm import-certificate --certificate-arn $1 --certificate file://quasar-vpn-server.crt --private-key file://quasar-vpn-server.key --certificate-chain file://ca.crt --region us-east-1
aws acm import-certificate --certificate-arn $2 --certificate file://quasar-vpn-client.d12g.co.crt --private-key file://quasar-vpn-client.d12g.co.key --certificate-chain file://ca.crt --region us-east-1
