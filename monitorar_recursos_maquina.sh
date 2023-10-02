#!/usr/bin/env bash

# Crie um único script para monitorar os recursos gerais do computador: CPU, memória, disco e rede, e constar a data e hora 
# em que foi coletado. A coleta de dados precisa ser realizada a cada 5 segundos.

monitorar_cpu()
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

monitorar_processos()
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

monitorar_memoria()
{
	echo -e "\n--------------------------------- MEMORIA MONITOR --------------------------------------"
	uso_memoria=$(ps -eo pid,%mem,rss,cmd --sort=-%mem | awk '$3 > 0 {rss_mb = $3 / 1024; printf "%-5s %-5s %10.2fMB %s\n", $1, $2, rss_mb, $4}')
	echo "$uso_memoria"
}

monitorar_disco()
{
	echo -e "\n--------------------------------- DISC MONITOR -----------------------------------------"
	uso_disco=$(df -hT)
	echo "$uso_disco"
}

monitorar_rede()
{
	echo -e "\n--------------------------------- NETWORKING MONITOR -----------------------------------"
	rede=$(ip addr show)
	route=$(ip route show)
	echo -e "Rede: $rede\n\nRotas: $route"
}

registrar_data_hora()
{
	nome_dia=$( date +%A )
	hora_minuto_segundo=$( date +%T )

	data=$( date +"%d/%m/%Y")

	echo -e "\n------------------------------------ TEMPO REGISTRO -----------------------------------------"
	echo -e "( dia da semana ): $nome_dia\n( dia/mes/ano ): $data\n( Hora:Minuto:Segundo ): $hora_minuto_segundo\n"
	echo -e "executado as $hora_minuto_segundo do dia $data\n---------------------------------------------------------------"
}

registrar_logs()
{
	cpu=$1
	processos=$2
	memoria=$3
	disco=$4
	rede=$5
	data=$6

	dados="$cpu\n$processos\n$memoria\n$disco\n$rede\n$data"
	[[ -f "logs/log.txt" ]] && arquivo_valido=0 || arquivo_valido=1

	if [[ -d "logs" ]]; then
		[[ "$arquivo_valido" -eq 0 ]] && echo -e "$dados" >> logs/log.txt || echo -e "$dados" > logs/log.txt
	else
		mkdir logs
		[[ "$arquivo_valido" -eq 0 ]] && echo -e "$dados" >> logs/log.txt || echo -e "$dados" > logs/log.txt
	fi
}

registrar_execucoes()
{
	[[ -f "registros/execucoes.txt" ]] && arquivo_valido=0 || arquivo_valido=1

	[[ "$arquivo_valido" -eq 0 ]] && quantidade_execucoes=$( cat registros/execucoes.txt ) || echo erro

	echo "${quantidade_execucoes: -2}"
}

limpar_logs()
{
	execucoes=$(registrar_execucoes)

	if [[ "$execucoes" -ge 5 ]]; then
		monitores="logs/log.txt"
		quantidade="executado"
		ocorrencia=$(grep -c "$quantidade" "$monitores")

		[[ "$ocorrencia" -eq 10 ]] && echo "precisa fazer limpeza de logs" || echo "nao precisa de limpeza: $ocorrencia"
	fi
}

main()
{
	registros=0

	clear
	while true; do
		echo "Iniciando monitoramento de recursos do sistema, pressione (ctrl + c) para sair!"

		monitorar_cpu && cpu=$(monitorar_cpu)

		monitorar_processos && processos=$(monitorar_processos)

		monitorar_memoria && memoria=$(monitorar_memoria)

		monitorar_disco && disco=$(monitorar_disco)

		monitorar_rede && rede=$(monitorar_rede)

		registrar_data_hora && data=$(registrar_data_hora)

		registrar_logs "$cpu $processos $memoria $disco $rede $data"

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

		registrar_execucoes
		limpar_logs

		sleep 5
		clear
	done

}

main
