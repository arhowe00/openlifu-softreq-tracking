#!/bin/bash

#
# extract_commit_linked_issues.sh
#
# Given a repository name and a maximum number of linked soft requirements, this
# script parses commit messages from commits/repository/ and extracts referenced
# issue numbers based on commit taglines only. For each qualifying issue, it
# creates a file in commit-linked-issues/repository/ containing a single
# TSV-formatted row suitable for spreadsheets.
#
# Filters:
#  - Only non-PR issues are included (note: `gh issue view` treats PRs as issues) 
#  - Only issues with fewer than MAX_LINKED_SOFTREQS traceability blocks (marked
#    by <!-- TRACEABILITY BLOCK START/END --> in the issue body) are included
#

if ! command -v gh &> /dev/null; then
    echo "gh CLI not found. Please install GitHub CLI first."
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 repository_name MAX_LINKED_SOFTREQS"
    exit 1
fi

REPO_NAME="$1"
MAX_LINKED_SOFTREQS="$2"
COMMITS_DIR="commits/$REPO_NAME"
OUTPUT_DIR="commit-linked-issues/$REPO_NAME"
mkdir -p "$OUTPUT_DIR"

cd "$COMMITS_DIR" || exit 1

head -n 1 * | grep -h -Eo '#[0-9]+' | sort -u | while read -r ISSUE_REF; do
    ISSUE_NUM=$(echo "$ISSUE_REF" | tr -d '#')
    OUTPUT_FILE="$OLDPWD/$OUTPUT_DIR/#${ISSUE_NUM}.tsv"

    # ---- Issue Qualification Criteria ----

    # Check if it's a pull request
    IS_PR=$(gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json isPullRequest -q '.isPullRequest')
    if [ "$IS_PR" = "true" ]; then
        echo "Skipping PR #$ISSUE_NUM"
        continue
    fi

    # Retrieve current issue body
    current_body=$(gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json body -q ".body")

    # Count number of traceability blocks
    start_count=$(echo "$current_body" | grep -c "<!-- TRACEABILITY BLOCK START -->")
    end_count=$(echo "$current_body" | grep -c "<!-- TRACEABILITY BLOCK END -->")
    traceability_block_count=$((start_count < end_count ? start_count : end_count))

    if [ "$traceability_block_count" -ge "$MAX_LINKED_SOFTREQS" ]; then
        echo "Skipping issue #$ISSUE_NUM due to $traceability_block_count linked softreqs (limit: $MAX_LINKED_SOFTREQS)"
        continue
    fi

    # --------------------------------------

    # Write header first
    echo -e "repo\tissue_number\ttitle\tbody\tlabels\tassignees\tstate\tcreated_at\tupdated_at\tcomments" > "$OUTPUT_FILE"

    # Append issue information. Make sure to replace all escaped newlines with actual newlines
    gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json number,title,body,labels,assignees,state,createdAt,updatedAt,comments \
    | jq -r --arg repo "$REPO_NAME" '
        [
            $repo,
            "#" + (.number|tostring),
            (.title|gsub("\t";"    ")|gsub("\n";" ")|gsub("\\|";" ")),
            (.body|gsub("\t";"    ")|gsub("\\|";" ")),
            ([.labels[].name]|join(",")),
            ([.assignees[].login]|join(",")),
            .state,
            .createdAt,
            .updatedAt,
            (
                [.comments[] | "@\(.author.login)\n\(.body | gsub("\\t";"    ") | gsub("\\|";" "))\n---"]
                | join("\n")
            )
        ] | @tsv' \
    >> "$OUTPUT_FILE"
done

cd "$OLDPWD" || exit 1
