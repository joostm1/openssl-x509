# Makefile for creating self-signed x509 certificates 
## using openssl


## With this, you get:

1. A self-signed Certification Authority (CA) certificate.
2. A user certificate with a (UPN) in the Subject Alternative Name, suitable for smartcard login.
3. A server certificate with the host name in the Subject Alternative Name, suitable for VPN 
   configurations.

## Here's how:

	git clone git@github.com:joostm1/openssl-x509.git
	cd openssl-x509
	make ORG='"XYZ9 Inc."' UPN=joost@xyz9.net SERVER=egx.xyz9.net

## Where:
	ORG		is the name of your organisation.
	UPN		is your User Principal Name.
	SERVER		is the DNS name of your VPN server

### Here's a run in my world with explanation:

My organization name is XYZ9 Inc., and my UPN is joost@xyz9.net and my router is egx.xyz9.net, so I do:

	make ORG='"XYZ9 Inc."' UPN=joost@xyz9.net SERVER=egx.xyz9.net

### Certificate Authority

The section in [config](ORG-CA.cnf) file states that it is a CA and it's intended use to sign other stuff:

	[ ca_ext ]
	basicConstraints        = critical,CA:true
	keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
	subjectKeyIdentifier    = hash

	openssl x509 -in "XYZ9 Inc."/certs/cacer.PEM -noout -text
	Certificate:
	    Data:
		Version: 3 (0x2)
		Serial Number:
			71:56:96:4b:e0:07:11:c8:a2:cf:3e:50:70:aa:62:0f:e7:c9:38:af
		Signature Algorithm: sha256WithRSAEncryption
	        Issuer: O = XYZ9 Inc., CN = XYZ9 Inc. Root CA
		Validity
			Not Before: Jan 11 11:51:20 2024 GMT
			Not After : Jan  8 11:51:20 2034 GMT
		Subject: O = XYZ9 Inc., CN = XYZ9 Inc. Root CA
		Subject Public Key Info:
		Public Key Algorithm: rsaEncryption
		Public-Key: (2048 bit)
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
            X509v3 Subject Key Identifier:
                95:...

Now that we have the CA, we can create a user- and server certificate and sign it with this CA.
______
### Server certificate
The below section from the [configuration file](ORG-openssl.cnf) specifies the x509 extensions to be used in the certificate. 

	[ server_ext ]
	basicConstraints = CA:false
	keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement
	extendedKeyUsage = critical, serverAuth, 1.3.6.1.5.5.8.2.2
	subjectAltName = DNS:${ENV::SERVER}
	subjectKeyIdentifier = hash

The ${ENV::SERVER} construction takes value of the SERVER environment variable, egx.xyz9.net in my case as the subjectAltname.

	openssl x509 -in "XYZ9 Inc."/certs/egx.xyz9.net-cer.PEM -noout -text
		Certificate:
			Data:
			Version: 3 (0x2)
			Serial Number:
				1d:ed:a6:08:8d:b1:78:ec:46:d1:33:d9:3e:c5:7a:9e:c8:dd:e7:c9
			Signature Algorithm: sha256WithRSAEncryption
			Issuer: O = XYZ9 Inc., CN = XYZ9 Inc. Root CA
			Validity
				Not Before: Jan 11 11:51:32 2024 GMT
				Not After : Jan  8 11:51:32 2034 GMT
			Subject: O = XYZ9 Inc., CN = egx.xyz9.net
			Subject Public Key Info:
		    Public Key Algorithm: rsaEncryption
			Public-Key: (2048 bit)
			Modulus:
			    00:b6:5c:f7:51:cd:2b:8d:b9:bd:8f:e0:db:d0:ed:
		X509v3 extensions:
		    X509v3 Basic Constraints:
			CA:FALSE
		    X509v3 Key Usage: critical
			Digital Signature, Non Repudiation, Key Encipherment, Key Agreement
		    X509v3 Extended Key Usage: critical
			TLS Web Server Authentication, 1.3.6.1.5.5.8.2.2
		    X509v3 Subject Alternative Name:
			DNS:egx.xyz9.net
		    X509v3 Subject Key Identifier:
			04:17:CB:0B:3F:82:07:74:09:7B:42:CC:B5:23:80:F4:C7:F7:32:25
		    X509v3 Authority Key Identifier:
			95:3B:FB:56:C8:EE:00:04:05:E9:A1:09:CF:8F:07:9B:1B:22:FB:35
	    Signature Algorithm: sha256WithRSAEncryption

### User certificate

	The below section from the [configuration file](ORG-openssl.cnf) specifies the x509 extensions to be used in the certificate. 

	[ user_ext ]
	basicConstraints = CA:false
	keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement
	extendedKeyUsage = critical, clientAuth, msSmartcardLogin
	subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:${ENV::UPN}
	subjectKeyIdentifier = hash

Note how subjectAltName is populated via otherName with a [User Pricipal Name](https://oidref.com/1.3.6.1.4.1.311.20.2.3).


See [RFC 3280](https://www.ietf.org/rfc/rfc3280.txt) for the encoding of the subjectAltName.

See [this](https://learn.microsoft.com/en-us/troubleshoot/windows-server/windows-security/enabling-smart-card-logon-third-party-certification-authorities) dated document for certificate requirements.



