section .data
    menu_title db 'Gestionnaire de Mots de Passe', 0xA
    menu_title_len equ $ - menu_title

    menu_option1 db '1. Ajouter un nouveau mot de passe', 0xA
    menu_option1_len equ $ - menu_option1

    menu_option2 db '2. Retrouver un mot de passe', 0xA
    menu_option2_len equ $ - menu_option2

    menu_option3 db '3. Modifier un mot de passe existant', 0xA
    menu_option3_len equ $ - menu_option3

    menu_option4 db '4. Supprimer un mot de passe', 0xA
    menu_option4_len equ $ - menu_option4

    menu_end db '------', 0xA
    menu_end_len equ $ - menu_end

    menu_write db 'Saisit : '
    menu_write_len equ $ - menu_write

    menu_exit db '5. Quitter', 0xA
    menu_exit_len equ $ - menu_exit

    password db 'Saisit le mot de passe', 0xA
    password_len equ $ - password

section .bss
    input_buffer resb 256

section .text
    global _start
    global print_string
    global display_menu
    global read_char
    global handle_user_input
    global read_input_string
    global clear_input_buffer
    extern add_password

; Fonction principale
_start:
    .main_loop:
        call display_menu
        call handle_user_input

        ; Vérifier si l'utilisateur a choisi de quitter
        cmp al, 5
        je .exit_program

        jmp .main_loop

    .exit_program:
        ; Terminer le programme proprement
        mov rax, 60
        xor rdi, rdi
        syscall

; Afficher une chaîne de caractères
; Entrée: RDI - Pointeur vers la chaîne
;         RSI - Longueur de la chaîne
print_string:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    push rdx
    push rax

    mov rax, 1
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, 1
    syscall

    pop rax
    pop rdx

    add rsp, 16
    pop rbp
    ret

; Affiche le menu du gestionnaire de mots de passe
display_menu:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; Imprimer le titre du menu
    mov rdi, menu_title
    mov rsi, menu_title_len
    call print_string

    ; Imprimer l'option 1
    mov rdi, menu_option1
    mov rsi, menu_option1_len
    call print_string

    ; Imprimer l'option 2
    mov rdi, menu_option2
    mov rsi, menu_option2_len
    call print_string

    ; Imprimer l'option 3
    mov rdi, menu_option3
    mov rsi, menu_option3_len
    call print_string

    ; Imprimer l'option 4
    mov rdi, menu_option4
    mov rsi, menu_option4_len
    call print_string

    ; Imprimer l'option pour quitter
    mov rdi, menu_exit
    mov rsi, menu_exit_len
    call print_string

    ; Imprimer les trait de séparation
    mov rdi, menu_end
    mov rsi, menu_end_len
    call print_string

    ; Imprimer l'affichage de saisit
    mov rdi, menu_write
    mov rsi, menu_write_len
    call print_string

    pop rsi
    pop rdi

    mov rsp, rbp
    pop rbp
    ret

; Fonction pour lire un caractère depuis l'entrée standard
read_char:
    mov rax, 0
    mov rdi, 0
    lea rsi, [rsp + 8]
    mov rdx, 1
    syscall

    movzx rax, byte [rsp + 8]

    ; Vider l'entrée utilisateur
    call clear_input_buffer

    ret

; Fonction pour vider l'entrée utilisateur
clear_input_buffer:
    push rax
    push rdi
    push rsi
    push rdx

.clear_loop:
    ; Lire un caractère
    mov rax, 0
    mov rdi, 0
    lea rsi, [rsp - 1]
    mov rdx, 1
    syscall

    ; Vérifier si le caractère est une nouvelle ligne
    cmp byte [rsp - 1], 0xA
    je .clear_done

    ; Continuer à lire jusqu'à la nouvelle ligne
    jmp .clear_loop

.clear_done:
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

handle_user_input:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    call read_char
    sub al, '0'

    cmp al, 1
    je .call_add_password
    cmp al, 2
    je .call_retrieve_password
    cmp al, 3
    je .call_modify_password
    cmp al, 4
    je .call_delete_password
    cmp al, 5
    je .call_exit_program

    ; Si aucune option valide n'est sélectionnée
    call display_menu
    call handle_user_input

.end_handle_input:
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret

.call_add_password:
    call add_password
    call handle_user_input  ; On appelle proprement pour ne pas écraser l'adresse de retour
    jmp .end_handle_input   ; Assurer un retour propre

.call_retrieve_password:
    ; Logique pour retrouver un mot de passe
    jmp .end_handle_input

.call_modify_password:
    ; Logique pour modifier un mot de passe
    jmp .end_handle_input

.call_delete_password:
    ; Logique pour supprimer un mot de passe
    jmp .end_handle_input

.call_exit_program:
    ; Logique pour quitter le programme
    jmp .end_handle_input

; Lire une chaîne de caractères depuis l'entrée standard
; Entrée: RDI - pointeur vers le buffer de la chaîne
;         RSI - longueur maximale de la chaîne à lire
read_input_string:
    push rax
    push rdx

    ; Lire l'entrée utilisateur
    mov rax, 0
    mov rdi, 0
    syscall

    pop rdx
    pop rax

    ret
