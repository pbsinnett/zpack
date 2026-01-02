# ZPack

A specialized Windows Batch script designed to automate the archiving of **32-bit Float** audio from the **Zoom H2 Essential**.

This tool solves the specific "fragmentation" issue where the H2 Essential splits long recordings across multiple sub-folders (e.g., `Rec_001.wav` in one folder, `Rec_002.wav` in another). It seamlessly stitches them, compresses them to WavPack, and cleans up the mess.

## Features

* **H2 Essential Specific:** Handles the unique `[Folder] -> [Folder]_001` file spanning structure used by the H2 Essential.
* **Blind/Screen-Reader Friendly:** Optimized for NVDA/JAWS with title-bar progress percentages and prompt-based status updates.
* **Lossless Archiving:** Compresses to WavPack (`.wv`) to save space without losing data.
* **Timestamp Sync:** Restores original creation dates to the final files.

## ⚠️ Supported Formats

This tool is strictly designed for stereo **.wav** files. MS raw has not been tested.

## 🤝 Call for Contributors (Other Zoom Models)

**I only own the H2 Essential.**

Different Zoom recorders (H1E, H4E, H6E) use different logic when splitting files (file size limit). The H2E creates entirely new folders.

**If you have a different Zoom recorder:**
I want to make this script universal. Please open an Issue or Pull Request with your folder structure!

1.  Record a long file until it splits.
2.  Run `tree /f` or `dir /s` on your SD card.
3.  Paste the output so I can add the detection logic to the script.
4.  If your recorder has other naming variation options, switch to each option and repeat these steps

---

## Why WavPack?

While FLAC is the industry standard for music, **WavPack** is the superior choice for archiving field recordings, particularly from modern 32-bit float recorders like the Zoom Essential series.

* **Native 32-Bit Float Support:** Unlike standard FLAC (which is limited to 24-bit integer), WavPack handles 32-bit floating-point audio natively and efficiently. This means your raw H2E recordings are compressed **bit-perfectly** without any conversion or data loss.
* **Efficient Compression:** WavPack is exceptionally good at compressing the high noise floor and silence often found in field recordings (like empty channels), significantly reducing file size compared to raw WAV.
* **Data Integrity:** WavPack includes MD5 checksums by default, ensuring your archives are never corrupted or altered.

---

## Prerequisites

Add these to your system PATH:
1.  **FFmpeg:** For joining streams.
2.  **WavPack:** For compression.
3.  **WvGain:** For loudness metadata.

## Usage

1.  Drop the script in the root of your SD card (or backup folder).
2.  Run it.
3.  Review the processing logs in the window.
4.  The script will pause and wait for your confirmation before deleting the source files.

## License

GNU General Public License v3.0