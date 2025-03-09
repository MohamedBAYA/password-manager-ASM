section .data
    ; Messages et invites
    prompt_filename       db '📄 Entrez le nom du fichier : ', 0
    prompt_filename_len   equ $ - prompt_filename

    prompt_password       db '🔒 Entrez votre mot de passe : ', 0
    prompt_password_len   equ $ - prompt_password

    confirm_msg           db 0xA, '✅ Mot de passe ajouté avec succès!', 0xA
    confirm_msg_len       equ $ - confirm_msg

    return_msg            db 0xA, '↩️ Retour aux options...', 0xA, 0xA
    return_msg_len        equ $ - return_msg

    separator             db '---------------------------------', 0xA
    separator_len         equ $ - separator

    newline               db 0xA

    xor_key               db 0xAA    ; Clé utilisée pour le chiffrement XOR

    ; Chemin de base pour stocker les fichiers de mots de passe
    base_directory        db "src/config/passwords/", 0

section .bss
    ; Buffers pour les saisies utilisateur et le chiffrement
    filename_buffer       resb 256   ; Pour le nom de fichier saisi par l'utilisateur
    password_buffer       resb 256   ; Pour le mot de passe saisi
    encrypt_buffer        resb 256   ; Pour le mot de passe à chiffrer (copie + retour à la ligne)
    full_filename_buffer  resb 512   ; Pour le chemin complet (base_directory + nom du fichier)

section .text
    global add_password
    extern read_input_string, print_string

; ===============================================
; add_password : fonction principale du module
; ===============================================
add_password:
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Réserver de l’espace sur la pile

    ; ─────────────────────────────────────────────
    ; 1. Demande du nom de fichier
    ; ─────────────────────────────────────────────
    mov rdi, separator
    mov rsi, separator_len
    call print_string

    mov rdi, prompt_filename
    mov rsi, prompt_filename_len
    call print_string

    ; Lire la saisie dans filename_buffer
    mov rdi, filename_buffer
    mov rsi, 256
    call read_input_string

    ; Supprimer le saut de ligne dans le nom de fichier
    mov rdi, filename_buffer
    call strip_newline

    mov rdi, separator
    mov rsi, separator_len
    call print_string

    ; ─────────────────────────────────────────────
    ; 1.5. Concaténer le chemin de base et le nom saisi
    ; ─────────────────────────────────────────────
    ; Copier le chemin de base dans full_filename_buffer
    lea rdi, [full_filename_buffer]
    mov rsi, base_directory
    call strcpy
    ; Calculer la longueur du chemin de base copié
    lea rsi, [full_filename_buffer]
    call strlen
    mov rcx, rax        ; rcx = longueur de base_directory
    ; Copier le nom de fichier (filename_buffer) à la suite
    lea rdi, [full_filename_buffer + rcx]
    mov rsi, filename_buffer
    call strcpy

    ; ─────────────────────────────────────────────
    ; 2. Demande du mot de passe
    ; ─────────────────────────────────────────────
    mov rdi, prompt_password
    mov rsi, prompt_password_len
    call print_string

    ; Lire le mot de passe dans password_buffer
    mov rdi, password_buffer
    mov rsi, 256
    call read_input_string

    mov rdi, separator
    mov rsi, separator_len
    call print_string

    ; ─────────────────────────────────────────────
    ; 3. Préparation et chiffrement du mot de passe
    ; ─────────────────────────────────────────────
    ; Copier le mot de passe dans encrypt_buffer
    lea rdi, [encrypt_buffer]
    mov rsi, password_buffer
    call strcpy

    ; Calculer la longueur du texte copié dans encrypt_buffer
    lea rsi, [encrypt_buffer]
    call strlen            ; longueur dans RAX
    mov rcx, rax           ; rcx = longueur

    ; Ajouter un retour à la ligne à la fin du texte
    lea rdi, [encrypt_buffer + rcx]
    mov byte [encrypt_buffer + rcx], 0xA
    inc rcx
    mov byte [encrypt_buffer + rcx], 0   ; Terminer la chaîne

    ; Appliquer le chiffrement XOR sur encrypt_buffer
    lea rsi, [encrypt_buffer]
    call xor_encrypt

    ; ─────────────────────────────────────────────
    ; 4. Ouverture du fichier et écriture
    ; ─────────────────────────────────────────────
    mov rax, 2
    lea rdi, [full_filename_buffer]   ; utiliser le chemin complet
    mov rsi, 0x441
    mov rdx, 420
    syscall

    ; Vérifier si l’ouverture a échoué
    cmp rax, 0
    jl .file_error
    mov rbx, rax         ; RBX = descripteur de fichier

    ; Calculer la longueur du texte chiffré à écrire
    lea rsi, [encrypt_buffer]
    call strlen          ; longueur dans RAX
    mov rdx, rax         ; rdx = nombre d’octets à écrire

    ; Écriture dans le fichier
    mov rax, 1           ; syscall: write
    mov rdi, rbx         ; descripteur de fichier
    lea rsi, [encrypt_buffer]
    syscall

    ; Fermer le fichier
    mov rax, 3           ; syscall: close
    mov rdi, rbx
    syscall

    ; ─────────────────────────────────────────────
    ; 5. Confirmation et retour
    ; ─────────────────────────────────────────────
    mov rdi, confirm_msg
    mov rsi, confirm_msg_len
    call print_string

    mov rdi, return_msg
    mov rsi, return_msg_len
    call print_string

    jmp .exit_add

.file_error:
    mov rdi, separator
    mov rsi, separator_len
    call print_string

.exit_add:
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

; ===============================================
; Fonctions utilitaires
; ===============================================

; strcpy : copie la chaîne pointée par RSI vers RDI
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

; strlen : calcule la longueur d’une chaîne dont l’adresse est dans RSI.
; La longueur est retournée dans RAX.
strlen:
    xor rax, rax
.length_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .length_loop
.done:
    ret

; xor_encrypt : applique un chiffrement XOR sur la chaîne pointée par RSI
; La clé utilisée est celle de 'xor_key' (clé 0xAA)
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

; strip_newline : supprime le caractère de nouvelle ligne (0xA) de la chaîne si présent
; Entrée: RDI pointe vers la chaîne
strip_newline:
    push rbp
    mov rbp, rsp
    mov rbx, rdi      ; sauvegarde du pointeur de départ
.strip_loop:
    mov al, [rbx]
    cmp al, 0
    je .strip_done    ; fin de chaîne
    cmp al, 0xA
    je .strip_replace
    inc rbx
    jmp .strip_loop
.strip_replace:
    mov byte [rbx], 0  ; remplace le saut de ligne par le caractère nul
.strip_done:
    pop rbp
    ret