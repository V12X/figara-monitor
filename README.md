# Monitor Figara

Confere **a cada minuto** (GitHub Actions) se estão no ar:

- https://figaracare.com/ (site)
- https://capsula.figaracare.com/health/deep (Cápsula: aplicativo, banco e servidor de arquivos do Enzo)
- validade dos certificados HTTPS (avisa com 14 dias)

Se algo falhar 3 conferências seguidas (~3 min), abre **uma** issue "FORA DO AR" (o GitHub avisa por e-mail o dono do
repositório) e a fecha sozinha quando voltar. O repositório é público de propósito (Actions grátis e sem limite); ele só
contém endereços públicos, nenhum segredo.

Rodar na hora: aba Actions > Monitor Figara > Run workflow.

## Como funciona por dentro

O cron do GitHub é pouco confiável (medido: uma execução a cada 5 a 8 horas, não a cada 5 minutos). Por isso cada execução é um
**ciclo de ~5h45** que confere de minuto em minuto (`monitor.sh`) e, ao terminar, inicia o ciclo seguinte; o cron (a cada 30 min)
só serve para reiniciar a cadeia se ela tiver parado. Um commit "sinal de vida" por mês impede o GitHub de desligar o agendamento.
Testar o aviso: Run workflow com `simular_queda` marcado e `segundos` = 330.
