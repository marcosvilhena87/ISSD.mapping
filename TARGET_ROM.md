# ROM-alvo — International Superstar Soccer Deluxe (SNES)

Este documento identifica por hash a ROM de referência fornecida para o projeto. Os endereços do catálogo devem ser testados contra esta ROM antes de receber status de validação em execução.

## Identificação

| Campo | Valor |
|---|---|
| Jogo | International Superstar Soccer Deluxe |
| Região indicada pelo nome do arquivo | USA |
| Arquivo dentro do ZIP | `International Superstar Soccer Deluxe (USA).sfc` |
| Arquivo ZIP fornecido | `International Superstar Soccer Deluxe (USA)(2).zip` |
| Plataforma | Super Nintendo Entertainment System (SNES) |
| Tamanho da ROM | 2.097.152 bytes (2 MiB) |
| Cabeçalho interno | `SUPERSTAR SOCCER 2` |
| Cabeçalho de cópia de 512 bytes | Ausente |
| CRC32 | `0A20E602` |
| MD5 | `345ddedcd63412b9373dabb67c11fc05` |
| SHA-256 | `d2fe66c1ce66c65ce14e478c94be2e616f9e2cad374b5783a6a64d3c1a99cfa9` |

Os hashes foram calculados sobre o conteúdo descompactado de 2.097.152 bytes da ROM `.sfc`, e **não** sobre o arquivo ZIP. Nome do arquivo e título interno não substituem a identificação criptográfica por SHA-256.

## Critério de validação do mapa

- A presença de um endereço em arquivo WCH não prova que ele tenha sido validado nesta ROM.
- Manter registros previamente descritos como validados, mas não inferir retroativamente qual hash de ROM foi utilizado em cada teste.
- Para novas validações, registrar ROM SHA-256, endereço WRAM, tipo/tamanho/sinal, valor ou comportamento observado, cenário, ferramenta e data.
- Se o SHA-256 da ROM em execução diferir do acima, não assumir equivalência dos endereços sem nova verificação.
- A ROM comercial não é distribuída por este repositório.

## Conferência independente

Extraia o arquivo `.sfc` e execute `Get-FileHash -Algorithm SHA256 "International Superstar Soccer Deluxe (USA).sfc"` no PowerShell. O hash deve coincidir exatamente com o registrado acima.
