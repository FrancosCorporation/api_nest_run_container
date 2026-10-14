# Plan — api_nest_run_container

## 1. Visão geral
API Nest 12 (scaffold migrado de Nest 7/Node 16) empacotada em container Docker multi-stage não-root, com `/health` fora do rate limit, shutdown hooks, headers de segurança e publicação Compose apenas em loopback.

## 2. Arquitetura e tecnologias
Nest 12 + TypeScript, Node 24 (engines), ESLint flat, Docker multi-stage, Compose validado. Lockfile rastreado e usado estritamente (`npm ci`).

## 3. Funcionalidades existentes
- [x] `GET /` e `GET /health`; rate limit global 120 req/min — implementado.
- [x] Imagem endurecida e Compose loopback — implementado (2026-10-11).
- [x] CI build+audit+docker — **modernizada nesta sessão** (Ubuntu 24.04, Actions v7 SHA, matriz Node 22/24).

## 4. Objetivos futuros
- OBJ-01 (P2, concluído nesta sessão): CI previsível.
- OBJ-02 (P3): suíte Jest — 20 vulnerabilidades moderadas transitivas no toolchain de Jest estão registradas no ledger; resolução depende de upstream ou migração de framework de teste (decisão adiada: forçar downgrade quebraria o toolchain).
- OBJ-03 (P3): endpoint de exemplo documentado (OpenAPI) se a API ganhar rotas reais.

## 5–9. Melhorias / Roadmap / Riscos / Ideias
- Risco conhecido: advisories moderados apenas no escopo dev (Jest) — aceitos e registrados; reavaliar nas revisões trimestrais.
- TEST-01 (smoke runtime do container) executável apenas com janela de serviço — fora desta esteira.

*(Gerado em 2026-10-14 pelo agente orquestrador)*
