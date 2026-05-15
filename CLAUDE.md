# CLAUDE.md — Newsletter Agent

## Instrucoes para o Claude Code

- Sempre que fizer uma alteracao no projeto, atualize as secoes relevantes deste CLAUDE.md no mesmo commit.
- Nunca deixe o CLAUDE.md desatualizado em relacao ao codigo que acabou de mudar.

---

## O que e este projeto

Automacao n8n que roda todo dia as 7h (timezone America/Sao_Paulo), coleta artigos de feeds RSS em 4 categorias, usa Claude para sintetizar uma newsletter estruturada em 7 secoes e salva cada edicao como uma subpagina no Notion.

**Usuario:** Wendel Bitencourt — empreendedor brasileiro, nao e desenvolvedor, aprende fazendo. Respostas curtas e diretas.

**Stack:** n8n (orquestracao), Node.js nativo nos Code nodes, Anthropic API (Claude), Notion API.

---

## Estrutura de arquivos

```
newsletter-agent/
+-- n8n-workflow/
|   +-- newsletter-agent.json   # workflow exportado e sanitizado (fonte da verdade, sem credenciais)
+-- sources/
|   +-- rss-feeds.json          # fontes RSS por categoria
+-- deploy-vps.ps1              # script de deploy para a VPS (injeta credenciais + importa)
+-- .env.example                # variaveis de ambiente necessarias (sem valores reais)
+-- .gitignore                  # bloqueia .env, workflows com credenciais reais
+-- CLAUDE.md                   # este arquivo
+-- README.md
```

---

## Ambientes

| Ambiente | URL | Workflow ID | Uso |
|----------|-----|-------------|-----|
| Dev/local | http://localhost:5678 | `v7cI1EUEJhcCP6Hx` | testar mudancas manualmente |
| Producao | http://145.79.7.215:5678 | `newsletter-agent-vps` | cron 7h automatico, ativo |

O n8n local e iniciado via `C:\claude-code\start-n8n.ps1`.
O n8n de producao roda em Docker na VPS Hostinger (mesma VPS do Lounge Cafe Bot).

---

## VPS — infraestrutura

| Item | Valor |
|------|-------|
| Provider | Hostinger KVM 2 |
| IP | `145.79.7.215` |
| OS | Ubuntu 24.04 |
| SSH key | `C:\Users\Admin\.ssh\lounge_cafe_vps` |
| Acesso SSH | `ssh -i C:\Users\Admin\.ssh\lounge_cafe_vps root@145.79.7.215` |
| Compose dir | `/opt/lounge-cafe/` |
| Servicos Docker | evolution-api (8080), n8n (5678), postgres, redis |

O newsletter-agent compartilha a VPS com o Lounge Cafe Bot. O compose file e `/opt/lounge-cafe/docker-compose.yml`.

---

## Nos do workflow (ordem de execucao)

### 1. Cron 7h (`scheduleTrigger`)
- Expressao: `0 7 * * *`
- Timezone: `America/Sao_Paulo`
- Ativo apenas na VPS. Local: executar manualmente (botao Execute Workflow)

### 2. Fetch RSS (`code`)
- Busca 15 feeds em paralelo com `Promise.allSettled()`
- Usa modulos nativos `https` e `http` (sem dependencias externas)
- Suporta RSS 2.0 (`<item>`) e Atom (`<entry>`)
- Redireccionamentos ate 3 saltos, timeout 15s por feed
- Retorna array de artigos: `{ title, description, link, pubDate, category }`

### 3. Filtro 24h (`code`)
- Remove artigos com `pubDate` mais antigo que 24h
- Fallback: se filtrar tudo, retorna os 20 mais recentes (feeds lentos como Lenny/Dwarkesh)

### 4. Preparar Prompt (`code`)
- Agrupa por categoria (max 10 artigos/categoria)
- Monta prompt detalhado para o Claude com formato exato da newsletter
- Formato gerado: callouts com emoji, headings `##`, titulos `**negrito**`, linha `Por que importa`
- Retorna `{ prompt }` para o proximo no

### 5. Claude Synthesis (`httpRequest`)
- POST `https://api.anthropic.com/v1/messages`
- Modelo: `claude-sonnet-4-6`
- `max_tokens`: 6000
- Header `x-api-key`: chave da Anthropic API
- Header `anthropic-version`: `2023-06-01`
- Body: `{ model, max_tokens, messages: [{ role: 'user', content: prompt }] }`

### 6. Salvar no Notion (`code`)
- Le `$json.content[0].text` (resposta do Claude)
- Converte markdown para blocos Notion:
  - `Bom dia, Wendel!` → callout com emoji 🌅
  - `## emoji SECAO` → heading_2
  - `**Titulo**` (linha sozinha) → heading_3
  - `💡 Por que importa:` → callout com emoji 💡
  - `"frase"` (comeca com aspas) → quote block
  - `— Autor` → paragraph italico
  - `_texto_` → paragraph italico
  - `---` → divider
  - `- item` → bulleted_list_item
  - Resto → paragraph
- Cria pagina via POST `/v1/pages` (ate 100 blocos)
- Appenda blocos restantes via PATCH `/v1/blocks/{id}/children` (lotes de 100)
- Retorna `{ notion_url, notion_page_id, title, status }`

---

## Secoes da newsletter e suas fontes

| # | Secao | Tipo | Fontes |
|---|-------|------|--------|
| 1 | 📊 MERCADO & ECONOMIA | RSS | InfoMoney, Valor Economico, CNN Brasil, Folha Mercado |
| 2 | 🗳️ POLITICA & BRASIL | RSS | G1 Politica, Agencia Brasil, Folha Brasil, UOL |
| 3 | 🤖 IA & TECNOLOGIA | RSS | MIT Tech Review, TechCrunch, The Verge, Ars Technica, Olhar Digital |
| 4 | 🚀 PRODUTO & GROWTH | RSS | Lenny's Newsletter, Dwarkesh Patel (Substack) |
| 5 | 💊 PILULA DO CONHECIMENTO | Claude | The Scaling Era (livro), Dario Amodei (darioamodei.com), Dwarkesh Podcast |
| 6 | ✝️ DEVOCIONAL DO DIA | Claude | Versiculo biblico + reflexao crista curta |
| 7 | 💬 FRASE DO DIA | Claude | Frase inspiradora com autoria |

Secoes 5, 6 e 7 sao geradas inteiramente pelo Claude (sem RSS), variando a cada dia.

---

## Notion

| Item | Valor |
|------|-------|
| Pagina raiz | "Newsletter do Dia" (criada manualmente) |
| Page ID | `3614f073-2f28-80b1-974a-eddb345456fa` |
| URL | https://www.notion.so/Newsletter-do-Dia-3614f0732f2880b1974aeddb345456fa |
| Integracao | `mcp-claude` (mesma do Podcast Processor) |
| Formato de titulo | `Atualize Hoje - DD/MM` |
| Icone da pagina | emoji 📰 |

**IMPORTANTE:** A integracao Notion precisa ter acesso a pagina "Newsletter do Dia". Para conceder: abrir a pagina no Notion → `...` → Connections → adicionar `mcp-claude`.

---

## Credenciais (nao estao no repositorio)

| Credencial | Onde configurar | Valor |
|------------|-----------------|-------|
| Anthropic API Key | No `Claude Synthesis` (header `x-api-key`) | Variavel `ANTHROPIC_API_KEY` no deploy |
| Notion Token | No `Salvar no Notion` (variavel `notionToken`) | Variavel `NOTION_TOKEN` no deploy |
| Notion Parent Page ID | No `Salvar no Notion` (variavel `parentPageId`) | `3614f073-2f28-80b1-974a-eddb345456fa` |

O arquivo `newsletter-agent.json` no repo usa placeholders (`YOUR_ANTHROPIC_API_KEY`, `YOUR_NOTION_TOKEN`, `YOUR_NOTION_PARENT_PAGE_ID`). O `deploy-vps.ps1` substitui os placeholders pelas variaveis de ambiente antes de enviar para a VPS.

Para o n8n local: as credenciais ficam embutidas diretamente nos nos via MCP (workflow ID `v7cI1EUEJhcCP6Hx`). Nunca exportar o workflow local com credenciais reais.

---

## Fluxo DevOps completo

```
DEV LOCAL                         GIT                        PROD (VPS)
─────────────────────             ─────────────────────      ──────────────────────
1. Editar nos no n8n local
   (via MCP ou interface)

2. Claude exporta via MCP:
   npx n8n export:workflow
   --id=v7cI1EUEJhcCP6Hx
   Sanitiza credenciais
   Salva em newsletter-agent.json

3. Criar feature branch:
   git checkout -b feature/nome

4. Testar localmente:
   Execute Workflow no n8n local

5. Commit e push:
   git add + git commit + push    → feature/nome no GitHub

6. PR e merge:                    → gh pr create + gh pr merge

7. Atualizar main local:          ← git pull origin main

8. Deploy:                                                   → .\deploy-vps.ps1
                                                               (injeta credenciais,
                                                                SCP, docker cp,
                                                                import, publish,
                                                                restart n8n)

9. Verificar ativacao:                                       → http://145.79.7.215:5678
   (reativar toggle se necessario)
```

### Como exportar o workflow apos mudancas (passo 2 em detalhe)

```powershell
# Exportar do n8n local
npx n8n export:workflow --id=v7cI1EUEJhcCP6Hx --output="$env:TEMP\na-export.json"

# Sanitizar e salvar no repo
$json = Get-Content "$env:TEMP\na-export.json" -Raw -Encoding utf8
$json = $json -replace 'sk-ant-api[A-Za-z0-9_\-]+', 'YOUR_ANTHROPIC_API_KEY'
$json = $json -replace 'ntn_[A-Za-z0-9]+', 'YOUR_NOTION_TOKEN'
$json = $json -replace '3614f073-2f28-80b1-974a-eddb345456fa', 'YOUR_NOTION_PARENT_PAGE_ID'
$obj = $json | ConvertFrom-Json
# Remover campos internos do n8n
foreach ($f in @('id','versionId','activeVersionId','versionCounter','triggerCount','shared','meta','pinData','staticData','createdAt','updatedAt','isArchived','description','active','tags','activeVersion')) {
    $obj.PSObject.Properties.Remove($f)
}
$obj | ConvertTo-Json -Depth 20 | Out-File "C:\dev\newsletter-agent\n8n-workflow\newsletter-agent.json" -Encoding utf8 -NoNewline
```

### Como fazer o deploy para a VPS (passo 8 em detalhe)

```powershell
# Definir variaveis de ambiente (sessao atual apenas)
$env:ANTHROPIC_API_KEY = "sk-ant-..."
$env:NOTION_TOKEN = "ntn_..."

# Rodar o script (a partir do diretorio do projeto)
Set-Location C:\dev\newsletter-agent
.\deploy-vps.ps1
```

O script faz automaticamente: substitui placeholders → SCP para VPS → docker cp para container n8n → import:workflow → publish:workflow → restart n8n.

**Apos o deploy:** verificar em http://145.79.7.215:5678 se o toggle do workflow esta ativo (verde). Se estiver inativo, ativar manualmente.

---

## Seguranca do repositorio

| Item | Status |
|------|--------|
| Credenciais no codigo | Nunca — apenas placeholders |
| `.gitignore` | Bloqueia `.env`, `*-vps.json`, `*-prod.json`, `*-with-credentials.json` |
| `.env.example` | Documenta variaveis necessarias sem valores reais |
| Branch protection | `main` exige PR antes de merge, force push bloqueado |
| Git history | Auditado — apenas placeholders encontrados |

Para verificar: `git log --all -p | Select-String 'sk-ant-api|ntn_'` — deve retornar vazio.

---

## Convencoes de PR e commit

- Branch: `feature/nome` ou `fix/nome`
- Commit: descricao em portugues, sem emoji, formato `tipo: descricao`
- Sempre atualizar CLAUDE.md no mesmo commit de mudancas no workflow
- Sempre sanitizar o JSON antes de commitar (verificar com `git diff` que nao ha credencial)

---

## Troubleshooting conhecido

| Problema | Causa | Solucao |
|----------|-------|---------|
| Erro 403 no Notion | Integracao sem acesso a pagina | Abrir "Newsletter do Dia" → `...` → Connections → adicionar `mcp-claude` |
| RSS sem artigos | Feed lento ou fora de horario | Filtro 24h tem fallback de 20 mais recentes |
| Newsletter cortada | max_tokens insuficiente | Aumentar no no Claude Synthesis (atualmente 6000) |
| Lenny/Dwarkesh vazios | Publicam 1-2x por semana | Normal — Claude indica curadoria propria na secao |
| Workflow inativo apos deploy | n8n desativa no import | Reativar manualmente em http://145.79.7.215:5678 |
| n8n VPS offline | Container parado | `ssh VPS "cd /opt/lounge-cafe && docker compose ps"` |
| Credencial no JSON exportado | Esqueceu de sanitizar | Nunca commitar — verificar com grep antes do push |

---

## n8n MCP (disponivel no Claude Code)

O MCP do n8n permite ler e escrever workflows programaticamente sem precisar da interface:

```
mcp__n8n-mcp__n8n_get_workflow      — ler workflow completo
mcp__n8n-mcp__n8n_update_partial_workflow — atualizar nos especificos
mcp__n8n-mcp__n8n_list_workflows    — listar todos os workflows
```

Workflow local acessivel pelo MCP: ID `v7cI1EUEJhcCP6Hx`.
O MCP conecta apenas ao n8n local (localhost:5678), nao ao n8n da VPS.

---

## Etapas de desenvolvimento (historico)

- [x] 1. Criar repositorio no GitHub (`wendelmb/newsletter-agent`)
- [x] 2. Definir fontes RSS e estrutura das 7 secoes
- [x] 3. Construir workflow no n8n local (6 nos)
- [x] 4. Definir pagina Notion de destino ("Newsletter do Dia") e configurar integracao
- [x] 5. Exportar JSON sanitizado para `n8n-workflow/newsletter-agent.json`
- [x] 6. Testar disparando manualmente no n8n local
- [x] 7. Importar workflow no n8n da VPS e configurar credenciais via deploy-vps.ps1
- [x] 8. Ativar workflow na VPS (Cron 7h automatico)
- [x] 9. Configurar seguranca do repo (gitignore, .env.example, branch protection)
- [x] 10. Estabelecer fluxo DevOps completo (feature branch → PR → merge → deploy)
- [x] 11. Newsletter v2: prompt rico, formato visual com callouts e headings no Notion
- [ ] 12. Validar chegada da newsletter por 2-3 dias consecutivos
- [ ] 13. Avaliar upgrade de modelo (claude-sonnet-4-6 → claude-opus-4-7) se qualidade insuficiente
