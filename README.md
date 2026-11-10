# Monitor Figara

Confere a cada 5 minutos (GitHub Actions) se estão no ar:

- https://figaracare.com/ (site)
- https://capsula.figaracare.com/health/deep (Cápsula: aplicativo, banco e servidor de arquivos do Enzo)
- validade dos certificados HTTPS (avisa com 14 dias)

Se algo falhar 3 vezes seguidas (com 20 s de pausa), abre **uma** issue "FORA DO AR" (o GitHub avisa por e-mail o dono do
repositório) e a fecha sozinha quando voltar. O repositório é público de propósito (Actions grátis e sem limite); ele só
contém endereços públicos, nenhum segredo.

Rodar na hora: aba Actions > Monitor Figara > Run workflow.
