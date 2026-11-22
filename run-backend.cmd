@echo off
rem Sobe banco + backend + servidor Java e deixa o terminal do servidor aberto
rem (digite status ou desativar). Uso:  run-backend   ou   run-backend --build
cd /d "%~dp0"

docker info >nul 2>&1
if errorlevel 1 (
  echo ERRO: o Docker nao esta rodando. Abra o Docker Desktop e tente de novo.
  exit /b 1
)

if not exist .env (
  echo ERRO: falta o arquivo .env na raiz. Veja o passo 2 do README: copy env.example .env
  exit /b 1
)

rem Remove um servidor antigo que tenha ficado em segundo plano (evita conflito na porta 3000)
docker rm -f servidor-talhao >nul 2>&1

if "%~1"=="--build" (
  echo ==^> Reconstruindo as imagens...
  docker compose --profile segundo-plano build
  if errorlevel 1 exit /b 1
)

echo ==^> Subindo banco, backend e servidor. Na primeira vez demora alguns minutos.
echo     Quando aparecer "Servidor ativo", pode rodar o app. Digite status ou desativar aqui.
docker compose run --rm --service-ports servidor
set codigo=%errorlevel%

if not "%codigo%"=="0" (
  echo.
  echo O servidor nao iniciou. Ultimas linhas do log do backend:
  docker compose logs --tail 25 backend
  echo.
  echo Se aparecer SSLException ou MongoTimeoutException com mongodb.net, o Atlas esta
  echo recusando seu IP. Veja a secao "Problemas comuns" do README.
)
exit /b %codigo%
