# Tools and tutorial for Certifcate Based Authentication (CBA) in Entra ID
## using [openssl](https://www.openssl.org/) and a [Yubikey 5](https://www.yubico.com/products/yubikey-5-overview/).


One of the authentication methods in Enrea ID is [Certificate-based authentication](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-certificate-based-authentication).
This is attractive as it combines a good passwordless user experience with good security.

This repo contains some tools and tutorial for enabling CBA in Azure AD using openssl and a yubikey 5.
It is divided in 3 parts:

1. Creating the certificates using openssl.
2. Enable CBA in Entra ID.
3. Using a Yubikey as a smartcard.


# 1. Creating the certificates with openssl


**In Entra ID, users authenticate with a certificate that:**

- provides the user's identity, i.e., the user principal name.

- is signed by _a certain_ certificate authority (CA).

**Entra ID verifies the user's identity by:**

- verifying that the requesting user certificate is signed by _a certain_ CA.

- the ability to map the requesting user certificate to a user.


The goal of this `aad-cba` repo is to get you started wiyth CBA.

____
**Let's create this _certain_ CA as well as the user certificate.**

Clone this `aad-cba` thing to your local workspace:

	git clone git@github.com:joostm1/aad-cba.git

Create both the CA and the user certificate:

	make ORG=YOURORG UPN=yourname@yourdomain.com

Provide your *organisation name* and *your UPN* on this commandline. 
____
### Here's a run in my world with explanation:

My organization name is XYZ9 and my UPN is joost@xyz9.net, so I do:

	cd aad-cba
	make ORG=XYZ9 UPN=joost@xyz9.net

### Certificate Authority

First thing created is a key for the CA certificate:

	openssl genpkey -config 'XYZ9/XYZ9-CA.cnf' -out XYZ9/private/cakey.PEM -outform PEM -algorithm RSA
      
With this key, a new selfsigned certificate is created with a lifetime of 10 years:

	openssl req -config 'XYZ9/XYZ9-CA.cnf' -x509 -days 3650 -reqexts ca_ext \
        	-outform PEM -key XYZ9/private/cakey.PEM -out XYZ9/certs/cacer.PEM

The `ca_ext` section in [config](ORG-CA.cnf) file states that it is a CA and it's intended use to sign other stuff:

	[ ca_ext ]
	basicConstraints        = critical,CA:true
	keyUsage                = critical,keyCertSign,cRLSign
	subjectKeyIdentifier    = hash

Azure requires the CA certificate to be in DER format with a `.cer` file extension, so we convert it from PEM to DER:

	openssl x509 -in XYZ9/certs/cacer.PEM -inform PEM -out XYZ9/certs/cacer.cer -outform DER

This CA in DER format, `XYZ9/certs/cacer.cer` is the file that must be configured in 
	`AAD | Security | Certificate authorities.`
See the next chapter for that. This CA is also the one that must be used to *sign* subsequent user certificates.

If we get details from this CA we see:

	openssl x509 -in XYZ9/certs/cacer.cer -noout -text
	Certificate:
	    Data:
        	Version: 3 (0x2)
        	Serial Number:
	            2b:96:a0:f0:78:bd:06:1c:4b:df:4f:58:92:9a:e3:80:6a:35:9b:71
        	Signature Algorithm: sha256WithRSAEncryption
        	Issuer: C = NL, O = XYZ9, CN = XYZ9 root CA
        	Validity
	            Not Before: Aug  7 14:58:08 2023 GMT
            	Not After : Aug  4 14:58:08 2033 GMT
        	Subject: C = NL, O = XYZ9, CN = XYZ9 root CA
        	Subject Public Key Info:
	            Public Key Algorithm: rsaEncryption
                	Public-Key: (2048 bit)
                	Modulus:
                    8b:73:88:1e:1f:02:6d:e3:ed:85:46:e7:9b:1a:a7:
                    d8:5f
                	Exponent: 65537 (0x10001)
        	X509v3 extensions:
            	X509v3 Basic Constraints: critical
	                CA:TRUE
    	        X509v3 Key Usage: critical
        	        Certificate Sign, CRL Sign
            	X509v3 Subject Key Identifier:
                	DB:BE:F9:2C:12:05:57:FF:48:AA:50:24:64:5C:B6:99:52:20:38:42
    	Signature Algorithm: sha256WithRSAEncryption
    	Signature Value:
        07:61:1b:3c:cd:e8:e4:57:9f:88:93:3f:e2:4a:90:30:96:5d:

Now that we have the CA, we can create a user certificate and sign it with this CA key.
______
### User certificate

A key for the user certificate is generated first:

	openssl genpkey -config 'XYZ9/XYZ9-CR.cnf' -out XYZ9/private/joost@xyz9.net-key.PEM -outform PEM -algorithm RSA

Secondly, a sign request is created using the `cr_ext` section of this [configuration file](ORG-CR.cnf):

	openssl req -config 'XYZ9/XYZ9-CR.cnf' -new -reqexts cr_ext -outform PEM \
	        -key XYZ9/private/joost@xyz9.net-key.PEM -out XYZ9/certs/joost@xyz9.net-csr.PEM

The below section from the [configuration file](ORG-CR.cnf) specifies the `cr_ext` x509 extensions to be used in the certificate. 

	[ cr_ext ]
	basicConstraints = CA:false
	keyUsage = digitalSignature
	extendedKeyUsage = serverAuth, clientAuth, msSmartcardLogin
	subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:${ENV::UPN}

Note how subjectAltName is populated via otherName with a [User Pricipal Name](https://oidref.com/1.3.6.1.4.1.311.20.2.3).

See [RFC 3280](https://www.ietf.org/rfc/rfc3280.txt) for the encoding of the subjectAltName.

See [this](https://learn.microsoft.com/en-us/troubleshoot/windows-server/windows-security/enabling-smart-card-logon-third-party-certification-authorities) dated document for certificate requirements.


The request is signed by the previously created CA:

	openssl x509 -req -extfile 'XYZ9/XYZ9-CR.cnf' -extensions cr_ext -days 365 \
		-in XYZ9/certs/joost@xyz9.net-csr.PEM -CA XYZ9/certs/cacer.PEM -CAkey XYZ9/private/cakey.PEM \
		-out XYZ9/certs/joost@xyz9.net-cer.PEM

And the user certificate, including it's private key, is bundled in a password protected pfx file. 
This file is to be placed on the user's smart card.

 	openssl pkcs12 -export -inkey XYZ9/private/joost@xyz9.net-key.PEM \
 		-in XYZ9/certs/joost@xyz9.net-cer.PEM \
		-name "joost@xyz9.net" -out XYZ9/certs/joost@xyz9.net.PFX




At this point we have created:

`XYZ9/certs/cacer.cer` that needs to go into Entra ID and we have 
 
`XYZ9/certs/joost@xyz9.net.PFX` that needs to go on a Yubikey.

Let's continue with adding `XYZ9/certs/cacer.cer` to Entra ID to enable the CBA option.
