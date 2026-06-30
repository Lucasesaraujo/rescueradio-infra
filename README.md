# RescueRadio Infra

Infraestrutura local do RescueRadio para a Entrega 3. Este repositorio sobe a
arquitetura completa com GUI, API, gateway, persistencia, cache, auditoria e
observabilidade.

Use este repositorio quando quiser demonstrar o sistema inteiro com um unico
`docker compose up -d`.

## O que este projeto entrega

- Orquestracao local com Docker Compose.
- API FastAPI.
- Frontend React/Vite servido por Nginx.
- Kong como gateway HTTP.
- PostgreSQL para dados duraveis.
- Redis para presenca e Pub/Sub.
- Kafka para eventos de auditoria.
- Prometheus para metricas.
- Loki e Promtail para logs.
- Grafana com datasources e dashboard provisionados.
- Scripts para build local das imagens da API e da Web.

## Arquitetura

```text
Usuario
  |
  | http://localhost:4200
  v
React/Nginx Web
  | HTTP via Kong                 | WebSocket direto
  | http://localhost:8001/api     | ws://localhost:8000
  v                               v
Kong Gateway ---------------> FastAPI API
                                  |
          +-----------------------+-----------------------+
          |                       |                       |
          v                       v                       v
     PostgreSQL                 Redis                   Kafka
 usuarios, bases,        presenca online e          auditoria
 mensagens, operacoes    Pub/Sub entre instancias    assincrona

FastAPI /metrics -> Prometheus -> Grafana
Docker logs -> Promtail -> Loki -> Grafana
```

Observacao: o transporte UDP legado existe na API, mas fica desabilitado por
padrao. A Entrega 3 usa GUI + HTTP + WebSocket como fluxo principal.

## Servicos e portas

| Servico | Porta | URL/uso |
| --- | --- | --- |
| Web | `4200` | <http://localhost:4200> |
| API direta | `8000` | <http://localhost:8000/health> |
| Swagger direto | `8000` | <http://localhost:8000/docs> |
| Kong proxy | `8001` | <http://localhost:8001/api> |
| Swagger via Kong | `8001` | <http://localhost:8001/docs> |
| Kong Admin | `8002` | <http://localhost:8002> |
| PostgreSQL | `5432` | banco `rescueradio` |
| Redis | `6379` | presenca e Pub/Sub |
| Kafka | `9092` | topico `rescueradio.audit` |
| Prometheus | `9090` | local: <http://localhost:9090> / producao: <https://prometheus.devflowapp.space> |
| Grafana | `3000` | local: <http://localhost:3000> / producao: <https://grafana.devflowapp.space> |
| Loki | `3100` | local: API interna/consulta por Grafana / producao: <https://loki.devflowapp.space> |

Login padrao do Grafana:

```text
usuario: admin
senha: admin
```

Pode ser alterado por `GRAFANA_ADMIN_USER` e `GRAFANA_ADMIN_PASSWORD`.

## Estrutura de pastas

```text
docker-compose.yml
.env.example
kong/
  kong.yml
observability/
  prometheus/prometheus.yml
  loki/loki.yml
  promtail/promtail.yml
  grafana/
    dashboards/rescueradio.json
    provisioning/
      datasources/datasources.yml
      dashboards/dashboards.yml
      alerting/alerting.yml
scripts/
  build-local-windows.ps1
  build-local-linux.sh
docs/
  architecture.md
  test-scenarios.md
```

## Como subir tudo

### Windows PowerShell

Na raiz de `rescueradio-infra`:

```powershell
.\scripts\build-local-windows.ps1
docker compose up -d
```

### Linux/macOS

```bash
./scripts/build-local-linux.sh
docker compose up -d
```

### Usando `.env`

```powershell
Copy-Item .env.example .env
docker compose --env-file .env up -d
```

Depois de alterar API ou Web, reconstrua as imagens:

```powershell
.\scripts\build-local-windows.ps1
docker compose up -d --force-recreate
```

Linux:

```bash
./scripts/build-local-linux.sh
docker compose up -d --force-recreate
```

## Comandos uteis

Ver status:

```powershell
docker compose ps
```

Ver logs da API:

```powershell
docker compose logs -f api
```

Reiniciar API para testar reconexao da GUI:

```powershell
docker compose restart api
```

Parar sem apagar dados:

```powershell
docker compose down
```

Parar apagando volumes:

```powershell
docker compose down -v
```

Validar o Compose:

```powershell
docker compose config --quiet
```

## Variaveis principais

O arquivo `.env.example` documenta os valores editaveis. As mais importantes:

| Variavel | Uso |
| --- | --- |
| `API_IMAGE` | imagem usada pelo servico API |
| `WEB_IMAGE` | imagem usada pelo servico Web |
| `DATABASE_URL` | URL async do PostgreSQL para a API |
| `REDIS_URL` | Redis para presenca e Pub/Sub |
| `JWT_SECRET` | segredo do JWT |
| `BOOTSTRAP_ADMIN_KEY` | chave para criar o primeiro admin |
| `KAFKA_BOOTSTRAP_SERVERS` | endereco do Kafka |
| `KAFKA_AUDIT_TOPIC` | topico de auditoria |
| `GATEWAY_HTTP_URL` | URL HTTP lida pelo frontend |
| `GATEWAY_WS_URL` | URL WebSocket lida pelo frontend |
| `GRAFANA_ADMIN_USER` | usuario admin do Grafana |
| `GRAFANA_ADMIN_PASSWORD` | senha admin do Grafana |
| `ENABLE_UDP` | liga o transporte UDP legado |

## Servicos em detalhe

### Web

Container `rescueradio-web`, imagem `rescueradio-web:local`.

Serve a SPA React em `http://localhost:4200`. O container gera `/config.js` no
boot usando:

- `GATEWAY_HTTP_URL`
- `GATEWAY_WS_URL`

### API

Container `rescueradio-api`, imagem `rescueradio-api:local`.

Exposes:

- HTTP em `8000`;
- WebSocket do chat em `/ws/channel/{channel_id}`;
- WebSocket global em `/ws/notifications`;
- metricas em `/metrics`;
- Swagger em `/docs`.

### Kong

Recebe chamadas HTTP do frontend em `8001` e encaminha para a API. O arquivo
`kong/kong.yml` define as rotas declarativas.

### PostgreSQL

Persiste usuarios, convites, perfis, bases, ocorrencias, operacoes, membros,
eventos e mensagens.

### Redis

Usado para presenca online e Pub/Sub de mensagens entre instancias da API.

### Kafka

Usado para auditoria assincrona. O chat nao depende do Kafka para funcionar: se
Kafka falhar, a API registra erro/metrica e continua publicando mensagens.

### Prometheus

Coleta metricas da API em `/metrics`. Exemplos:

- `rescueradio_active_connections`
- `rescueradio_messages_published_total`
- `rescueradio_websocket_errors_total`
- `rescueradio_reconnections_total`
- `rescueradio_kafka_failures_total`

### Loki e Promtail

Promtail le logs dos containers pelo Docker socket e envia para Loki. O Loki e
consultado principalmente pelo Grafana.

### Grafana

Ja sobe com datasources provisionados para Prometheus e Loki e com dashboard
`RescueRadio Operacao`.

## Fluxo de demonstracao recomendado

1. Suba tudo:

   ```powershell
   .\scripts\build-local-windows.ps1
   docker compose up -d
   ```

2. Abra <http://localhost:4200>.
3. Use a opcao de bootstrap para criar o primeiro admin.
4. Complete o onboarding.
5. Em Gestao de Usuarios, crie convite para operador ou comandante.
6. Abra uma aba anonima e registre o usuario convidado.
7. Complete onboarding do convidado.
8. Envie mensagens na Central de Comunicacao.
9. Abra nova aba com outro usuario e confirme o briefing automatico.
10. Reinicie a API:

    ```powershell
    docker compose restart api
    ```

11. Confirme que a GUI entra em reconexao e volta sem travar.
12. Como comandante/admin, crie uma operacao, adicione operadores e use o chat
    especifico.
13. Finalize a operacao como sucesso ou falha.
14. Confira o Historico e o mapa.
15. Abra Prometheus e Grafana para mostrar metricas/logs.

## Teste manual de briefing

1. Login como usuario A.
2. Entre em Central de Comunicacao.
3. Envie 3 mensagens.
4. Login como usuario B em outra aba.
5. Entre na mesma base.
6. A area de mensagens deve ser preenchida automaticamente com o briefing das
   ultimas mensagens.

## Teste manual de reconexao

```powershell
docker compose restart api
```

Resultado esperado:

- a GUI nao congela;
- o chat mostra estado de reconexao;
- quando a API volta, o canal restabelece;
- novas mensagens podem ser enviadas.

## UDP legado opcional

O Compose nao liga UDP por padrao. Para testar o legado:

1. Defina no `.env`:

   ```text
   ENABLE_UDP=true
   UDP_PORT=9000
   ```

2. Exponha a porta UDP no `docker-compose.yml`, se necessario:

   ```yaml
   ports:
     - "9000:9000/udp"
   ```

3. Recrie a API.

Esse fluxo nao e necessario para a Entrega 3, pois a GUI e o WebSocket sao o
caminho principal.

## Solucao de problemas

- `docker compose up` usa imagem antiga: rode build e `--force-recreate`.
- Grafana nao aceita `admin/admin`: confira variaveis `GRAFANA_ADMIN_USER` e
  `GRAFANA_ADMIN_PASSWORD` ou remova o volume `grafana-data`.
- Kafka demora para ficar saudavel: aguarde o healthcheck ou rode
  `docker compose logs -f kafka`.
- Web abre, mas API falha: confira Kong em <http://localhost:8001/health> e API
  direta em <http://localhost:8000/health>.
- WebSocket falha no navegador: confira se `GATEWAY_WS_URL` aponta para
  `ws://localhost:8000`.
- Prometheus sem dados: abra <http://localhost:9090/targets> localmente ou
  <https://prometheus.devflowapp.space/targets> em producao e veja se o target
  da API esta `UP`.
- Loki em `localhost:3100` ou <https://loki.devflowapp.space> pode mostrar
  endpoints tecnicos. Para consulta amigavel, use o Grafana Explore com
  datasource Loki.

## CI

Os workflows validam o Compose com:

```bash
docker compose config --quiet
```

Isso garante que o arquivo principal da raiz continua sintaticamente valido em
pull requests e pushes relevantes.
