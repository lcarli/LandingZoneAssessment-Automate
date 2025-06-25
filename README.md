# Landing Zone Assessment Automation Project

## Project Overview

This project automates the evaluation of an **Azure Landing Zone** based on the **Azure Landing Zone Framework**. It provides a detailed assessment of your cloud infrastructure configuration and compliance with best practices. The evaluation generates:

- A structured JSON report (`report.json`) summarizing the findings.
- An interactive web dashboard (`web/index.html`) to visualize the results through charts and tables.

The tool also supports manual overrides for certain evaluations, allowing users to mark specific questions as **Implemented** or **Not Applicable** via an `exceptions.json` file.

---

## Project Structure

- `bicep/`: Bicep files to provision Azure resources.
- `arm/`: ARM templates to provision Azure resources.
- `scripts/`: PowerShell scripts to run the analyses.
- `web/`: Static website files.
- `README.md`: Project documentation.

---

## How It Works

### Execution

1. Run the main script:

   ```powershell
   ./scripts/Main.ps1
   ```

2. During execution, the script:
   - Reads the configuration from `shared/config.json`.
   - Evaluates the tenant and subscription(s) based on the selected **Design Areas**.
   - Generates:
     - A detailed JSON report (`report.json`).
     - An error log (`ErrorLog.json`), if applicable.
     - An HTML dashboard (`web/index.html`).

3. Open the `web/index.html` file in any browser to explore the results.

---

## Configuration

The configuration file (`shared/config.json`) determines the evaluation scope. Below is an example:

```json
{
    "TenantId": "{YOUR_TENANT_ID}",
    "DefaultSubscriptionId": "",
    "ContractType": "EnterpriseAgreement", 
    "AlzChecklist": "alz_checklist.en.json",
    "DesignAreas": {
        "Billing": true,
        "IAM": true,
        "ResourceOrganization": true,
        "Network": false,
        "Governance": true,
        "Security": true,
        "DevOps": true,
        "Management": true
    }
}
```

### Key Fields

- **`TenantId`**: Your Azure tenant ID.
- **`DefaultSubscriptionId`**: The default subscription to evaluate (optional).
- **`ContractType`**: The type of Azure agreement. Options include:
  - `EnterpriseAgreement`
  - `MicrosoftCustomerAgreement`
  - `CloudSolutionProvider`
  - `MicrosoftEntraIDTenants`
- **`DesignAreas`**: Specify which **Design Areas** should be evaluated by enabling (`true`) or disabling (`false`) them.

---

## Handling Exceptions

You may encounter situations where specific questions require manual intervention or are not applicable to your environment. These exceptions are handled through the `shared/exceptions.json` file.

### Adding Exceptions

Edit the `exceptions.json` file to include the question and define its **New Status**. For example:

```json
{
  "exceptions": [
    {
      "id": "E01.01",
      "text": "Leverage Azure Policy strategically...",
      "status": "NotImplemented",
      "newStatus": "Implemented"
    },
    {
      "id": "IAM.03",
      "text": "Enforce MFA for privileged users...",
      "status": "NotImplemented",
      "newStatus": "NotApplicable"
    }
  ]
}
```

### How Exceptions Are Applied

- When generating the dashboard, the script compares the `exceptions.json` entries with the `report.json` results.
- The script updates the status of matching questions in the report.
- The updated status is reflected in the **Exceptions Table** on the dashboard.

---

## The Web Dashboard

The final output is an interactive web page (`web/index.html`) that includes:

1. **Overview Charts**:
   - Pie chart showing status distribution (e.g., Implemented, Not Applicable).
   - Radar chart displaying progress across Design Areas.
2. **Detailed Tables**:
   - **Details Table**: Lists all evaluated questions grouped by Design Area.
   - **Error Log**: Shows all detected errors during the execution.
   - **Exceptions Table**: Highlights overridden questions with their original and updated statuses.

#### Dashboard 
![Dashboard](images/headercharts.png)

---

#### Tables
![Tables](images/tables.png)

---

## License

This project is licensed under the terms specified in the `LICENSE` file. Feel free to contribute and extend the project!

## Prerequisites and Module Management

### PowerShell Requirements
- PowerShell 5.1 or PowerShell Core 7.x
- Appropriate permissions to read Azure resources and Microsoft Entra ID

### Module Installation Strategy
This project uses an **optimized module management strategy** for better performance and reliability:

#### What Gets Installed
- **`Az` meta-module**: This single module includes ALL Azure PowerShell sub-modules
- **Microsoft Graph modules**: Installed individually as they're separate from Az
  - `Microsoft.Graph.Authentication`
  - `Microsoft.Graph.Identity.DirectoryManagement`
  - `Microsoft.Graph.Users`
  - `Microsoft.Graph.Groups`
  - `Microsoft.Graph.Applications`
  - `Microsoft.Graph.Identity.Governance`
  - `Microsoft.Graph.Identity.SignIns`

#### What Gets Imported
Only the specific Azure sub-modules actually used by the assessment:
- `Az.Accounts`, `Az.Resources`, `Az.Monitor`, `Az.Billing`
- `Az.Network`, `Az.Storage`, `Az.Sql`, `Az.KeyVault`, `Az.Websites`

#### Benefits
- **Faster installation**: Only install `Az` meta-module instead of individual sub-modules
- **Better performance**: Only load modules actually used
- **Easier maintenance**: No need to track individual sub-modules for installation
- **Backwards compatible**: All Az cmdlets available if needed

### Manual Installation (if needed)
If automatic installation fails, run these commands:

```powershell
# Install core modules
Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber

# Install Microsoft Graph modules
Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Force
Install-Module -Name Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser -Force
Install-Module -Name Microsoft.Graph.Users -Scope CurrentUser -Force
Install-Module -Name Microsoft.Graph.Groups -Scope CurrentUser -Force
Install-Module -Name Microsoft.Graph.Applications -Scope CurrentUser -Force
Install-Module -Name Microsoft.Graph.Identity.Governance -Scope CurrentUser -Force
Install-Module -Name Microsoft.Graph.Identity.SignIns -Scope CurrentUser -Force
```

---

## Troubleshooting

### Common Module Issues

#### "Cmdlet not recognized" errors
If you see errors like `Get-AzStorageAccount: The term 'Get-AzStorageAccount' is not recognized`:

1. **Check if Az module is installed**:
   ```powershell
   Get-Module Az -ListAvailable
   ```

2. **Install if missing**:
   ```powershell
   Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber
   ```

3. **Restart PowerShell** and run the assessment again

#### Assembly conflicts with Microsoft Graph modules
If you see assembly loading warnings:

1. **Close all PowerShell sessions**
2. **Start a fresh PowerShell session**
3. **Run the assessment script directly** without manually importing modules

#### Performance issues
- The script automatically imports only required sub-modules for better performance
- If you need additional Az cmdlets, they're available through the installed Az meta-module
- For best performance, avoid manually importing additional modules

#### Permission issues
- Ensure your account has appropriate read permissions for Azure resources
- Some assessments require special permissions (e.g., diagnostic settings for Entra ID)
- The script gracefully handles missing permissions and marks items as "Unknown" where access is not available
