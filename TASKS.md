# 📋 Lista de Tarefas — Azure Landing Zone Assessment

> **Gerado em**: 19/02/2026  
> **Status geral**: 5 bugs críticos | 54 checks por implementar (32%) | 5 problemas de performance | ~10 melhorias  
> **Prioridade sugerida**: Bugs críticos → Checks NotDeveloped → Performance → Novas funcionalidades

---

## 🔴 BUGS CRÍTICOS (Corrigir imediatamente)

- [x] **#1** — Corrigir `$status = $status` nos catch blocks — `Management.ps1`  
  Self-assignment silencioso — deveria ser `[Status]::Error`. Erros nunca são reportados.

- [x] **#2** — Corrigir `Write-Warning -ForegroundColor` — `Security.ps1`  
  `-ForegroundColor` não é parâmetro válido de `Write-Warning`. Vai dar erro em runtime.

- [x] **#3** — Corrigir lógica quebrada no C03.01 — `ResourceOrganization.ps1`  
  `ForEach-Object` sempre retorna `$false` — security baseline nunca reporta compliance.

- [x] **#4** — Corrigir retorno inconsistente no B03.07 — `IdentityandAccessManagement.ps1`  
  Um path de erro retorna hashtable raw ao invés de usar `Set-EvaluationResultObject`.

- [x] **#5** — Corrigir uso de `$_` ao invés de `$checklistItem` — `AzureBillingandMicrosoftEntraIDTenants.ps1`  
  Check A01.01 passa variável errada no return.

---

## 🟡 CHECKS NÃO IMPLEMENTADOS (54 itens — 32% do total)

### Security.ps1 — 20 `NotDeveloped` + 1 `ManualVerificationRequired` (21/31)

- [x] **#6** — Implementar checks: G02.06, G02.07, G02.08, G02.09, G02.10, G02.12, G02.13, G03.01–G03.12, G04.02, G05.01, G06.01, G06.02  
  **Apenas 10/31 checks funcionam.** Pior cobertura junto com DevOps.

### PlatformAutomationandDevOps.ps1 — 11 stubs (11/13)

- [x] **#7** — Implementar checks: H01.01, H01.02, H01.03, H01.05, H01.07, H02.01–H02.04, H04.01+  
  **Apenas 2/13 checks têm lógica real.** 85% são stubs.

### ResourceOrganization.ps1 — 8 stubs (8/19)

- [x] **#8** — Implementar checks: C01.01, C02.07, C02.08, C02.09, C02.12, C02.13, C02.14, C03.03  
  42% são stubs.

### Governance.ps1 — 7 stubs (7/14)

- [x] **#9** — Implementar checks: E01.07, E01.09, E01.10, E01.11, E01.12, E01.13  
  Checks de soberania/regulatório.

### NetworkTopologyandConnectivity.ps1 — ~5 stubs

- [x] **#10** — Implementar checks: D01.09, D01.10, D03.01, D03.04

### Management.ps1 — 2 stubs

- [x] **#11** — Implementar checks: F01.13, F01.16

---

## ⚡ PERFORMANCE (N+1 Query Patterns)

- [x] **#12** — Eliminar N+1 queries no Management — `Management.ps1`  
  `Get-AzDiagnosticSetting` e `Get-AzMetricAlertRuleV2` chamados por recurso; `Get-AzPolicyAssignment` por VM.

- [x] **#13** — Eliminar N+1 queries no IAM (MFA check) — `IdentityandAccessManagement.ps1`  
  MFA status consultado por usuário via Graph API.

- [x] **#14** — Eliminar N+1 queries no Governance — `Governance.ps1`  
  `Get-AzRoleAssignment` por MG; `Get-AzConsumptionBudget` por subscription.

- [x] **#15** — Eliminar N+1 queries no Billing — `AzureBillingandMicrosoftEntraIDTenants.ps1`  
  REST API por subscription (A03.05, A04.03).

- [x] **#16** — Eliminar N+1 queries no Security — `Security.ps1`  
  `Set-AzContext` por Key Vault (G02.04).

---

## 🔧 QUALIDADE DE CÓDIGO

- [x] **#17** — Corrigir rawData copy-paste errado — `PlatformAutomationandDevOps.ps1`  
  H01.04 diz "IaC tool usage" mas pergunta é sobre version control. *(Já corrigido na Task #7)*

- [x] **#18** — Corrigir rawData copy-paste errado — `ResourceOrganization.ps1`  
  C02.13 diz "cost management" mas pergunta é sobre identity services. *(Já corrigido na Task #8)*

- [x] **#19** — Melhorar heurísticas frágeis (naming-based) — Diversos  
  DCs, break-glass accounts, Entra Connect detectados só por nome de VM — falso-positivos/negativos.

- [x] **#20** — Padronizar filtro `$_.Type` vs `$_.ResourceType` — `NetworkTopologyandConnectivity.ps1`  
  Inconsistente ao filtrar `$global:AzData.Resources`.

- [x] **#21** — Corrigir `switch` statement confuso no weight — `SharedFunctions.ps1`  
  `$weight = 1;break;` dentro de expression funciona mas é confuso.

- [ ] **#22** — Remover código comentado (A03.03) — `AzureBillingandMicrosoftEntraIDTenants.ps1`  
  Grande bloco de código comentado.

---

## 📊 COBERTURA DE CHECKLIST

- [ ] **#23** — Cobrir itens faltantes do checklist  
  O checklist tem **242 itens**, mas apenas **~169 são avaliados**. **73 itens não têm função correspondente** (especialmente Network com 102 itens mas ~25 checks).

- [ ] **#24** — Usar os 44 Azure Resource Graph queries do checklist  
  O checklist tem **44 itens com campo `graph`** — muitos não são aproveitados pelas funções. Network usa alguns via `Test-QuestionAzureResourceGraph` mas outros módulos não.

---

## 🚀 FUNCIONALIDADES NOVAS

- [ ] **#25** — Adicionar execução paralela dos assessments — `Main.ps1`  
  As 8 áreas rodam sequencialmente. Usar `ForEach-Object -Parallel` (PS 7+) para acelerar.

- [ ] **#26** — Consumir `Weight` e `Score` no report/dashboard  
  Calculados em `Set-EvaluationResultObject` mas **nunca usados** — adicionar scoring ao relatório e dashboard.

- [ ] **#27** — Adicionar suporte a múltiplos idiomas do checklist  
  Estrutura já suporta (`alz_checklist.en.json`) mas não há outros idiomas.

- [ ] **#28** — Melhorar o `exceptions.json`  
  Apenas um exemplo comentado. Documentar e permitir override por `guid` além de `id`.

- [ ] **#29** — Corrigir `DebugFunctions.ps1`  
  Faltam 3 dos 8 módulos (Security, ResourceOrg, PlatformAutomation); usa `Invoke-Expression` (risco de segurança); mock hardcoded.

- [ ] **#30** — Corrigir `CompareChecklist.ps1`  
  `$changedInCategory` sempre = 0; só detecta `Test-Question*` (ignora checks ARG do Network); caminhos hardcoded.

- [ ] **#31** — Adicionar validação do `config.json` na inicialização  
  Não valida campos obrigatórios, formatos, ou se o TenantId é um GUID válido.

- [ ] **#32** — Gerar resumo executivo no relatório  
  Percentual geral de compliance, top riscos por severidade, comparação com execuções anteriores.

- [ ] **#33** — Adicionar progress bar no `Main.ps1`  
  Usar `Write-Progress` para feedback visual durante a execução dos 8 módulos.

---

## 📈 Resumo de Cobertura Atual

| Arquivo | Total | Automatizados | Stubs | % Stubs |
|---------|:-----:|:-------------:|:-----:|:-------:|
| AzureBillingandMicrosoftEntraIDTenants.ps1 | 19 | 18 | 1 | 5% |
| Governance.ps1 | 14 | 7 | 7 | 50% |
| IdentityandAccessManagement.ps1 | 22 | 22 | 0 | 0% |
| Management.ps1 | 26 | 24 | 2 | 8% |
| NetworkTopologyandConnectivity.ps1 | ~25 | ~20 | ~5 | ~20% |
| PlatformAutomationandDevOps.ps1 | 13 | 2 | 11 | **85%** |
| ResourceOrganization.ps1 | 19 | 11 | 8 | 42% |
| Security.ps1 | 31 | 11 | 20 | **65%** |
| **TOTAL** | **~169** | **~115** | **~54** | **~32%** |

> **Nota**: O checklist possui 242 itens, mas apenas ~169 são avaliados. 73 itens não possuem checks implementados.
