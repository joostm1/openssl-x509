# Makefile

# run this as 
#		make ORG='"XYZ9 Inc."' UPN=joost@xyz9.net SERVER=egx.xyz9.net

# openssl output formats
FORMPEM		:= PEM
FORMDER		:= DER
FORMPFX		:= PFX

# default form
FORM		:= $(FORMPEM)

# openssl config file with sections for CA, server and user certificates
DIR			:="$(ORG)"
CONF		:= $(DIR)/openssl.cnf
CONF_SECT_CA	:= "req_ca"
CONF_SECT_US	:= "req_user"
CONF_SECT_SR	:= "req_server"

KEYS		:= $(DIR)/private
CERTS		:= $(DIR)/certs

# files for the CA
CAKEY		:= $(KEYS)/cakey.$(FORM)
CACER		:= $(CERTS)/cacer.$(FORM)
CACERDER	:= $(CERTS)/cacer.$(FORMDER)

# files for the server certificate
SCER		:= $(CERTS)/$(SERVER)-cer.$(FORM)
SKEY		:= $(KEYS)/$(SERVER)-key.$(FORM)

# files for the user certificate
UCER		:= $(CERTS)/$(UPN)-cer.$(FORM)
UKEY		:= $(KEYS)/$(UPN)-key.$(FORM)
UPFX		:= $(CERTS)/$(UPN).$(FORMPFX)

all:	$(UPFX) $(SCER) $(UCER)

# Create a PFX bundle with the user certificate, the user key and the CA
$(UPFX): $(UCER)
	openssl pkcs12 -export -inkey $(UKEY) -in $(UCER) \
		-certfile $(CACER) -name "$(UPN)" -out $(UPFX) 

# Create and sign a user certificate
$(UCER): $(CACER)
	openssl req -x509 -noenc -new -config $(CONF) \
		-section $(CONF_SECT_US) -days 1825 \
		-outform $(FORM) -keyout $(UKEY) -out $(UCER) \
		-CA $(CACER) -CAkey $(CAKEY)
	openssl x509 -in $(UCER) -noout -text

# Create and sign a server certificate
$(SCER): $(CACER)
	openssl req -x509 -noenc -new -config $(CONF) \
		-section $(CONF_SECT_SR) -days 3650 \
		-outform $(FORM) -keyout $(SKEY) -out $(SCER) \
		-CA $(CACER) -CAkey $(CAKEY)
	openssl x509 -in $(SCER) -noout -text

# Create a self-signed CA certificate
$(CACER): $(CONF)
	openssl req -x509 -noenc -new -config $(CONF) \
		-section $(CONF_SECT_CA) -days 3650 \
		-outform $(FORM) -keyout $(CAKEY) -out $(CACER) 
	# Convert a copy in DER format
	openssl x509 -in $(CACER) -inform $(FORM) -out $(CACERDER) -outform $(FORMDER)
	openssl x509 -in $(CACER) -noout -text

$(CONF):	ORG-openssl.cnf $(DIR)
	cp ORG-openssl.cnf $(CONF)

$(DIR):
	mkdir -p $(KEYS) $(CERTS)

clean:
	rm $(CAKEY) $(CACER) $(CACERDER) \
	       	$(UCER) $(UKEY) $(UPFX) \
		$(CONF) \
	       	$(SCER) $(SKEY)
	rmdir $(CERTS) $(KEYS) $(DIR)
