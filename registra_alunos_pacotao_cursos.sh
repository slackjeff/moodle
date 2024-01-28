#!/usr/bin/env bash
#####################################################################
# AUTOR:
#   Jefferson Carneiro
# DESCRIÇÃO:
#   Registra usuário no pacotão dos cursos e gera um arquivo .csv
#   Envia para o servidor via scp e executa o comando:
#   uploaduser.php. É necessário chave ssh.
#
# CHANGELOG:
#   (28/01/2024)
#   - Reformulado parte de inserção de curso para deixar dinamico,
#     sem muita interveção manual.
#
#   (23/10/2022)
#   - Adicionado novo curso: vagrant
#   - Adicionado opção para enviar o arquivo csv para o servidor
#     e registra usuário atráves do comando uploaduser.php
#####################################################################
set -e

# Carregando arquivo de configuração.
source registra_alunos_pacotao_cursos.conf

#####################################################################
# Cursos
#####################################################################
# Adicione os cursos de acordo com o nome cadastrado no moodle!
# Um curso por linha englobado em aspas simples.
courses=(
          'html_css'
          'editor_gnu_nano'
          'crie_o_seu_gerenciador_de_pacotes'
          'aprenda_a_compilar'
          'Slackware_essentials_14.2'
          'shell_script_avancado'
          'iniciantes_no_terminal'
          'administracao_servidor_vps_debian'
          'darkweb'
          'vagrant'
)

#####################################################################
# Testes e criações
#####################################################################

# Cria arquivo se não existe.
[[ ! -e $arquivo_final ]] && :> $arquivo_final

# Gerando lista de cursos necessários para cadastro.
len=${#courses[*]} # Capturando quantindade.

for ((p=1; $p<=$len; p++)); do
    courses_numbers+="course$p;" # Incrementando
done
courses_numbers=${courses_numbers[@]%;} # Removendo última da linha;
# Substituindo espaços por ; que é o padrão da lista csv do moodle.
courses=($(sed 's/ /;/g' <<< ${courses[@]}))
courses="${courses%;}" # Removendo última da linha;

clear
cat << 'EOF'
 ____  _            _     _       __  __   ____                 _
/ ___|| | __ _  ___| | __(_) ___ / _|/ _| |  _ \ __ _  ___ ___ | |_ __ _  ___
\___ \| |/ _` |/ __| |/ /| |/ _ \ |_| |_  | |_) / _` |/ __/ _ \| __/ _` |/ _ \
 ___) | | (_| | (__|   < | |  __/  _|  _| |  __/ (_| | (_| (_) | || (_| | (_) |
|____/|_|\__,_|\___|_|\_\/ |\___|_| |_|   |_|   \__,_|\___\___/ \__\__,_|\___/
                       |__/
EOF

while true
do
    # Input para pegar dados do usuário
    read -ep "Digite o E-mail do Usuário: " email
    [[ -z "$email" ]] && { echo "Campo E-MAIL não preenchido."; exit 1 ;}

    read -ep "Nome do Usuário: " nome
    [[ -z "$nome" ]] && { echo "Campo Nome não preenchido."; exit 1 ;}

    read -ep "Sobrenome do Usuário: " sobrenome
    [[ -z "$sobrenome" ]] && { echo "Campo Sobrenome não preenchido."; exit 1 ;}

    # Criando arquivo CSV corretamente para o moodle entender quantos cursos são...
    if ! grep -q "^username" $arquivo_final; then
        #echo "username;firstname;lastname;email;course1;course2;course3;course4;course5;course6;course7;course8;course9;course10" >> $arquivo_final
        echo "username;firstname;lastname;email;${courses_numbers[@]}" >> $arquivo_final
    fi

    # Enviando para arquivo CSV.
    #echo "$email;$nome;$sobrenome;$email;html_css;editor_gnu_nano;crie_o_seu_gerenciador_de_pacotes;aprenda_a_compilar;Slackware_essentials_14.2;shell_script_avancado;iniciantes_no_terminal;administracao_servidor_vps_debian;darkweb;vagrant" >> $arquivo_final
    echo "$email;$nome;$sobrenome;$email;${courses[@]}" >> $arquivo_final
    echo "$nome - REGISTRADO COM SUCESSO NO PACOTÃO DE CURSOS..."
    echo

    # Vamos cadastrar mais algum aluno?
    read -ep "Registrar mais algum aluno? [y/N]: " continua
    continua=${continua,,}  # tudo em minusculo
    continue=${continua:=n} # Defina resposta padrão como n
    [[ $continua = y ]] && continue || break
done

# Enviando para o servidor o arquivo aluno.csv
# e registrando na plataforma.
echo "Enviando arquivo $arquivo_final para servidor..."
scp -P $port_server $arquivo_final $user_server@${domain_server}:/tmp/
echo
echo "Registrando/atualizando aluno em $domain_server..."
ssh -p $port_server $user_server@$domain_server '/usr/bin/php /var/www/html/area-do-aluno/admin/tool/uploaduser/cli/uploaduser.php --file=/tmp/aluno.csv --uutype=2 --uupasswordnew=1; rm /tmp/aluno.csv'

printf "Removendo arquivo $arquivo_final da máquina local..." && rm $arquivo_final || printf '[FAIL]' && printf '[OK]\n'
