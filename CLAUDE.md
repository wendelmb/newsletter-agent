# CLAUDE.md - Newsletter Agent

## Instrucoes para o Claude Code

- Sempre que fizer uma alteracao no projeto, atualize as secoes relevantes deste CLAUDE.md no mesmo commit.
- Nunca deixe o CLAUDE.md desatualizado em relacao ao codigo que acabou de mudar.

## O que e este projeto

Automacao n8n que roda todo dia as 7h, coleta artigos de feeds RSS em 4 categorias, usa Claude para sintetizar uma newsletter estruturada em 7 secoes e salva no Notion.

**Usuario:** Wendel Bitencourt - nao e desenvolvedor, aprende fazendo. Respostas curtas e diretas.

## Estrutura de arquivos

```
newsletter-agent/
+-- n8n-workflow/newsletter-agent.json  # workflow exportado (fonte da verdade, sem credenciais)
+-- sources/rss-feeds.json              # fontes RSS e definicao de secoes Claude-generated
+-- CLAUDE.md
+-- README.md
```

## Ambientes

| Ambiente | Onde | Uso |
|----------|------|-----|
| Dev/teste | localhost:5678 (C:\claude-code\start-n8n.ps1) | testar mudancas antes de subir |
| Producao | VPS Hostinger - http://145.79.7.215:5678 | execucao diaria automatica as 7h |

O workflow de producao roda na VPS Hostinger (nao no n8n local).
Fluxo de deploy: editar localmente -> testar -> exportar JSON -> importar na VPS.

## n8n local (desenvolvimento)

- Workflow ID local: v7cI1EUEJhcCP6Hx
- n8n MCP disponivel para ler/escrever workflows programaticamente

## Notion

- Pagina raiz: "Newsletter do Dia" (criada manualmente na raiz do workspace)
- Page ID: 3614f073-2f28-80b1-974a-eddb345456fa
- URL: https://www.notion.so/Newsletter-do-Dia-3614f0732f2880b1974aeddb345456fa
- Cada newsletter = subpagina com titulo "Atualize Hoje - DD/MM"
- Token Notion: mesmo do Podcast Processor (configurado no no "Salvar no Notion")

## Secoes da newsletter e suas fontes

| # | Secao | Tipo | Fonte |
|---|-------|------|-------|
| 1 | MERCADO & ECONOMIA | RSS | InfoMoney, Valor Economico, CNN Brasil, Folha Mercado |
| 2 | POLITICA & BRASIL | RSS | G1 Politica, Agencia Brasil, Folha Brasil, UOL |
| 3 | IA & TECNOLOGIA | RSS | MIT Tech Review, TechCrunch, The Verge, Ars Technica, Olhar Digital |
| 4 | PRODUTO & GROWTH | RSS | Lenny's Newsletter, Dwarkesh Patel (Substack) |
| 5 | PILULA DO CONHECIMENTO | Claude | The Scaling Era (livro), Dario Amodei (darioamodei.com), Dwarkesh Podcast |
| 6 | DEVOCIONAL DO DIA | Claude | Versiculo biblico + reflexao crista curta |
| 7 | FRASE DO DIA | Claude | Frase inspiradora com autoria |

Secoes 5, 6 e 7 sao geradas inteiramente pelo Claude (sem RSS), variando a cada dia.

## Nos do workflow n8n (em ordem de execucao)

1. Cron 7h         - Schedule Trigger, cron 0 7 * * *, timezone America/Sao_Paulo
2. Fetch RSS        - Code node: busca 15 feeds em paralelo (https module), parseia XML/Atom
3. Filtro 24h       - Code node: remove artigos com mais de 24h; fallback: 20 mais recentes
4. Preparar Prompt  - Code node: agrupa por categoria (max 8/cat), monta prompt para Claude
5. Claude Synthesis - HTTP Request: POST api.anthropic.com, claude-sonnet-4-6, max_tokens 4000
6. Salvar no Notion - Code node: converte markdown em blocos Notion, cria pagina via HTTPS direto

## Credenciais (nao estao no repositorio)

Configurar nos nos apos importar o workflow na VPS:
- Anthropic API Key: no "Claude Synthesis" (header x-api-key)
- Notion Token: no "Salvar no Notion" (variavel notionToken)
- Notion Parent Page ID: no "Salvar no Notion" (parentPageId = 3614f073-2f28-80b1-974a-eddb345456fa)

## Etapas de desenvolvimento

- [x] 1. Criar repositorio no GitHub (newsletter-agent)
- [x] 2. Clonar em C:\dev\newsletter-agent e commitar estrutura inicial
- [x] 3. Construir workflow no n8n local (6 nos)
- [x] 4. Exportar JSON sanitizado para n8n-workflow/newsletter-agent.json
- [x] 5. Definir pagina Notion de destino ("Newsletter do Dia")
- [ ] 6. Testar disparando manualmente no n8n local
- [ ] 7. Importar workflow no n8n da VPS (145.79.7.215:5678) e configurar credenciais
- [ ] 8. Ativar workflow na VPS (Cron 7h automatico)
- [ ] 9. Validar chegada da newsletter por 2-3 dias
- [ ] 10. Abrir PR com estado final

## Convencoes de PR

- Branch: feature/nome ou fix/nome
- Commit: descricao em portugues, sem emoji
- Sempre atualizar CLAUDE.md no mesmo commit de mudancas no workflow

## Troubleshooting conhecido

- RSS sem artigos: ajustar filtro de 24h para 48h no Code node "Filtro 24h"
- Claude cortando newsletter: reduzir max 8 artigos/categoria ou aumentar max_tokens
- Notion erro 400: verificar parentPageId e se token tem permissao de escrita
- Lenny/Dwarkesh vazios: normal (publicam 1-2x/semana); Claude indica na secao automaticamente
- n8n VPS offline: verificar containers com docker compose ps em /opt/lounge-cafe/
