#!/bin/bash

#
# extract_commit_linked_issues.sh
#
# Given a repository name, parses commit messages from commits/repository/
# and extracts referenced issue numbers based on commit taglines only.
# Creates commit-linked-issues/repository/ containing one file per issue,
# formatted as spreadsheet-compatible rows.
#

if ! command -v gh &> /dev/null; then
    echo "gh CLI not found. Please install GitHub CLI first."
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 repository_name"
    exit 1
fi

REPO_NAME="$1"
COMMITS_DIR="commits/$REPO_NAME"
OUTPUT_DIR="commit-linked-issues/$REPO_NAME"
mkdir -p "$OUTPUT_DIR"

cd "$COMMITS_DIR" || exit 1

head -n 1 * | grep -h -Eo '#[0-9]+' | sort -u | while read -r ISSUE_REF; do
    ISSUE_NUM=$(echo "$ISSUE_REF" | tr -d '#')
    OUTPUT_FILE="$OLDPWD/$OUTPUT_DIR/#${ISSUE_NUM}.tsv"

    # Check if it's a pull request
    IS_PR=$(gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json isPullRequest -q '.isPullRequest')
    if [ "$IS_PR" = "true" ]; then
        echo "Skipping PR #$ISSUE_NUM"
        continue
    fi

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
