# OpenLIFU Software Tracking

This repository contains scripts that trace software requirements for the
OpenLIFU integrated software platform for ultrasound research. OpenLIFU
encompasses multiple coordinated repositories
([SlicerOpenLIFU](https://github.com/OpenwaterHealth/SlicerOpenLIFU),
[OpenLIFU-python](https://github.com/OpenwaterHealth/OpenLIFU-python), and
[OpenLIFU-app](https://github.com/OpenwaterHealth/OpenLIFU-app)), combining
ultrasound control, visualization, and analysis for experimentation on human
subjects and tissue models.

The repository exists to implement an auditable and consistent traceability
process that aligns code changes with formal software requirements (SOFTREQ)
under [Openwater](https://www.openwater.health)'s requirements management
framework. See
[SlicerOpenLIFU#359](https://github.com/OpenwaterHealth/SlicerOpenLIFU/issues/359).

## Prerequisites

- `gh` == `2.74.1`

## Scripts

This repository includes scripts that extract commit and issue data from GitHub
to support requirement traceability:

### `extract_commits.sh`

Clones a GitHub git repository and saves commit messages into
`commits/<repository>/`, one file per commit hash.

**Output schema (per file):**

```sh
<full commit message as plain text>
```

### `extract_commit_linked_issues.sh`

Parses commit messages in `commits/<repository>/`, extracts referenced issues
(e.g., `#123`), and outputs issue details into
`commit-linked-issues/<repository>/`, one file per issue.

Only non-pull-request issues with fewer than a given number of traceability
blocks are included.

**Output schema (TSV):**

```sh
repo\tissue_number\ttitle\tbody\tlabels\tassignees\tstate\tcreated_at\tupdated_at\tcomments
```

### `extract_softreq_issues.sh`

Extracts issues tagged with `SOFTREQ` or labeled `requirement` from a repository
and outputs TSV files to `softreq-issues/<repository>/`. Includes both open and
closed SOFTREQs, but not SOFTREQs that were closed as duplicates.

**Output schema (TSV):**

```sh
repo\tissue_number\ttitle\tbody\tlabels\tassignees\tstate\tcreated_at\tupdated_at\tcomments
```

### `edit_issue_descriptions_with_matching_list.sh`

Appends a traceability block to GitHub issue descriptions, linking them to
corresponding software requirements based on a provided mapping file.

**Input format (TSV):**

```sh
primary_key\tSOFTREQ
<repo1>#<issue1>\t<repo2>#<issue2>
...
```

- Uses the GitHub CLI (`gh`) and requires authentication.
- Only appends the block if one does not already exist.
- Output is committed directly to the issue body via GitHub API.

**Traceability block (appended to issue body):**

```markdown
<!-- TRACEABILITY BLOCK START -->

---

**Traceability Information:**
- Issue: [repo#issue](...)
- SOFTREQ: [repo#issue](...)
- Comment: This issue is related to the requirements defined in ...

_This information was populated automatically by a script on YYYY-MM-DD._

<!-- TRACEABILITY SCRIPT sha1sum abc123 -->
<!-- TRACEABILITY BLOCK END -->
```

## Questions

Please direct questions about the OpenLIFU project to the [Openwater
team](https://www.openwater.health/about):

### **Contributors**

- Ebrahim Ebrahim (Kitware) -
  [ebrahim.ebrahim@kitware.com](mailto:ebrahim.ebrahim@kitware.com)
- Peter Hollender (Openwater) -
  [phollender@openwater.health](mailto:phollender@openwater.health)
- Sam Horvath (Kitware) -
  [sam.horvath@kitware.com](mailto:sam.horvath@kitware.com)
- Andrew Howe (Kitware) -
  [andrew.howe@kitware.com](mailto:andrew.howe@kitware.com)
- Sadhana Ravikumar (Kitware) -
  [sadhana.ravikumar@kitware.com](mailto:sadhana.ravikumar@kitware.com)
- George Vigelette (Openwater) -
  [george@openwater.cc](mailto:george@openwater.cc)
