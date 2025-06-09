#!/bin/bash

#
# edit_issue_descriptions_with_matching_list.sh
#
# Given a mapping file that links GitHub issues to software requirements,
# this script updates each issue description to append a traceability block 
# that links it to the related software requirement. 
#
# The mapping file must have the following format:
# 
#   primary_key SOFTREQ
#   <repo1>#<issue1> <repo2>#<issue2>
#   ...
#
# Each line links one primary issue (repo#issue) to one requirement (repo#issue).
#
# The script uses the GitHub CLI (`gh`) and requires that you are authenticated
# and have the appropriate repository permissions.
#
# Usage:
#   ./edit_issue_descriptions_with_matching_list.sh mapping_file.tsv
#

GITHUB_ORG="OpenwaterHealth"

# Ensure gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "gh CLI not found. Please install GitHub CLI first."
    exit 1
fi

# Check for correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 mapping_file.tsv"
    exit 1
fi

# Read input mapping file
mapping_file="$1"


# Process mapping file, skipping header
tail -n +2 "$mapping_file" | while read -r line; do

    # Extract primary and foreign keys from the mapping file line.
    primary_key=$(echo "$line" | awk '{print $1}')
    foreign_key=$(echo "$line" | awk '{print $2}')

    # Note: xargs trim (passing to xargs after awk) did **not** work to get rid
    # of formatting issues. Using tr -d \r\n to remove **both carriage returns
    # and newlines** worked to have a properly formatted issue body.
    primary_key=$(echo "$primary_key" | tr -d '\r\n')
    foreign_key=$(echo "$foreign_key" | tr -d '\r\n')

    # Parse repository names and issue numbers for primary and foreign keys
    primary_repo=$(echo "$primary_key" | cut -d'#' -f1)
    primary_issue=$(echo "$primary_key" | cut -d'#' -f2)
    primary_repo_full="$GITHUB_ORG/$primary_repo"

    foreign_repo=$(echo "$foreign_key" | cut -d'#' -f1)
    foreign_issue=$(echo "$foreign_key" | cut -d'#' -f2)
    foreign_repo_full="$GITHUB_ORG/$foreign_repo"

    # Construct full GitHub issue URLs
    primary_url="https://github.com/$primary_repo_full/issues/$primary_issue"
    foreign_url="https://github.com/$foreign_repo_full/issues/$foreign_issue"

    # Markdown formatted references (safely avoid newlines)
    primary_md="[$primary_key]($primary_url)"
    foreign_md="[$foreign_key]($foreign_url)"

    # Get current UTC timestamp in ISO 8601 format
    current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Construct traceability block with cleaner start and end markers
    traceability_block=$(printf "\n\n<!-- TRACEABILITY BLOCK START -->\n\n---\n**Traceability Information:**\n- Time: %s\n- Issue: %s\n- SOFTREQ: %s\n- Comment: This issue addresses the requirements defined in %s.\n<!-- TRACEABILITY BLOCK END -->" \
        "$current_time" "$primary_md" "$foreign_md" "$foreign_md")

    # Display progress
    echo "Updating $primary_repo#$primary_issue ..."

    # Retrieve current issue body
    current_body=$(gh issue view "$primary_issue" -R "$primary_repo_full" --json body -q ".body")

    # Count START and END tags separately. Note that this assumes in good faith
    # that TRACEABILITY BLOCKs have START and END blocks in succession, and this
    # script does not verify that the ordering is correct, in case traceability
    # blocks contain each other.
    start_count=$(echo "$current_body" | grep -c "<!-- TRACEABILITY BLOCK START -->")
    end_count=$(echo "$current_body" | grep -c "<!-- TRACEABILITY BLOCK END -->")

    # Determine number of complete blocks (min of start and end counts)
    if [ "$start_count" -ge 1 ] && [ "$end_count" -ge 1 ]; then
        complete_blocks=1
    else
        complete_blocks=0
    fi

    if [ "$complete_blocks" -lt 1 ]; then
        # No complete existing block found, append traceability block
        new_body="${current_body}${traceability_block}"

        # Update issue description
        gh issue edit "$primary_issue" -R "$primary_repo_full" --body "$new_body"

        echo "Traceability block added to $primary_repo#$primary_issue."
    else
        echo "Traceability block already exists in $primary_repo#$primary_issue. Skipping."
    fi

done
