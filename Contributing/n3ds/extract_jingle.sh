#!/bin/bash

shopt -s nullglob
for ROM in *.3ds *.cci; do
    echo "Processing $ROM..."
    OUTPUT="${ROM%.*}.wav"

    3dstool -xvtf cci "$ROM" -0 partition0.cxi --header /dev/null
    3dstool -xvtf cxi partition0.cxi --exefs exefs.bin --exefs-auto-key
    3dstool -xvtfu exefs exefs.bin --exefs-dir exefs_dir/

    mv exefs_dir/banner.bnr banner.bin

    3dstool -xvtf banner banner.bin --banner-dir banner_dir/

    # Trim bcwav to the size declared in its header
    python3 -c "
import struct
with open('banner_dir/banner.bcwav','rb') as f:
    data = f.read()
size = struct.unpack('<I', data[12:16])[0]
with open('banner_dir/banner.bcwav','wb') as f:
    f.write(data[:size])
"

    vgmstream-cli banner_dir/banner.bcwav -o "$OUTPUT"

    rm -r partition0.cxi exefs.bin exefs_dir/ banner.bin banner_dir/

    FINAL=$(echo "$OUTPUT" \
        | sed "s/'//g" \
        | sed 's/([^)]*)//g' \
        | sed 's/ *- */-/g' \
        | sed 's/ /-/g' \
        | sed 's/--*/-/g' \
        | sed 's/^-//; s/-$//' \
        | sed 's/-\(\.[^.]*\)$/\1/' \
        | tr '[:upper:]' '[:lower:]')
    [ "$FINAL" != "$OUTPUT" ] && mv "$OUTPUT" "$FINAL"

    echo "Saved: $FINAL"
done
