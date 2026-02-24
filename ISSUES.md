# Issues Identificados no Log de Assessment

**Fonte:** `logs/LandingZone-Assessment_20260220_101226_transcript.log` (76.753 linhas)  
**Execução total:** 3h 48m 23s | **Assessment:** 48m 21s  
**Resultado:** 8 OK, 0 failed — mas com resultados potencialmente incompletos/incorretos nas questões afetadas.

---

## Bugs Críticos

- [x] **#1 — `Invoke-RestMethod` sem `api-version`** (~21 ocorrências)  
  - **Seção:** [1/8] Azure Billing & Entra ID Tenants (questões A03.xx)  
  - **Arquivo:** `functions/AzureBillingandMicrosoftEntraIDTenants.ps1`  
  - **Erro:** `MissingApiVersionParameter — The api-version query parameter (?api-version=) is required for all requests.`  
  - **Causa (investigada):** As 3 chamadas `Invoke-RestMethod` no código JÁ possuem `api-version` na URL. Os erros vêm de cmdlets internos do módulo `Az.Billing` (`Get-AzBillingAccount`, `Get-AzBillingProfile`, etc.) que fazem chamadas REST internas sem `api-version`. Não é bug do nosso código — é limitação do módulo `Az.Billing`.  
  - **Impacto:** Erros são capturados por `try/catch` e o assessment completa, mas os resultados de billing/EA podem estar incompletos. Os erros no transcript são "ruído" do módulo.  
  - **Ação:** Sem correção possível no nosso código. Aguardar atualização do módulo `Az.Billing`.

- [x] **#2 — `Get-AzOperationalInsightsWorkspace` com parâmetro inexistente `-SubscriptionId`** (~63 ocorrências)  
  - **Seção:** [8/8] Management (questões F01.01 a F01.03)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `A parameter cannot be found that matches parameter name 'SubscriptionId'.`  
  - **Causa:** A versão instalada do módulo `Az.OperationalInsights` não suporta o parâmetro `-SubscriptionId`.  
  - **Impacto:** Cascata de erros — causa também os erros #3 e #4. Resultados de Log Analytics Workspaces ficam vazios.

- [x] **#3 — `Select-Object -ExpandProperty RetentionInDays` falha** (~42 ocorrências)  
  - **Seção:** [8/8] Management (questão F01.01)  
  - **Arquivo:** `functions/Management.ps1` (linha ~116)  
  - **Erro:** `Property "RetentionInDays" cannot be found.`  
  - **Causa:** Consequência direta do bug #2 — workspace objects são nulos e não possuem a propriedade.  
  - **Impacto:** Avaliação de retenção de logs retorna dados incorretos.

- [x] **#4 — `Get-AzRoleAssignment` com Scope nulo** (1 ocorrência)  
  - **Seção:** [8/8] Management (questão F01.01)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `Cannot validate argument on parameter 'Scope'. The argument is null or empty.`  
  - **Causa:** Consequência do bug #2 — scope do workspace é nulo porque o workspace nunca foi recuperado.

---

## Erros de Recursos Não Encontrados (Resource Groups deletados/movidos)

- [x] **#5 — `Get-AzVMExtension` falha com ResourceGroupNotFound** (~96 ocorrências)  
  - **Seção:** [8/8] Management (questão F01.04)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `Resource group '<RG_NAME>' could not be found. ErrorCode: ResourceGroupNotFound, StatusCode: 404`  
  - **Causa:** VMs listadas no Azure Resource Graph referenciam Resource Groups que foram deletados ou movidos (32 RGs distintos).  
  - **Correção:** Bug em `Invoke-AzCmdletSafely` (SharedFunctions.ps1) — `Write-Output` poluía o pipeline de retorno. Corrigido para `Write-Host -ForegroundColor Yellow`.

- [x] **#6 — `Get-AzStorageAccount` — NotFound** (~197 ocorrências)  
  - **Seção:** [2/8] Identity (B04.02-B04.04) e [8/8] Management  
  - **Arquivos:** `functions/IdentityandAccessManagement.ps1`, `functions/Management.ps1`  
  - **Erro:** `Operation returned an invalid status code 'NotFound'` com `ErrorActionPreference` em Stop.  
  - **Causa:** Stale data — storage accounts em subscriptions/RGs que não existem mais.  
  - **Correção:** Resolvido pela mesma correção do #5 — `Invoke-AzCmdletSafely` já trata o erro com fallback. Pipeline pollution corrigido.

- [x] **#7 — `Get-AzRecoveryServicesVault` — NotFound** (~23 ocorrências)  
  - **Seção:** [8/8] Management (questão F02.02)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `Operation failed. One or more errors occurred. (Operation returned an invalid status code 'NotFound')`  
  - **Causa:** Recovery Services vaults em resource groups que não existem mais.  
  - **Correção:** Resolvido pela mesma correção do #5 — `Invoke-AzCmdletSafely` pipeline fix.

- [x] **#8 — `Get-AzDataProtectionBackupVault` — RG not found** (~5 ocorrências)  
  - **Seção:** [8/8] Management (questão F02.02)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `Resource group '<RG_NAME>' could not be found.`  
  - **RGs afetados:** `RG-BackupFortinet-Cace-Prd`, `RG-BackupFortinet-Caea-Prd`, `RG-BackupStorageAccount-Caea-Prd`, `GR-DataLake-CRC-Avaya-Prd`  
  - **Correção:** Resolvido pela mesma correção do #5 — `Invoke-AzCmdletSafely` pipeline fix.

- [x] **#9 — `Get-AzWebApp` — NotFound** (~15 ocorrências)  
  - **Seção:** [8/8] Management (questão F01.04)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `Operation returned an invalid status code 'NotFound'`  
  - **Causa:** Web apps em subscriptions/RGs que não existem mais.  
  - **Correção:** Resolvido pela mesma correção do #5 — `Invoke-AzCmdletSafely` pipeline fix.

---

## Erros de Compatibilidade de Módulos

- [x] **#10 — `Get-AzRecoveryServicesBackupProperty` — tipo incorreto de parâmetro** (~23 ocorrências)  
  - **Seção:** [8/8] Management (questão F02.02)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `Cannot convert 'System.Object[]' to the type 'Microsoft.Azure.Commands.RecoveryServices.ARSVault' required by parameter 'Vault'.`  
  - **Causa:** Cascata do bug Write-Output no `Invoke-AzCmdletSafely` — quando `Get-AzRecoveryServicesVault` falhava, o retorno era `@("Warning...", $null)` (array) em vez de `$null`. O `if ($vaultProperties)` avaliava como `$true` e passava o array para `-Vault`.  
  - **Correção:** Resolvido pela mesma correção do #5 — `Write-Host` não polui o pipeline, `$vaultProperties` agora é `$null` quando falha, e o `if` avalia `$false`.

- [x] **#11 — `Get-AzRecoveryServicesAsrProtectionContainerMapping` — parâmetro inexistente** (1 ocorrência)  
  - **Seção:** [8/8] Management (questão F04.01)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `A parameter cannot be found that matches parameter name 'ResourceGroupName'.`  
  - **Causa:** O cmdlet não aceita `-ResourceGroupName` — requer vault context.  
  - **Correção:** Removido parâmetro `-ResourceGroupName` inválido. Adicionado try/catch individual por VM para evitar terminating error no foreach.

---

## Performance / Volume Excessivo de Erros

- [ ] **#12 — `Get-AzDiagnosticSetting` em resource types não suportados** (~8.216 ocorrências)  
  - **Seção:** [8/8] Management (F01.11 a F02.01) e [6/8] Security  
  - **Arquivos:** `functions/Management.ps1`, `functions/Security.ps1`  
  - **Erro:** `The resource type '<type>' does not support diagnostic settings.`  
  - **Causa:** O código itera TODOS os Azure resources e tenta obter diagnostic settings — mas 46+ resource types não suportam.  
  - **Sugestão:** Manter uma lista de resource types que suportam diagnostic settings e filtrar antes de chamar o cmdlet.  
  - **Resource types afetados (exemplos):** `microsoft.compute/images`, `microsoft.network/privateendpoints`, `microsoft.insights/actiongroups`, `microsoft.operationalinsights/querypacks`, etc.

- [ ] **#13 — `Get-AzMetricAlertRuleV2` — NotFound massivo** (~546 ocorrências)  
  - **Seção:** [8/8] Management (questão F01.12)  
  - **Arquivo:** `functions/Management.ps1`  
  - **Erro:** `Exception type: ErrorResponseException, Status code: NotFound, Reason phrase: Not Found`  
  - **Causa:** Consulta metric alert rules em subscriptions onde certos recursos não existem mais.  
  - **Sugestão:** Tratar `404/NotFound` silenciosamente com `-ErrorAction SilentlyContinue`.

---

## Warnings (Baixa Prioridade)

- [ ] **#14 — WARNING: `Get-AzDiagnosticSetting` breaking changes** (~8.042 ocorrências)  
  - **Seção:** [6/8] Security e [8/8] Management  
  - **Warning:** `Upcoming breaking changes: The types of the properties Log and Metric will be changed from single object or fixed array to 'List'. Takes effect Az.Monitor 7.0.0`  
  - **Causa:** Az.Monitor module deprecation notice emitido a cada chamada.  
  - **Sugestão:** Preparar código para a mudança futura. Suprimir warnings com `$WarningPreference = 'SilentlyContinue'` durante as chamadas, ou usar `-WarningAction SilentlyContinue`.

- [ ] **#15 — WARNING: `Get-AzRoleDefinition` breaking changes** (1 ocorrência)  
  - **Seção:** [2/8] Identity  
  - **Warning:** `Upcoming breaking changes in the cmdlet 'Get-AzRoleDefinition'`  
  - **Sugestão:** Baixa prioridade — apenas um aviso de deprecação.

---

## Erros na Governance

- [ ] **#16 — `Get-AzPolicyDefinition` com ID vazio** (~4 ocorrências)  
  - **Seção:** [5/8] Governance (questão E01.06)  
  - **Arquivo:** `functions/Governance.ps1`  
  - **Erro:** `Cannot bind argument to parameter 'Id' because it is an empty string.`  
  - **Warning associado:** `Failed to get policy definition for assignment : Cannot bind argument to parameter 'Id' because it is an empty string.`  
  - **Causa:** Policy assignments com `PolicyDefinitionId` nulo ou vazio.  
  - **Sugestão:** Validar que `$assignment.Properties.PolicyDefinitionId` não é nulo/vazio antes de chamar `Get-AzPolicyDefinition -Id`.

---

## Resumo de Concentração de Erros por Módulo

| Arquivo | Qtd Erros Aprox. | Issues Relacionados |
|---|---|---|
| `functions/Management.ps1` | ~17.300+ | #2, #3, #4, #5, #7, #8, #9, #10, #11, #12, #13 |
| `functions/AzureBillingandMicrosoftEntraIDTenants.ps1` | ~21 | #1 |
| `functions/IdentityandAccessManagement.ps1` | ~197 | #6 |
| `functions/Security.ps1` | ~8.000+ | #12, #14 |
| `functions/Governance.ps1` | ~4 | #16 |

> **Observação:** A seção Management (8/8) concentra ~97% dos erros e levou 15m 42s dos 48m de assessment. A correção dos issues #2 e #12 teria o maior impacto na redução de erros e tempo de execução.
