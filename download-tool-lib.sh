# Find a suitable download tool.
if [ -f "$(type -p curl)" ]; then
    download="curl"
    download_args_rss="-s"
    download_args="-# -L -o"
elif [ -f "$(type -p wget)" ]; then
    download="wget"
    download_args_rss="-q -O -"
    download_args="-N -O"
else
    echo "ERROR: No suitable download tool found."
    exit 1
fi

# Find a suitable unpacking tool.
if [ -f "$(type -p xz)" ]; then
    unpack="tar -xf"
    ext="\.tar\.xz"
elif [ -f "$(type -p unzip)" ]; then
    unpack="unzip -o"
    ext="\.zip"
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
