section .data
    prompt_delete       db "🗑️  Entrez le nom du fichier à supprimer : ", 0
    prompt_delete_len   equ $ - prompt_delete

    delete_success      db 0xA, "✅ Fichier supprimé avec succès!", 0xA, 0
    delete_success_len  equ $ - delete_success

    delete_error        db 0xA, "❌ Erreur : impossible de supprimer le fichier.", 0xA, 0
    delete_error_len    equ $ - delete_error

    separator           db "---------------------------------", 0xA
    separator_len       equ $ - separator

    base_directory      db "src/config/passwords/", 0

section .bss
    filename_buffer     resb 256
    full_filename_buffer resb 512

section .text
    global delete_password
    extern print_string          ; Pour afficher des messages
    extern read_input_string     ; Pour lire la saisie
    extern master_password       ; Pour vérifier le mot de passe maître

delete_password:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 1. Vérifier le mot de passe maître
    call master_password
    ; Si le master password est incorrect, master_password se charge de quitter le programme.

    ; 2. Afficher un séparateur et le prompt pour le nom de fichier
    mov rdi, separator
    mov rsi, separator_len
    call print_string

    mov rdi, prompt_delete
    mov rsi, prompt_delete_len
    call print_string

    ; 3. Lire le nom du fichier et enlever le saut de ligne
    mov rdi, filename_buffer
    mov rsi, 256
    call read_input_string
    mov rdi, filename_buffer
    call strip_newline

    ; 3.5. Concaténer base_directory et le nom de fichier dans full_filename_buffer
    lea rdi, [full_filename_buffer]
    mov rsi, base_directory
    call strcpy

    ; Calculer la longueur de base_directory
    lea rsi, [full_filename_buffer]
    call strlen             ; Longueur en RAX
    mov rcx, rax
    ; Copier le nom de fichier à la suite
    lea rdi, [full_filename_buffer + rcx]
    mov rsi, filename_buffer
    call strcpy

    ; 4. Appeler le syscall unlink pour supprimer le fichier
    mov rax, 87             ; unlink syscall
    lea rdi, [full_filename_buffer]
    syscall

    ; Vérifier le code de retour (RAX)
    cmp rax, 0
    jl .delete_error        ; Si RAX < 0, une erreur s'est produite

    ; 5. Afficher le message de succès
    mov rdi, delete_success
    mov rsi, delete_success_len
    call print_string
    jmp .end_delete

.delete_error:
    mov rdi, delete_error
    mov rsi, delete_error_len
    call print_string

.end_delete:
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

; =============================================================================
; Fonctions utilitaires locales
; =============================================================================

; strip_newline : supprime le caractère de nouvelle ligne (0xA) de la chaîne en RDI.
strip_newline:
    push rbp
    mov rbp, rsp
    mov rbx, rdi      ; sauvegarder l'adresse initiale
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

; strcpy : copie la chaîne pointée par RSI dans RDI (terminée par 0).
strcpy:
    push rbp
    mov rbp, rsp
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .done
    inc rsi
    inc rdi
    jmp .copy_loop
.done:
    pop rbp
    ret

; strlen : calcule la longueur d'une chaîne pointée par RSI, retourne la longueur dans RAX.
strlen:
    push rbp
    mov rbp, rsp
    xor rax, rax
.length_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .length_loop
.done:
    pop rbp
    ret
