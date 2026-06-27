# RescueRadio Infra

Infraestrutura local da Entrega 3 do RescueRadio.

## Servicos

| Servico | Endereco |
| --- | --- |
| Web | <http://localhost:4200> |
| API direta | <http://localhost:8000/health> |
| API via Kong | <http://localhost:8001/health> |
| API HTTP via Kong | <http://localhost:8001/api> |
| Kong Admin | <http://localhost:8002> |
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| Kafka | `localhost:9092` |
| Prometheus | <http://localhost:9090> |
| Loki | <http://localhost:3100> |
| Grafana | <http://localhost:3000> |
| UDP | `localhost:9000/udp` |

Login inicial do Grafana: `admin` / `admin`, salvo se alterado no `.env`.

## Arquitetura

```text
Angular GUI
   | HTTP / WebSocket
   v
Kong Gateway
   |
   v
FastAPI API <--- UDP 9000
   |   |   |
   |   |   v
   |   |  Kafka auditoria
   |   v
   |  Redis presenca/pubsub
   v
PostgreSQL usuarios/mensagens

Prometheus -> /metrics
Promtail -> Loki -> Grafana
```

## Execucao local

Na raiz de `rescueradio-infra`, construa as imagens locais:

```powershell
./scripts/build-local.ps1
```

Suba o ambiente:

```powershell
docker compose -f compose/docker-compose.yml up -d
```

Depois de alterar API ou Web, rode novamente `./scripts/build-local.ps1` antes do `up -d`. Se os containers ja existirem e voce quiser garantir que as imagens novas entrem em uso, execute:

```powershell
docker compose -f compose/docker-compose.yml up -d --force-recreate
```

Ou, usando `.env`:

```powershell
Copy-Item .env.example .env
docker compose --env-file .env -f compose/docker-compose.yml up -d
```

Para encerrar sem apagar dados:

```powershell
docker compose -f compose/docker-compose.yml down
```

Para encerrar apagando volumes:

```powershell
docker compose -f compose/docker-compose.yml down -v
```

## Demonstracao operacional

1. Abra <http://localhost:4200>.
2. Crie o primeiro usuario; ele sera `admin`.
3. Complete o onboarding operacional.
4. Use o Chat Geral da base para validar comunicacao persistente.
5. Abra outra aba anonima, crie um operador e complete onboarding na mesma base.
6. No Admin, promova um usuario a comandante se necessario.
7. Em Operacoes, crie uma ocorrencia, clique no mapa para coordenada e adicione operadores.
8. Use o chat especifico da operacao, finalize e confira o Historico auditavel.
9. Reinicie a API ou o Kong:

```powershell
docker compose -f compose/docker-compose.yml restart api
```

10. Confirme que a GUI fica em `Reconectando` e volta sem congelar.
11. Abra <http://localhost:9090> e consulte metricas `rescueradio_*`.
12. Abra <http://localhost:3000> e veja o dashboard `RescueRadio Operacao`.

## Validacao UDP

Com um usuario conectado pela GUI:

```powershell
$udp = [System.Net.Sockets.UdpClient]::new()
$payload = @{
  type = "SEND_MESSAGE"
  channel_id = "base:base-central:geral"
  usuario = "Central"
  timestamp_iso = [DateTime]::UtcNow.ToString("o")
  corpo_texto = "Mensagem enviada por UDP."
} | ConvertTo-Json -Compress
$bytes = [Text.Encoding]::UTF8.GetBytes($payload)
$udp.Send($bytes, $bytes.Length, "localhost", 9000)
$udp.Dispose()
```

A mensagem deve aparecer na GUI e entrar no briefing.
