section .data
    prompt_filename_edit db "📄 Entrez le nom du fichier à modifier : ", 0
    prompt_filename_edit_len equ $ - prompt_filename_edit

    prompt_new_password db "🔒 Entrez le nouveau mot de passe : ", 0
    prompt_new_password_len equ $ - prompt_new_password

    identical_password_msg db 0xA, "❌ Le nouveau mot de passe ne peut pas être identique à l'ancien.", 0xA, 0
    identical_password_msg_len equ $ - identical_password_msg

    mod_confirm_msg db 0xA, "✅ Mot de passe modifié avec succès!", 0xA, 0
    mod_confirm_msg_len equ $ - mod_confirm_msg

    mod_error_msg db 0xA, "❌ Erreur : fichier non trouvé ou inaccessible.", 0xA, 0
    mod_error_msg_len equ $ - mod_error_msg

    separator db "---------------------------------", 0xA
    separator_len equ $ - separator

    ; Chemin de base pour le stockage des mots de passe
    base_directory db "src/config/passwords/", 0

    xor_key db 0xAA    ; Clé XOR utilisée pour chiffrement/déchiffrement

section .bss
    filename_buffer resb 256         ; Pour saisir le nom de fichier
    full_filename_buffer resb 512      ; Pour le chemin complet (base_directory + nom)
    old_password_buffer resb 256       ; Pour l'ancien mot de passe lu dans le fichier
    new_password_buffer resb 256       ; Pour le nouveau mot de passe saisi
    encrypt_buffer resb 256            ; Pour préparer le mot de passe chiffré à écrire
    fd resq 1                        ; Pour stocker le descripteur du fichier

section .text
    global modify_password
    extern read_input_string, print_string

modify_password:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; 1. Demande du nom du fichier à modifier
    mov rdi, separator
    mov rsi, separator_len
    call print_string

    mov rdi, prompt_filename_edit
    mov rsi, prompt_filename_edit_len
    call print_string

    mov rdi, filename_buffer
    mov rsi, 256
    call read_input_string
    mov rdi, filename_buffer
    call strip_newline

    ; 1.5. Concaténer le chemin de base et le nom du fichier
    lea rdi, [full_filename_buffer]
    mov rsi, base_directory
    call strcpy
    lea rsi, [full_filename_buffer]
    call strlen
    mov rcx, rax           ; rcx = longueur de base_directory
    lea rdi, [full_filename_buffer + rcx]
    mov rsi, filename_buffer
    call strcpy

    ; 2. Ouvrir le fichier en lecture (O_RDONLY = 0)
    mov rax, 2             ; syscall: open
    lea rdi, [full_filename_buffer]
    mov rsi, 0             ; lecture seule
    syscall
    cmp rax, 0
    jl .file_error
    mov [fd], rax

    ; 3. Lire le contenu du fichier dans old_password_buffer
    mov rax, 0             ; syscall: read
    mov rdi, [fd]
    lea rsi, [old_password_buffer]
    mov rdx, 256
    syscall
    ; Terminer la chaîne lue
    mov rbx, rax
    lea rdi, [old_password_buffer + rbx]
    mov byte [rdi], 0
    ; Déchiffrer l'ancien mot de passe
    lea rsi, [old_password_buffer]
    call xor_decrypt
    ; Fermer le fichier en lecture
    mov rax, 3             ; syscall: close
    mov rdi, [fd]
    syscall

    ; 4. Demander le nouveau mot de passe
    mov rdi, prompt_new_password
    mov rsi, prompt_new_password_len
    call print_string

    mov rdi, new_password_buffer
    mov rsi, 256
    call read_input_string
    mov rdi, new_password_buffer
    call strip_newline

    ; 5. Comparer l'ancien mot de passe et le nouveau
    mov rdi, new_password_buffer
    mov rsi, old_password_buffer
    call strcmp
    cmp rax, 0
    je .password_identical

    ; 6. Préparer l'encryption du nouveau mot de passe
    ; Zéro le buffer encrypt_buffer
    mov rcx, 256
    lea rdi, [encrypt_buffer]
    call zero_buffer

    ; Copier le nouveau mot de passe dans encrypt_buffer
    lea rdi, [encrypt_buffer]
    mov rsi, new_password_buffer
    call strcpy

    ; Calculer la longueur et la stocker dans RBX
    lea rsi, [encrypt_buffer]
    call strlen          ; longueur dans RAX
    mov rbx, rax         ; sauvegarder la longueur
    ; Ajouter un saut de ligne
    lea rdi, [encrypt_buffer + rbx]
    mov byte [encrypt_buffer + rbx], 0xA
    inc rbx
    mov byte [encrypt_buffer + rbx], 0
    ; Appliquer le chiffrement XOR sur encrypt_buffer
    lea rsi, [encrypt_buffer]
    call xor_encrypt
    ; Utiliser la longueur stockée (RBX) pour l'écriture

    ; 7. Ouvrir le fichier en écriture avec troncature (O_WRONLY | O_TRUNC)
    ; O_WRONLY = 1, O_TRUNC = 0x200, combinaison = 0x201
    mov rax, 2             ; syscall: open
    lea rdi, [full_filename_buffer]
    mov rsi, 0x201         ; O_WRONLY | O_TRUNC
    mov rdx, 420           ; Permissions 0644
    syscall
    cmp rax, 0
    jl .file_error
    mov [fd], rax

    ; 8. Écrire le nouveau mot de passe chiffré dans le fichier
    mov rax, 1             ; syscall: write
    mov rdi, [fd]
    lea rsi, [encrypt_buffer]
    mov rdx, rbx         ; utiliser la longueur sauvegardée
    syscall

    ; Fermer le fichier
    mov rax, 3             ; syscall: close
    mov rdi, [fd]
    syscall

    ; 9. Afficher le message de confirmation
    mov rdi, mod_confirm_msg
    mov rsi, mod_confirm_msg_len
    call print_string
    jmp .exit_edit

.password_identical:
    mov rdi, identical_password_msg
    mov rsi, identical_password_msg_len
    call print_string
    jmp .exit_edit

.file_error:
    mov rdi, mod_error_msg
    mov rsi, mod_error_msg_len
    call print_string

.exit_edit:
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

; zero_buffer : met à zéro RCX octets à partir de l'adresse dans RDI.
zero_buffer:
    push rbx
.zero_loop:
    cmp rcx, 0
    je .done_zero
    mov byte [rdi], 0
    inc rdi
    dec rcx
    jmp .zero_loop
.done_zero:
    pop rbx
    ret