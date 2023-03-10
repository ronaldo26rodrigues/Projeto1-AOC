# [BCC 2022.1] Arquitetura e Organização de Computadores
# Lista de exercícios - Projeto 01
# Questão 01
# Arquitetantes:
# - Gabriel Santos
# - Gilvaney Leandro
# - Joyce Mirelle
# - Ronaldo Rodrigues

.eqv R 10                                                               # DEFINE: Enter (Return) char = 10
.eqv BS 8                                                               # DEFINE: Backpace char = 8

.data

building: .space 1600 							                        # 40 apartamentos * 36 bytes por apartamento

next_line: .asciiz "\n"                                                 # nova linha
separador: .asciiz "-"                                                  # separador de comando

banner: .asciiz "GGJR-shell>> "                                         # Banner da equipe (shell)




input: .space 1024                                                      # espaco para o input do usuario
output: .space 1024


.text
.globl print_str, start, input, output, separador, building, next_line

main:

    la $a0, building							                        # carrega em $a0 o endereço para o building
    jal set_building							                        # inicializa a função de preencher os apartamentos    

    lui $s0, 0xFFFF                                                     # carrega o endereco base dos registradores do controle mmio em s0
    la $s1, input                                                       # carrega o endereco base do input em s1
    j start
    
start:
    la $a0, banner                                                      # carrega o endereco do banner
    jal print_str                                                       # chama a funcao print string
    jal clear_input
    j mmio_loop                                                         # inicia o loop do mmio

clear_input:                                                            # limpa a string input
    addi $s1, $s1, -1                                                   # decrementa um do cursor do input
    lb $t0, 0($s1)                                                      # carrega o byte
    beqz $t0, end_clear                                                 # caso seja \n, o input esta vazio
    sb $zero, 0($s1)                                                    # grava 0 no cursor atual
    j clear_input                                                       # reinicia o loop
    end_clear:                  
    	addi $s1, $s1, 1                                                # avanca um no cursor
        jr $ra                                                          # retorna

mmio_loop:                                                              # loop do mmio
    lw $t0, 0($s0)                                                      # s1 = receiver ready
    beqz $t0, mmio_loop                                                 # se receiver nao estiver pronto, reinicia o loop
    lw $s2, 4($s0)                                                      # s2 = receiver data
    beq $s2, BS, backspace                                              # se o character digitado for um backspace, inicia a logica de apagar um character do input
    sb $s2, 0($s1)                                                      # escreve o ultimo char digitado em transmitter data
    jal mmio_show_char                                                  # chama a funcao que mostra o char na tela mmio
    addi $s1, $s1, 1                                                    # move o cursor do input para o proximo byte
    beq $s2, R, enter                                                   # se for um enter, inicia a logica
    j mmio_loop                                                         # reinicia o loop do mmio

mmio_show_char:                                                         # funcao que imprime um character na tela mmio
    lw $s3, 8($s0)                                                      # t0 = transmitter ready
    beqz $s3, mmio_show_char                                            # caso transmitter nao esteja pronto, volta ao inicio da funcao
    sw $s2, 12($s0)                                                     # escreve o dado recebido do teclado em transmitter data
    jr $ra                                                              # return


print_str:                                                              # imprime uma string na tela mmio [$a0: endereco da string]
    addi	$sp, $sp, -4			                                    # reserva uma posicao na stack
    sw $ra, 0($sp)                                                      # grava return adress na stack
    lb		$s2, 0($a0)                                                 # carrega o byte da string em s2
    jal		mmio_show_char				                                # chama a funcao mmio_show_char
    lw $ra, 0($sp)                                                      # recupera o return adress da stack
    addi $sp, $sp, 4                                                    # libera uma posicao na stack
    addi $a0, $a0, 1                                                    # move o cursor da string 
    bnez $s2, print_str	                                                # se o character nao for zero, reinicia a funcao e continua a imprimir
    jr $ra                                                              # return
    
enter:                                                                  # executado quando a tecla enter eh digitada
    la $a0, input                                                       # endereco de input
    jal get_str_size                                                    # calcula tamaho da string input
    beqz $v0, skip_proc_cmd                                             # caso input esteja vazio, não executa o processamento de comando
    jal process_command                                                 # chama a funcao que processa o comando
    skip_proc_cmd:
    j start                                                             # desvia para o inicio do loop mmio

backspace:                                                              # executado quando um backspace eh digitado
    lb $t0, -1($s1)                                                     # carrega o ultimo byte do input
    beqz $t0, end_backspace                                             # se for o fim da string, encerra a funcao
    la $a0, next_line                                                   # pula uma linha
    jal print_str
    la $a0, banner                                                      # imprime o banner
    jal print_str
    addi $s1, $s1, -1                                                   # move o cursor do input a uma posicao anterior
    sb $zero, 0($s1)                                                    # escreve \0 nessa posicao
    la $a0, input                                                       # inprime o input atualizado na nova linha                                                 
    jal print_str                                                       
    end_backspace:                                                      # encerra a funcao
        j mmio_loop                                                     # desvia para o inicio de mmio_loop
    

