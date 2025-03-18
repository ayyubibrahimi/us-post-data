.PHONY: make-env
make-env:
	uv venv

.PHONY: create-requirements
create-requirements:
	uv pip compile --generate-hashes pyproject.toml > requirements.txt


.PHONY: lint
lint:
	pre-commit run --all-files
