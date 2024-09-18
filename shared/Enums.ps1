<#
.SYNOPSIS
    Shared enums and constants.

.DESCRIPTION
    This script contains enums and constants that are shared across multiple scripts.

.LICENSE
    MIT License

.AUTHOR
    lramoscostah@microsoft.com
#>

enum Status {
    Implemented
    PartiallyImplemented
    NotImplemented
    Unknown
    ManualVerificationRequired
    NotApplicable
    NotDeveloped
    Error
}

enum ContractType {
    EnterpriseAgreement
    MicrosoftCustomerAgreement
    CloudSolutionProvider
    MicrosoftEntraIDTenants
}
