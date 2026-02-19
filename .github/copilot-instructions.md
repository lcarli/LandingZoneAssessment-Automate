# Copilot Instructions — Regras de Execução de Tarefas

## Fluxo Obrigatório de Trabalho

Ao trabalhar neste projeto, siga **rigorosamente** este fluxo para cada tarefa:

### 1. Consultar o TASKS.md
- Abra o arquivo `TASKS.md` na raiz do projeto.
- Identifique a **próxima tarefa não concluída** (checkbox `[ ]`), seguindo a ordem de prioridade (bugs críticos primeiro, depois checks não implementados, performance, qualidade, funcionalidades novas).

### 2. Executar APENAS 1 tarefa por vez
- **Nunca** execute mais de uma tarefa simultaneamente.
- Foque 100% na tarefa atual até que ela esteja concluída e validada.

### 3. Implementar a correção/melhoria
- Faça as alterações necessárias no(s) arquivo(s) indicado(s) na tarefa.
- Siga os padrões existentes do projeto (uso de `Set-EvaluationResultObject`, `Write-ErrorLog`, enums `[Status]::`, etc.).

### 4. Testar usando DebugFunctions.ps1
- Após implementar, teste a alteração usando o script de debug:
  ```powershell
  cd Debug
  .\DebugFunctions.ps1 -FunctionName "NomeDaFuncao"
  ```
- O `DebugFunctions.ps1` testa **uma função/pergunta específica** por vez.
- Se o DebugFunctions não suportar o teste necessário (ex: módulo não importado, checklist item mock incorreto), **adapte o DebugFunctions.ps1 primeiro** para suportar o teste da tarefa atual.

### 5. Avaliar o resultado do teste
- Mostre o resultado completo do teste ao usuário.
- Explique o que foi testado, o output obtido, e se o resultado está correto.
- **Aguarde a confirmação explícita do usuário** antes de prosseguir.

### 6. Marcar como concluído no TASKS.md
- Somente após a confirmação do usuário, marque a tarefa como concluída:
  - Altere `[ ]` para `[x]` no `TASKS.md`.

### 7. Commit e Push
- Crie um commit com mensagem descritiva:
  ```
  fix: #<número> - <descrição curta da tarefa>
  ```
  Exemplos:
  - `fix: #1 - corrige self-assignment nos catch blocks do Management.ps1`
  - `feat: #6 - implementa checks G02.06-G02.10 no Security.ps1`
  - `perf: #12 - elimina N+1 queries no Management.ps1`
- Faça o push para o repositório remoto.

### 8. Parar e aguardar
- **Pare completamente** após o push.
- Só inicie a próxima tarefa quando o usuário solicitar.

---

## Regras Gerais

- **Uma tarefa de cada vez** — nunca pule etapas ou agrupe tarefas.
- **Sempre testar** — nenhuma tarefa é concluída sem teste via `DebugFunctions.ps1`.
- **Sempre aguardar confirmação** — o usuário precisa validar o teste antes do commit.
- **Commits atômicos** — cada commit corresponde a exatamente 1 tarefa do `TASKS.md`.
- **Nunca commitar código não testado**.

## Estrutura do Projeto (Referência Rápida)

```
scripts/Main.ps1            → Orquestrador principal
scripts/Initialize.ps1      → Setup de ambiente e autenticação
scripts/CreateWebSite.ps1   → Geração do dashboard web
functions/                   → Módulos de assessment (8 design areas)
shared/SharedFunctions.ps1   → Funções compartilhadas (Set-EvaluationResultObject, etc.)
shared/ErrorHandling.ps1     → Write-ErrorLog
shared/Enums.ps1             → Status, ContractType enums
shared/config.json           → Configuração do assessment
shared/alz_checklist.en.json → Checklist de referência (242 itens)
shared/exceptions.json       → Overrides manuais
Debug/DebugFunctions.ps1     → Teste unitário de funções individuais
TASKS.md                     → Lista de tarefas (fonte da verdade)
```
