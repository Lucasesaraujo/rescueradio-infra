# RescueRadio Infra

Infraestrutura local e configuracoes de execucao do RescueRadio.

## Responsabilidades

- Docker Compose;
- Kong API Gateway;
- PostgreSQL para historico de mensagens;
- Redis para presenca online;
- redes e volumes;
- exposicao HTTP, WebSocket e UDP;
- futuramente, Kafka e observabilidade.

## Decisao Tecnologica

A infraestrutura utiliza Docker Compose, Kong API Gateway, PostgreSQL e Redis.
O Docker Compose executa API, frontend, gateway, banco e cache de forma
reproduzivel e conectada por uma rede comum. O Kong centraliza HTTP e WebSocket.
O PostgreSQL persiste o historico dos canais, enquanto o Redis mantem presenca
temporaria dos socorristas online.

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
      |              |
      v              v
PostgreSQL        Redis
historico         presenca
```

Mensagens validas vindas de WebSocket ou UDP sao persistidas no PostgreSQL e
retransmitidas aos clientes WebSocket do canal. A presenca dos membros ativos
fica no Redis. O broadcast ainda e local a instancia da API; Redis Pub/Sub nao
faz parte desta etapa.

## Repositorios

Para o fluxo local padrao, mantenha os tres repositorios como diretorios irmaos:

```text
Sistemas Distribuidos/
|-- rescueradio-api/
|-- rescueradio-web/
`-- rescueradio-infra/
```

## Estrutura de Pastas

```text
rescueradio-infra/
|-- compose/
|   `-- docker-compose.yml  # integracao dos servicos
|-- kong/
|   `-- kong.yml            # rotas HTTP e WebSocket
|-- docs/
|   |-- architecture.md
|   `-- test-scenarios.md
|-- scripts/
|   `-- build-local.ps1
|-- .env.example
`-- README.md
```

## Execucao Local

Construa as imagens da API e do frontend:

```powershell
./scripts/build-local.ps1
```

Copie `.env.example` para `.env` se quiser alterar imagens, portas, credenciais
ou URLs. Em seguida:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml up -d
```

Sem um arquivo `.env`, o Compose usa os valores padrao definidos no proprio
arquivo:

```powershell
docker compose -f compose/docker-compose.yml up -d
```

Servicos:

| Servico | Endereco |
| --- | --- |
| Web | <http://localhost:4200> |
| API direta | <http://localhost:8000/health> |
| API via Kong | <http://localhost:8001/health> |
| Kong Admin | <http://localhost:8002> |
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| Entrada UDP | `localhost:9000/udp` |

Volumes:

- `postgres-data`: dados persistentes do PostgreSQL;
- `redis-data`: dados do Redis.

Para encerrar sem apagar dados:

```powershell
docker compose -f compose/docker-compose.yml down
```

Para encerrar apagando volumes locais:

```powershell
docker compose -f compose/docker-compose.yml down -v
```

## Imagens Publicadas

Em CI/CD, altere `API_IMAGE` e `WEB_IMAGE` para tags imutaveis publicadas em um
registry. O repositorio de infraestrutura nao copia nem compila codigo das
aplicacoes.

## Fluxo de Desenvolvimento

- `main`: homologacao das versoes aprovadas em `develop`;
- `develop`: desenvolvimento e integracao das funcionalidades aprovadas;
- `feature/*`: desenvolvimento isolado, sempre criado a partir de `develop`.

As branches de funcionalidade devem voltar para `develop` por pull request apos
a aprovacao do CI. A promocao para homologacao ocorre por pull request de
`develop` para `main`.
