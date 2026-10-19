# Challenge Mode — inventário de memória (pendente de descoberta)

**Estado em 2026-10-19:** capturas de tela confirmam a existência dos modos e níveis, mas **nenhum endereço WRAM específico do Challenge Mode foi descoberto ou validado**. Este documento registra *variáveis-alvo*, não endereços candidatos. Não atribua o status 🟡 (candidato) sem endereço e evidência reproduzível.

Referência de implementação: [ISSD.challenge_mode](https://github.com/marcosvilhena87/ISSD.challenge_mode). ROM-alvo e critérios de compatibilidade: [TARGET_ROM.md](../TARGET_ROM.md).

## Variáveis específicas a mapear

| ID lógico | Significado | WRAM | Tipo | Status | Evidência necessária |
|---|---|---|---|---|---|
| challenge_mode_active | presença do Challenge Mode | — | desconhecido | 🔴 não localizado | contrastar menu normal, seleção e jogo |
| challenge_menu_selected | seleção de modalidade (6 opções) | — | desconhecido | 🔴 | percorrer opções em menu |
| challenge_level_selected | nível selecionado (1–4) | — | desconhecido | 🔴 | alternar LV1–LV4 por modalidade |
| challenge_phase | menu, preparo, execução, conclusão, falha | — | desconhecido | 🔴 | coletar transições com frames |
| challenge_timer | cronômetro exibido no desafio | — | desconhecido | 🔴 | comparar valor visual e snapshots |
| challenge_score | pontuação obtida durante desafio | — | desconhecido | 🔴 | comparar eventos e placar |
| challenge_best_time | melhor tempo de cada modalidade/nível | — | desconhecido | 🔴 | verificar persistência e slots |
| challenge_best_score | melhor pontuação por modalidade/nível | — | desconhecido | 🔴 | comparar slots e reinício |
| challenge_success | flag de sucesso | — | desconhecido | 🔴 | conclusões positivas e negativas |
| challenge_failure | flag de falha | — | desconhecido | 🔴 | falha por tempo e por condição |
| dribble_opponents_count | oponentes driblados no desafio Dribble | — | desconhecido | 🔴 | driblar sucessivamente |
| pass_players_reached | jogadores que receberam passe no desafio Pass | — | desconhecido | 🔴 | passar entre jogadores distintos |
| shoot_target_or_bonus | alvo, canto ou bônus do desafio Shoot | — | desconhecido | 🔴 | repetir chutes em alvos diferentes |
| defense_ball_recovered | evento de recuperação no desafio Defense | — | desconhecido | 🔴 | interceptação e desarme |
| corner_goal_event | gol originado de escanteio | — | desconhecido | 🔴 | tentativas com e sem gol |
| free_kick_goal_event | gol originado de falta | — | desconhecido | 🔴 | tentativas com e sem gol |

**Atenção:** nomes acima representam hipóteses de variáveis observáveis. Não há evidência de que cada uma exista como campo independente na memória, nem de sua codificação. A existência de quatro níveis e seis modalidades está documentada pelas capturas, mas os **códigos internos ainda são desconhecidos**.

## Endereços de partida já catalogados — não validados no Challenge Mode

Os seguintes registros pertencem ao [mapa principal](RAM_MAP.md) e podem ser monitorados como **pistas**, sem assumir que mantenham a mesma semântica em desafios:

| WRAM | Nome existente | Situação no Challenge Mode |
|---|---|---|
| `0x0006` | Gameplay Active | não testado neste modo |
| `0x00BA` | Game State | não testado neste modo |
| `0x042A` | Ball X | não testado neste modo |
| `0x042C` | Ball Y | não testado neste modo |
| `0x00A6` | Player Ball Possession | não testado neste modo |
| `0x104C` | Team Possession | não testado neste modo |
| `0x0DA2` | Score For | não testado neste modo; já era candidato |
| `0x0EA2` | Score Against | não testado neste modo; já era candidato |

## Experimento controlado recomendado (BizHawk)

1. Registrar hash da ROM, versão do BizHawk, núcleo, domínio da memória e savestates de controle.
2. Tirar snapshots de WRAM com menu normal, menu do Challenge Mode e cada uma das seis modalidades em LV1–LV4.
3. Comparar alterações mantendo todo o restante fixo, sobretudo seleção, nível e início/fim da execução.
4. Repetir mudanças de menu para detectar falsos positivos causados por animações, cronômetros ou valores temporários.
5. Identificar tipo (byte/word, signed/unsigned), endianidade, domínio e possíveis offsets; registrar endereços **candidatos** com logs CSV antes de promovê-los a validados.
6. Verificar positivamente os 24 cenários e negativamente estados fora do Challenge Mode; só então integrar ao reconhecedor automático.

### Modelo para cada descoberta

```text
variavel:
dominio: WRAM
endereco: 0x????  # preencher somente apos observar
largura:
signedness:
endianidade:
rom_sha256:
bizhawk_versao:
captura_savestate:
valores_por_modo_e_nivel:
evidencias_csv:
status: candidato | validado | descartado
limitacoes:
```

**Critério de integridade:** não adicionar endereços inexistentes nem reclassificar como validados endereços que só foram comprovados em partidas convencionais.
