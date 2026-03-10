#!/bin/bash

# Usage: ./extract_wiiu_jingles.sh <input_folder> <output_folder>
# Extracts bootSound.btsnd from every .wua file and converts to .wav

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_folder> <output_folder>"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
TEMP_DIR="$OUTPUT_DIR/.wua_tmp"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

shopt -s nullglob
WUA_FILES=("$INPUT_DIR"/*.wua)

if [ ${#WUA_FILES[@]} -eq 0 ]; then
    echo "No .wua files found in '$INPUT_DIR'"
    rm -rf "$TEMP_DIR"
    exit 1
fi

for WUA in "${WUA_FILES[@]}"; do
    BASENAME=$(basename "$WUA" .wua)
    echo "Processing: $BASENAME"

    EXTRACT_DIR="$TEMP_DIR/$BASENAME"
    mkdir -p "$EXTRACT_DIR"

    # Extract the .wua
    zarchive "$WUA" "$EXTRACT_DIR" > /dev/null
    if [ $? -ne 0 ]; then
        echo "  ERROR: zarchive failed for $BASENAME, skipping."
        rm -rf "$EXTRACT_DIR"
        continue
    fi

    # Find any one subdirectory (title ID folder) and look for meta/bootSound.btsnd
    BOOTSOUND=$(find "$EXTRACT_DIR" -maxdepth 3 -path "*/meta/bootSound.btsnd" | head -n 1)

    if [ -z "$BOOTSOUND" ]; then
        echo "  WARNING: bootSound.btsnd not found for $BASENAME, skipping."
        rm -rf "$EXTRACT_DIR"
        continue
    fi

    # Skip empty boot sounds (some titles ship a dummy zero-byte file)
    if [ ! -s "$BOOTSOUND" ]; then
        echo "  WARNING: bootSound.btsnd is empty for $BASENAME (no jingle), skipping."
        rm -rf "$EXTRACT_DIR"
        continue
    fi

    # Convert to .wav
    OUTPUT_WAV="$OUTPUT_DIR/$BASENAME.wav"
    vgmstream-cli "$BOOTSOUND" -o "$OUTPUT_WAV"
    if [ $? -ne 0 ]; then
        echo "  ERROR: vgmstream failed for $BASENAME"
    else
        echo "  OK: $OUTPUT_WAV"
    fi

    # Clean up extracted folder to save space
    rm -rf "$EXTRACT_DIR"
done

rm -rf "$TEMP_DIR"
echo "Done."
