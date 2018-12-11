#!/bin/bash

# Requirements; lynx,parallel,wget,grep,sed
# Usage; ./impawards_scraper.sh 128
# 128 represents how many tasks to run in parallel.
# Expected output; https://the-eye.eu/imp_scrape.mp4

# Color Variables
green='\033[0;32m'
red='\033[0;31m'
cyan='\033[0;36m'
black='\033[0;30m'
yellow='\e[93m'
clear

# Logo
cat << "EOF"


 /$$$$$$$$ /$$                         /$$$$$$$$                                            
|__  $$__/| $$                        | $$_____/                                            
   | $$   | $$$$$$$   /$$$$$$         | $$       /$$   /$$  /$$$$$$       /$$$$$$  /$$   /$$
   | $$   | $$__  $$ /$$__  $$ /$$$$$$| $$$$$   | $$  | $$ /$$__  $$     /$$__  $$| $$  | $$
   | $$   | $$  \ $$| $$$$$$$$|______/| $$__/   | $$  | $$| $$$$$$$$    | $$$$$$$$| $$  | $$
   | $$   | $$  | $$| $$_____/        | $$      | $$  | $$| $$_____/    | $$_____/| $$  | $$
   | $$   | $$  | $$|  $$$$$$$        | $$$$$$$$|  $$$$$$$|  $$$$$$$ /$$|  $$$$$$$|  $$$$$$/
   |__/   |__/  |__/ \_______/        |________/ \____  $$ \_______/|__/ \_______/ \______/ 
                                                 /$$  | $$                                  
                                                |  $$$$$$/                                  
                                                 \______/                                   


impawards.com Poster Scraper v0.2 By The French Guy.

EOF
sleep 5

# List each item the site contains in links.txt
echo -e "${cyan}================="
echo -e "${cyan}= ${yellow}LISTING ITEMS ${cyan}="
echo -e "${cyan}================="
for i in {1912..2018..1}
do
    url=http://www.impawards.com/${i}/std.html
    read -ra result <<< $(curl -Is --connect-timeout 5 "${url}" || echo "timeout 500")
    status=${result[1]}
    echo -e "${red}Bounce at $url with status $status"
    if [ $status -ne 404 ]
    then
        echo -e "${green}$url is a valid url. Scraping"
	curl -s "http://www.impawards.com/${i}/std.html" | lynx --dump -stdin | grep -o "/lynx.*" | cut -b 17- | grep -v "TMP" >> temp_links
	while read p; do
		echo "Adding http://www.impawards.com/${i}/${p} to links.txt.."
		echo "http://www.impawards.com/${i}/${p}" >> links.txt
	done < temp_links
	rm temp_links
    else
        echo -e "${red}${url} isn't a valid url. Skipping."
    fi
done

# Parse links for images urls
function parse_links {
        year=$(echo $1 | grep -o '/..../')
        image_link=$(curl -s "$1" | lynx --dump -stdin | grep -o "/.*xlg.html")
        if [ $(echo $?) -eq 0 ]
        then
		image_link=$(curl -s "$1" | lynx --dump -stdin | grep -o "/.*xlg.html" | cut -b 23- | sort -nr | head -1)
                poster_link=$(curl -s "http://www.impawards.com${year}${image_link}" | grep -o 'posters/.*' | sed 's/\.jpg.*/.jpg/')
                echo -e "${yellow}Adding ${green}http://www.impawards.com${year}${poster_link}${yellow} to ${green}posters_urls.txt.."
		echo "http://www.impawards.com${year}${poster_link}" >> posters_urls.txt
        else
                poster_link=$(curl -s "$1" | grep -o 'posters/.*' | sed 's/\.jpg.*/.jpg/')
		echo -e "${yellow}Adding ${green}http://www.impawards.com${year}${poster_link}${yellow} to ${green}posters_urls.txt.."
                echo "http://www.impawards.com${year}${poster_link}" >> posters_urls.txt
        fi
}
export -f parse_links

# Parallel images url scraping.
echo -e "${cyan}======================="
echo -e "${cyan}= ${yellow}GETTING IMAGES URLS ${cyan}="
echo -e "${cyan}======================="
cat links.txt | parallel -j$1 'parse_links {}'

# Parallel downloading
echo -e "${cyan}======================"
echo -e "${cyan}= ${yellow}DOWNLOADING IMAGES ${cyan}="
echo -e "${cyan}======================"
mkdir impawards.com/
for i in {1912..2018..1}
do
        echo -e "${cyan}Downloading year ${yellow}${i} ${cyan}!"
	mkdir impawards.com/$i
	cd impawards.com/$i
        cat ../../posters_urls.txt | grep "/$i/" | parallel -j$1 'wget -c -U "The-Eye.eu; A Distributed Preservation of Content Tool" -R "*.html" {}'
	cd ../../
done
echo -e "${cyan}========="
echo -e "${cyan}= ${yellow}DONE! ${cyan}="
echo -e "${cyan}========="
