# Janela empírica de recepção UP+B

Captura `diagonal_risk_UP_B.csv`: passe de `$0800` para `$0B00`, primeiro sinal de posse do receptor no frame 19 e nenhum sinal de posse da CPU até o frame 120. Isso é uma **amostra**, não uma taxa de sucesso.

A implementação adiciona uma janela experimental muito restrita em `DIAGONAL_PASS_EMPIRICAL_OVERRIDE_GUARDED.reception_pocket`, restrita ao portador `$0800`, receptor `$0B00`, sentido de ataque para a direita, zona defensiva e ausência de passe seguro pelo planejador principal. A posição inicial do portador é comparada à posição observada (83,296), a geometria ao caso (avanço 142; lateral superior 20). Mesmo na janela, verifica pressão próxima ao portador e mínimos explícitos de corredor, pressão do receptor e margem estimada de chegada.

**Por padrão `enabled=false`.** Somente habilite temporariamente num ambiente de teste controlado:
```lua
M.DIAGONAL_PASS_EMPIRICAL_OVERRIDE_GUARDED.reception_pocket.enabled=true
```
Atenção: `enabled` é definido dentro da tabela `reception_pocket`; altere no bloco `config.lua`. Isso pode aceitar um passe rejeitado por filtros globais. Recolha novos relatórios e verifique `DIAGONAL_OVERRIDE_CANDIDATE`, `DIAGONAL_OVERRIDE_FIRED` e o resultado da posse. Desative se houver regressão.

Não se generaliza ao `$0C00`, nem se alteram os limites globais de segurança. Para liberação permanente, repita capturas independentes no mesmo contexto e investigue o efeito da pressão adversária.
