#!/bin/bash

#
# extract_softreq_issues.sh
#
# Given a repository name, extracts all issues that are soft requirements:
# either containing SOFTREQ in title/body, or labeled with 'requirement'.
# Outputs files in softreq-issues/repository/ formatted for spreadsheet input.
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
OUTPUT_DIR="softreq-issues/$REPO_NAME"
mkdir -p "$OUTPUT_DIR"

# gh issue list is paginated to 30 by default.
gh issue list --repo "OpenwaterHealth/$REPO_NAME" --limit 999999 --json number,title,state \
| jq -c '.[]' \
| while read -r issue; do
    ISSUE_NUM=$(echo "$issue" | jq '.number')
    TITLE=$(echo "$issue" | jq -r '.title')
    STATE=$(echo "$issue" | jq -r '.state')

    MATCH_REQ=0

    if echo "$TITLE" | grep -qi "SOFTREQ"; then
        MATCH_REQ=1
    fi

    LABELS=$(gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json labels | jq -r '[.labels[].name] | join(",")')
    if echo "$LABELS" | grep -q "requirement"; then
        MATCH_REQ=1
    fi

    if [ "$MATCH_REQ" -eq 1 ]; then
        # The following command passes the issue into a json parser (jq), which
        # can output as tsv. However, newlines both within the .body and the
        # comments after using gsub to format comments are left as "\n" in the
        # tab-separated output. Therefore, before sending it to the file, we have
        # to replace those characters with actual newlines.
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
            ] | @tsv' > "$OUTPUT_DIR/#${ISSUE_NUM}"
    fi
done
