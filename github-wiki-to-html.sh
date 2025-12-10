#!/bin/bash
#
# Wrapper for the main Ruby script, run directly from the terminal.
#

# Exit immediately if any command fails.
set -euo pipefail
IFS=$'\n\t'

# Run the main Ruby script and capture the output directory.
out=$(ruby -r ./github-wiki-to-html.rb -e 'puts OUTPUT_DIRECTORY')

# Beautify the generated HTML/XML files.
find "$out" -type f \
  \( -name '*.html' -o -name '*.xml' \) \
  \! -name '404.html' \
  -print0 \
  | xargs -0 npx html-beautify --replace --quiet
