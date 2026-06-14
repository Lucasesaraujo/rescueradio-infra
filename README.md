# RescueRadio Infra

Infraestrutura local e configurações de execução do RescueRadio.

## Responsabilidades

- Docker Compose;
- Kong API Gateway;
- redes e volumes;
- exposição HTTP, WebSocket e UDP;
- futuramente, PostgreSQL, Redis, Kafka e observabilidade.

## Decisão tecnológica

A infraestrutura utiliza Docker Compose e Kong API Gateway. O Docker Compose
foi escolhido para executar API, frontend e gateway de forma reproduzível,
isolada e conectada por uma rede comum, mantendo configurações de portas e
imagens em um único arquivo. O Kong foi escolhido como ponto de entrada para
HTTP e WebSocket, permitindo centralizar o roteamento e preparar a arquitetura
para futuras políticas de autenticação, controle de acesso e observabilidade.

Essas escolhas se encaixam na arquitetura de alto nível porque separam as
responsabilidades entre cliente, gateway e servidor, sem acoplar a interface
ao endereço interno da API.

## Arquitetura

```text
Angular Web App
      |
      | HTTP/WebSocket
      v
Kong API Gateway
      |
      v
FastAPI WebSocket API <--- UDP 9000
      |
      v
Estado em memória por canal
```

O Angular usa o Kong como entrada WebSocket. O Kong encaminha as conexões para
o FastAPI, que valida as mensagens, atualiza o buffer circular e realiza o
broadcast. Em paralelo, a API recebe datagramas UDP diretamente na porta
`9000`; depois da validação, eles entram no mesmo fluxo de publicação. O estado
em memória mantém o histórico recente e a presença das conexões WebSocket.

## Repositórios

Para o fluxo local padrão, mantenha os três repositórios como diretórios irmãos:

```text
Sistemas Distribuidos/
|-- rescueradio-api/
|-- rescueradio-web/
`-- rescueradio-infra/
```

## Estrutura de pastas

```text
rescueradio-infra/
|-- compose/
|   `-- docker-compose.yml  # integração dos três serviços
|-- kong/
|   `-- kong.yml            # rotas HTTP e WebSocket
|-- docs/
|   |-- architecture.md     # visão arquitetural detalhada
|   `-- test-scenarios.md   # roteiro de validação manual
|-- scripts/
|   `-- build-local.ps1     # build das imagens locais
|-- .env.example            # portas, imagens e URL do gateway
`-- README.md
```

## Execução local

Construa as imagens da API e do frontend:

```powershell
./scripts/build-local.ps1
```

Copie `.env.example` para `.env` se quiser alterar imagens, portas ou a URL
WebSocket usada pelo frontend. Em seguida:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml up -d
```

Sem um arquivo `.env`, o Compose usa os valores padrão definidos no próprio
arquivo:

```powershell
docker compose -f compose/docker-compose.yml up -d
```

O projeto Compose usa o nome `rescueradio`, exibido como o grupo dos
containers no Docker Desktop.

Serviços:

| Serviço | Endereço |
| --- | --- |
| Web | <http://localhost:4200> |
| API direta | <http://localhost:8000/health> |
| API via Kong | <http://localhost:8001/health> |
| Kong Admin | <http://localhost:8002> |
| Entrada UDP | `localhost:9000/udp` |

Para encerrar:

```powershell
docker compose -f compose/docker-compose.yml down
```

## Imagens publicadas

Em CI/CD, altere `API_IMAGE` e `WEB_IMAGE` para tags imutáveis publicadas em
um registry. O repositório de infraestrutura não copia nem compila código das
aplicações.

## Estrutura futura

Os diretórios em `observability/` estão reservados para Prometheus, Grafana e
Loki. PostgreSQL, Redis e Kafka serão adicionados quando entrarem na
especificação da aplicação.

## Fluxo de desenvolvimento

- `main`: versões estáveis;
- `develop`: integração das funcionalidades aprovadas;
- `feature/*`: desenvolvimento isolado, sempre criado a partir de `develop`.

As branches de funcionalidade devem voltar para `develop` por pull request
após a aprovação do CI.
