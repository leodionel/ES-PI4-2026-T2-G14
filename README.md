# ES-PI4-2026-T2-G14
Repositório do Projeto integrador IV
Produzido pelo Grupo 14 da Turma 2 de Engenharia de Software da PUC-Campinas 4º semestre


## Executar com Docker Compose

O Compose usa MongoDB local por padrão (mongodb://mongo:27017/talhao). Para iniciar, crie um arquivo .env na raiz do projeto e configure um segredo JWT aleatório com pelo menos 32 bytes. Com OpenSSL instalado, gere o valor com openssl rand -base64 32 e adicione ao .env:

```dotenv
JWT_SECRET_BASE64=COLE_AQUI_O_VALOR_GERADO
```

Depois execute docker compose up --build. O .env é ignorado pelo Git. Para usar outro banco, defina também MONGODB_URI no .env; sem essa variável, será usado o MongoDB do Compose.
