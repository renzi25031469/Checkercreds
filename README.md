<p align="center">
<pre>
 ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗  ██████╗██████╗ ███████╗██████╗ ███████╗
██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝
██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝██║     ██████╔╝█████╗  ██║  ██║███████╗
██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗██║     ██╔══██╗██╔══╝  ██║  ██║╚════██║
╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║╚██████╗██║  ██║███████╗██████╔╝███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝
</pre>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/bash-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white"/>
  <img src="https://img.shields.io/badge/hydra-required-red?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/linux-supported-green?style=for-the-badge&logo=linux&logoColor=white"/>
  <img src="https://img.shields.io/badge/licença-MIT-blue?style=for-the-badge"/>
</p>

<p align="center">
  <b>Default Credentials Checker — Hydra</b><br/>
  <b>Verificador automatizado de credenciais padrão via SSH, Telnet e RDP usando Hydra.</b><br/><br/>
  <i>⚠ Use somente em sistemas próprios ou com autorização expressa. ⚠</i>
</p>

---

## 📌 Sobre

O **Checkercreds** é uma ferramenta de linha de comando escrita em Bash para auditorias de segurança. Ela testa automaticamente listas de hosts contra um conjunto de credenciais padrão (default) amplamente conhecidas, nos protocolos **SSH**, **Telnet** e **RDP**, usando o **Hydra** como motor de força bruta.

Ideal para pentesters e sysadmins que precisam identificar rapidamente dispositivos ou servidores com credenciais fracas em sua infraestrutura.

---

## ✨ Funcionalidades

- ✅ Suporte a múltiplos hosts em paralelo
- ✅ Testa SSH (porta 22), Telnet (porta 23) e RDP (porta 3389)
- ✅ Lista de usuários e senhas padrão embutida
- ✅ Relatório consolidado ao final da execução
- ✅ Logs separados por protocolo
- ✅ Banner centralizado e adaptável ao tamanho do terminal
- ✅ Opções para pular protocolos individualmente

---

## 📋 Pré-requisitos

| Dependência | Instalação                   |
|-------------|------------------------------|
| `bash`      | já incluso na maioria dos sistemas Linux |
| `hydra`     | `sudo apt install hydra`     |
| `tput`      | já incluso (pacote `ncurses`) |

---

## 🚀 Uso

```bash
./checkercreds.sh -i <arquivo_hosts> [opções]
```

### Opções

| Flag           | Descrição                                      |
|----------------|------------------------------------------------|
| `-i <arquivo>` | Arquivo com hosts alvo, um por linha **(obrigatório)** |
| `-o <dir>`     | Diretório de saída dos resultados              |
| `-t <n>`       | Tasks paralelas do Hydra (padrão: `4`)         |
| `-S`           | Pular verificação SSH                          |
| `-T`           | Pular verificação Telnet                       |
| `-R`           | Pular verificação RDP                          |
| `-h`           | Exibe a ajuda                                  |

### Exemplos

```bash
# Verificação completa em uma lista de hosts
./checkercreds.sh -i hosts.txt

# Definir diretório de saída e aumentar paralelismo
./checkercreds.sh -i hosts.txt -o /tmp/resultado -t 8

# Testar somente RDP (pular SSH e Telnet)
./checkercreds.sh -i hosts.txt -S -T

# Exibir ajuda
./checkercreds.sh -h
```

### Formato do arquivo de hosts (`hosts.txt`)

```
192.168.1.1
192.168.1.10
10.0.0.5
servidor.interno
```

---

## 📁 Estrutura de saída

```
output_default_creds_YYYYMMDD_HHMMSS/
├── ssh/
│   └── results.txt        # Credenciais encontradas via SSH
├── telnet/
│   └── results.txt        # Credenciais encontradas via Telnet
├── rdp/
│   └── results.txt        # Credenciais encontradas via RDP
├── logs/
│   ├── ssh.log            # Log de execução do Hydra (SSH)
│   ├── telnet.log         # Log de execução do Hydra (Telnet)
│   └── rdp.log            # Log de execução do Hydra (RDP)
├── users.txt              # Lista de usuários utilizados
├── passwords.txt          # Lista de senhas utilizadas
└── all_results.txt        # Consolidado de todos os hits (deduplicado)
```

---

## 🔑 Credenciais testadas

### Usuários padrão
`admin` `administrator` `root` `user` `guest` `test` `support` `operator` `manager` `service` `ubnt` `pi` `cisco` `oracle` `postgres` `mysql` `ftp` `anonymous`

### Senhas padrão
`admin` `administrator` `root` `password` `password123` `123456` `12345678` `1234` `test` `guest` `blank` `default` `changeme` `letmein` `welcome` `qwerty` `abc123` `pass` `support` `service`

---

## ⚠️ Aviso Legal

Esta ferramenta é destinada **exclusivamente** a fins educacionais e de auditoria em ambientes **próprios ou com autorização explícita**. O uso não autorizado contra sistemas de terceiros é **ilegal** e pode resultar em penalidades civis e criminais. O autor não se responsabiliza pelo uso indevido desta ferramenta.

---

## 👤 Autor

Desenvolvido por **Renzi**

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
