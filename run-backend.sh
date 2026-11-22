#!/usr/bin/env bash
# Sobe banco + backend + servidor Java e deixa o terminal do servidor aberto
# (digite status ou desativar).
# Uso:  ./run-backend.sh     ou     ./run-backend.sh --build
set -uo pipefail
cd "$(dirname "$0")"

docker info >/dev/null 2>&1 || { echo "ERRO: o Docker nao esta rodando. Abra o Docker Desktop e tente de novo." >&2; exit 1; }
[ -f .env ] || { echo "ERRO: falta o arquivo .env na raiz. Veja o passo 2 do README: cp env.example .env" >&2; exit 1; }

# Remove um servidor antigo que tenha ficado em segundo plano (evita conflito na porta 3000)
docker rm -f servidor-talhao >/dev/null 2>&1 || true

if [ "${1:-}" = "--build" ]; then
  echo "==> Reconstruindo as imagens..."
  docker compose --profile segundo-plano build || exit 1
fi

echo "==> Subindo banco, backend e servidor. Na primeira vez demora alguns minutos."
echo "    Quando aparecer \"Servidor ativo\", pode rodar o app. Digite status ou desativar aqui."
docker compose run --rm --service-ports servidor
codigo=$?

if [ $codigo -ne 0 ]; then
  echo
  echo "O servidor nao iniciou. Ultimas linhas do log do backend:"
  docker compose logs --tail 25 backend
  echo
  echo "Se aparecer SSLException ou MongoTimeoutException com mongodb.net, o Atlas esta"
  echo "recusando seu IP. Veja a secao \"Problemas comuns\" do README."
fi
exit $codigo
