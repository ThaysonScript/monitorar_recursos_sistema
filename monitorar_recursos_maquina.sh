#!/usr/bin/env bash

################################################################################################## SOBRE
# Fazer o que: monitorar recursos gerais de uma maquina ou servidor
# recursos: monitorar cpu, processos, memoria, disco, rede, registrar data e hora, fazer logs de registro e execuções do programa

################################################################################################## VARIAVEIS GLOBAIS

################################################################################################## FUNCOES
MONITORAR_CPU()
{
	cpu_monitoramento=()

	echo -e "\n------------------------------------ CPU MONITOR  ------------------------------------------"
	top=$(top -n 1 -b | grep "top")
	cpu_monitoramento[0]=$top

	tarefas=$(top -n 1 -b | grep "Tarefas")
	cpu_monitoramento[1]=$tarefas

	uso_cpu=$(top -n 1 -b | grep "%CPU(s)")
	cpu_monitoramento[2]=$uso_cpu

	echo -e "${cpu_monitoramento[0]:0:65}\n${cpu_monitoramento[1]}\n${cpu_monitoramento[2]}"
}

MONITORAR_PROCESSOS()
{
	echo -e "\n--------------------------------------- PROCESSOS ------------------------------------------"
	saida_processos_uso_memoria=$(top -n 1 -o RES -b | awk 'NR > 6 && $6 > 0 {res_mb = $6 / 1024; printf "%-8s %-10s %-5s %-5s %-8s %10.2fMB    %-10s %-5s %-5s %-5s %-10s %s\n", $1, $2, $3, $4, $5, res_mb, $7, $8, $9, $10, $11, $12}')


	if [[ -n "$saida_processos_uso_memoria" ]]; then
        	echo "$cabecalho_processos"
        	echo "$saida_processos_uso_memoria"
    	else
        	echo "Processos não encontrados na saída do comando 'ps'."
        	return 1
    	fi
}

MONITORAR_MEMORIA()
{
	echo -e "\n--------------------------------- MEMORIA MONITOR --------------------------------------"
	uso_memoria=$(ps -eo pid,%mem,rss,cmd --sort=-%mem | awk '$3 > 0 {rss_mb = $3 / 1024; printf "%-5s %-5s %10.2fMB %s\n", $1, $2, rss_mb, $4}')
	echo "$uso_memoria"
}

MONITORAR_DISCO()
{
	echo -e "\n--------------------------------- DISC MONITOR -----------------------------------------"
	uso_disco=$(df -hT)
	echo "$uso_disco"
}

MONITORAR_REDE()
{
	echo -e "\n--------------------------------- NETWORKING MONITOR -----------------------------------"
	rede=$(ip addr show)
	route=$(ip route show)
	echo -e "Rede: $rede\n\nRotas: $route"
}

REGISTRAR_DATA_HORA()
{
	nome_dia=$( date +%A )
	hora_minuto_segundo=$( date +%T )

	data=$( date +"%d/%m/%Y")

	echo -e "\n------------------------------------ TEMPO REGISTRO -----------------------------------------"
	echo -e "( dia da semana ): $nome_dia\n( dia/mes/ano ): $data\n( Hora:Minuto:Segundo ): $hora_minuto_segundo\n"
	echo -e "executado as $hora_minuto_segundo do dia $data\n---------------------------------------------------------------"
}

REGISTRAR_LOGS()
{
	local cpu=$1
	local processos=$2
	local memoria=$3
	local disco=$4
	local rede=$5
	local data=$6

	local dados="$cpu\n$processos\n$memoria\n$disco\n$rede\n$data"
	[[ -f "logs/log.txt" ]] && arquivo_valido=0 || arquivo_valido=1

	if [[ -d "logs" ]]; then
		[[ "$arquivo_valido" -eq 0 ]] && echo -e "$dados" >> logs/log.txt || echo -e "$dados" > logs/log.txt
	else
		mkdir logs
		[[ "$arquivo_valido" -eq 0 ]] && echo -e "$dados" >> logs/log.txt || echo -e "$dados" > logs/log.txt
	fi
}

REGISTRAR_EXECUCOES()
{
	[[ -f "registros/execucoes.txt" ]] && arquivo_valido=0 || arquivo_valido=1

	[[ "$arquivo_valido" -eq 0 ]] && quantidade_execucoes=$( cat registros/execucoes.txt ) || echo erro

	echo "${quantidade_execucoes: -2}"
}

LIMPAR_LOGS()
{
	local execucoes=$(registrar_execucoes)

	if [[ "$execucoes" -ge 5 ]]; then
		local monitores="logs/log.txt"
		local quantidade="executado"
		local ocorrencia=$(grep -c "$quantidade" "$monitores")

		[[ "$ocorrencia" -eq 10 ]] && echo "precisa fazer limpeza de logs" || echo "nao precisa de limpeza: $ocorrencia"
	fi
}

################################################################################################## PROGRAMA PRINCIPAL
MAIN()
{
	local registros=0

	clear
	while true; do
		echo "Iniciando monitoramento de recursos do sistema, pressione (ctrl + c) para sair!"

		MONITORAR_CPU && cpu=$(MONITORAR_CPU)

		MONITORAR_PROCESSOS && processos=$(MONITORAR_PROCESSOS)

		MONITORAR_MEMORIA && memoria=$(MONITORAR_MEMORIA)

		MONITORAR_DISCO && disco=$(MONITORAR_DISCO)

		MONITORAR_REDE && rede=$(MONITORAR_REDE)

		REGISTRAR_DATA_HORA && data=$(REGISTRAR_DATA_HORA)

		REGISTRAR_LOGS "$cpu $processos $memoria $disco $rede $data"

		[[ -f "registros/execucoes.txt" ]] && quantidade_execucoes=$( cat registros/execucoes.txt )

		if [[ "$quantidade_execucoes" != 1 && -f "registros/execucoes.txt" ]]; then
			ultimo_registro=$( cat registros/execucoes.txt )
			registros="${ultimo_registro: -2}"
			registros=$(( registros + 1 ))
		else
			registros=$(( registros + 1 ))
		fi

		if [[ -d "registros" ]]; then
			echo "$registros" >> registros/execucoes.txt

		else
			mkdir registros

			echo "$registros" > registros/execucoes.txt
		fi

		REGISTRAR_EXECUCOES
		LIMPAR_LOGS

		sleep 5
		clear
	done

}

MAIN
