# Sem API Lua de savestate: procedimento manual

Se a sonda retornar `BizHawk snapshot unavailable`, significa que o ambiente
Lua atual não expõe as interfaces `memorysavestate` e `savestate`.
Na sonda `probes/diagonal_risk_comparison.lua`, configure:

```lua
local MANUAL_ACTION="UP_B"
```

Carregue **pela interface do EmuHawk** um mesmo savestate em que `$0800`
esteja com a posse individual, com partida ativa. Execute a sonda sem `main.lua`.
O arquivo `diagonal_risk_UP_B.csv` será gerado e a partida avançará 120 frames.
**O modo manual não restaura automaticamente o estado.**

Depois, pare a sonda, altere `MANUAL_ACTION` para `DOWN_B`, recarregue
**o mesmo savestate** pela interface do EmuHawk e execute novamente.
Repita para `RIGHT_A`, sempre a partir do mesmo ponto.
Serão produzidos três arquivos separados. Não renomeie nem concatene os CSVs
como se fossem uma captura automática única sem conferir a equivalência
do estado inicial.

O modo de três ações automáticas permanece disponível se a API Lua de
savestate existir. Para diagnóstico de disponibilidade das bibliotecas:
```lua
print("memorysavestate",type(memorysavestate),
  memorysavestate and type(memorysavestate.savecorestate))
print("savestate",type(savestate),
  savestate and type(savestate.save))
```

Este fallback não modifica a política tática nem altera valores de RAM.
