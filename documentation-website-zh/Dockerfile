# syntax=docker/dockerfile:1.7
# https://www.jetbrains.com/help/writerside/build-with-docker.html
ARG WRITERSIDE_DOCKER_VERSION=2026.04.8711

# Stage 1: Build Writerside documentation
FROM jetbrains/writerside-builder:${WRITERSIDE_DOCKER_VERSION} AS writerside-build

ARG SOURCE_DIR=/opt/sources
ARG MODULE_INSTANCE=Writerside/hi
ARG OUTPUT_DIR=/opt/wrs-output

RUN mkdir -p ${SOURCE_DIR} ${OUTPUT_DIR}
WORKDIR ${SOURCE_DIR}

COPY documentation-website-zh/ ${SOURCE_DIR}/documentation-website-zh/
COPY documentation-website/ ${SOURCE_DIR}/documentation-website/

RUN \
    set -eu; \
    export DISPLAY=:99; \
    Xvfb :99 & \
    /opt/builder/bin/idea.sh helpbuilderinspect \
        --source-dir ${SOURCE_DIR}/documentation-website-zh \
        --product ${MODULE_INSTANCE} \
        --runner other \
        --output-dir ${OUTPUT_DIR}

# Stage 2: Prepare Algolia indexes for the publisher image.
FROM jetbrains/writerside-builder:${WRITERSIDE_DOCKER_VERSION} AS algolia-index-prep

ARG OUTPUT_DIR=/opt/wrs-output

COPY --from=writerside-build ${OUTPUT_DIR}/ ${OUTPUT_DIR}/
COPY --chmod=755 documentation-website-zh/scripts/prepare-algolia-index.py /usr/local/bin/prepare-algolia-index.py

RUN set -eu; \
    index_archive="$(find "${OUTPUT_DIR}" -maxdepth 1 -name 'algolia-indexes-*.zip' | head -n 1)"; \
    if [ -z "${index_archive}" ]; then \
        echo "Algolia index archive was not produced by Writerside build" >&2; \
        exit 1; \
    fi; \
    rm -rf /opt/algolia-index; \
    mkdir -p /opt/algolia-index; \
    unzip -o "${index_archive}" -d /opt/algolia-index >/dev/null; \
    python3 /usr/local/bin/prepare-algolia-index.py /opt/algolia-index

# Stage 3: Upload Algolia indexes with the official publisher image.
FROM registry.jetbrains.team/p/writerside/builder/algolia-publisher:latest AS algolia-upload

ARG SOURCE_DIR=/opt/sources
ARG ALGOLIA_KEY=
ARG ALGOLIA_UPLOAD_NONCE=

WORKDIR ${SOURCE_DIR}

COPY documentation-website-zh/ ${SOURCE_DIR}/documentation-website-zh/
COPY --from=algolia-index-prep /opt/algolia-index/ /opt/algolia-index/
COPY --chmod=755 documentation-website-zh/scripts/upload-algolia-index.sh /usr/local/bin/upload-algolia-index.sh

RUN --mount=type=secret,id=ALGOLIA_KEY,required=false \
    set -eu; \
    printf '%s' "${ALGOLIA_UPLOAD_NONCE}" >/dev/null; \
    /usr/local/bin/upload-algolia-index.sh "${SOURCE_DIR}/documentation-website-zh/Writerside" /opt/algolia-index "${ALGOLIA_KEY:-}"; \
    touch /opt/algolia-upload-complete

# Stage 4: Final image with nginx
FROM nginx:alpine AS final

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy Writerside documentation
COPY --from=writerside-build /opt/wrs-output/ /tmp/wrs-output/
COPY --from=algolia-upload /opt/algolia-upload-complete /tmp/algolia-upload-complete
RUN cd /tmp/wrs-output && \
    unzip -o webHelpHI2.zip -d /usr/share/nginx/html/ && \
    unzip -o webHelpImages.zip -d /usr/share/nginx/html/images/ && \
    rm -rf /tmp/wrs-output /tmp/algolia-upload-complete

# Copy API documentation
COPY docs/api/ /usr/share/nginx/html/api/

# Copy nginx configuration
COPY documentation-website-zh/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
