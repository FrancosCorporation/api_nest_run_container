# Melhorias — api_nest_run_container

## Implementado

- Atualizado o runtime de Node 16 para Node 24 LTS e o scaffold de Nest 7 para Nest 12; versões e lockfile foram regenerados.
- Removidos os fallbacks `npm ci || npm install`; build e runtime instalam apenas o lockfile.
- Mantida a rota de exemplo `GET /` e adicionada `GET /health`, usada pelo healthcheck do container.
- Configurados `HOST` e `PORT`, validação de porta, cabeçalhos de segurança, shutdown hooks e log de falha de inicialização.
- Adicionado limite global de 120 requisições/minuto por processo; healthcheck está fora do limite; CORS permanece desabilitado.
- Endurecida a imagem com `.dockerignore`, etapas separadas, usuário sem privilégios e healthcheck. Compose agora funciona com a imagem final e publica só em loopback.
- Atualizados engines, ESLint flat config, README e política de segurança.
- CI adicionado para instalação reproduzível, build, auditoria alta e build do container.
- Removido o antigo script de entrypoint de desenvolvimento, que o estágio final da imagem nunca copiava.

## Validação e limites

- `docker compose config --quiet` passou.
- `docker build --tag api-nest-run-container:local .` passou; o build usou Node 24, `npm ci` estrito e compilou o projeto. O estágio de runtime instalou apenas dependências de produção.
- `npm run lint` passou sem apontamentos.
- `npm audit --audit-level=high` passou; a auditoria das dependências de produção reportou zero vulnerabilidades.
- A auditoria completa ainda reporta 20 vulnerabilidades moderadas no toolchain de testes, em caminho transitivo de Jest/`sprintf-js`. A correção sugerida por `npm audit fix --force` faz downgrade incompatível do `ts-jest`; não foi aplicada. A vulnerabilidade alta do `picomatch` foi corrigida por `npm audit fix` sem `--force`.
- Não foram adicionados nem executados testes. A suíte existente mantém a rota `/`; a rota nova `/health` ainda não tem teste dedicado.
- O limitador usa memória local; várias réplicas precisam de backend compartilhado para aplicar cotas globais.

## Fora do escopo

- Regras de negócio, autenticação e CORS não foram inventados para este scaffold.
