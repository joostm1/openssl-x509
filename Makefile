# Makefile for creating a CA, a server certificate and a user certificate
#
# Yours to configure:
#-----------------------------------------------------------------------------#
export ORG				:= XYZ9 Inc.
export UPN				:= joost@xyz9.net
export SERVER			:= egx.xyz9.net
export SAN				:= DNS:$(SERVER)
export DOMAIN			:= xyz9.net
#-----------------------------------------------------------------------------#
# The above can be overridden like this:
#   make UPN=bob@xyz9.net
#	make SERVER=opi.xyz9.net SAN=DNS.1:opi.xyz9.net,DNS.2:opi4.xyz9.net,DNS.3:opi6.xyz9.net
#-----------------------------------------------------------------------------#

# openssl output formats
FORMPEM		:= PEM
FORMDER		:= DER
FORMPFX		:= PFX

# format file extensions
FORM		:= $(FORMPEM)		# default format
FORMEXT		:= pem
ALTFORM		:= $(FORMDER)
ALTFORMEXT	:= cer

# openssl config section names
CONF			:= openssl.cnf
CONF_SECT_CA	:= req_ca
CONF_SECT_US	:= req_user
CONF_SECT_DM	:= req_domain
CONF_SECT_SR	:= req_server

# directories for keys and certificates
KEYS		:= keys
CERTS		:= certs
DIRS		:= $(KEYS) $(CERTS)

# files for the CA
CAKEY		:= $(KEYS)/cakey.$(FORMEXT)
CACER		:= $(CERTS)/cacer.$(FORMEXT)
CACERALT	:= $(CERTS)/cacer.$(ALTFORMEXT)

# files for the domain certificate
DMKEY		:= $(KEYS)/$(DOMAIN)-key.$(FORMEXT)
DMCER		:= $(CERTS)/$(DOMAIN)-cer.$(FORMEXT)
DMCERALT	:= $(CERTS)/$(DOMAIN)-cer.$(ALTFORMEXT)

# files for the server certificate
SRKEY		:= $(KEYS)/$(SERVER)-key.$(FORMEXT)
SRCER		:= $(CERTS)/$(SERVER)-cer.$(FORMEXT)
SRCERALT	:= $(CERTS)/$(SERVER)-cer.$(ALTFORMEXT)

# files for the user certificate
USKEY		:= $(KEYS)/$(UPN)-key.$(FORMEXT)
USCER		:= $(CERTS)/$(UPN)-cer.$(FORMEXT)
USCERALT	:= $(CERTS)/$(UPN)-cer.$(ALTFORMEXT)
UPFX		:= $(CERTS)/$(UPN).pfx

all: $(SCER) $(USCER) $(SRCER) $(DMCER) $(UPFX)

# Create a PFX bundle with the user certificate, the user key and the CA
$(UPFX): $(UCER)
	openssl pkcs12 -export -inkey $(USKEY) -in $(USCER) \
		-certfile $(CACER) -name $(UPN) -out $(UPFX) 

# Create and sign the user certificate
$(USCER): $(CACER)
	openssl req -x509 -noenc -new -config $(CONF) \
		-section $(CONF_SECT_US) -days 1825 \
		-outform $(FORM) -keyout $(USKEY) -out $(USCER) \
		-CA $(CACER) -CAkey $(CAKEY)
	openssl x509 -in $(USCER) -inform $(FORM) -out $(USCERALT) -outform $(ALTFORM)
	openssl x509 -in $(USCER) -noout -text

# Create and sign the domain certificate
$(DMCERALT): $(DMCER)
	openssl x509 -in $(DMCER) -inform $(FORM) -out $(DMCERALT) -outform $(ALTFORM)
$(DMCER): $(CONF) $(CACER)
	openssl req -x509 -noenc -new -config $(CONF) \
		-section $(CONF_SECT_DM) -days 3650 \
		-outform $(FORM) -keyout $(DMKEY) -out $(DMCER) \
		-CA $(CACER) -CAkey $(CAKEY)
	openssl x509 -in $(DMCER) -noout -text

# Create and sign the server certificate
$(SRCERALT): $(SRCER)
	openssl x509 -in $(SRCER) -inform $(FORM) -out $(SRCERALT) -outform $(ALTFORM)
$(SRCER): $(CACER)
	openssl req -x509 -noenc -new -config $(CONF) \
		-section $(CONF_SECT_SR) -days 3650 \
		-outform $(FORM) -keyout $(SRKEY) -out $(SRCER) \
		-CA $(CACER) -CAkey $(CAKEY)
	openssl x509 -in $(SRCER) -noout -text

# Create a self-signed CA certificate
$(CACERALT): $(CACER)
	openssl x509 -in $(CACER) -inform $(FORM) -out $(CACERALT) -outform $(ALTFORM)

$(CACER):
	openssl req -x509 -noenc -new -config $(CONF) \
		-section $(CONF_SECT_CA) -days 3650 \
		-outform $(FORM) -keyout $(CAKEY) -out $(CACER)
	openssl x509 -in $(CACER) -noout -text

$(DIRS):
	mkdir -p $(KEYS) $(CERTS)

clean:
	rm -f $(KEYS)/* $(CERTS)/*