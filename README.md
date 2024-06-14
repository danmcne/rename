# File Renamer Script

This script renames and organizes files based on metadata, hash values, and custom naming options. It supports various operations, such as copying or moving files, and can process directories recursively.

## Features

- Copy or move files to a specified directory.
- Rename files based on metadata or original filenames.
- Append hash values to filenames using various algorithms (md5, sha1, sha256).
- Support for automatic or manual mode for renaming.
- Recursive directory processing.
- Optional inclusion of version numbers and dates in filenames.
- Verbose and quiet modes for detailed or suppressed output.

## Usage

```bash
./rename.sh [-d target_directory] [-a hash_algorithm] [-m mode] [-o operation] [-r recursion] [-t title_option] [-q quiet] [-v version] [-D use_date] [-T use_datetime] [files...]
```

### Options

- `-d target_directory`: Directory to copy/move the files into. If not provided, files are copied/moved into the current directory.
- `-a hash_algorithm`: Hash algorithm to use (md5, sha1, sha256). If not provided, no hash is appended.
- `-m mode`: Mode to use (`auto` or `manual`). Default is `auto`.
- `-o operation`: Operation to perform (`copy` or `move`). Default is `copy`.
- `-r recursion`: Recursion mode (`1` to enable, `0` to disable). Default is `0`.
- `-t title_option`: Title option: `filename` (use original filename) or `metadata` (use title from metadata). Default is `filename`.
- `-q quiet`: Quiet mode (`1` to suppress output, `0` to enable). Default is `0`.
- `-v version`: Include version in filename (`1` to include, `0` to exclude). Default is `1`.
- `-D use_date`: Include date in filename (`1` to include, `0` to exclude). Default is `1`.
- `-T use_datetime`: Use full datetime in filename (`1` to include, `0` to exclude). Default is `0`.
- `-h`: Display the help message.

### Examples

#### Basic Usage

Copy files to the `Copy` directory, using md5 hash and metadata for naming:
```bash
./rename.sh -d Copy -a md5 -m auto -t metadata *
```

#### Move Files with Verbose Output

Move files to the `MovedFiles` directory with verbose output:
```bash
./rename.sh -d MovedFiles -o move *
```

#### Quiet Mode

Suppress output while processing:
```bash
./rename.sh -q 1 *
```

#### Recursive Processing

Process directories and their contents recursively:
```bash
./rename.sh -r 1 *
```

#### Customizing Filename Components

Exclude version and date from filenames:
```bash
./rename.sh -v 0 -D 0 *
```

Include full datetime in filenames:
```bash
./rename.sh -T 1 *
```

### Requirements

- `exiftool`: Used for extracting metadata from files.
- `md5sum`, `sha1sum`, `sha256sum`: Used for generating hash values.

### Installation

Ensure the script is executable:
```bash
chmod +x rename.sh
```

Install required dependencies on a Debian-based system:
```bash
sudo apt-get install exiftool coreutils
```

### License

This project is licensed under the MIT License.

### Contributing

Feel free to submit issues or pull requests to improve the script.
