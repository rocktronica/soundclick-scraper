#!/bin/bash

{

function parse_html_for_image_ids() {
    cat cache/cache.html | \
        grep -oE "downloadSong.cfm\?ID=\d*" | \
        grep -oE "\d+"
}

function basename() {
    echo $1 | grep -oE "[^/]*\.[^/]*$"
}

function get_download_urls() {
    while read id; do
        url="http://www.soundclick.com/util/downloadSong.cfm?ID=$id"

        # idk how this works!
        final_url=$(curl -w "%{url_effective}\n" -I -L -s -S $url -o /dev/null)

        echo $url
        echo $final_url

        filename=$(basename $final_url)

        curl -# -L --compressed $final_url > "output/$filename"
        echo
    done;
}

function cache_page() {
    url="http://www.soundclick.com/bands/default.cfm?bandID=505305&content=music&songcount=114&offset=0&currentPage=5"

    echo "Caching $url"
    curl -# -L --compressed "$url" > cache/cache.html

    echo
    echo
}

cache_page
parse_html_for_image_ids | get_download_urls

}
