# CLAUDE.md - Newsletter Agent

## Instrucoes para o Claude Code

- Sempre que fizer uma alteracao no projeto, atualize as secoes relevantes deste CLAUDE.md no mesmo commit.
- Nunca deixe o CLAUDE.md desatualizado em relacao ao codigo que acabou de mudar.

## O que e este projeto

Automacao n8n que roda todo dia as 7h, coleta artigos de feeds RSS, usa Claude para sintetizar uma newsletter em 3 secoes e envia via WhatsApp (Evolution API).

**Usuario:** Wendel Bitencourt - nao e desenvolvedor, aprende fazendo. Respostas curtas e diretas.

## Contexto do ambiente

- n8n rodando em localhost:5678 (iniciado via C:\claude-code\start-n8n.ps1)
- n8n MCP disponivel para ler/escrever workflows programaticamente
- Evolution API: gerencia conexao WhatsApp (configurar nesta etapa)
- Repositorio GitHub: github.com/wendelmb/newsletter-agent (criar novo repo)
- Ambiente de desenvolvimento: C:\dev\newsletter-agent
- Ambiente de producao: C:\claude-code-newsletter (ou mesmo n8n do podcast-processor)
- Shell: PowerShell (Windows 11)

## Projeto de referencia

O Podcast Processor (github.com/wendelmb/podcast-processor) ja esta funcionando em producao.
Mesma stack, mesmas convencoes de PR, mesmo n8n. Consultar o CLAUDE.md dele para padroes.

## Estrutura de arquivos

```
newsletter-agent/
+-- n8n-workflow/newsletter-agent.json  # workflow exportado (fonte da verdade)
+-- sources/rss-feeds.json              # fontes RSS por categoria
+-- CLAUDE.md
+-- README.md
```

## Nos do workflow n8n (em ordem de execucao)

1. Cron Trigger     - dispara as 7h todos os dias
2. RSS Politica     - busca feeds de politica/Brasil
3. RSS Economia     - busca feeds de economia/mercado
4. RSS IA-Tech      - busca feeds de IA e tecnologia
5. Merge            - une todos os artigos
6. Filtro 24h       - remove artigos mais antigos que 24h
7. Claude Synthesis - sintetiza newsletter em 3 secoes
8. Send WhatsApp    - envia via Evolution API HTTP Request

## Fontes RSS (sources/rss-feeds.json)

Politica/Brasil: G1, UOL, Folha de SP, Agencia Brasil
Economia: InfoMoney, Valor Economico, CNN Brasil Economia
IA/Tecnologia: MIT Technology Review, TechCrunch, Olhar Digital, The Verge

## Formato da newsletter (prompt Claude)

Secoes:
- POLITICA & BRASIL: 3-4 manchetes com 2 linhas cada
- ECONOMIA & MERCADO: 3-4 manchetes com 2 linhas cada
- IA & TECNOLOGIA: 3-4 manchetes com 2 linhas cada
- DESTAQUE DO DIA: a noticia mais importante de todas
Limite: mensagem deve caber em uma tela de WhatsApp (sem scroll excessivo)

## Dados operacionais

- WhatsApp destino: (11) 97095-7327 (Wendel - pessoal)
- Horario de envio: 7h (todos os dias, incluindo fins de semana)
- Evolution API instance name: wendel-personal

## Limites e comportamentos

| Componente | Limite | Comportamento |
|------------|--------|---------------|
| Claude max_tokens | 4000 | suficiente para newsletter compacta |
| RSS por categoria | 3-4 fontes | balanco entre cobertura e ruido |
| Filtro de data | 24h | evita noticias velhas |
| WhatsApp mensagem | ~4096 chars | Claude instrudo a ser conciso |

## Etapas de desenvolvimento (sequencial)

1. Criar repositorio no GitHub (newsletter-agent)
2. Clonar em C:\dev\newsletter-agent
3. Configurar Evolution API + conectar WhatsApp de Wendel
4. Construir workflow n8n (nos acima em ordem)
5. Testar disparando manualmente (sem esperar o Cron)
6. Ativar Cron e validar chegada as 7h
7. Exportar workflow e commitar no GitHub

## Convencoes de PR

- Branch: feature/nome ou fix/nome ou docs/nome
- Commit: descricao em portugues, sem emoji
- PR pequena e focada - uma mudanca por vez
- Sempre atualizar CLAUDE.md no mesmo commit de mudancas no workflow

## Troubleshooting conhecido

- Evolution API desconectada: reconectar via QR Code no painel
- RSS sem artigos: ajustar filtro de 24h para 48h temporariamente
- Claude cortando newsletter: reduzir fontes RSS ou aumentar max_tokens
