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
    fi
    #-----------------------------------------



    #----------- Menu de seleções ------------
    
    #-----------------------------------------



#-------------- Tratamento de erro ---------------
else
    echo "ERRO: O arquivo $arg não existe."
    exit 1
fi
#-------------------------------------------------



exit 0
