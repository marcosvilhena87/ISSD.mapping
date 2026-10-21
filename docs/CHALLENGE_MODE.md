# Mapeamento de memória — Challenge Mode (auditoria 2026-10-21)

## Escopo e procedência

Este documento incorpora **hipóteses instrumentadas** no repositório [ISSD.challenge_mode](https://github.com/marcosvilhena87/ISSD.challenge_mode), conforme `lua/challenge/memory_probe.lua`, `lua/challenge/runtime.lua` e `docs/AUTO_RECOGNITION.md` consultados em 2026-10-21. **Não constitui validação experimental independente dos endereços.**

- Jogo: International Superstar Soccer Deluxe (SNES).
- Domínio de leitura: `WRAM` no BizHawk (`memory.read_u8(address, "WRAM")`).
- Largura **usada pelo código atual**: 1 byte unsigned (u8) para cada sonda, não prova de que a variável interna do jogo tenha apenas 1 byte.
- Região capturada pelos scanners: `0x00000..0x1FFFF` (128 KiB de WRAM).
- ROM-alvo de referência neste catálogo: SHA-256 `d2fe66c1ce66c65ce14e478c94be2e616f9e2cad374b5783a6a64d3c1a99cfa9` (ver [TARGET_ROM.md](../TARGET_ROM.md)). **Não há comprovação de que as sessões que originaram os candidatos tenham usado precisamente esta ROM.**
- Como todas as sondas são u8, endianidade não se aplica a essas leituras.

## Níveis de evidência

1. **Hipótese instrumental:** endereço presente no reconhecedor ou associado à observação, sem evidência reprodutível anexada.
2. **Comportamento reproduzido:** capturas de diferentes sessões e controles positivos/negativos demonstram a correlação, mas não a função estrutural do campo.
3. **Layout estabelecido:** semântica e estrutura verificadas, incluindo controles negativos, compatibilidade com ROM/build, reinicializações e exclusão de falsos positivos.

Os cinco registros originais abaixo **permanecem na primeira categoria**. O candidato adicional `0x01542` possui correlação reproduzida em duas sequências, mas aguarda controles negativos e verificação de ROM/build para satisfazer integralmente a categoria 2. O estado `candidate` emitido pelo software nunca equivale a uma confirmação.

## Inventário de endereços

| Campo do probe | WRAM (offset) | Leitura | Hipótese / valores previstos | Evidência | Situação |
|---|---|---|---|---|---|
| `challenge_a` | `0xD708` | u8 | Seleção da modalidade; 0..5 | Instrumentado no v0.4/v0.5 | Hipótese |
| `challenge_b` | `0xE52C` | u8 | Segunda leitura da modalidade; prevista concordância com `challenge_a` | Instrumentado no v0.4/v0.5 | Hipótese |
| `selected_level` | `0x1550` | u8 | Nível destacado; 0..3 representa LV1..LV4 | Instrumentado no v0.4/v0.5 | Hipótese |
| `legacy_level_a` | `0xD70A` | u8 | Antiga sonda de nível; apenas telemetria | Endereço legado preservado | Hipótese histórica; **não usar para determinar nível** |
| `legacy_level_b` | `0xE52E` | u8 | Antiga sonda de nível; apenas telemetria | Endereço legado preservado | Hipótese histórica; **não usar para determinar nível** |
| `challenge_start_cursor` | `0x01542` | u8 | Cursor do submenu Challenge Start: 0 Start, 1 Key Configuration, 2 Change Controller | Discovery v1 e Validation v2, duas sequências observadas | **Comportamento correlacionado reproduzido (preliminar)**; sem exclusividade/flag de menu validada |

Codificação **postulada** para o identificador de modalidade:

| Valor | Modalidade |
|---:|---|
| 0 | DRIBBLE |
| 1 | PASS |
| 2 | SHOOT |
| 3 | DEFENSE |
| 4 | CORNER KICK |
| 5 | FREE KICK |

Codificação **postulada** de nível: `0 -> LV1`, `1 -> LV2`, `2 -> LV3`, `3 -> LV4`. São 24 combinações possíveis; isso **não** significa que 24 combinações tenham sido validadas experimentalmente.

## Lógica atual e limitações observadas na auditoria

- O decodificador só produz `candidate` quando `challenge_a == challenge_b`, ambos no intervalo 0..5, e `selected_level` no intervalo 0..3.
- O runtime aguarda três frames estáveis para publicar candidato; isso não verifica **presença do menu**.
- Os valores podem persistir fora do menu. **Ainda não existe flag de presença do Challenge Mode validada.**
- As sondas legadas são lidas junto dos campos essenciais; uma falha em uma leitura legada invalida toda a operação no código atual, apesar de seu papel ser apenas telemétrico.
- O monitor `lua/challenge/live_monitor.lua` compara snapshots completos e grava diferenças em `snapshots/live_menu_changes.csv`; o runtime grava `snapshots/recognizer_transitions_v05.csv`.
- `tests/test_memory_probe.lua` e `tests/test_wram_analyzer.lua` usam valores simulados. Testes sintéticos demonstram lógica de software, **não** função de endereço no jogo.
- O arquivo CSV de transições registra mudanças publicadas, mas não todas as leituras intermediárias `pending`.
- Não foram incorporados snapshots, CSVs experimentais, hash de sessão ou testes diretos da ROM a este catálogo durante esta atualização.

## Compatibilidade e uso pelo ISSD_bot

Este módulo descreve exclusivamente **o menu/seleção de Challenge Mode** e não altera a interpretação já registrada em [RAM_MAP.md](RAM_MAP.md) para o jogo normal (bola, jogadores, posse, cartões, `Game State`, `Gameplay Active` etc.). Não interpretar `0x0006` (guard de gameplay do jogo normal) nem `0x00BA` (estados da partida) como prova de que o menu Challenge Mode está aberto. Não ativar comandos de jogo usando apenas os candidatos deste documento.

## Plano de validação

1. Confirmar hash SHA-256 da ROM carregada, versão do BizHawk, domínio, largura, data e identificação da sessão.
2. Reunir **duas sessões independentes** dos seis desafios × quatro níveis, com indicação visual e frame da captura.
3. Alterar somente o desafio ou somente o nível, inclusive em sentido inverso, e conferir cada mudança dos três endereços prioritários.
4. Coletar controles negativos: menu principal, tela Training/Challenge, menu de seleção, desafio em andamento, pausa e partida normal.
5. Repetir saída/retorno ao menu e reinício da ROM para detectar valores residuais.
6. Identificar possível flag de presença do menu com testes negativos e verificar se é independente das sondas de desafio/nível.
7. Registrar os arquivos de evidência **sem distribuir ROM, savestates sensíveis ou dumps brutos no Git**, e documentar hashes e resultados auditáveis.
8. Promover um endereço somente após reproduzir seu comportamento; reservar o status de layout estabelecido para semântica estruturalmente demonstrada.


## Evidência preliminar de navegação — 2026-10-21

O operador forneceu saídas do console do BizHawk v0.2 abrangendo **24/24 combinações candidatas** (modalidades 0..5, níveis 0..3), com concordância de `0xD708` e `0xE52C` nas linhas fornecidas. Também foram observados `0x1550=4` em DEFENSE e CORNER KICK, e `0x1550=5` em CORNER KICK; o decodificador retornou `unknown`.

**Limitações:** saída textual sem frames, etiquetas visuais independentes, hash da ROM da sessão, controles negativos ou sessões independentes. Cobertura dos candidatos **não equivale a validação**; todos os endereços mantêm a classificação de hipótese instrumental. Valores 4/5 não são considerados níveis. Próxima coleta: monitor CSV v0.3 em `ISSD.challenge_mode`.

## Evidência observacional de 0x01542 — 2026-10-21

- Discovery v1, sessão `20261021T213107Z`: capturas visuais A/B/C/A nos frames 434589, 435111, 435667, 436369. O endereço 0x01542 foi o primeiro candidato por progressão ascendente. A correspondência individual C=2 e retorno=0 deve ser confirmada pela consulta integral do CSV, pois o PowerShell apresentado exibiu somente A e B.
- Validation v2, sessão `20261021T214439Z`: eventos do operador A=0 (474088), C=2 (474726), B=1 (475383), A=0 (476063). As linhas `transition` marcadas `match=no` refletem rótulo anterior persistente durante navegação; não são quatro falhas dos eventos manuais.
- Correlacao reproduzida em duas sequências de navegação independentes; **não** significa que o endereço seja exclusivo da tela ou que sua semântica interna/layout estejam definitivamente estabelecidos.
- Pendências: controles negativos nas demais telas, hash da ROM das sessões, repetição após reinício. Nenhuma flag autônoma de presença de submenu foi validada. Manter uso condicionado ao rótulo visual `challenge_start_menu` e confiança `candidate`.

## Histórico

- **2026-10-21 — Inventário inicial integrado:** cinco sondas trazidas do `ISSD.challenge_mode`; nenhuma promovida a endereço validado. Preservado o mapeamento anterior dos demais modos.
