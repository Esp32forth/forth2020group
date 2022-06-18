( INFO: )
( recriação em FORTH de um jogo em BASIC publicado na revista )
( MICROSISTEMAS n. 53, de fev. 1986, pág. 32,)
( de nome "Estratégia", )
( de autoria de Jorge A. C. Bettencourt Soares )
( https://datassette.org/revistas/micro-sistemas/micro-sistemas-no-53 )
( . )
( Versão em esp32FORTH por Ricardo Cunha Michel, Brasil, 2022 )


( ponto de apagamento )
: ALL ;

( variaveis )
decimal
variable dr_altura      ( o quão perto o drone está da regiao segura )
variable dr_pos         ( posição do drone em um dos 4 caminhos aéreos )
variable dr_char        ( caracter que representa o drone, "A")
variable dr_ok?         ( registra se o drone está OK, i.e., se não foi atingido )
variable vitorias       ( quantas missoes cumpriu sem ser atingido? )
variable derrotas       ( quantas missoes foram impedidas pelo míssil? )
variable mi_altura      ( onde está o missil )
variable mi_pos         ( posição do míssil em um dos 4 caminhos aéreos )
variable mi_char        ( caracter que representa o míssil, "^" )

( procedimentos )
: cls 50 0 do cr loop ;     ( limpa tela )
: var- dup @ rot - swap ! ;  ( n var_name -- )  ( subtrai "n" unidades do valor armazenado na variável )

variable RND 
MS-TICKS RND ! 
: RANDOM RND @ 31421 * 6927 + ABS 65536 /MOD drop DUP RND ! ;
: CHOOSE RANDOM * 65536 /MOD SWAP DROP ; 

: init_vars ( caminho e distancia iniciais do drone e do missil )
    22 dr_altura ! 
    1  dr_pos !
    65 dr_char !
    28 mi_altura !  
    0  mi_pos ! 
    94 mi_char ! 
    1 dr_ok? !  ; 

( o JOGO em si )    
: zona1   ." #########################" cr ; 
: zona2   ." #### FORA DE ALCANCE ####" cr ; 
: zona3   ." ########|0|1|2|3|########" cr ; 
: zona4   ." ////////| | | | |////////" cr ; 
: zona_dr s" ////////| | | | |////////" 2dup drop 9 dr_pos @ 2 * + + dup dr_char @ swap c! rot rot TYPE 32 swap c! cr ;
: zona_mi s" ////////| | | | |////////" 2dup drop 9 mi_pos @ 2 * + + dup mi_char @ swap c! rot rot TYPE 32 swap c! cr ;

: desenha
    cls
    zona1 zona1 zona2 zona1 zona3
    29 0 do
    i dr_altura @ = if zona_dr else 
    i mi_altura @ = if zona_mi else 
    zona4 then then
    loop ;

: MOVE_dr begin key? until key 48 - dr_pos ! ;  ( o código das teclas numéricas menos 48 é o valor do dígito )
: MOVE_mi_alea  4 CHOOSE mi_pos ! ;  ( ‘n CHOOSE’ gera um número aleatório inteiro entre 0 e n-1 )
: ATUALIZA_posicoes  mi_pos @ dr_pos @ = if 3 mi_altura var- else 1 dr_altura var- then ;
: TESTA_FIM 
    mi_altura @ dr_altura @ <= 
        if ." >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>MORREU" 1 derrotas +! cr 0 dr_ok?  ! then  
    dr_altura @ 0 <= 
        if ." <><><><><><><><> V I T O R I A <><><><><><><><> " 1 vitorias +! cr 0 dr_ok? ! then
    ; 

( IA ************************************************************** )
variable ia_dr_atual    ( a posição atual que o míssil vê o drone, X )
variable ia_dr_anterior ( onde o drone estava antes de estar na posição atual, Y )
variable situacao       ( situação do drone )

: init_IA  ( como não há informação sobre como o drone chegou nesse posição, assume ambos os valores como sendo iguais )
    dr_pos @ dup ia_dr_atual ! ia_dr_anterior ! ; 

: tabela CREATE 64 cells allot DOES> swap cells + ;  ( ‘posição nome_da_tabela’ deixará no stack o endereço da posição )
tabela ia_tab_freq      ( a tabela com 64 posições, com as 4 frequências de ocorrẽncia para cada uma das 16 situações )

: zera_tab_freq 64 0 do 0 i ia_tab_freq ! loop ;
zera_tab_freq

: mostra_tab_freq 
    16 0 do 
        i . ." : " 
        i 4 * 0 + ia_tab_freq ? ." : " 
        i 4 * 1 + ia_tab_freq ? ." : " 
        i 4 * 2 + ia_tab_freq ? ." : " 
        i 4 * 3 + ia_tab_freq ? 
        cr loop ; 
        
: max rot > if swap then drop ; 

: MOVE_mi_IA 
        ( calcula e armazena o valor de ‘situação’ )
    ia_dr_anterior @ 4 * ia_dr_atual @ + situacao !
        ( agora, recordar as 4 frequências de movimento... )    
    situacao @ 4 * 0 + ia_tab_freq @ 
    situacao @ 4 * 1 + ia_tab_freq @ 
    situacao @ 4 * 2 + ia_tab_freq @ 
    situacao @ 4 * 3 + ia_tab_freq @ 
        ( . . . e compará-las )    
    3 mi_pos !
    3 0 do  
    2dup > if 2 i - mi_pos ! swap then nip 
    loop 
    drop 
    cr mi_pos ? cr ;

: ATUALIZA_IA
    ia_dr_atual @ ia_dr_anterior !  ( atualiza posicoes )
    dr_pos @ ia_dr_atual !          ( coloca a posição detectada como sendo a nova 'posição atual' )
    situacao @ 4 * ia_dr_atual @ + ia_tab_freq dup @ 1 + swap ! ;  ( atualiza a tabela de frequencias da situação ocorrida )

( ************************************************************** FIM da IA )

( descrição de abertura, tela inicial etc. )

: ABERTURA
CR CR CR
CR 
." O objetivo é fazer o máximo de missões, escapando do míssil."
CR
." Você pode usar os quatro corredores aéreos: 0, 1, 2, 3"
CR 
." Mas o míssil aprende..."
CR
CR
." Pressione qualquer tecla..."
CR CR CR
;    

( cada execução do jogo )
: UM_JOGO 
init_vars ( nao zera memoria )  
init_IA
desenha 
begin
    dr_ok? @
    while
        MOVE_dr 
        MOVE_mi_IA
        ATUALIZA_posicoes
        ATUALIZA_IA
        desenha 
        TESTA_FIM 
    repeat
;  

( a chamada inicial >> AQUI começa o jogo )
: JOGO
cls
ABERTURA
0 vitorias !
0 derrotas !
begin 
    key? key 27 -
    while 
        UM_JOGO 
        CR ." VITORIAS: " vitorias @ .
        CR ." DERROTAS: " derrotas @ .
        CR CR CR
        3000 ms
        ." <ESC> interrompe, outra tecla recomeça"
    repeat
;
( ************************************************************** FIM )
