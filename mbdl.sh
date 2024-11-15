#!/bin/bash
# Bash script to download Malware Bazaar based on tag

# Define tag and number of samples to download
set -e -o pipefail -u

TAG=$1
DOWNLOAD_LIMIT=10

mkdir -p "${TAG}"
cd "${TAG}" || exit 1

# Determin OS
OS=$(uname -s)

# Download hash values from tag, save the SHA256 hashes
curl -XPOST -d "query=get_file_type&selector=time&file_type=${TAG}&limit=${DOWNLOAD_LIMIT}" https://mb-api.abuse.ch/api/v1/ | grep sha256_hash | awk '{print $2}' >${TAG}.raw

# OS Loop
# If macOS, clean up the download to remove "'s and ,'s
if [ ${OS} == Darwin ]; then
	sed -i.bak 's/\"//g' ${TAG}.raw
	rm ${TAG}.raw.bak
	sed -i.bak 's/\,//' ${TAG}.raw
	rm ${TAG}.raw.bak

# If Linux, clean up the download to remove "'s and ,'s
else
	if [ ${OS} == Linux ]; then
		sed -i 's/\"//g' ${TAG}.raw
		sed -i 's/\,//' ${TAG}.raw

	# Exiting OS loop
	fi
fi

# Create the hash file from the raw file
mv ${TAG}.raw ${TAG}.hash

# Download the samples using their hash vaules
while read h; do
    if [[ -f ".${h}" ]]; then
        continue
    fi
    curl -XPOST -d "query=get_file&sha256_hash=${h}" -o ${h} https://mb-api.abuse.ch/api/v1/;
    7zz -y x ${h} -p"infected"
    rm ${h}

	# it's a dmg
	if [[ -f "${h}.dmg" ]]; then
		hdiutil attach -readonly -mountpoint "/Volumes/${h}" "${h}.dmg"
		rsync -va "/Volumes/${h}" "${h}"
		hdiutil eject "/Volumes/${h}"
	fi
    touch .${h}
	exit 1
done <${TAG}.hash

rm ${TAG}.raw.bak
rm ${TAG}.hash
