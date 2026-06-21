# Cenarios de teste manual

## Preparacao

Na raiz de `rescueradio-infra`:

```powershell
./scripts/build-local.ps1
docker compose -f compose/docker-compose.yml up -d
```

Servicos esperados:

| Servico | Endereco |
| --- | --- |
| Frontend | <http://localhost:4200> |
| API direta | <http://localhost:8000/health> |
| API via Kong | <http://localhost:8001/health> |
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| UDP | `localhost:9000/udp` |

## Validacao academica via terminal

Abra tres terminais na raiz de `rescueradio-api` e conecte tres socorristas
via Kong:

```powershell
python -m app.terminal_client --url ws://localhost:8001 --usuario Lucas
```

```powershell
python -m app.terminal_client --url ws://localhost:8001 --usuario Marcelo
```

```powershell
python -m app.terminal_client --url ws://localhost:8001 --usuario Julia
```

Em um dos terminais, digite:

```text
Equipe Alfa chegou ao local.
```

Resultado esperado:

- os outros dois terminais recebem a mensagem imediatamente;
- o terminal remetente nao recebe eco da propria mensagem;
- todos recebem eventos de entrada e saida dos membros;
- se a API ou o Kong cair e voltar, o cliente tenta reconectar sem precisar
  reiniciar o processo.
- reinicie somente a API e abra um novo cliente para confirmar que o briefing
  continua vindo do PostgreSQL.

## Demonstracao do produto via navegador

Abra <http://localhost:4200> em duas ou tres abas do navegador.

1. Entre no canal como `Lucas`, `Marcelo` e `Julia`.
2. Envie uma mensagem em uma das abas.
3. Confirme que a aba remetente mostra a mensagem localmente.
4. Confirme que as outras abas recebem a mensagem pelo servidor.
5. Pare e suba novamente a API ou o Kong para validar o estado
   `Reconectando` e a reconexao automatica da interface.
6. Abra uma nova aba e confirme que o briefing contem as mensagens anteriores.

## UDP para WebSocket

Mantenha um cliente terminal conectado ao `canal-geral` e execute:

```powershell
$udp = [System.Net.Sockets.UdpClient]::new()
$payload = @{
  type = "SEND_MESSAGE"
  channel_id = "canal-geral"
  usuario = "Central"
  timestamp_iso = [DateTime]::UtcNow.ToString("o")
  corpo_texto = "Mensagem enviada por UDP."
} | ConvertTo-Json -Compress
$bytes = [Text.Encoding]::UTF8.GetBytes($payload)
$udp.Send($bytes, $bytes.Length, "localhost", 9000)
$udp.Dispose()
```

Resultado esperado:

- a mensagem aparece no cliente como `MESSAGE_RECEIVED`;
- `Central` nao aparece como membro ativo;
- a mensagem passa a fazer parte do briefing.

Datagramas sem `channel_id`, com JSON invalido ou com campos invalidos devem
ser descartados e registrados nos logs da API.

## Persistencia PostgreSQL e presenca Redis

Depois de enviar algumas mensagens, reinicie apenas a API:

```powershell
docker compose -f compose/docker-compose.yml restart api
```

Abra um novo cliente terminal ou uma nova aba da interface. Resultado esperado:

- o evento `BRIEFING` contem as mensagens anteriores, persistidas no
  PostgreSQL;
- a lista de membros online volta a refletir apenas as conexoes WebSocket
  ativas no momento, registradas no Redis;
- mensagens UDP continuam entrando no mesmo historico persistente.

## Encerramento

```powershell
docker compose -f compose/docker-compose.yml down
```
