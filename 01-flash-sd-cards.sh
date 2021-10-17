#!/bin/bash
set -u -e -o pipefail

# see https://www.raspberrypi.com/software/operating-systems/
SHA_256_CHECKSUM="c5dad159a2775c687e9281b1a0e586f7471690ae28f2f2282c90e7d59f64273c"
DOWNLOAD_LINK="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip"

ZIP_FILE_NAME="${DOWNLOAD_LINK##*/}"
IMAGE_FILE_NAME="${ZIP_FILE_NAME%.*}.img"

function download_image() {
    if [[ ! -e "${ZIP_FILE_NAME}" ]]; then
        wget "${DOWNLOAD_LINK}"
        echo "${SHA_256_CHECKSUM} ${ZIP_FILE_NAME}" | sha256sum -c
        unzip "${ZIP_FILE_NAME}"
    fi
}

function flash_sd_card() {
    diskutil list

    # sd_card_device="/dev/disk3"

    set +u
    if [[ ! "${sd_card_device}" ]]; then
        set -u
        read -p "type the desired device: " -r sd_card_device
        echo "you selected ${sd_card_device}"

        diskutil info "${sd_card_device}"
        ask_for_confirmation "Will use ${sd_card_device}"

        sd_card_raw_device=$(echo "${sd_card_device}" | awk -F"/" '{print "/"$2"/r"$3}')
        diskutil info "${sd_card_raw_device}"
        ask_for_confirmation "Will use ${sd_card_raw_device}"
    else
        set -u
        sd_card_raw_device=$(echo "${sd_card_device}" | awk -F"/" '{print "/"$2"/r"$3}')
    fi

    if [[ ! -e "${IMAGE_FILE_NAME}" ]]; then
        echo >&2 "ERROR: ${IMAGE_FILE_NAME} file does not exist"
        exit 1
    fi

    # Flash the card
    diskutil unmountDisk "${sd_card_device}"
    pv "./${IMAGE_FILE_NAME}" | sudo dd bs=1m of="${sd_card_raw_device}"
    sync

    sleep 10 # Add a sleep to wait until the volume is present (ls below fails with permission denied)

    # Enable SSH
    ls /Volumes/boot
    touch /Volumes/boot/ssh

    # shellcheck source=.env
    source .env
    # Connect to WIFI
    tee /Volumes/boot/wpa_supplicant.conf <<-EOF >/dev/null
		country=${COUNTRY}
		ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
		update_config=1
		
		network={
		    ssid="${NETWORK_SSID}"
		    psk="${NETWORK_PASSWORD}"
		}
		EOF

    ls -la /Volumes/boot/ssh
    ls -la /Volumes/boot/wpa_supplicant.conf
    diskutil unmountDisk "${sd_card_device}"
}

function ask_for_confirmation() {
    local prompt="${1}"
    local user_reply
    read -p "${prompt} . Are you sure? [yes]: " -r user_reply
    if [[ "${user_reply}" != "yes" ]]; then
        exit 1
    fi
}

download_image
flash_sd_card

say "done" || echo -e "\a"
