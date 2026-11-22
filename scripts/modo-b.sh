#!/usr/bin/env bash
# Modo B: banco e backend no Docker, servidor Java rodando neste terminal
# (com os comandos "status" e "desativar").
#
# Uso:   ./scripts/modo-b.sh            (rapido; reconstroi so se faltar imagem)
#        ./scripts/modo-b.sh --build    (reconstroi o backend antes)
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
cd "$raiz"

erro() { echo "ERRO: $1" >&2; exit 1; }

command -v docker >/dev/null || erro "Docker nao encontrado. Abra o Docker Desktop."
docker info >/dev/null 2>&1 || erro "O Docker nao esta rodando. Abra o Docker Desktop e tente de novo."
command -v javac >/dev/null || erro "Java 17 (javac) nao encontrado no PATH."
[ -f .env ] || erro "Falta o arquivo .env na raiz. Veja o passo 2 do README (cp env.example .env)."

construir=""
[ "${1:-}" = "--build" ] && construir="--build"

echo "==> Parando o servidor do Docker (se estiver rodando)..."
docker compose stop servidor >/dev/null 2>&1 || true

echo "==> Subindo banco e backend (espera ficarem prontos)..."
if ! docker compose up -d --wait $construir mongo backend; then
  echo >&2
  echo "O backend nao ficou pronto. Ultimas linhas do log:" >&2
  docker compose logs --tail 25 backend >&2 || true
  echo >&2
  echo "Se aparecer SSLException/MongoTimeoutException com mongodb.net, libere seu IP no Atlas" >&2
  echo "ou comente MONGODB_URI no .env para usar o banco local." >&2
  exit 1
fi

echo "==> Compilando o servidor Java..."
rm -rf servidor/out
mkdir -p servidor/out
javac -d servidor/out servidor/src/*.java

echo "==> Servidor no ar. Digite status ou desativar."
cd servidor
exec java -cp out Servidor
