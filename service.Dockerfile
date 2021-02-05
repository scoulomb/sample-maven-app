FROM app-build:latest as builder

# This intermediate layer is not really necessary but shown for the example
FROM base-service:latest as base-service

COPY --from=builder /dist/my-app-1.0-SNAPSHOT.jar /${WORKING_DIR}/



