---
name: aws-investigate
description: Interactively investigate and troubleshoot an AWS resource issue. Asks for the problem description, AWS profile, and region, then systematically diagnoses the issue using the AWS CLI.
argument-hint: "[optional: brief description of the issue]"
allowed-tools:
  - Agent
---

# AWS Investigation

The user wants to troubleshoot an AWS resource issue with automated service detection and investigation.

Launch the AWS investigator agent to handle the investigation. The agent will:
1. Gather information about the problem (service type, credentials, resource details)
2. Verify AWS access
3. Automatically detect the service type from the problem description
4. Run appropriate investigation scripts (Lambda, RDS, etc.)
5. Provide findings and recommendations

Use the Agent tool to launch the aws-investigator agent with the user's issue description.
