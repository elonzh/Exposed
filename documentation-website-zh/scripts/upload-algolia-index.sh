#!/bin/sh

set -eu

writerside_root="$1"
index_dir="$2"
algolia_key_arg="${3:-}"
algolia_key="${algolia_key_arg}"

if [ -f /run/secrets/ALGOLIA_KEY ]; then
    algolia_key="$(cat /run/secrets/ALGOLIA_KEY)"
fi

if [ -z "${algolia_key}" ]; then
    echo "ALGOLIA_KEY not provided, skipping Algolia index upload"
    exit 0
fi

buildprofiles_path="${writerside_root}/cfg/buildprofiles.xml"
writerside_cfg_path="${writerside_root}/writerside.cfg"

algolia_app_name="$(sed -n 's:.*<algolia-id>\(.*\)</algolia-id>.*:\1:p' "${buildprofiles_path}" | head -n 1)"
algolia_index_name="$(sed -n 's:.*<algolia-index>\(.*\)</algolia-index>.*:\1:p' "${buildprofiles_path}" | head -n 1)"
instance_src="$(sed -n 's:.*<instance[^>]*src="\([^"]*\)".*:\1:p' "${writerside_cfg_path}" | head -n 1)"
instance_id="${instance_src%.tree}"
web_path="$(sed -n 's:.*<instance[^>]*web-path="\([^"]*\)".*:\1:p' "${writerside_cfg_path}" | head -n 1)"
normalized_web_path="${web_path#/}"
config_product="${instance_id}"
config_version="$(sed -n 's:.*<instance[^>]*version="\([^"]*\)".*:\1:p' "${writerside_cfg_path}" | head -n 1)"

if [ -n "${normalized_web_path}" ] && [ "${normalized_web_path}" != "${instance_id}" ]; then
    config_product="${normalized_web_path}"
fi

if [ -z "${algolia_app_name}" ] || [ -z "${algolia_index_name}" ] || [ -z "${config_product}" ] || [ -z "${config_version}" ]; then
    echo "Missing Algolia publication metadata in Writerside configuration" >&2
    exit 1
fi

if [ ! -d "${index_dir}" ]; then
    echo "Prepared Algolia index directory not found: ${index_dir}" >&2
    exit 1
fi

algolia_api_base="https://${algolia_app_name}.algolia.net"

algolia_request() {
    method="$1"
    path="$2"
    body="$3"

    curl --fail --silent --show-error \
        --request "${method}" \
        --url "${algolia_api_base}${path}" \
        --header 'accept: application/json' \
        --header 'content-type: application/json' \
        --header "x-algolia-api-key: ${algolia_key}" \
        --header "x-algolia-application-id: ${algolia_app_name}" \
        --data "${body}"
}

echo "Ensuring Algolia facets for product/version"
algolia_request PUT \
    "/1/indexes/${algolia_index_name}/settings" \
    '{"attributesForFaceting":["searchable(product)","searchable(version)"]}' \
    >/dev/null

echo "Deleting existing Algolia records for ${config_product}@${config_version}"
algolia_request POST \
    "/1/indexes/${algolia_index_name}/deleteByQuery" \
    "{\"filters\":\"product:${config_product} AND version:${config_version}\"}" \
    >/dev/null

echo "Uploading Algolia indexes for ${config_product}@${config_version}"
env "algolia-key=${algolia_key}" java -jar /opt/builder/help-publication-agent.jar \
    update-index \
    --application-name "${algolia_app_name}" \
    --index-name "${algolia_index_name}" \
    --product "${config_product}" \
    --version "${config_version}" \
    --index-directory "${index_dir}"
