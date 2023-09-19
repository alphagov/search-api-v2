# ADR 003: Google Cloud Platform Infastructure as Code
2023-09-15

## Context
As part GOV.UK site search improvements, there is a need to orchestrate provision Google Cloud Platform services such as BigQuery, Cloud Storage etc.

## Considered options
### Terraform
![Terraform](images/003-iac-terraform.drawio.svg)
GOV.UK currently manages AWS infrastructure via Terraform and have an existing [repository](https://github.com/alphagov/govuk-infrastructure) and tooling for that purpose. This could be used and extended to provision GCP resources required for Search Enhancements

### Google Cloud Build
![Google Cloud Build](images/003-iac-cloud-build.drawio.svg)
Google Cloud Build is Google Cloud Platform's service for orchestrating build and provisioning. Google Cloud Build provides accelerators specifically for provisioning GCP resources. This could be used to provision GCP resources required for Search Enhancements

## Decision drivers
1. GOV.UK uses Terraform consistently for IAC across the estate and existing patterns and tooling is used and managed for this purpose
2. There is no current usage as far as we know of Cloud Build for these purposes within GOV.UK
3. Terraform providers are available for the majority of GCP resources and Google Cloud SDK can be used for those not natively supported

## Decision
In discussions between @richardTowers and Matt Gregory on 14th Sept 2023 it was agreed to use Terraform for IaC of Google Cloud resources and add additional deployments to existing [repository](https://github.com/alphagov/govuk-infrastructure) for Search Improvements

## Status
Decided
