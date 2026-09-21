# api-nest-run-container

API **NestJS** pronta para rodar em container: `Dockerfile`, `docker-compose`
com hot-reload e o setup completo de qualidade do framework (ESLint, Prettier,
Jest).

![NestJS](https://img.shields.io/badge/NestJS-7-E0234E?style=flat-square&logo=nestjs&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-4-3178C6?style=flat-square&logo=typescript&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Tests](https://img.shields.io/badge/tests-Jest-C21325?style=flat-square&logo=jest)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Status](https://img.shields.io/badge/status-estudo-lightgrey?style=flat-square)

## Sobre

**Projeto de estudo** de 2022 para praticar a criação de APIs com NestJS e,
principalmente, o empacotamento da aplicação em Docker. O repositório sobe uma
API mínima (controller/service de exemplo) com testes unitários e e2e, e um
ambiente containerizado com script de entrada (`entrypoint.sh`).

## Funcionalidades

Comprovadas pelo código:

- **API NestJS** com `AppController`/`AppService` de exemplo
  (`GET /` responde `Hello World!`).
- **Containerização**: `Dockerfile` baseado em `node:14-alpine` com
  `@nestjs/cli` instalado e script de entrada `/.docker/entrypoint.sh`.
- **docker-compose** para desenvolvimento.
- **Qualidade**: ESLint + Prettier configurados; testes unitários
  (`src/app.controller.spec.ts`) e e2e (`test/app.e2e-spec.ts`) com Jest.

## Como rodar

### Com Docker (recomendado)

```bash
docker compose up --build
```

### Localmente

```bash
npm install
npm run start:dev     # desenvolvimento (watch)
npm run start:prod    # produção (node dist/main)
```

### Testes e lint

```bash
npm test              # testes unitários
npm run test:e2e      # testes end-to-end
npm run lint          # ESLint com --fix
npm run format        # Prettier
```

A API fica disponível em `http://localhost:3000`.

## Estrutura do projeto

```
.docker/            # entrypoint do container
src/                # app.module, app.controller, app.service
test/               # testes e2e (Jest + supertest)
Dockerfile          # imagem da aplicação
docker-compose.yaml # ambiente de desenvolvimento
```

## Licença

MIT — veja [LICENSE](LICENSE).
