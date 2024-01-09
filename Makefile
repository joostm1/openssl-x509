# Makefile

# run this as 
#		make ORG="XYZ9" UPN=joost@xyz9.net SERVER=egx.xyz9.net

# openssl output formats
FORMPEM		:= PEM
FORMDER		:= DER
FORMPFX		:= PFX

# default form
FORM		:= $(FORMPEM)

# openssl config files for CA, server and user certificates
CONFCA		:= $(ORG)/CA.cnf
CONFCS		:= $(ORG)/CS.cnf
CONFCU		:= $(ORG)/CU.cnf

# files for the CA
CAKEY		:= $(ORG)/private/cakey.$(FORM)
CACER		:= $(ORG)/certs/cacer.$(FORM)

# files for the server certificate
SCER		:= $(ORG)/certs/$(SERVER)-cer.$(FORM)
SCSR		:= $(ORG)/certs/$(SERVER)-csr.$(FORM)
SKEY		:= $(ORG)/private/$(SERVER)-key.$(FORM)

# files for the user certificate
UCER		:= $(ORG)/certs/$(UPN)-cer.$(FORM)
UCSR		:= $(ORG)/certs/$(UPN)-csr.$(FORM)
UKEY		:= $(ORG)/private/$(UPN)-key.$(FORM)
UPFX		:= $(ORG)/certs/$(UPN).$(FORMPFX)

all:	$(UPFX) $(SCER) $(UCER)

# Create a PFX bundle with the user certificate and the user key.
$(UPFX): $(UCER)
<<<<<<< HEAD
	openssl pkcs12 -export -inkey $(UKEY) -in $(UCER) \
		-certfile $(CACER) -name "$(UPN)" -out $(UPFX) 
=======
	openssl pkcs12 -export -inkey $(UKEY) -in $(UCER) -certfile $(CACER) \
		-name "$(UPN)" -out $(UPFX) 
>>>>>>> f53ecc3544f3bcba0f0de1dddd885a9eba3feb10

# Sign the user certificate
$(UCER): $(UCSR) $(CACER)
	openssl x509 -req -extfile $(CONFCU) -extensions cr_ext -days 365 \
		-in $(UCSR) -CA $(CACER) -CAkey $(CAKEY) -out $(UCER)

# Create a user certificate
$(UCSR): $(UKEY)
	openssl req -config $(CONFCU) -new -reqexts cr_ext -outform $(FORM) \
		-key $(UKEY) -out $(UCSR)

# Create a user key
$(UKEY): $(CONFCU)
	openssl genpkey -config $(CONFCU) -out $(UKEY) -outform $(FORM) \
		-algorithm RSA

# Sign the server certificate
$(SCER): $(SCSR) $(CACER)
	openssl x509 -req -extfile $(CONFCS) -extensions cr_ext -days 3650 \
		-in $(SCSR) -CA $(CACER) -CAkey $(CAKEY) -out $(SCER)
	openssl x509 -in $(SCER) -noout -text

# Create a server certificate 
$(SCSR): $(SKEY)
	openssl req -config $(CONFCS) -new -reqexts cr_ext -outform $(FORM) \
		-key $(SKEY) -out $(SCSR)

# Create a server key
$(SKEY): $(CACER) $(CONFCS)
	openssl genpkey -config $(CONFCS) -out $(SKEY) -outform $(FORM) \
		-algorithm RSA

# Create a CA from CA key
$(CACER): $(CAKEY)
	openssl req -config $(CONFCA) -x509 -days 3650 -reqexts ca_ext \
		-outform $(FORM) -key $(CAKEY) -out $(CACER)
	openssl x509 -in $(CACER) -noout -text

# Create a key for the CA certificate
$(CAKEY): $(CONFCA)
	openssl genpkey -config $(CONFCA) -out $(CAKEY) -outform $(FORM) \
		-algorithm RSA

$(CONFCA):	ORG-CA.cnf $(ORG)
	cp ORG-CA.cnf $(CONFCA)

$(CONFCS):	ORG-CS.cnf $(ORG)
	cp ORG-CS.cnf $(CONFCS)

$(CONFCU):	ORG-CU.cnf $(ORG)
	cp ORG-CU.cnf $(CONFCU)

$(ORG):
	mkdir -p $(ORG) $(ORG)/certs $(ORG)/private

clean:
	rm $(CAKEY) $(CACER) \
	       	$(UCER) $(UCSR) $(UKEY) $(UPFX) \
		$(CONFCA) $(CONFCS) $(CONFCU) \
	       	$(SCER) $(SCSR) $(SKEY)
	rmdir $(ORG)/certs $(ORG)/private
	rmdir $(ORG)
