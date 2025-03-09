section .data
    prompt_filename_retrieve db '📄 Entrez le nom du fichier à consulter : ', 0
    prompt_filename_retrieve_len equ $ - prompt_filename_retrieve

    retrieve_msg db 0xA, "🔍 Voici le contenu déchiffré : ", 0
    retrieve_msg_len equ $ - retrieve_msg

    error_msg db 0xA, "❌ Erreur lors de l'ouverture du fichier", 0xA, 0xA, 0
    error_msg_len equ $ - error_msg

    separator db '---------------------------------', 0xA
    separator_len equ $ - separator

    ; Chemin de base pour les fichiers de mots de passe (doit correspondre à celui utilisé pour l'ajout)
    base_directory db "src/config/passwords/", 0

    xor_key db 0xAA            ; Clé utilisée pour le déchiffrement XOR

section .bss
    filename_buffer resb 256       ; Pour la saisie du nom de fichier
    full_filename_buffer resb 512  ; Pour le chemin complet (base_directory + nom de fichier)
    file_buffer resb 256           ; Buffer pour lire le contenu du fichier
    fd resq 1                      ; Pour stocker le descripteur du fichier

section .text
    global retrieve_password
    extern read_input_string, print_string

retrieve_password:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Afficher un séparateur et le prompt pour le nom de fichier à consulter
    mov rdi, separator
    mov rsi, separator_len
    call print_string

    mov rdi, prompt_filename_retrieve
    mov rsi, prompt_filename_retrieve_len
    call print_string

    ; Lire le nom du fichier dans filename_buffer
    mov rdi, filename_buffer
    mov rsi, 256
    call read_input_string

    ; Supprimer le saut de ligne dans le nom de fichier
    mov rdi, filename_buffer
    call strip_newline

    ; Concaténer le chemin de base et le nom de fichier
    lea rdi, [full_filename_buffer]
    mov rsi, base_directory
    call strcpy
    ; Calculer la longueur du chemin de base
    lea rsi, [full_filename_buffer]
    call strlen
    mov rcx, rax         ; rcx = longueur de base_directory
    ; Copier le nom saisi à la suite
    lea rdi, [full_filename_buffer + rcx]
    mov rsi, filename_buffer
    call strcpy

    ; Ouvrir le fichier en mode lecture (O_RDONLY = 0)
    mov rax, 2           ; syscall: open
    lea rdi, [full_filename_buffer] ; chemin complet
    mov rsi, 0           ; O_RDONLY
    syscall
    cmp rax, 0
    jl .file_error
    mov [fd], rax        ; Sauvegarder le descripteur

    ; Afficher un message indiquant que le contenu va être affiché
    mov rdi, retrieve_msg
    mov rsi, retrieve_msg_len
    call print_string

.read_loop:
    ; Lire le fichier dans file_buffer
    mov rax, 0           ; syscall: read
    mov rdi, [fd]
    lea rsi, [file_buffer]
    mov rdx, 256
    syscall
    cmp rax, 0
    je .close_file       ; Fin du fichier
    js .file_error       ; En cas d'erreur

    ; Déchiffrer le contenu du buffer
    lea rsi, [file_buffer]
    call xor_decrypt

    ; Calculer la longueur du contenu déchiffré
    lea rsi, [file_buffer]
    call strlen          ; Longueur dans RAX
    mov rdx, rax         ; Nombre d'octets à écrire

    ; Afficher le contenu déchiffré
    mov rax, 1           ; syscall: write
    mov rdi, 1           ; stdout
    lea rsi, [file_buffer]
    syscall

    jmp .read_loop

.close_file:
    mov rax, 3           ; syscall: close
    mov rdi, [fd]
    syscall
    jmp .exit_retrieve

.file_error:
    mov rdi, error_msg
    mov rsi, error_msg_len
    call print_string

.exit_retrieve:
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

; ====================================================
; Fonctions utilitaires (copie des modules add_password)
; ====================================================

; strcpy : copie la chaîne pointée par RSI dans RDI
strcpy:
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .done
    inc rsi
    inc rdi
    jmp .copy_loop
.done:
    ret

; strlen : calcule la longueur d'une chaîne (retourne la longueur dans RAX)
strlen:
    xor rax, rax
.length_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .length_loop
.done:
    ret

; xor_decrypt : déchiffre une chaîne avec XOR (clé 0xAA)
xor_decrypt:
.decrypt_loop:
    mov al, [rsi]
    cmp al, 0
    je .done
    mov bl, [xor_key]
    xor al, bl
    mov [rsi], al
    inc rsi
    jmp .decrypt_loop
.done:
    ret

; strip_newline : supprime le caractère de nouvelle ligne (0xA) dans la chaîne
strip_newline:
    push rbp
    mov rbp, rsp
    mov rbx, rdi      ; sauvegarde du pointeur initial
.strip_loop:
    mov al, [rbx]
    cmp al, 0
    je .strip_done
    cmp al, 0xA
    je .strip_replace
    inc rbx
    jmp .strip_loop
.strip_replace:
    mov byte [rbx], 0
.strip_done:
    pop rbp
    ret