clean:
	rm -rf _output
	rm -rf .up
	rm -rf ~/.up/cache

build:
	up project build

render: render-example

render-all: render-example

render-example:
	up composition render --xrd=apis/irsas/definition.yaml apis/irsas/composition.yaml examples/irsas/example.yaml

test:
	up test run tests/*

validate: validate-composition validate-example

validate-composition:
	up composition render --xrd=apis/irsas/definition.yaml apis/irsas/composition.yaml examples/irsas/example.yaml --include-full-xr --quiet | crossplane beta validate apis/irsas --error-on-missing-schemas -

validate-example:
	crossplane beta validate apis/irsas examples/irsas

publish:
	@if [ -z "$(tag)" ]; then echo "Error: tag is not set. Usage: make publish tag=<version>"; exit 1; fi
	up project build --push --tag $(tag)

generate-definitions:
	up xrd generate examples/irsas/example.yaml

generate-function:
	up function generate --language=go-templating render apis/irsas/composition.yaml

e2e:
	up test run tests/* --e2e