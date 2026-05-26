# https://www.jetbrains.com/help/writerside/build-with-docker.html
# Stage 1: Build Writerside documentation
FROM jetbrains/writerside-builder:2026.04.8711 AS writerside-build

ARG SOURCE_DIR=/opt/sources
ARG MODULE_INSTANCE=Writerside/hi_zh
ARG OUTPUT_DIR=/opt/wrs-output

RUN mkdir -p ${SOURCE_DIR} ${OUTPUT_DIR}
WORKDIR ${SOURCE_DIR}

COPY . ${SOURCE_DIR}/documentation-website-zh/

RUN export DISPLAY=:99 && \
    Xvfb :99 & \
    /opt/builder/bin/idea.sh helpbuilderinspect \
        --source-dir ${SOURCE_DIR}/documentation-website-zh \
        --product ${MODULE_INSTANCE} \
        --runner other \
        --output-dir ${OUTPUT_DIR}

# Stage 2: Final image with nginx
FROM nginx:alpine AS final

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy Writerside documentation
COPY --from=writerside-build /opt/wrs-output/ /tmp/wrs-output/
RUN cd /tmp/wrs-output && \
    if [ -f "webHelpHI_ZH2-all.zip" ]; then \
        unzip webHelpHI_ZH2-all.zip -d /usr/share/nginx/html/ ; \
    elif [ -f "webHelpHI_ZH2.zip" ]; then \
        unzip webHelpHI_ZH2.zip -d /usr/share/nginx/html/ ; \
    fi && \
    rm -rf /tmp/wrs-output

# Copy API documentation
COPY docs/api/ /usr/share/nginx/html/api/

# Copy nginx configuration
COPY documentation-website-zh/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
