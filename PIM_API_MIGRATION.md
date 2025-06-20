# Migração da API do PIM (Privileged Identity Management)

## Problema Identificado

O script estava falhando com o seguinte erro:
```
{"error":{"code":"TenantEnabledInAadRoleMigration","message":"The current endpoints of AAD roles have been disabled for the tenant for migration purpose. Please use the new Azure AD RBAC roles. Please refer to https://aka.ms/PIMFeatureUpdateDoc for new PIM features; https://aka.ms/PIMAPIUpdateDoc for API and PowerShell changes because of migration."}}
```

## Causa Raiz

A Microsoft migrou as APIs do PIM para novas versões. As APIs antigas (`Get-MgBetaPrivilegedRoleRoleAssignment`) foram depreciadas e desabilitadas em muitos tenants. A migração faz parte de uma atualização maior do PIM para usar as APIs unificadas de Role Management.

## Solução Implementada

### 1. Atualização da Função de Avaliação PIM

**Antes (API depreciada):**
```powershell
$pimRoles = Get-MgBetaPrivilegedRoleRoleAssignment | Where-Object { 
    $_.RoleDefinitionName -in @("Global Administrator", "Privileged Role Administrator", "Security Administrator") 
}
```

**Depois (Nova API PIM v3):**
```powershell
# Get role definitions for privileged roles
$roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition | Where-Object { 
    $_.DisplayName -in $privilegedRoleNames 
}

# Get active and eligible assignments
$activeRoleAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -Filter "roleDefinitionId eq '$($roleDefinition.Id)'"
$eligibleRoleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "roleDefinitionId eq '$($roleDefinition.Id)'"
```

### 2. Lógica Melhorada de Avaliação

A nova implementação:
- Diferencia entre **atribuições ativas** (permanentes) e **atribuições elegíveis** (PIM)
- Fornece uma análise mais precisa do status de "zero standing access"
- Oferece dados mais detalhados sobre a configuração do PIM
- Calcula a porcentagem baseada na relação entre atribuições elegíveis vs. ativas

### 3. Tratamento de Erros Aprimorado

- Tratamento específico para problemas de autorização
- Mensagens de erro mais informativas
- Graceful degradation quando permissões são insuficientes

### 4. Módulos Atualizados

Adicionado o módulo `Microsoft.Graph.Identity.Governance` aos módulos requeridos no Initialize.ps1:
```powershell
'Microsoft.Graph.Identity.Governance' = @{ MinVersion = '2.0.0'; Critical = $false }
```

## APIs Utilizadas na Nova Implementação

### Role Management APIs (PIM v3)
- `Get-MgRoleManagementDirectoryRoleDefinition` - Obter definições de roles
- `Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance` - Atribuições ativas
- `Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance` - Atribuições elegíveis (PIM)

### Benefícios das Novas APIs
1. **Compatibilidade futura** - APIs suportadas a longo prazo
2. **Melhor granularidade** - Separação clara entre atribuições ativas e elegíveis
3. **Mais informações** - Metadados adicionais sobre as atribuições
4. **Alinhamento** - Consistente com outras APIs de Role Management

## Critérios de Avaliação

| Status | Condição | Explicação |
|--------|----------|------------|
| **Implemented** | Apenas atribuições elegíveis (PIM) | Zero standing access implementado corretamente |
| **NotImplemented** | Apenas atribuições ativas (permanentes) | Sem PIM, apenas acesso permanente |
| **PartiallyImplemented** | Mix de atribuições ativas e elegíveis | Migração parcial para PIM |
| **NotApplicable** | Nenhuma atribuição encontrada | Sem roles privilegiados atribuídos |

## Teste da Solução

Para testar a nova implementação:

1. Execute o script normalmente
2. Verifique se não há mais erros de "TenantEnabledInAadRoleMigration"
3. Confirme que as avaliações PIM retornam dados válidos
4. Revise os logs para ver mensagens sobre atribuições ativas vs. elegíveis

## Links de Referência

- [PIM API Overview](https://learn.microsoft.com/graph/api/resources/privilegedidentitymanagementv3-overview)
- [PIM API Migration Guide](https://aka.ms/PIMAPIUpdateDoc)
- [New PIM Features](https://aka.ms/PIMFeatureUpdateDoc)
- [Role Management API Reference](https://learn.microsoft.com/graph/api/resources/unifiedroleassignmentschedulerequest)
