#!/bin/bash
# Get the latest version of the Markdown (kramdown) documentation files from
# the RCS subdirectory, then convert them to HTML using the "kramdown" command
# line tool.  Needs to have the kramdown gem installed for that to work.
# AGMS20200130

echo "Checking out all files in an unlocked state.  If you want to leave a file"
echo "locked, answer no to the overwrite prompt."
co -u RCS/*

echo "Converting Markdown files to HTML."
for NameMD in *.md
do
  NameHTML="${NameMD%.md}.html"
  echo "Now converting $NameMD to $NameHTML."
  kramdown < "$NameMD" > "$NameHTML"
done
