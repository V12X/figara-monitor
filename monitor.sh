#!/bin/bash
# Confere o site, a Cápsula (aplicativo + banco + servidor do Enzo) e os certificados a cada minuto,
# durante ~5h45, abrindo UM aviso (issue) por queda e fechando quando voltar.
# Por que um laço e não o cron de 5 em 5 min: o GitHub atrasa muito os agendamentos (medido: 1 execução a cada 5 a 8 horas).
set -u
DURACAO=${MONITOR_SEGUNDOS:-20700}
ALVO=${ALVO_SITE:-https://figaracare.com/}
FIM=$(( $(date +%s) + DURACAO ))
falhas=0; aberto=0; volta=0; n=0

checar() { # preenche $problemas (vazio = tudo ok)
  problemas=""
  for t in 1 2; do
    c=$(curl -s -m 15 -A "figara-monitor/1.0" -o /dev/null -w "%{http_code}" "$ALVO" || true)
    [ "$c" = "200" ] && break; sleep 5
  done
  [ "$c" = "200" ] || problemas="${problemas}- Site figaracare.com: HTTP ${c:-sem resposta}"$'\n'
  for t in 1 2; do
    out=$(curl -s -m 15 -A "figara-monitor/1.0" -w "\n%{http_code}" https://capsula.figaracare.com/health/deep || true)
    c=$(printf "%s" "$out" | tail -n1); b=$(printf "%s" "$out" | sed '$d')
    [ "$c" = "200" ] && printf "%s" "$b" | grep -q '"status":"ok"' && break; sleep 5
  done
  if ! { [ "$c" = "200" ] && printf "%s" "$b" | grep -q '"status":"ok"'; }; then
    problemas="${problemas}- Cápsula (aplicativo, banco ou servidor do Enzo): HTTP ${c:-sem resposta} ${b:0:120}"$'\n'
  fi
}

certificados() {
  for h in figaracare.com capsula.figaracare.com; do
    fim=$(echo | openssl s_client -servername $h -connect $h:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -z "$fim" ]; then problemas="${problemas}- Certificado de $h: não foi possível ler"$'\n'; continue; fi
    dias=$(( ( $(date -d "$fim" +%s) - $(date +%s) ) / 86400 ))
    [ "$dias" -lt 14 ] && problemas="${problemas}- Certificado de $h vence em $dias dia(s)"$'\n'
  done
}

abrir_aviso() {
  n_=$(gh issue list --state open --label queda --json number --jq '.[0].number // empty')
  if [ -z "$n_" ]; then
    gh label create queda --color B60205 --description "Serviço fora do ar" 2>/dev/null || true
    gh issue create --title "FORA DO AR: Figara ($(date -u '+%d/%m %H:%M') UTC)" --label queda \
      --body "Detectado em $(date -u '+%d/%m/%Y %H:%M') UTC (3 conferências seguidas):"$'\n\n'"$problemas" >/dev/null && echo "aviso aberto"
  fi
  aberto=1
}
fechar_avisos() {
  for x in $(gh issue list --state open --label queda --json number --jq '.[].number'); do
    gh issue comment "$x" --body "Voltou ao normal em $(date -u '+%d/%m/%Y %H:%M') UTC." >/dev/null
    gh issue close "$x" >/dev/null && echo "aviso #$x fechado"
  done
  aberto=0
}

while [ "$(date +%s)" -lt "$FIM" ]; do
  checar
  if [ $(( n % 60 )) -eq 0 ]; then certificados; fi   # certificados: a cada hora
  n=$((n+1))
  if [ -n "$problemas" ]; then
    falhas=$((falhas+1)); volta=0
    echo "[$(date -u +%H:%M:%S)] FALHA $falhas: $problemas"
    [ "$falhas" -ge 3 ] && [ "$aberto" -eq 0 ] && abrir_aviso
  else
    falhas=0; volta=$((volta+1))
    # 2 conferências boas seguidas depois de uma queda: fecha o aviso
    if [ "$volta" -ge 2 ] && { [ "$aberto" -eq 1 ] || [ "$(gh issue list --state open --label queda --json number --jq 'length')" != "0" ]; }; then fechar_avisos; fi
  fi
  sleep 60
done
echo "fim do ciclo"
