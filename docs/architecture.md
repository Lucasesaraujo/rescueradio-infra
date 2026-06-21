# Arquitetura do RescueRadio

## Visao Geral

```text
Angular Web App
      |
      v
Kong Gateway
      |
      v
FastAPI WebSocket API <--- UDP 9000
      |              |
      v              v
PostgreSQL        Redis
historico         presenca
```

O frontend usa o Kong como entrada HTTP e WebSocket. A API tambem recebe
datagramas UDP diretamente na porta `9000`, valida-os pelo mesmo servico de
mensagens, persiste mensagens validas no PostgreSQL e retransmite eventos aos
clientes WebSocket conectados ao canal.

## Componentes

| Componente | Responsabilidade |
| --- | --- |
| Angular Web App | Entrada no canal, chat, briefing, membros e eventos. |
| Kong Gateway | Encaminhamento HTTP e WebSocket para a API. |
| FastAPI | WebSocket, UDP, validacao, broadcast e orquestracao. |
| PostgreSQL | Historico persistente de mensagens por canal. |
| Redis | Presenca temporaria dos socorristas online. |

Presenca e exclusiva das conexoes WebSocket. Remetentes UDP nao aparecem na
lista de membros, e a API nao responde ACK nesta fase.

## Limites Desta Etapa

- O broadcast ainda e local a instancia da API.
- Redis Pub/Sub ainda nao foi implementado.
- O schema PostgreSQL e criado automaticamente no startup da API.
- Autenticacao JWT, Kafka e observabilidade ficam para proximas entregas.
