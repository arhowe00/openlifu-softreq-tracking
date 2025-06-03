#!/bin/bash

#
# create_openlifu_edgeless_graph.sh
#
# This master script orchestrates the extraction pipeline for all repositories.
# It calls sub-scripts to extract commits, commit-linked issues, and softreq issues.
#

set -e

REPOS=(
    "github.com/OpenwaterHealth/SlicerOpenLIFU"
    "github.com/OpenwaterHealth/OpenLIFU-python"
    "github.com/OpenwaterHealth/OpenLIFU-app"
)

for REPO in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$REPO")
    bash scripts/extract_commits.sh "$REPO"
    bash scripts/extract_commit_linked_issues.sh "$REPO_NAME"
    bash scripts/extract_softreq_issues.sh "$REPO_NAME"
done

# Create headers for issues.tsv and softreqs.tsv
HEADER="repo	issue_number	title	body	labels	assignees	state	created_at	updated_at	comments	type	primary_key"

printf "%s\n" "$HEADER" > issues.tsv
printf "%s\n" "$HEADER" > softreqs.tsv

# Process commit-linked-issues
for FILE in commit-linked-issues/*/*.tsv; do
    [ -e "$FILE" ] || continue  # skip if no files
    tail -n +2 "$FILE" | while IFS= read -r LINE; do
        REPO=$(printf "%s" "$LINE" | cut -f1)
        ISSUE_NUMBER=$(printf "%s" "$LINE" | cut -f2)
        TYPE="issue"
        PRIMARY_KEY="${REPO}${ISSUE_NUMBER}"
        printf "%s\t%s\t%s\n" "$LINE" "$TYPE" "$PRIMARY_KEY" >> issues.tsv
    done
done

# Process softreq-issues
for FILE in softreq-issues/*/*.tsv; do
    [ -e "$FILE" ] || continue  # skip if no files
    tail -n +2 "$FILE" | while IFS= read -r LINE; do
        REPO=$(printf "%s" "$LINE" | cut -f1)
        ISSUE_NUMBER=$(printf "%s" "$LINE" | cut -f2)
        TYPE="softreq"
        PRIMARY_KEY="${REPO}${ISSUE_NUMBER}"
        printf "%s\t%s\t%s\n" "$LINE" "$TYPE" "$PRIMARY_KEY" >> softreqs.tsv
    done
done
