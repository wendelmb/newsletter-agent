# CLAUDE.md - Newsletter Agent

## Instrucoes para o Claude Code

- Sempre que fizer uma alteracao no projeto, atualize as secoes relevantes deste CLAUDE.md no mesmo commit.
- Nunca deixe o CLAUDE.md desatualizado em relacao ao codigo que acabou de mudar.

## O que e este projeto

Automacao n8n que roda todo dia as 7h, coleta artigos de feeds RSS em 4 categorias, usa Claude para sintetizar uma newsletter estruturada em 7 secoes e salva no Notion.

**Usuario:** Wendel Bitencourt - nao e desenvolvedor, aprende fazendo. Respostas curtas e diretas.

## Contexto do ambiente

- n8n rodando em localhost:5678 (iniciado via C:\claude-code\start-n8n.ps1)
- n8n MCP disponivel para ler/escrever workflows programaticamente
- Notion API: mesma conexao do Podcast Processor (ja configurada no n8n)
- Repositorio GitHub: github.com/wendelmb/newsletter-agent
- Ambiente de desenvolvimento: C:\dev\newsletter-agent
- Shell: PowerShell (Windows 11)

## Projeto de referencia

O Podcast Processor (github.com/wendelmb/podcast-processor) ja esta funcionando em producao.
Mesma stack, mesmas convencoes de PR, mesmo n8n. Consultar o CLAUDE.md dele para padroes.

## Estrutura de arquivos

```
newsletter-agent/
+-- n8n-workflow/newsletter-agent.json  # workflow exportado (fonte da verdade)
+-- sources/rss-feeds.json              # fontes RSS e definicao de secoes Claude-generated
+-- CLAUDE.md
+-- README.md
```

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

1. Cron Trigger        - dispara as 7h todos os dias (America/Sao_Paulo)
2. RSS Mercado         - busca 4 feeds de economia/mercado em paralelo
3. RSS Politica        - busca 4 feeds de politica/Brasil em paralelo
4. RSS IA-Tech         - busca 5 feeds de IA e tecnologia em paralelo
5. RSS Produto-Growth  - busca Lenny + Dwarkesh em paralelo
6. Merge               - une todos os artigos RSS em array unico
7. Filtro 24h          - Code node: remove artigos publicados ha mais de 24h
8. Preparar Prompt     - Code node: formata artigos por categoria + instrucoes Claude
9. Claude Synthesis    - HTTP Request: gera newsletter completa (todas as 7 secoes)
10. Save to Notion     - HTTP Request: cria pagina no Notion com a newsletter do dia

## Formato da newsletter (o que Claude deve gerar)

```
Bom dia, Wendel! Aqui estao os principais acontecimentos de hoje:

MERCADO & ECONOMIA
- [manchete]: descricao em 1-2 linhas (3-4 noticias)

POLITICA & BRASIL
- [manchete]: descricao em 1-2 linhas (3-4 noticias)

IA & TECNOLOGIA
- [manchete]: descricao em 1-2 linhas (3-4 noticias)

PRODUTO & GROWTH
- [manchete ou insight do Lenny/Dwarkesh]: 1-2 linhas (1-2 itens, so se houver novo conteudo)

PILULA DO CONHECIMENTO
[Um paragrafo sobre um topico do livro 'The Scaling Era', ensaios do Dario Amodei ou episodio do Dwarkesh Podcast. Rotativo, um tema diferente por dia.]

DEVOCIONAL DO DIA
[Versiculo] — Livro Cap:Verso
[2-3 linhas de reflexao pratica crista]

FRASE DO DIA
'[frase inspiradora]' — Autor
```

## Dados operacionais

- Horario de envio: 7h (todos os dias, incluindo fins de semana)
- Destino: Notion (mesma conta/integracao do Podcast Processor)
- Notion Database ID: o mesmo usado no Podcast Processor ou criar database dedicado

## Limites e comportamentos

| Componente | Limite | Comportamento |
|------------|--------|---------------|
| Claude max_tokens | 4000 | suficiente para newsletter completa com 7 secoes |
| RSS por categoria | 4-5 fontes | balanco entre cobertura e ruido |
| Filtro de data | 24h | evita noticias velhas; ampliar para 48h se sem conteudo |
| Lenny/Dwarkesh | publica 1-2x/semana | Claude indica "sem novo conteudo esta semana" quando vazio |
| Notion pagina | 1 por dia | titulo = "Newsletter - DD/MM/AAAA" |

## Etapas de desenvolvimento (sequencial)

- [x] 1. Criar repositorio no GitHub (newsletter-agent)
- [x] 2. Clonar em C:\dev\newsletter-agent e commitar estrutura inicial
- [ ] 3. Construir workflow n8n (nos acima em ordem)
- [ ] 4. Testar disparando manualmente (sem esperar o Cron)
- [ ] 5. Validar por 2-3 dias e ajustar formato
- [ ] 6. Exportar workflow, substituir credenciais por placeholders, commitar e abrir PR

## Convencoes de PR

- Branch: feature/nome ou fix/nome ou docs/nome
- Commit: descricao em portugues, sem emoji
- PR pequena e focada - uma mudanca por vez
- Sempre atualizar CLAUDE.md no mesmo commit de mudancas no workflow

## Troubleshooting conhecido

- RSS sem artigos: ajustar filtro de 24h para 48h no Code node Filtro 24h
- Claude cortando newsletter: reduzir numero de fontes RSS ou aumentar max_tokens
- Notion erro 400: verificar se database ID esta correto e token tem permissao de escrita
- Lenny/Dwarkesh vazios: normal em dias sem publicacao; Claude deve indicar na secao
