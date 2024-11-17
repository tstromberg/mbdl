#!/bin/bash
# Download Malware Bazaar samples based on tag or file extension

# Define tag and number of samples to download
set -e -o pipefail -u

DOWNLOAD_LIMIT=100
TAG=$2
case "$1" in
	file_type)
		query="query=get_file_type&selector=time&file_type=${TAG}&limit=${DOWNLOAD_LIMIT}"
		;;
	tag)
		query="query=get_taginfo&&selector=time&tag=${TAG}&limit=${DOWNLOAD_LIMIT}"
		;;
	*)
		echo "unknown query type: $1"
		exit 1
		;;
esac


mkdir -p "${TAG}"
cd "${TAG}" || exit 1

# Determin OS
OS=$(uname -s)

# Download hash values from tag, save the SHA256 hashes
echo "running query: ${query}"
results=$(mktemp)
curl -s -XPOST -d "${query}" https://mb-api.abuse.ch/api/v1/ > "${results}"

grep sha256_hash "${results}" | awk '{print $2}' >${TAG}.hashes || true
if [[ ! -s "${TAG}.hashes" ]]; then
	echo "no results for ${query}: $(cat ${results})"
	exit 1
fi

wc -l "${TAG}.hashes"

# Download the samples using their hash vaules
for hash in $(cut -d\" -f2 ${TAG}.hashes); do
	if [[ -f ".${hash}" ]]; then
		echo "${TAG}: ${hash} exists"
		continue
	fi
	echo "${TAG}: fetching ${hash}"
	curl -s -XPOST -d "query=get_file&sha256_hash=${hash}" -o ${hash} https://mb-api.abuse.ch/api/v1/
	7zz -y x ${hash} -p"infected" >/dev/null
	rm ${hash}

	# it's a dmg
	if [[ -f "${hash}.dmg" ]]; then
		hdiutil attach -readonly -mountpoint "/Volumes/${hash}" "${hash}.dmg"
		rsync -va "/Volumes/${hash}" "${hash}_dmg"
		hdiutil eject "/Volumes/${hash}"
		rm -f "${hash}.dmg"
	fi
	pwd
	ls -la | grep "${hash}"
	find ${hash}* -type f -exec chmod 400 {} \;
	touch .${hash}
done

rm ${TAG}.hashes

