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

# Stage 2: Build API documentation with Dokka
FROM gradle:8.5-jdk17 AS dokka-build

WORKDIR /opt/project

# Copy only what's needed for Dokka
COPY build.gradle.kts .
COPY gradle/ gradle/
COPY gradlew .
COPY settings.gradle.kts .

# Copy source modules
COPY exposed-core/ exposed-core/
COPY exposed-dao/ exposed-dao/
COPY exposed-jdbc/ exposed-jdbc/
COPY exposed-r2dbc/ exposed-r2dbc/
COPY exposed-crypt/ exposed-crypt/
COPY exposed-java-time/ exposed-java-time/
COPY exposed-jodatime/ exposed-jodatime/
COPY exposed-json/ exposed-json/
COPY exposed-kotlin-datetime/ exposed-kotlin-datetime/
COPY exposed-money/ exposed-money/
COPY exposed-migration-core/ exposed-migration-core/
COPY exposed-migration-jdbc/ exposed-migration-jdbc/
COPY exposed-migration-r2dbc/ exposed-migration-r2dbc/
COPY exposed-spring-boot-starter/ exposed-spring-boot-starter/
COPY exposed-spring-boot4-starter/ exposed-spring-boot4-starter/
COPY spring-transaction/ spring-transaction/
COPY spring7-transaction/ spring7-transaction/
COPY exposed-gradle-plugin/ exposed-gradle-plugin/

# Generate Dokka API documentation
RUN gradle dokkaGenerate --no-daemon

# Stage 3: Final image with nginx
FROM nginx:alpine AS final

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy Writerside documentation
COPY --from=writerside-build /opt/wrs-output/ /tmp/wrs-output/
RUN cd /tmp/wrs-output && \
    if [ -f "webHelpHI_ZH2-all.zip" ]; then \
        unzip -O UTF-8 webHelpHI_ZH2-all.zip -d /usr/share/nginx/html/ ; \
    elif [ -f "webHelpHI_ZH2.zip" ]; then \
        unzip -O UTF-8 webHelpHI_ZH2.zip -d /usr/share/nginx/html/ ; \
    fi && \
    rm -rf /tmp/wrs-output

# Copy API documentation
COPY --from=dokka-build /opt/project/docs/api/ /usr/share/nginx/html/api/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
