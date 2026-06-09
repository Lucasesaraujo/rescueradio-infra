# Cenários de teste manual

## Preparação

Na raiz de `rescueradio-infra`:

```powershell
./scripts/build-local.ps1
docker compose -f compose/docker-compose.yml up -d
```

Serviços esperados:

| Serviço | Endereço |
| --- | --- |
| Frontend | <http://localhost:4200> |
| API direta | <http://localhost:8000/health> |
| API via Kong | <http://localhost:8001/health> |
| UDP | `localhost:9000/udp` |

## WebSocket

1. Abra duas abas do frontend.
2. Entre como `Lucas` e `Marcelo`.
3. Envie uma mensagem em uma das abas.
4. Confirme que ambas recebem a mensagem e exibem os dois membros.
5. Feche uma aba e confirme o evento de saída na outra.
6. Abra uma terceira aba e confirme que o briefing contém as mensagens
   anteriores.

## UDP para WebSocket

Mantenha uma aba conectada ao `canal-geral` e execute:

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

- a mensagem aparece no frontend como `MESSAGE_RECEIVED`;
- `Central` não aparece como membro ativo;
- a mensagem passa a fazer parte do briefing.

Datagramas sem `channel_id`, com JSON inválido ou com campos inválidos devem
ser descartados e registrados nos logs da API.

## Encerramento

```powershell
docker compose -f compose/docker-compose.yml down
```
