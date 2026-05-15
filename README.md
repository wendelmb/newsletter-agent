# Newsletter Agent

Automacao n8n que roda todo dia as 7h, coleta artigos de feeds RSS em 4 categorias, usa Claude para sintetizar uma newsletter estruturada em 7 secoes e salva cada edicao no Notion.

## Fluxo

```
Cron 7h → Fetch RSS (15 feeds) → Filtro 24h → Preparar Prompt → Claude Synthesis → Salvar no Notion
```

## Newsletter

Cada edicao e salva como subpagina de "Newsletter do Dia" no Notion com titulo `Atualize Hoje - DD/MM`.

| Secao | Fonte |
|-------|-------|
| 📊 Mercado & Economia | RSS (InfoMoney, Valor, CNN Brasil, Folha) |
| 🗳️ Politica & Brasil | RSS (G1, Agencia Brasil, Folha, UOL) |
| 🤖 IA & Tecnologia | RSS (MIT Tech Review, TechCrunch, The Verge, Ars Technica, Olhar Digital) |
| 🚀 Produto & Growth | RSS (Lenny's Newsletter, Dwarkesh Patel) |
| 💊 Pilula do Conhecimento | Claude (The Scaling Era, Dario Amodei, Dwarkesh Podcast) |
| ✝️ Devocional do Dia | Claude (versiculo biblico + reflexao) |
| 💬 Frase do Dia | Claude (frase inspiradora) |

## Ambientes

| | Local (dev) | VPS (producao) |
|--|-------------|----------------|
| URL | localhost:5678 | 145.79.7.215:5678 |
| Cron | Manual | Ativo — 7h diario |
| Workflow ID | v7cI1EUEJhcCP6Hx | newsletter-agent-vps |

## Configuracao inicial

1. Importe `n8n-workflow/newsletter-agent.json` no n8n
2. Substitua os placeholders nos nos:
   - `YOUR_ANTHROPIC_API_KEY` → no "Claude Synthesis"
   - `YOUR_NOTION_TOKEN` → no "Salvar no Notion"
   - `YOUR_NOTION_PARENT_PAGE_ID` → no "Salvar no Notion"
3. Compartilhe a pagina Notion com a integracao
4. Ative o workflow

Para deploy automatico na VPS, use `.\deploy-vps.ps1` com as variaveis de ambiente `ANTHROPIC_API_KEY` e `NOTION_TOKEN` definidas.

## Desenvolvimento

Ver `CLAUDE.md` para documentacao completa: arquitetura, fluxo DevOps, troubleshooting e convencoes.
