section .data
    confirm_msg db 0xA, '✅ Mot de passe ajouté avec succès!', 0xA
    confirm_msg_len equ $ - confirm_msg

    prompt_password db '🔒 Entrez votre mot de passe : ', 0
    prompt_password_len equ $ - prompt_password

    return_msg db 0xA, '↩️ Retour aux options...', 0xA, 0xA
    return_msg_len equ $ - return_msg

    separator db '---------------------------------', 0xA
    separator_len equ $ - separator

section .bss
    input_buffer resb 256  ; Buffer pour stocker le mot de passe

section .text
    global add_password
    extern read_input_string, print_string

add_password:
    push rbp
    mov rbp, rsp
    sub rsp, 16   ; Sécuriser un espace mémoire pour éviter tout écrasement

    ; 🔹 Ajouter un séparateur avant la saisie du mot de passe
    mov rdi, separator
    mov rsi, separator_len
    call print_string

    ; 🔹 Afficher l'invite de saisie du mot de passe
    mov rdi, prompt_password
    mov rsi, prompt_password_len
    call print_string

    ; 🔹 Lire le mot de passe de l'utilisateur
    mov rdi, input_buffer
    mov rsi, 256
    call read_input_string

    ; 🔹 Ajouter un séparateur après la saisie
    mov rdi, separator
    mov rsi, separator_len
    call print_string

    ; 🔹 Afficher le message de confirmation
    mov rdi, confirm_msg
    mov rsi, confirm_msg_len
    call print_string

    ; 🔹 Afficher le message de retour aux options
    mov rdi, return_msg
    mov rsi, return_msg_len
    call print_string

    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret