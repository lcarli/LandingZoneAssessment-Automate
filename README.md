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
