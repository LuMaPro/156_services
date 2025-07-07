#!/bin/bash


#----------------- Corpo inicial -----------------
arg=$1          #Parâmetro passado na linha de comando

echo "+++++++++++++++++++++++++++++++++++++++
Este programa mostra estatísticas do
Serviço 156 da Prefeitura de São Paulo
+++++++++++++++++++++++++++++++++++++++"

IFSOLD=$IFS     #Variável que guarda o valor original de 'IFS'
#-------------------------------------------------
                    


#---------------    Funções     ------------------
function baixa_arq {                        #Baixa os arquivos referentes a cada URL

    local inicio=$(date +%s)                #Marca o instante inicial
    local qtde_arq=0                        #Guarda a quantidade de arquivos baixados

    IFS=$'\n'
    
    for linha in $( cat $arg ); do          #Loop para baixar os arquivos de cada URL
        wget -nv "$linha" -P dados
        qtde_arq=$((qtde_arq + 1))
    done

    IFS=$IFSOLD

    local fim=$(date +%s)                   #Marca o instante final
    local tempo_total=$((fim - inicio))     #Guarda o tempo decorrido em segundos
    
    #Conversão do tempo decorrido para o formato minutos + segundos
    local min=$((tempo_total / 60))
    local seg=$((tempo_total % 60))

    #Chamada da função total_bytes e conversão do total de bytes para mega bytes
    local mbytes=$( bc <<< "scale=2; $(total_bytes) / 1024 / 1024")

    #Velocidade de download em MB/s
    local vel=$(echo "scale=2; $mbytes / $tempo_total" | bc)

    #Saída de texto
    echo "FINALIZADO --$(date '+%Y-%m-%d %H:%M:%S')--"
    echo "Tempo total decorrido: ${min}m ${seg}s"
    echo "Baixados: $qtde_arq arquivos, ${mbytes}M em ${min}m ${seg}s (${vel} MB/s)"
}

function total_bytes {                  #Calcula a quantidade total de bytes de todos os arquivos baixados

    local total=0                       #Guarda o total de bytes
    local temp=0                        #Guarda a quantidade de bytes do arquivo atual lido
    
    #Loop para calcular a quantidade total de bytes
    IFS=$'\n'
    
    for linha in $( ls dados | cat ); do 
        temp=$(wc -c dados/$linha | awk '{print $1}')
        total=$((temp + total))
    done

    IFS=$IFSOLD

    echo $total
}

function convert {                      #Faz a conversão dos arquivos para o padrão UTF8 

    #Loop para converter cada arquivo. Nesse processo, cria-se um ".csv" temporário
    #para garantir que a conversão seja bem sucedida, ou seja, o conteúdo da conver-
    #são só é passado ao arquivo original em caso de o comando anterior ao "&&" for
    #executado com êxito
    IFS=$'\n'
    
    for linha in $( ls dados | cat ); do
        iconv -f ISO-8859-1 -t UTF8 "dados/$linha" -o "dados/temp_$linha" && mv "dados/temp_$linha" "dados/$linha"
    done
    
    #Junção do conteúdo dos arquivos ".csv", já em padrão UTF8, em um novo arquivo
    #intitulado "arquivocompleto". Nesse caso, o count serve como controle para in-
    #clusão única da primeira linha, a qual é comum em todos os arquivos originais
    
    local count=0
    
    for linha in $( ls dados | cat); do
        if [ $count -eq 0 ]; then
            cat dados/$linha >> dados/arquivocompleto.csv
            ((count++))
        else
            tail -n +2 dados/$linha >> dados/arquivocompleto.csv
        fi
    done
    
    IFS=$IFSOLD

}

function vec_reset {
    
    #Função reseta o vetor de filtros
    for i in $( seq 1 20 ); do
        vec[i]=0
    done
}

function vec_print {
    
    #Função para printar os filtros atuais

    #Vetor auxiliar que associa os índices às colunas dos arquivos ".csv"
    local vec_aux=()
    vec_aux[1]="Data de abertura"
    vec_aux[2]="Canal"
    vec_aux[3]="Tema"
    vec_aux[4]="Assunto"
    vec_aux[5]="Serviço"
    vec_aux[6]="Logradouro"
    vec_aux[7]="Número"
    vec_aux[8]="CEP"
    vec_aux[9]="Subprefeitura"
    vec_aux[10]="Distrito"
    vec_aux[11]="Latitude"
    vec_aux[12]="Longitude"
    vec_aux[13]="Data do Parecer"
    vec_aux[14]="Status da solicitação"
    vec_aux[15]="Orgão"
    vec_aux[16]="Data"
    vec_aux[17]="Nível"
    vec_aux[18]="Prazo Atendimento"
    vec_aux[19]="Qualidade Atendimento"
    vec_aux[20]="Atendeu Solicitação"

    #Se o elemento correspondente ao índice não for "0", então
    #significa que tal índice corresponde a um filtro ativo
    for i in $( seq 1 20 ); do
        if [ "${vec[i]}" != "0" ]; then
            echo -n "${vec_aux[i]} = ${vec[i]} | "
        fi
    done

    echo 
}

function count_reclama {

    #Função para calcular a quantidade de reclamações, com
    #base nos filtros ativos.
    local resultado=$( cat dados/$arq_escol )
    
    for i in $( seq 1 20 ); do
        if [ "${vec[i]}" != "0" ]; then
            resultado=$( echo "$resultado" | grep "${vec[i]}" )
        fi
    done

    echo "$( echo "$resultado" | wc -l )"
}

function tempo_medio {

    #Função para calcular a duração média, em dias, de uma
    #reclamação, com base nos filtros ativos 
    local c_reclama=$( count_reclama )
    ((c_reclama++))
    local count=1
    
    local resultado=$( cat dados/$arq_escol )
    
    for i in $( seq 1 20 ); do
        if [ "${vec[i]}" != "0" ]; then
            resultado=$( echo "$resultado" | grep "${vec[i]}" )
        fi
    done

    local diferenca=0
    local tempo=0

    until [ $count == $c_reclama ]; do
        
        local data1=$(echo "$resultado" | cut -d';' -f1 | sed -n "${count}p" )
        local data2=$(echo "$resultado" | cut -d';' -f13 | sed -n "${count}p" )

        local tempo1=$(date -d "$data1" +%s)
        local tempo2=$(date -d "$data2" +%s)

        #Calcula a diferença em segundos
        diferenca=$((tempo2 - tempo1))
        tempo=$((tempo + diferenca))

        ((count++))
    done

    #Conversão de segundos para dias
    local media_dias=$( bc <<< "$tempo / 86400 / $( count_reclama )")

    echo "+++ Duração média da reclamação: $media_dias dias"
    echo "+++++++++++++++++++++++++++++++++++++++"
}

function rank_reclama {
    
    #Função para listar as cinco categorias, baseadas no
    #filtro de coluna, com mais reclamações
    local resultado=$( cat dados/$arq_escol )

    for i in $( seq 1 20 ); do
        if [ "${vec[i]}" != "0" ]; then
            resultado=$( echo "$resultado" | grep "${vec[i]}" )
        fi
    done
    echo "+++ Serviço com mais reclamações:"
    echo "$( echo "$resultado" | cut -d';' -f$col_escol | sort | uniq -c | sort -nr | head -n5 )"
    echo "+++++++++++++++++++++++++++++++++++++++" 

}

function mostra_reclama {

    #Função para listar as reclamações, com base nos
    #filtros ativos
    local resultado=$( cat dados/$arq_escol )

    for i in $( seq 1 20 ); do
        if [ "${vec[i]}" != "0" ]; then
            resultado=$( echo "$resultado" | grep "${vec[i]}" )
        fi
    done

    echo "$resultado"
    echo "+++ Arquivo atual: $arq_escol"
    echo "+++ Filtros atuais:"
    vec_print
    echo "+++ Número de reclamações: $( count_reclama )"
    echo "+++++++++++++++++++++++++++++++++++++++"
}

function valor_filtro {
    
    #Função para listar os valores dos filtro considerado,
    #com base nos filtros ativos
    local resultado=$( tail -n +2 dados/$arq_escol )

    IFS=$'\n' 
    
    for i in $( seq 1 20 ); do
        if [ "${vec[i]}" != "0" ]; then
            resultado=$( echo "$resultado" | grep "${vec[i]}" )
        fi
    done

    IFS=' '
    resultado=$( echo "$resultado" | cut -d';' -f$col_escol | sort | uniq )

    local teste=$( echo "$resultado" | tr -d '\r' )

    echo $teste

    IFS=$IFSOLD
}
#-------------------------------------------------



#------- Inicialização do vetor de filtros ------- 
vec=()
vec_reset
#-------------------------------------------------



#---------------Corpo principal---------------
if [[ "$arg" == "" || -e "$arg" ]]; then
    
    
    
    #--------- Download dos arquivos ---------
    if [ -e "$arg" ]; then
        baixa_arq
        convert
    fi
    #-----------------------------------------

    

    #---------- Tratamento de erro -----------
    if [ ! -d "dados" ]; then
    
        echo "ERRO: Não há dados baixados."
        echo "Para baixar os dados antes de gerar as estatísticas, use:"
        echo "    ./ep2_servico156.sh <nome do arquivo com URLs de dados do Serviço 156>"
        exit 1
    #-----------------------------------------



    #----------- Menu de seleções ------------
    else
        arq_escol="arquivocompleto.csv"
        OPCOES="selecionar_arquivo adicionar_filtro_coluna limpar_filtros_colunas mostrar_duracao_media_reclamacao mostrar_ranking_reclamacoes mostrar_reclamacoes sair"
        echo
        
        until [ "$opt" == "sair" ]; do
            echo "Escolha uma opção de operação:"
            
            select opt in $OPCOES; do
                if [ "$opt" == "selecionar_arquivo" ]; then
                    echo
                    echo "Escolha uma opção de arquivo:"
                    OPCOES_ARQ=$( ls dados )
                    
                    select opt_arq in $OPCOES_ARQ; do
                        vec_reset
                        arq_escol=$opt_arq    
                        echo "+++ Arquivo atual: $arq_escol"
                        echo "+++ Número de reclamações: $( tail -n +2 dados/$arq_escol | wc -l )"
                        echo "+++++++++++++++++++++++++++++++++++++++"
                        break
                    done
                
                elif [ "$opt" == "adicionar_filtro_coluna" ]; then
                    echo
                    echo "Escolha uma opção de coluna para o filtro:"
                    IFS=";"
                    OPCOES_COL=$( head -n 1 dados/$arq_escol | tr -d '\r' )
                    
                    select opt_col in $OPCOES_COL; do
                        col_escol=$REPLY
                        break
                    done
                    
                    IFS=$'\n'
                    echo
                    echo "Escolha uma opção de valor para $opt_col:"
                    OPCOES_FIL=$( valor_filtro )
                    
                    select opt_fil in $OPCOES_FIL; do
                        fil_escol=$opt_fil
                        break
                    done
                    
                    IFS=$IFSOLD
                    vec[$col_escol]="$fil_escol"
                    
                    echo "+++ Adicionado filtro: $opt_col = $fil_escol"
                    echo "+++ Arquivo atual: $arq_escol"
                    echo "+++ Filtros atuais:" 
                    vec_print
                    echo "+++ Número de reclamações: $( count_reclama )"
                    echo "+++++++++++++++++++++++++++++++++++++++"
                
                elif [ "$opt" == "limpar_filtros_colunas" ]; then
                    vec_reset
                    echo "+++ Filtros removidos"
                    echo "+++ Arquivo atual: $arq_escol"
                    echo "+++ Número de reclamações: $( tail -n +2 dados/$arq_escol | wc -l )"
                    echo "+++++++++++++++++++++++++++++++++++++++"
            
                elif [ "$opt" == "mostrar_duracao_media_reclamacao" ]; then
                    tempo_medio                
                
                elif [ "$opt" == "mostrar_ranking_reclamacoes" ]; then
                    echo
                    echo "Escolha uma opção de coluna para análise:"
                    IFS=";"
                    OPCOES_COL=$( head -n 1 dados/$arq_escol )
                    
                    select opt_col in $OPCOES_COL; do
                        col_escol=$REPLY
                        break
                    done
                    
                    IFS=$IFSOLD
                    rank_reclama
               
                elif [ "$opt" == "mostrar_reclamacoes" ]; then
                    mostra_reclama
                
                elif [ "$opt" == "sair" ]; then
                    echo "Fim do programa"
                    echo "+++++++++++++++++++++++++++++++++++++++"
                fi
                break
            done
            echo
        done    
        exit 1
    fi
    #-----------------------------------------



#-------------- Tratamento de erro ---------------
else
    echo "ERRO: O arquivo $arg não existe."
    exit 1
fi
#-------------------------------------------------



exit 0
