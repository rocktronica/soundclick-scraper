#!/bin/bash

{

# Rename argument(s)
program_name="$0"
band_id="$1"

if [ "$1" == '-h' ]; then
    echo "\
A script to download an entire music catalogue from a SoundCloud artist

Usage:
$program_name BAND_ID

(The Band ID is easily obtained as a URL parameter on their page)
"
    exit
fi


# Create output directory
mkdir -p "output/$band_id"

function get_basename() {
    echo $1 | grep -oE "[^/]*\.[^/]*$"
}

function get_download_url_from_id() {
    id="$1"
    url="http://www.soundclick.com/util/downloadSong.cfm?ID=$id"
    final_url=$(curl -w "%{url_effective}\n" -I -L -s -S $url -o /dev/null)
    echo "$final_url"
}

alias trim="xargs"
alias count="wc -l | trim"

function get_music_url() {
    band_id="$1"
    page="${2:-1}"

    echo "http://www.soundclick.com/bands/default.cfm?bandID=$band_id&content=music&currentPage=$page"
}

function run() {
    page_number=1
    going=true

    while $going; do
        url=$(get_music_url $band_id $page_number)

        echo "PAGE $page_number"
        echo "$url"
        echo
        curl --silent --compressed "$url" > "cache/$page_number.html"

        # Cache IDs to file
        cat "cache/$page_number.html" | \
            grep -oE "downloadSong.cfm\?ID=\d*" | \
            grep -oE "\d+" \
            > "cache/$page_number.txt"

        # Quit if exhausted
        total=$(cat "cache/$page_number.txt" | count)
        if [ $total == 0 ]; then
            going=false
            echo "All done!"
            exit 0
        fi

        # Read through IDs, get URLs, and download
        current=1
        while read id; do
            url=$(get_download_url_from_id "$id")
            filename=$(get_basename $url)
            filepath="output/$band_id/$filename"

            echo " - $current/$total: #$id"
            echo "   $url"
            echo "   $filepath"

            curl --silent --compressed "$url" > "$filepath"

            let current=$current+1
        done < "cache/$page_number.txt"

        let page_number=$page_number+1

        echo
    done;

}

run

}
