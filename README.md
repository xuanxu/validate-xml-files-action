# Open Journals :: Validate JATS & Crossref XML Files

This action validates Open Journals' JATS and Crossref XML files. If an error happens it sends back a message to the review issue.


## Usage

As part of a review process, usually this action is used as a step in a workflow that also includes other steps to generate the XML files.

### Inputs

The action accepts the following inputs:

- **jats_path**: Optional. The path to a JATS file to be validated.
- **crossref_path**: Optional. The path to a Crossref XML file to be validated.
- **validation_mode**: Optional. Posible values: draft (defaut, will allow invalid DOI values) or strict.


### ENV

In order to post a comment in the review issue these variables should be set in the env context:

- **GITHUB_TOKEN**: Used to authenticate when using the GitHub API
- **GH_REPO**: The reviews repo
- **ISSUE_ID**: The issue where this submission is being reviewed
- **DEFAULT_ERROR**: An optional default error message
