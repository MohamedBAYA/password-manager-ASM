section .data
    master_file_path db "src/config/master/masterpass.dat", 0

    prompt_set_master db "Définissez le mot de passe maître : ", 0
    prompt_set_master_len equ $ - prompt_set_master

    prompt_enter_master db "Entrez le mot de passe maître : ", 0
    prompt_enter_master_len equ $ - prompt_enter_master

    success_msg db 0xA, "Accès autorisé.", 0xA, 0
    success_msg_len equ $ - success_msg

    failure_msg db 0xA, "Mot de passe incorrect. Accès Refusé.", 0xA, 0
    failure_msg_len equ $ - failure_msg

    master_set_msg db 0xA, "Mot de passe maître défini avec succès.", 0xA, 0
    master_set_msg_len equ $ - master_set_msg

    mod_error_msg db 0xA, "❌ Erreur lors de la lecture/écriture du fichier master.", 0xA, 0
    mod_error_msg_len equ $ - mod_error_msg

    ; Clé XOR utilisée pour le chiffrement/déchiffrement
    xor_key db 0xAA

section .bss
    stored_master resb 256   ; Buffer pour stocker le master password lu du fichier
    input_buffer resb 256    ; Buffer pour la saisie utilisateur

section .text
    global master_password
    extern read_input_string, print_string

master_password:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Tenter d'ouvrir le fichier maître en lecture (O_RDONLY = 0)
    mov rax, 2                ; syscall: open
    lea rdi, [master_file_path]
    mov rsi, 0                ; lecture seule
    syscall
    cmp rax, 0
    jl .file_not_exist       ; Si le fichier n'existe pas, aller à la configuration

    ; Fichier existant : lire le contenu dans stored_master
    mov rbx, rax             ; sauvegarder le descripteur dans RBX
    mov rax, 0               ; syscall: read
    mov rdi, rbx
    lea rsi, [stored_master]
    mov rdx, 256
    syscall
    ; Placer un terminateur à la fin du contenu lu (nombre d'octets lus en RAX)
    mov rcx, rax
    lea rdi, [stored_master + rcx]
    mov byte [rdi], 0

    ; Fermer le fichier
    mov rax, 3               ; syscall: close
    mov rdi, rbx
    syscall

    ; Déchiffrer le master password lu
    lea rsi, [stored_master]
    call xor_decrypt
    ; Supprimer un éventuel saut de ligne dans stored_master
    mov rdi, stored_master
    call strip_newline

    ; Demander à l'utilisateur d'entrer le master password
    mov rdi, prompt_enter_master
    mov rsi, prompt_enter_master_len
    call print_string

    mov rdi, input_buffer
    mov rsi, 256
    call read_input_string
    mov rdi, input_buffer
    call strip_newline

    ; Comparer l'entrée avec le master password stocké
    mov rdi, input_buffer
    mov rsi, stored_master
    call strcmp
    cmp rax, 0
    je .access_granted

    ; Si incorrect, afficher message d'échec et quitter
    mov rdi, failure_msg
    mov rsi, failure_msg_len
    call print_string
    mov rax, 60
    mov rdi, 1    ; code de sortie 1
    syscall

.file_not_exist:
    ; Fichier introuvable : première exécution ou fichier supprimé
    ; Demander à l'utilisateur de définir le master password
    mov rdi, prompt_set_master
    mov rsi, prompt_set_master_len
    call print_string

    mov rdi, input_buffer
    mov rsi, 256
    call read_input_string
    mov rdi, input_buffer
    call strip_newline

    ; Copier la saisie dans stored_master
    lea rdi, [stored_master]
    mov rsi, input_buffer
    call strcpy

    ; Calculer la longueur et placer un terminateur (sans ajout de saut de ligne)
    lea rsi, [stored_master]
    call strlen         ; longueur dans RAX
    mov rcx, rax
    lea rdi, [stored_master + rcx]
    mov byte [rdi], 0   ; Terminaison de la chaîne

    ; Chiffrer stored_master avec XOR
    lea rsi, [stored_master]
    call xor_encrypt

    ; Ouvrir le fichier en écriture (O_WRONLY | O_CREAT | O_TRUNC)
    mov rax, 2                ; syscall: open
    lea rdi, [master_file_path]
    mov rsi, 577              ; O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 420              ; Permissions 0644
    syscall
    cmp rax, 0
    jl .file_error_master
    ; Écrire stored_master dans le fichier
    mov rdi, rax              ; File descriptor
    lea rsi, [stored_master]
    call strlen             ; longueur dans RAX
    mov rdx, rax
    mov rax, 1              ; syscall: write
    syscall
    mov rax, 3
    
    mov rdi, master_set_msg
    mov rsi, master_set_msg_len
    call print_string
    jmp .access_granted

.file_error_master:
    mov rdi, mod_error_msg
    mov rsi, mod_error_msg_len
    call print_string
    mov rax, 60
    mov rdi, 1
    syscall

.access_granted:
    mov rdi, success_msg
    mov rsi, success_msg_len
    call print_string
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

; ====================================================
; Fonctions utilitaires
; ====================================================

; strcmp : compare deux chaînes pointées par RDI et RSI.
; Retourne 0 si identiques, sinon une valeur non nulle.
strcmp:
    push rbp
    mov rbp, rsp
.compare_loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc rdi
    inc rsi
    jmp .compare_loop
.not_equal:
    mov rax, 1
    jmp .done_cmp
.equal:
    xor rax, rax
.done_cmp:
    pop rbp
    ret

; strcpy : copie la chaîne pointée par RSI dans RDI.
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

; strlen : calcule la longueur d'une chaîne (retourne la longueur dans RAX).
strlen:
    xor rax, rax
.length_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .length_loop
.done:
    ret

; xor_encrypt : applique un chiffrement XOR sur la chaîne pointée par RSI.
; Utilise la clé dans xor_key.
xor_encrypt:
.encrypt_loop:
    mov al, [rsi]
    cmp al, 0
    je .done
    mov bl, [xor_key]
    xor al, bl
    mov [rsi], al
    inc rsi
    jmp .encrypt_loop
.done:
    ret

; xor_decrypt : déchiffre une chaîne avec XOR (identique à xor_encrypt).
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

; strip_newline : supprime le caractère de nouvelle ligne (0xA) de la chaîne si présent.
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