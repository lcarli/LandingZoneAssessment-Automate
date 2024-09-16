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
    PartialImplemented
    NotImplemented
    Unknown
    ManualVerificationRequired
    NotApplicable
    Error
}

enum ContractType {
    EnterpriseAgreement
    MicrosoftCustomerAgreement
    CloudSolutionProvider
    MicrosoftEntraIDTenants
}
