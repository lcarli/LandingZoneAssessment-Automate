param storageAccountName string = 'reviewcheckliststorage'
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource checklistContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${storageAccount.name}/default/checklists'
  properties: {}
}

resource resultsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${storageAccount.name}/default/results'
  properties: {}
}

resource staticWebsite 'Microsoft.Storage/storageAccounts/staticWebsite@2021-02-01' = {
  name: storageAccount.name
  properties: {
    indexDocument: 'index.html'
    errorDocument404Path: '404.html'
  }
}

output storageAccountEndpoint string = storageAccount.properties.primaryEndpoints.web
