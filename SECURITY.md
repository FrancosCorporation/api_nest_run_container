# Segurança

## Reportar vulnerabilidades

Use o recurso de reporte privado de vulnerabilidades do GitHub para este repositório. Não publique detalhes exploráveis em uma issue pública.

## Configuração segura

- Atualize a imagem e as dependências a partir do lockfile mantido pelo projeto.
- Não adicione segredos ao Dockerfile, à imagem ou ao Compose. Injete configurações sensíveis pelo ambiente da implantação.
- O Compose de desenvolvimento publica a API somente em `127.0.0.1`.
- CORS fica desabilitado até que a aplicação tenha uma origem de frontend definida. Se for habilitado, use uma allowlist e não combine origem curinga com credenciais.
- O limitador padrão é local ao processo. Use armazenamento compartilhado antes de operar várias réplicas atrás de um balanceador.
- Este scaffold não implementa autenticação nem autorização; não exponha rotas de negócio sem acrescentá-las.
