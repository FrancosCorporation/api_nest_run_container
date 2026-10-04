# MELHORIAS — api_nest_run_container

> **Gerado por análise de código em 2026-10-02** · Stack: Node 16 + NestJS 7 + TypeScript 4 (scaffold padrão)
> Branch `main` · 5 arquivos em `src/` · Dockerfile presente · sem compose · **sem autenticação**
>
> **Este arquivo é um plano de execução.** Cada item tem ID, `arquivo:linha`, mudança exata,
> critério de aceite e comando de verificação.

---

## 0. Como usar este documento

1. Execute na ordem **P0 → P1 → P2 → P3**, respeitando as ondas da §8.
2. Ao terminar um item: marque `- [x]`, rode o **Verificação**, comite `fix(<ID>): descrição`.
3. **Este é o scaffold oficial do Nest** (`nest new`), com 5 arquivos: `main.ts`, `app.module.ts`,
>   `app.controller.ts`, `app.service.ts`, `app.controller.spec.ts`. Não há regra de negócio.
4. **O nome sugere "pronto para container"** — e o Dockerfile existe. Mas `docker-compose.yml` **não**,
   e o projeto não expõe nada além do `Hello World` (ver `IMP-01`).
5. **Idioma:** português.

---

## 1. Diagnóstico executivo

API NestJS de exemplo, containerizada. O README promete "pronta para rodar em container Docker" — e o
Dockerfile funciona. O que não funciona é o resto do ecosystem.

**O que está bem (não reaça):**

| Item | Evidência |
|---|---|
| Dockerfile **multi-stage** correto | `Dockerfile:1-5` (build) + `:7-13` (runtime, só `dist`) |
| `NODE_ENV=production` na imagem final | `Dockerfile:9` |
| Dependências de produção separadas | `Dockerfile:12` (`npm ci --omit=dev`) |
| Smoke test presente | `src/app.controller.spec.ts` |
| `main.ts` minimalista e limpo | `src/main.ts:4-7` |

**O que está quebrado:**

1. **Node 16 EOL** (setembro/2023) em **todas** as etapas do Dockerfile — build e runtime.
2. **NestJS 7 / TypeScript 4** (@nestjs/core ^7.6.15) — versões fora de suporte.
3. `npm ci || npm install` e `npm ci --omit=dev || npm install` no Dockerfile — **a barra de
   integridade do lockfile é ignorada** (`||` faz o `npm install` cair em silêncio).
4. Sem `docker-compose.yml`, apesar do README prometer container.
5. `main.ts` escuta em `3000` **sem** validar host/porta e **sem** tratamento de shutdown.

---

## 2. Tabela de prioridades

| ID | Título | Sev | Arquivo | Depende de |
|---|---|---|---|---|
| SEC-01 | Node 16 EOL (build + runtime) | **P0** | `Dockerfile:1,7` | — |
| SEC-02 | `|| npm install` ignora falha do `npm ci` (lockfile não é respeitado) | **P0** | `Dockerfile:5,12` | — |
| BUG-01 | Sem `HOST`/`PORT` de env + sem shutdown gracioso | **P1** | `src/main.ts:6` | — |
| BUG-02 | Dockerfile copia `package*.json` mas roda `npm ci` sem lockfile garantido | **P2** | `Dockerfile:4` | SEC-02 |
| IMP-01 | API só responde "Hello World" — README promete mais | **P1** | `src/app.controller.ts` | — |
| IMP-02 | Sem `helmet` / headers de segurança | **P1** | `src/main.ts` | — |
| IMP-03 | Sem CORS explícito (armadilha futura) | **P2** | `src/main.ts` | — |
| IMP-04 | Sem healthcheck no container | **P2** | `Dockerfile` | — |
| IMP-05 | Sem rate limit | **P2** | `src/main.ts` | — |
| TEST-01 | Só 1 smoke test; sem e2e | **P2** | `test/` | — |
| DEVOPS-01 | Sem `docker-compose.yml` (README promete) | **P2** | *(ausente)* | — |
| DEVOPS-02 | Sem CI | **P2** | *(ausente)* | — |
| DEVOPS-03 | `engines` ausente (não declara versão de Node) | **P3** | `package.json` | SEC-01 |
| DEVOPS-04 | Sem `.dockerignore` | **P2** | *(ausente)* | — |
| DOC-01 · README promete container pronto, sem compose | **P2** | `README.md` | DEVOPS-01 |
| DOC-02 · Falta `SECURITY.md` | **P3** | *(ausente)* | — |

**Placar: 2 P0 · 3 P1 · 8 P2 · 1 P3 = 14 itens.**

---

## 3. Segurança

### SEC-01 · Node 16 EOL (build + runtime) · [P0]

- **Arquivo:** `Dockerfile:1` (`FROM node:16-alpine AS build`) e `:7` (`FROM node:16-alpine`)
- **Evidência:** as **duas** etapas usam `node:16-alpine`. O Node 16 entrou em EOL em
  **setembro/2023**.
- **Impacto:** (a) sem patch de segurança no runtime e no build; (b) `npm ci` em Node 16 usa um
  cliente antigo; (c) a dependência `@nestjs/core ^7.6.15` (Nest 7) também está fora de suporte —
  os dois se combiner para uma imagem sem correções. Como é uma API que **vai** ser deployada
  (tem Dockerfile e README prometendo container), o EOL é risco de produção, não de laboratório.
- **Mudança:** (1) subir para **Node 20 LTS** (`node:20-alpine`) ou **22** em ambas as etapas;
  (2) alinhar `@nestjs/*` para a versão 10 (LTS) e `typescript` 5; (3) pinar a tag (não `16`) —
  atualizar em conjunto, porque Nest 10 requer Node ≥ 16 mas o ideal é 20+.
- **Aceite:** Dockerfile usa `node:20-alpine` (ou 22) em build e runtime; `npm ci` sem aviso.
- **Verificação:**
  ```bash
  grep -n '^FROM node' Dockerfile          # deve ser 20-alpine ou 22-alpine (ambas)
  docker build -t nest:test . && docker run --rm nest:test node -v   # v20+ / v22+
  ```

### SEC-02 · `|| npm install` ignora falha do `npm ci` · [P0]

- **Arquivo:** `Dockerfile:5` e `:12`
- **Evidência:**
  ```dockerfile
  RUN npm ci || npm install
  ...
  RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev
  ```
- **Impacto:** o `||` é uma **armadilha de reprodutibilidade e de segurança**. (a) Se o
  `package-lock.json` estiver **fora de sincronia** com o `package.json`, o `npm ci` **falha** (é o
  ponto do `npm ci`) e o `npm install` "conserta" — instalando versões **não declaradas** e
  reescrevendo o lock **dentro da imagem**; (b) o `2>/dev/null` da linha 12 **esconde** o motivo da
  falha; (c) o resultado é uma imagem com dependências que **ninguém deklarou** — se o `npm ci`
  falha por lock corrompido (ou por registry indisponível), o build segue com o que der. O
  `npm ci` estritamente (sem `||`) é o que garante build reprodutível.
- **Mudança:** (1) remover os `|| npm install` e o `2>/dev/null` — deixar o build **falhar** se o
  `npm ci` falhar (é o comportamento correto); (2) garantir que `package-lock.json` está no
  contexto (o `COPY package*.json ./` já faz, mas confirme que o lock está versionado — ver
  `BUG-02`); (3) garantir o cache de camadas do npm (`--prefer-offline` opcional).
- **Aceite:** `npm ci` falha o build se o lock não bater; não há fallback silencioso.
- **Verificação:**
  ```bash
  grep -n 'npm ci' Dockerfile   # sem '|| npm install' e sem 2>/dev/null
  docker build -t nest:test .  # falha se lock dessincronizado
  ```

---

## 4. Bugs e defeitos funcionais

### BUG-01 · Sem `HOST`/`PORT` de env + sem shutdown gracioso · [P1]

- **Arquivo:** `src/main.ts:4-7`
- **Evidência:**
  ```typescript
  const app = await NestFactory.create(AppModule);
  await app.listen(3000);
  ```
  Porta fixa (3000), sem `process.env.PORT`, e **sem** `app.enableShutdownHooks()` nem
  tratamento de `SIGTERM`.
- **Impacto:** (a) a porta não é configurável sem rebuild — o Dockerfile fixa `ENV PORT=3000`;
  (b) **sem shutdown gracioso**, um `SIGTERM` (deploy, Kubernetes, `docker stop`) corta conexões
  abruptas; (c) erros de boot não são tratados — falha silenciosa.
- **Mudança:** (1) `await app.listen(process.env.PORT ?? 3000, process.env.HOST ?? '0.0.0.0')`;
  (2) `app.enableShutdownHooks()`; (3) `bootstrap().catch(e => { console.error(e); process.exit(1); })`
  (hoje `bootstrap()` é chamado sem `catch` — rejeição fica sem log).
- **Aceite:** `PORT=8080` sobe em 8080; SIGTERM fecha graciosamente.
- **Verificação:**
  ```bash
  docker run --rm -e PORT=8080 nest:test   # escuta em 8080
  docker stop <container>                  # sem erro de "connections forcibly closed"
  ```

### BUG-02 · Lockfile no contexto do build · [P2]

- **Arquivo:** `Dockerfile:4` (`COPY package*.json ./`)
- **Evidência:** o glob copia `package.json` **e** `package-lock.json` se existir. O inventário não
  lista `package-lock.json` explicitamente aqui — se o lock **não estiver** versionado, o `npm ci`
  falha (e o `||` mascara, ver `SEC-02`).
- **Impacto:** se o lock não estiver versionado, a imagem instala o que resolver no momento do build
  — não reprodutível e **não auditado**.
- **Mudança:** (1) versionar `package-lock.json` (`git add package-lock.json`); (2) confirmar com
  `git ls-files package-lock.json`; (3) garantir o `.dockerignore` (ver `DEVOPS-04`) para não leaks.
- **Aceite:** `git ls-files package-lock.json` retorna o arquivo.
- **Verificação:**
  ```bash
  git ls-files --error-unmatch package-lock.json && echo OK
  ```

---

## 5. Qualidade: arquitetura e operação

### IMP-01 · API só responde "Hello World" · [P1]

- **Arquivo:** `src/app.controller.ts` · `src/app.service.ts`
- **Evidência:** scaffold padrão — o controller chama `appService.getHello()`.
- **Impacto:** o README promete "API NestJS de exemplo, pronta para rodar em container". Não há
  rota de negócio. O README deve refletir isso (ver `DOC-01`).
- **Mudança:** (1) documentar que é **exemplo/scaffold**; (2) se o objetivo é ter um template
  reaproveitável, trocar o Hello World por um `/health` real (ver `IMP-04`) e documentar como
  adicionar módulos (`@Module`); (3) não é "adicionar features" — é alinhar a promessa.
- **Aceite:** o único endpoint é `/health` (ou o README diz que é exemplo).
- **Verificação:**
  ```bash
  curl -s localhost:3000/health | jq .   # resposta clara
  ```

### IMP-02 · Sem `helmet` / headers de segurança · [P1]

- **Arquivo:** `src/main.ts` (`NestFactory.create(AppModule)` sem helmet)
- **Evidência:** nenhum `helmet()`.
- **Impacto:** sem `X-Content-Type-Options`, `X-Frame-Options`, HSTS. Como template, quem copiar
  herda a lacuna.
- **Mudança:** (1) `npm i helmet`; (2) `app.use(helmet())` no `main.ts`; (3) se houver CORS, listar
  explicitamente (ver `IMP-03`).
- **Aceite:** resposta traz `x-content-type-options: nosniff` e `x-frame-options`.
- **Verificação:**
  ```bash
  curl -sI localhost:3000/ | grep -iE 'x-content-type-options|x-frame-options'
  ```

### IMP-03 · Sem CORS explícito (armadilha futura) · [P2]

- **Arquivo:** `src/main.ts`
- **Evidência:** nenhum `enableCors()`.
- **Impacto:** hoje seguro (same-origin). Quando a primeira rota cross-origin entrar, o caminho
  idiomático e **errado** é `app.enableCors()` (que abre `*`). Decidir agora evita a armadilha.
- **Mudança:** (1) não habilitar CORS enquanto não precisar (só rotas same-origin); (2) se precisar,
  `app.enableCors({ origin: [lista explícita], credentials: true })` — **nunca** `origin: true`/`*`
  com `credentials`.
- **Aceite:** sem `enableCors()` com wildcard; se houver, allowlist.
- **Verificação:**
  ```bash
  grep -n 'enableCors' src/main.ts   # se existir, sem '*'
  ```

### IMP-04 · Sem healthcheck no container · [P2]

- **Arquivo:** `Dockerfile` · `src/app.controller.ts`
- **Evidência:** o Dockerfile **não** tem `HEALTHCHECK`.
- **Impacto:** o orquestrador considera o container "são" desde que o processo do Node esteja de pé —
  não valida que a API responde. Um app que falha em `/` (ex.: erro de config) fica "saudável".
- **Mudança:** (1) criar rota `GET /health` (ver `IMP-01`); (2) `HEALTHCHECK --interval=30s --timeout=3s
  CMD wget -qO- http://localhost:3000/health || exit 1` no Dockerfile (ou usar `node -e` se não
  houver `wget` no alpine).
- **Aceite:** `docker inspect` mostra `Health: healthy`; unhealthy quando a API não responde.
- **Verificação:**
  ```bash
  docker inspect --format '{{.State.Health.Status}}' <container>
  ```

### IMP-05 · Sem rate limit · [P2]

- **Arquivo:** `src/main.ts`
- **Evidência:** nenhum `@nestjs/throttler` nem middleware de rate limit.
- **Impacto:** como template, quem copiar não tem proteção contra abuso. Para `Hello World` é
  irrelevante; para as rotas que virão, é responsável.
- **Mudança:** (1) `@nestjs/throttler` com limite default global; (2) `ThrottlerGuard` global.
- **Aceite:** N requisições em X min → `429`.
- **Verificação:**
  ```bash
  for i in $(seq 1 200); do curl -s -o /dev/null -w "%{http_code} " localhost:3000/; done; echo
  ```

### TEST-01 · Só 1 smoke test; sem e2e · [P2]

- **Arquivo:** `src/app.controller.spec.ts` · `test/` (script `test:e2e` existe, sem arquivos)
- **Evidência:** um teste unitário do controller; `test:e2e` aponta para `test/jest-e2e.json` que
  **não existe** no inventário.
- **Impacto:** o `npm run test:e2e` **falha** (arquivo inexistente) — quem rodar recebe erro.
- **Mudança:** (1) criar `test/jest-e2e.json` e um teste e2e real (`GET /health` → 200); (2) manter
  o smoke unitário; (3) `npm run test:cov` para medir.
- **Aceite:** `npm test` **e** `npm run test:e2e` passam.
- **Verificação:**
  ```bash
  npm test && npm run test:e2e
  ```

---

## 6. DevOps / Infra

### DEVOPS-04 · Sem `.dockerignore` · [P2]

- **Arquivo:** *(ausente)* `.dockerignore`
- **Evidência:** o `Dockerfile` faz `COPY . .` (linha 6) sem `.dockerignore`.
- **Impacto:** o contexto de build inclui `.git`, `node_modules`, `.env` (se existir localmente) —
  então **segredo local pode entrar na imagem de build** (mesmo que não vá para a etapa final, ele
  fica no **layer** intermediário da imagem, recuperável via `docker history`). É a classe de
  vazamento mais esquecida.
- **Mudança:** criar `.dockerignore` com pelo menos:
  ```
  node_modules
  dist
  .git
  .gitignore
  .env
  .env.*
  npm-debug.log*
  coverage
  ```
- **Aceite:** o contexto de build não contém `.git`/`.env` (`docker build` mostra contexto menor).
- **Verificação:**
  ```bash
  docker build -t nest:test . 2>&1 | grep -i 'transferring context'   # tamanho reduzido
  ```

### DEVOPS-01 · Sem `docker-compose.yml` (README promete) · [P2]

- **Arquivo:** *(ausente)* `docker-compose.yml` · `README.md`
- **Evidência:** o README descreve o projeto como "pronta para rodar em container Docker"; há
  `Dockerfile` mas **não** há compose.
- **Impacto:** a promessa do README não é cumprida (falta o `docker compose up` que o usuário
  espera). Impacto de **confiança/documentação**.
- **Mudança:** criar `docker-compose.yml` mínimo (serviço `api`, `build: .`, `ports: 3000:3000`,
  `restart: unless-stopped`) para o comando prometido funcionar.
- **Aceite:** `docker compose up --build` sobe a API.
- **Verificação:**
  ```bash
  docker compose up --build -d && sleep 3
  curl -s localhost:3000/   # responde
  ```

### DEVOPS-02 · Sem CI · [P2]

- **Arquivo:** *(ausente)* `.github/workflows/`
- **Evidência:** sem workflow; o projeto tem `test` e `test:e2e`.
- **Impacto:** nada garante que o build (que tem o Dockerfile) ou os testes continuam verdes.
- **Mudança:** `ci.yml`: `npm ci`, `npm run build`, `npm test`, `npm run test:e2e`, e
  `docker build` como verificação de que o container constrói.
- **Aceite:** PR que quebra build/teste é bloqueado.
- **Verificação:**
  ```bash
  npm run build && npm test && docker build -t nest:test .
  ```

### DEVOPS-03 · `engines` ausente · [P3]

- **Arquivo:** `package.json`
- **Evidência:** sem `"engines": { "node": ">=20" }`.
- **Impacto:** o `node` mínimo não é declarado — quem usa Node 18 (também em fim de vida em 2025)
  tenta rodar e falha de forma obscura.
- **Mudança:** adicionar `engines` coerente com o `SEC-01` (Node 20+).
- **Aceite:** `npm ci` avisa quando o Node é antigo.
- **Verificação:**
  ```bash
  node -e "console.log(require('./package.json').engines)"
  ```

---

## 7. Documentação

### DOC-01 · README promete container pronto, sem compose · [P2]

- **Arquivo:** `README.md`
- **Evidência:** a descrição no `package.json` é "API NestJS de exemplo, pronta para rodar em
  container Docker". O `Dockerfile` existe; o compose não (ver `DEVOPS-01`). E a API só responde
  Hello World (ver `IMP-01`).
- **Impacto:** o README super-promete em relação ao estado real — quem chega não encontra o
  `docker compose up` esperado nem rota de negócio.
- **Mudança:** (1) atualizar o README com o que **existe** (scaffold, `/health`, Dockerfile);
  (2) se adicionar compose (`DEVOPS-01`), atualizar com o comando; (3) declarar explicitamente
  "exemplo — sem regras de negócio".
- **Aceite:** README reflete o estado real.
- **Verificação:** `grep -n 'docker compose\|health\|exemplo' README.md`.

### DOC-02 · Falta `SECURITY.md` · [P3]

- **Arquivo:** *(ausente)* `SECURITY.md`
- **Evidência:** tem `README`/`LICENSE`.
- **Impacto:** baixo hoje (scaffold). Como template, a política de segredo/CORS/rate-limit deveria
  vir documentada.
- **Mudança:** criar com canal + as invariantes: "segredo só em env", "CORS com allowlist (nunca `*`
  com `credentials`)", "`npm ci` estrito (sem fallback)".
- **Aceite:** arquivo existe.
- **Verificação:** `ls SECURITY.md`

---

## 8. Ordem de execução (waves)

### Wave 1 — Supply chain e runtime (P0)
1. **`SEC-01`** — Node 20/22 no build **e** runtime; Nest 10 + TS 5.
2. **`SEC-02`** — remover `|| npm install` e `2>/dev/null`; `npm ci` estrito.
3. **`DEVOPS-04`** — `.dockerignore` (antes de rebuild, para não levar `.git` no contexto).
4. **`DEVOPS-03`** — `engines` declarado.

> Depois da Wave 1, o container é reprodutível e está em runtime suportado.

### Wave 2 — Operação e armadilhas (P1)
5. **`BUG-01`** — `PORT`/`HOST` de env + shutdown gracioso.
6. **`IMP-02`** — `helmet`.
7. **`IMP-01`** — `Hello World` → `/health` (alinha com a promessa).
8. **`TEST-01`** — e2e de `/health` (o script `test:e2e` hoje aponta para arquivo inexistente).

### Wave 3 — Completeza (P2)
9. **`IMP-04`** — healthcheck no Dockerfile (depende do passo 7).
10. **`IMP-03`** — CORS explícito; **`IMP-05`** — rate limit.
11. **`BUG-02`** — lockfile versionado; **`DEVOPS-01`** — compose.
12. **`DEVOPS-02`** — CI; **`DOC-01`** — README honesto.

### Wave 4 — Registro (P3)
13. **`DOC-02`**.

**Dependências que não podem ser invertidas:**
`DEVOPS-04` **antes** de qualquer `docker build` (não levar `.git`/`.env` no contexto) ·
`SEC-02` antes de `BUG-02` (sem lock, o `npm ci` nem roda) · `BUG-02` antes de `SEC-02` (o fix do
`||` **exige** lock válido, senão o build quebra — então versione o lock antes de endurecer) ·
`IMP-01` antes de `IMP-04` (healthcheck precisa de `/health`) · `SEC-01` antes de `DEVOPS-03`.

---

## 9. Fora de escopo / riscos

| Item | Decisão | Motivo |
|---|---|---|
| Adicionar autenticação (JWT/Guards) | **Não, ainda** | É scaffold sem rota de negócio. Registrado o caminho em `IMP-02`/`IMP-03`. |
| Implementar o que o README promete (rotas) | **Não** | Alinhe o README (`DOC-01`), não invente escopo. |
| Migrar para Fastify em vez de Express | **Não** | Escolha de performance; sem ganho de segurança aqui. |
| Matar o projeto (não é usado) | **Não** | Ele serve como template de container Nest. |

**Riscos desta execução:**

- **`SEC-01` (Node 16→20 + Nest 7→10) é a maior mudança** e pode exigir ajustes de tipo e de
  dependência. Faça em um commit só e valide `npm run build && npm test`.
- **`SEC-02` + `BUG-02` juntos**: se remover o `||` sem versionar o lock, o **build quebra**. Faça
  `git add package-lock.json` **antes** de endurecer o Dockerfile.
- **`SEC-01` + `DEVOPS-04`**: o `.dockerignore` deve ser criado **antes** do próximo build, ou o
  `.git` entra no contexto da imagem.
- **Nest 10 pode mudar a API** do `main.ts` (`app.listen` com objeto de opções) — leia a nota de
  migração.

---

## 10. Definição de pronto (DoD)

**Segurança**
- [ ] `SEC-01` — `node:20-alpine` (ou 22) em build **e** runtime; Nest 10 + TS 5
- [ ] `SEC-02` — `npm ci` **estrito** (sem `|| npm install`, sem `2>/dev/null`)
- [ ] `DEVOPS-04` — `.dockerignore` cobre `.git`, `.env`, `node_modules`, `dist`

**Funcional**
- [ ] `BUG-01` — `PORT`/`HOST` de env; shutdown gracioso
- [ ] `BUG-02` — `package-lock.json` versionado
- [ ] `IMP-01` — único endpoint é `/health` (alinhado ao README)
- [ ] `IMP-02` — headers do `helmet` presentes
- [ ] `IMP-03` — CORS com allowlist (ou não habilitado), sem `*`
- [ ] `IMP-04` — `HEALTHCHECK` no Dockerfile, `docker inspect` → `healthy`
- [ ] `IMP-05` — rate limit global (429 acima do limite)

**Testes e infra**
- [ ] `TEST-01` — `npm test` **e** `npm run test:e2e` passam
- [ ] `DEVOPS-01` — `docker compose up` funciona (promessa do README)
- [ ] `DEVOPS-02` — CI verde (build + testes + `docker build`)
- [ ] `DEVOPS-03` — `engines` declarado (Node 20+)

**Documentação**
- [ ] `DOC-01` — README reflete o estado real
- [ ] `DOC-02` — `SECURITY.md`

**Validação final:**
```bash
npm run build && npm test && npm run test:e2e
docker build -t nest:test . && docker run --rm -p 3000:3000 nest:test &
curl -s localhost:3000/health
```

---

*Fim do plano. Gerado por leitura direta do código em 2026-10-02. Nenhum item já estava corrigido.*
