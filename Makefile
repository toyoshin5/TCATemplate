.PHONY: project test

project:
	cd App && xcodegen generate

test:
	swift test --package-path iOS
