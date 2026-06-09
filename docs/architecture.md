# Arquitetura do RescueRadio

## Visão geral

```text
Angular Web App
      |
      v
Kong Gateway
      |
      v
FastAPI WebSocket API <--- UDP 9000
      |
      v
Estado em memória
```

O frontend usa o Kong como entrada HTTP e WebSocket. A API também recebe
datagramas UDP diretamente na porta `9000`, valida-os pelo mesmo serviço de
mensagens e retransmite as mensagens aos clientes WebSocket do canal.

## Componentes

| Componente | Responsabilidade |
| --- | --- |
| Angular Web App | Entrada no canal, chat, briefing, membros e eventos. |
| Kong Gateway | Encaminhamento HTTP e WebSocket para a API. |
| FastAPI | WebSocket, UDP, validação, broadcast, briefing e presença. |
| Estado em memória | Buffer das últimas mensagens de cada canal. |

Presença é exclusiva das conexões WebSocket. Remetentes UDP não aparecem na
lista de membros, e a API não responde ACK nesta fase.

## Evoluções aguardando especificação

- autenticação JWT e roles;
- persistência em PostgreSQL;
- presença ou cache em Redis;
- eventos com Kafka;
- observabilidade com Prometheus, Grafana e Loki.
