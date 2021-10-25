#!/bin/sh
# Add Google Service to images

INPUT_IMG_DIR=$(realpath $1)
GAPPS_ZIP=$(realpath $2)
WSAGAScript=$(realpath $3)/WSAGAScript
OUTPUT_IMG_DIR=$(realpath $4)
TEMPDIR=$(mktemp -d)
MOUNT=$TEMPDIR

# if user is using Arch Linux, remind them to install SELinux tools
if [ -f /etc/arch-release ]; then
    echo "Arch Linux detected. Please install SELinux tools or your build will not work!"
    echo "See https://wiki.archlinux.org/title/SELinux and README.me for details!"
fi

# exit with error message if lzip is not installed
if ! command -v lzip >/dev/null 2>&1; then
    echo "lzip is not installed"
    exit 1
fi

# clone if file doesn't exist
if [ ! -e $WSAGAScript/apply.sh ]; then
    git clone https://github.com/knackebrot/WSAGAScript $WSAGAScript --depth=1 --branch=gapps-nano --recurse-submodules
else
    git -C $WSAGAScript pull
fi

# copy gapps zip to temp dir
echo "-> Copying files"
rm -rf $WSAGAScript/gapps/*.zip
if command -v rsync >/dev/null 2>&1; then
    rsync -aPuc $INPUT_IMG_DIR/*.img $WSAGAScript/images || exit 1
    rsync -aPuc $GAPPS_ZIP $WSAGAScript/gapps || exit 1
else
    echo "Copying images from $INPUT_IMG_DIR to $WSAGAScript/images"
    cp -r $INPUT_IMG_DIR/*.img $WSAGAScript/images || exit 1
    echo "Copying gapps from $GAPPS_ZIP to $WSAGAScript/gapps"
    cp $GAPPS_ZIP $WSAGAScript/gapps || exit 1
fi

# run scripts
pushd $WSAGAScript > /dev/null

echo "-> Mount point set to $MOUNT/mnt"
mkdir -p $MOUNT/mnt

# echo "-> Patching scripts"
# sed -i "s!^Root=.*\$!Root=$PWD!" $WSAGAScript/VARIABLES
# sed -i "s!^\(MountPointProduct\)=.*!\1=\"$MOUNT/mnt/product\"!g" $WSAGAScript/VARIABLES.sh
# sed -i "s!^\(MountPointSystemExt\)=.*!\1=\"$MOUNT/mnt/system_ext\"!g" $WSAGAScript/VARIABLES.sh
# sed -i "s!^\(MountPointSystem\)=.*!\1=\"$MOUNT/mnt/system\"!g" $WSAGAScript/VARIABLES.sh
# sed -i "s!^\(MountPointVendor\)=.*!\1=\"$MOUNT/mnt/vendor\"!g" $WSAGAScript/VARIABLES.sh
# sed -i "s!^\(InstallPartition\)=.*!\1=\$MountPointSystem!g" $WSAGAScript/VARIABLES.sh

# sed -i 's! /mnt/product/! $MountPointProduct!g' $WSAGAScript/apply.sh
# sed -i 's! /mnt/system_ext/! $MountPointSystemExt!g' $WSAGAScript/apply.sh
# sed -i 's! /mnt/system/! $MountPointSystem!g' $WSAGAScript/apply.sh
# sed -i 's! /mnt/vendor/! $MountPointVendor!g' $WSAGAScript/apply.sh

# echo "-> Changing permissions"
# chmod +x extract_gapps.sh
# chmod +x extend_and_mount_images.sh
# chmod +x apply.sh
# chmod +x unmount_images.sh

echo "-> Extract gapps"
sudo ./extract_gapps.sh || exit 1
echo "-> Extend and mount images"
sudo ./extend_and_mount_images.sh || exit 1
echo "-> Apply"
sudo ./apply.sh || exit 1
echo "-> Unmount images"
sudo ./unmount_images.sh || exit 1

popd > /dev/null

rm -rf $TEMPDIR

# move built images to output dir
mkdir -p $OUTPUT_IMG_DIR
mv $WSAGAScript/images/*.img $OUTPUT_IMG_DIR
