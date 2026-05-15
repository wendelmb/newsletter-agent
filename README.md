# Newsletter Agent

Automação n8n que roda todo dia às 7h, coleta artigos de feeds RSS em 3 categorias, sintetiza com Claude e envia via WhatsApp (Evolution API).

## Fluxo

```
Cron 7h → RSS (Política + Economia + IA/Tech) → Merge → Filtro 24h → Claude → WhatsApp
```

## Pré-requisitos

- n8n instalado e rodando em localhost:5678
- Conta Evolution API com instância configurada
- Chave da Anthropic API (Claude)

## Configuração

1. Importe `n8n-workflow/newsletter-agent.json` no n8n
2. Configure as credenciais nos nós (ver CLAUDE.md)
3. Ative o workflow

## Fontes RSS

Ver `sources/rss-feeds.json` — Política/Brasil, Economia/Mercado, IA/Tecnologia.

## Troubleshooting

- **Sem artigos**: ampliar filtro de 24h para 48h no Code node
- **WhatsApp desconectado**: reconectar via QR Code no painel Evolution API
- **Newsletter cortada**: reduzir fontes RSS ou aumentar max_tokens no nó Claude
