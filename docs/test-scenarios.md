# Cenarios de teste manual

## Preparacao

Na raiz de `rescueradio-infra`:

```powershell
./scripts/build-local.ps1
docker compose -f compose/docker-compose.yml up -d
```

## GUI principal e onboarding

1. Abra <http://localhost:4200>.
2. Cadastre `lucas` com senha `segredo123`; ele deve aparecer como admin.
3. Complete o onboarding com base `Base Central`, funcao, contato e skills.
4. Acesse Chat Geral e envie uma mensagem.
5. Abra outra aba anonima e cadastre `marcelo`.
6. Complete o onboarding de `marcelo` na mesma base.
7. Confirme que o Chat Geral da base carrega briefing e retransmite mensagens.

## Operacoes

1. No usuario admin, va em Admin e promova `marcelo` para `comandante`, se quiser testar com comandante separado.
2. Va em Operacoes.
3. Preencha titulo, prioridade, endereco e descricao.
4. Clique no mapa para definir a coordenada real.
5. Selecione operadores disponiveis e clique em `Criar e abrir chat`.
6. Envie mensagens no chat especifico da operacao.
7. Preencha o resumo e finalize a operacao.
8. Va em Historico e confirme auditoria com participantes, status e mensagens.

## Reconexao

Com duas GUIs abertas:

```powershell
docker compose -f compose/docker-compose.yml restart api
```

Resultado esperado:

- as telas mudam para `Reconectando`;
- o historico permanece visivel;
- o input fica bloqueado enquanto o WebSocket nao volta;
- a reconexao acontece sem refresh manual.

## UDP para WebSocket

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

Resultado esperado:

- a mensagem aparece na GUI como `Central`;
- `Central` nao aparece como membro ativo;
- a mensagem entra no briefing de novas conexoes.

## Observabilidade

1. Acesse localmente <http://localhost:9090> ou em producao <https://prometheus.devflowapp.space> e consulte `rescueradio_active_connections`.
2. Acesse localmente <http://localhost:3000> ou em producao <https://grafana.devflowapp.space>.
3. Abra o dashboard `RescueRadio Operacao`.
4. Em Explore, use Loki e filtre por `service="api"` ou outro container
   `rescueradio-*`.

## Encerramento

```powershell
docker compose -f compose/docker-compose.yml down
```
