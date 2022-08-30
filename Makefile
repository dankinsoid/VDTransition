init:
	swift package --allow-writing-to-directory ./docs \
    generate-documentation --target VDTransition \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path VDTransition \
    --output-path ./docs