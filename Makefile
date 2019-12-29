SHELL := /bin/bash

export LAMBDA_FUNCS := ./lambda_functions
export LAMBDA_PKGS  := ./pkgtmp


.PHONY: clean
clean:
	rm -f ${LAMBDA_PKGS}/*.zip

.PHONY: package
package: clean
	test -d ${LAMBDA_PKGS} || mkdir ${LAMBDA_PKGS} &&\
	zip -j \
		${LAMBDA_PKGS}/sg_ingress_checker.zip \
		${LAMBDA_FUNCS}/sg_ingress_checker/sg_ingress_checker.py

.PHONY: apply
apply: package
	terraform apply

.PHONY: validate
validate:
	terraform validate

.PHONY: destroy
destroy:
	terraform destroy
