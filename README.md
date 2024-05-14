# Azure Review Checklist Project

This project provides a framework to evaluate Azure configurations using checklists and store the results in an Azure Storage Account. It includes a static website to view the checklist items and PowerShell scripts to perform the analyses.

## Project Structure

- `bicep/`: Bicep files to provision Azure resources.
- `arm/`: ARM templates to provision Azure resources.
- `scripts/`: PowerShell scripts to run the analyses.
- `web/`: Static website files.
- `README.md`: Project documentation.

## Deployment

Click the button below to deploy the resources to Azure.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flcarli%2FLandingZoneAssessment-Automate%2Fmain%2Farm%2Fmain.json)

## How to Use

1. **Provision the resources:** Use the "Deploy to Azure" button to provision the Storage Account and containers.
2. **Upload the checklists:** Upload the JSON checklist files to the `checklists` container.
3. **Run the scripts:** Execute the PowerShell script `analyze.ps1` to analyze the configurations and store the results in the `results` container.
4. **View the checklist:** Access the static website to view the checklist items.

## Contributing

Contributions are welcome! Please open a PR or issue on GitHub to suggest improvements.
