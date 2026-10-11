# api-nest-run-container

Scaffold de estudo para uma API NestJS 12 em Node.js 24 LTS. O repositório não contém regras de negócio ou autenticação.

## Rotas

- `GET /` mantém a resposta de exemplo `Hello World!`.
- `GET /health` responde `{"status":"ok"}` e não consome a cota do limitador.

As respostas recebem cabeçalhos de segurança do Nest. As demais rotas têm limite padrão de 120 requisições por minuto e por processo. CORS fica desabilitado enquanto não houver uma origem de frontend definida. Em instalações com várias réplicas, configure um armazenamento compartilhado para o limitador.

## Requisitos

- Node.js 24.15 ou mais recente na linha 24
- npm 10 ou mais recente
- Docker Compose (opcional)

## Rodar localmente

```bash
npm ci
npm run start:dev
```

A API escuta em `127.0.0.1:3000` por padrão. `PORT` e `HOST` podem mudar a porta e o endereço.

## Rodar em container

```bash
docker compose up --build --detach
curl http://localhost:3000/health
```

O Compose publica a porta apenas em loopback. A imagem usa etapas separadas de build e runtime, instala dependências do lockfile sem fallback, executa como usuário sem privilégios e inclui healthcheck.

## Build e qualidade

```bash
npm run build
npm run lint
npm test
npm run test:e2e
```

O CI executa `npm ci`, build, auditoria de dependências de alta gravidade e build da imagem. Os testes existentes continuam disponíveis nos comandos acima.

## Segurança

Consulte [SECURITY.md](SECURITY.md) para orientações de reporte e configuração.
