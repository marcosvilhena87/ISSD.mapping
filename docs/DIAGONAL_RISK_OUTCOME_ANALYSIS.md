# Análise pareada dos três comandos

Execute `probes/diagonal_risk_comparison.lua` em estados independentes com
`$0800` em posse. Salve cada resultado com nome diferente; o script Lua
sobrescreve seu CSV original a cada execução. Execute, por exemplo:

```bash
python tools/diagonal_risk_outcomes.py captures/*.csv --output diagonal_risk_outcomes.csv
```

O analisador exige que cada arquivo contenha as três ações
`UP_B` ($0B00), `DOWN_B` ($0C00) e `RIGHT_A` (desafogo);
dados incompletos são rejeitados, evitando comparação de estados diferentes.
Ele compara o primeiro sinal de posse individual da CPU com o primeiro
sinal de posse do receptor após o frame zero. Também registra distâncias
mínimas à bola, ao receptor e deslocamento máximo.

Os rótulos `TARGET_OWNER_FIRST`, `CPU_OWNER_FIRST` e `UNRESOLVED`
são **sinais observados** e não certificam fisicamente contato ou recepção.
O desfecho sem receptor do `RIGHT_A` pode ser inconclusivo mesmo se um
companheiro diferente recuperar a bola; consulte `final_owner` e o CSV
bruto. Não use um resultado isolado para liberar passes arriscados.
Para conclusão robusta, repita em vários estados iniciais e calibre
também a duração do botão para reproduzir o teste manual.
