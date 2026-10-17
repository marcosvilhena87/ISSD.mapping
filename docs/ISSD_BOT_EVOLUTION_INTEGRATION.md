# Integração do ISSD_bot — atualização de 17/10/2026

O projeto `ISSD_bot.v0` mantém seu controlador operacional em `tools/bizhawk/issd/main.lua`.
O laboratório de evolução [ISSD_bot](https://github.com/marcosvilhena87/ISSD_bot) foi incluído como **submódulo Git** em `experimental/ISSD_bot`, atualizado para o commit `4684f275dc327eb2f1538fc210a9c16dbbabaccb` (referência fixa e reproduzível).

## O que foi incorporado

O submódulo contém o `main.lua` independente e seus módulos de leitura WRAM, perseguição, passes progressivos e de apoio, modo combinado, Dash (Y), troca de jogador, telemetria e contadores de partida, calibração de direção e receptores, monitoramento de companheiros, radar completo e geometria dependente de estádio, com seus testes e documentação. A atualização de 17/10/2026 também traz o módulo específico de distribuição do goleiro, a automação B + direcional (`gk_auto_actuator.lua`), observação de resultados (`gk_auto_result_observer.lua`), inicialização em `lua/gk_auto_start.lua` carregada por `main.lua`, calibrador de passes direcionais, telemetria tática e radar mais limpo.

## Instalação

Clone com `git clone --recurse-submodules https://github.com/marcosvilhena87/ISSD_bot.v0.git` ou, em um clone existente:

```bash
git pull --ff-only
git submodule update --init --recursive
```

## Operação segura

- **Controlador principal (inalterado):** execute `tools/bizhawk/issd/main.lua` no Lua Console.
- **Laboratório importado:** execute **somente** `experimental/ISSD_bot/main.lua` no Lua Console, após ler `experimental/ISSD_bot/README.md`. As configurações de controle ativo do laboratório constam do início desse arquivo.
- **Nunca execute os dois loops simultaneamente:** os dois podem enviar entradas à porta 1 do BizHawk.
- A integração **não** altera automaticamente a tática, o overlay, as rotinas de passe nem o CSV do controlador principal. As evoluções estão disponibilizadas como implementação isolada para testes e migração gradual.

## Atualização futura

O commit do submódulo é fixo e reproduzível. Para atualizar deliberadamente:

```bash
git -C experimental/ISSD_bot fetch origin main
git -C experimental/ISSD_bot checkout origin/main
git add experimental/ISSD_bot
git commit -m "chore: atualiza laboratorio ISSD_bot"
```

Execute os testes do laboratório usando o interpretador Lua no diretório adequado e valide em BizHawk antes de migrar módulos para o controlador principal. Um teste de integração funcional entre as arquiteturas **não** foi executado aqui.
