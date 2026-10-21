# Catálogo de memória ISSD

Este repositório destina-se exclusivamente ao registro de endereços de memória, incluindo endereços candidatos ainda não validados.

Consulte `docs/RAM_MAP.md` para o mapa detalhado das posições da bola, jogadores, equipes, campo, posse e estados da partida.

## Versão de referência

A ROM de referência é **International Superstar Soccer Deluxe (USA)** (SNES), identificada por SHA-256. Consulte [`TARGET_ROM.md`](TARGET_ROM.md) para tamanho, cabeçalho, CRC32, MD5, SHA-256 e critérios de validação por versão.

## Challenge Mode — mapeamento experimental

O inventário auditado das cinco sondas de WRAM investigadas pelo [`ISSD.challenge_mode`](https://github.com/marcosvilhena87/ISSD.challenge_mode) está em [`docs/CHALLENGE_MODE.md`](docs/CHALLENGE_MODE.md). Os endereços `0xD708`, `0xE52C`, `0x1550`, `0xD70A` e `0xE52E` permanecem **hipóteses**, não validadas para acionamento automático; a presença do menu ainda não foi comprovada por uma flag independente.
