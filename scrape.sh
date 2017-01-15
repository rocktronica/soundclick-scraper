#!/bin/bash

{

# Rename argument(s)
program_name="$0"
band_id="$1"
greedy=false # !!!!!

if [ "$1" == '-h' ]; then
    echo "\
A script to download an entire music catalogue from a SoundCloud artist

Options:
    -h      Show this help info and quit
    -g      Download all songs on page, regardless of artist

Usage:
    $program_name -h
    $program_name BAND_ID
    $program_name -g BAND_ID

(The Band ID is easily obtained as a URL parameter on their page)
"
    exit
fi

if [ "$1" == '-g' ]; then
    greedy=true
    band_id="$2"
fi

function get_basename() {
    echo $1 | grep -oE "[^/]*\.[^/]*$"
}

function get_download_url_from_id() {
    id="$1"
    url="http://www.soundclick.com/util/downloadSong.cfm?ID=$id"
    final_url=$(curl -w "%{url_effective}\n" -I -L -s -S $url -o /dev/null)
    echo "$final_url"
}

function trim() {
    xargs
}
function count() {
    wc -l | trim
}

function get_music_url() {
    band_id="$1"
    page="${2:-1}"

    echo "http://www.soundclick.com/bands/default.cfm?bandID=$band_id&content=music&currentPage=$page"
}

function parse_and_cache_ids() {
    input="$1"
    output="$2"
    song_regex="downloadSong.cfm\?ID=\d*"

    if $greedy; then
        song_regex="songid=\d*"
    fi

    cat "$input" | \
        grep -oE "$song_regex" | \
        grep -oE "\d+" | \
        uniq \
        > "$output"
}

function run() {
    # Create cache and output folders
    output_folder="output/$band_id"
    mkdir -p "$output_folder"
    cache_folder="cache/$band_id"
    mkdir -p "$cache_folder"

    page_number=1
    going=true

    while $going; do
        url=$(get_music_url $band_id $page_number)

        # Download and cache page
        curl --silent --compressed "$url" > "$cache_folder/$page_number.html"

        parse_and_cache_ids \
            "$cache_folder/$page_number.html" \
            "$cache_folder/$page_number.txt"

        # Quit if exhausted and no IDs found
        total=$(cat "$cache_folder/$page_number.txt" | count)
        if [ $total == 0 ]; then
            going=false
            echo "All done!"
            rm -rf $cache_folder
            exit 0
        fi

        echo "PAGE $page_number"
        echo "$url"
        echo

        # Read through IDs, get URLs, and download
        current=1
        while read id; do
            url=$(get_download_url_from_id "$id")
            filename=$(get_basename $url)
            filepath="$output_folder/$filename"

            echo " - $current/$total: #$id"
            echo "   $url"
            echo "   $filepath"

            curl --silent --compressed "$url" > "$filepath"

            let current=$current+1
        done < "$cache_folder/$page_number.txt"

        let page_number=$page_number+1

        echo
    done;
}

run

}
