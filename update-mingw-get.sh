#!/bin/sh

# Limit the number of RSS feed entries.
limit=500

# Get the download link to the most recent version of mingw-get.
if [ -f "$(type -p xz)" ]; then
    ext="\.tar\.xz"
    unpack="tar -xf"
elif [ -f "$(type -p unzip)" ]; then
    ext="\.zip"
    unpack="unzip -o"
else
    echo "ERROR: No suitable unpacking tool found."
    exit 1
fi

sed_version=$(sed --version 2> /dev/null)
if [ $? -eq 0 ]; then
    # Assume GNU sed.
    sed_args="-nr"
else
    # Assume BSD sed.
    sed_args="-nE"
fi

# Parse the RSS feed for the most recent download link and construct a line with the file name and URL separated by a
# tab character so we can easily separate it via "cut" later.
url=http://sourceforge.net/api/file/index/project-id/2435/mtime/desc/limit/$limit/rss
link=$(wget -q -O - $url |
     sed $sed_args "s/<link>(.+(mingw-get-[0-9]+\.[0-9]+-mingw32-.+-bin$ext).+)<\/link>/\2	\1/p" |
     head -1)

file=$(echo "$link" | cut -f 1)
url=$(echo "$link" | cut -f 2)

# Trim whitespaces.
file=$(echo $file)
url=$(echo $url)

mkdir -p root/mingw && cd root/mingw && (
    if [ -n "$url" ]; then
        echo "Downloading $file ..."
        file="../../$file"
	wget --progress=bar -O $file $url
        $unpack $file
    else
        echo "WARNING: Invalid URL, skipping download of mingw-get."
    fi

    if [ -f bin/mingw-get.exe ]; then
        wine=$(type -p wine)
        if [ $? -eq 0 ]; then
            version=$($wine bin/mingw-get.exe --version 2> /dev/null | grep -m 1 -o -P ".*version.*[^\s]")
        else
            version=$(bin/mingw-get.exe --version | head -1)
        fi
        if [ -z "$version" ]; then
            echo "ERROR: Unable to execute mingw-get."
            exit 2
        fi
        echo "Using $version."

        # Install mingw in a directory below the msys root.
        cat > var/lib/mingw-get/data/profile.xml << EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<profile project="MinGW" application="mingw-get">
    <repository uri="http://prdownloads.sourceforge.net/mingw/%F.xml.lzma?download">
    </repository>
    <repository uri="https://github.com/downloads/sschuberth/mingwGitDevEnv/%F.xml.lzma">
      <package-list catalogue="mingwgitdevenv-package-list" />
    </repository>
    <system-map id="default">
      <sysroot subsystem="mingw32" path="%R" />
      <sysroot subsystem="msys" path="%R/../" />
    </system-map>
</profile>
EOF

        # Get the list of available packages.
        echo "Downloading catalogues ..."
        $wine bin/mingw-get.exe update
    else
        echo "WARNING: mingw-get not found, skipping download of catalogues."
    fi
)
