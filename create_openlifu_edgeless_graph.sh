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
