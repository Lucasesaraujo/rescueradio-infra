# RescueRadio Infra

Infraestrutura local e configuracoes de execucao do RescueRadio.

## Responsabilidades

- Docker Compose;
- Kong API Gateway;
- redes e volumes;
- exposição HTTP, WebSocket e UDP;
- futuramente, PostgreSQL, Redis, Kafka e observabilidade.

## Repositorios

Para o fluxo local padrao, mantenha os tres repositorios como diretorios irmaos:

```text
Sistemas Distribuidos/
|-- rescueradio-api/
|-- rescueradio-web/
`-- rescueradio-infra/
```

## Execucao local

Construa as imagens da API e do frontend:

```powershell
.\scripts\build-local.ps1
```

Copie `.env.example` para `.env` se quiser alterar imagens, portas ou a URL
WebSocket usada pelo frontend. Em seguida:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml up -d
```

Sem um arquivo `.env`, o Compose usa os valores padrao definidos no proprio arquivo:

```powershell
docker compose -f compose/docker-compose.yml up -d
```

O projeto Compose usa o nome `rescueradio`, exibido como o grupo dos
containers no Docker Desktop.

Servicos:

| Servico | Endereco |
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

Em CI/CD, altere `API_IMAGE` e `WEB_IMAGE` para tags imutaveis publicadas em um registry. O repositorio de infraestrutura nao copia nem compila codigo das aplicacoes.

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
