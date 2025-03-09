section .data
    newline db 0xA              ; Caractère de nouvelle ligne
    xor_key db 0xAA             ; Clé XOR

section .bss
    file_handle resq 1
    line_buffer resb 256

section .text
    global chiffrement

chiffrement:
    ; Récupérer les arguments de la ligne de commande
    pop rcx                     ; Nombre d'arguments (argc)
    cmp rcx, 3
    jne exit_program            ; Si ce n'est pas le cas, quitter

    ; Récupérer les arguments
    pop rsi                     ; Ignorer le premier argument (nom du programme)
    pop rsi                     ; Récupérer le mot de passe (premier argument)
    mov r8, rsi                 ; Sauvegarder le mot de passe dans r8
    pop rsi                     ; Récupérer le nom du fichier (deuxième argument)
    mov r9, rsi                 ; Sauvegarder le nom du fichier dans r9

    ; Ouvrir le fichier en mode append (O_WRONLY | O_APPEND | O_CREAT)
    mov rax, 2                  ; Appel système pour open
    mov rdi, r9                 ; Nom du fichier
    mov rsi, 0x401              ; O_WRONLY | O_APPEND | O_CREAT
    mov rdx, 0o644              ; Permissions du fichier (rw-r--r--)
    syscall                     ; Appeler le noyau
    cmp rax, 0                  ; Vérifier si l'ouverture a réussi
    jl exit_program             ; Si échec, quitter
    mov [file_handle], rax      ; Stocker le handle du fichier

    ; Copier le mot de passe dans line_buffer
    mov rdi, line_buffer        ; Adresse du buffer
    mov rsi, r8                 ; Adresse du mot de passe
    call strcpy                 ; Copier le mot de passe
    mov byte [rdi], 0xA         ; Ajouter une nouvelle ligne
    inc rdi                     ; Passer au caractère suivant
    mov byte [rdi], 0           ; Terminer la chaîne

    ; Chiffrer la ligne avec XOR
    mov rsi, line_buffer        ; Adresse de la ligne
    call xor_encrypt            ; Chiffrer la ligne

    ; Écrire la ligne chiffrée dans le fichier
    mov rsi, line_buffer        ; Adresse de la ligne chiffrée
    call strlen                 ; Calculer la longueur de la ligne
    mov rdx, rax                ; Longueur de la ligne
    mov rax, 1                  ; Appel système pour write
    mov rdi, [file_handle]      ; Handle du fichier
    syscall                     ; Appeler le noyau

    ; Fermer le fichier
    mov rax, 3                  ; Appel système pour close
    mov rdi, [file_handle]      ; Handle du fichier
    syscall                     ; Appeler le noyau

exit_program:
    ; Quitter le programme
    mov rax, 60                 ; Appel système pour exit
    xor rdi, rdi                ; Code de retour 0
    syscall                     ; Appeler le noyau

; Fonction pour copier une chaîne (strcpy)
strcpy:
    mov al, [rsi]               ; Charger le caractère de la source
    mov [rdi], al               ; Stocker le caractère dans la destination
    inc rsi                     ; Passer au caractère suivant de la source
    inc rdi                     ; Passer au caractère suivant de la destination
    test al, al                 ; Vérifier si le caractère est nul
    jnz strcpy                  ; Si non, continuer
    ret                         ; Retourner

; Fonction pour chiffrer une chaîne avec XOR
xor_encrypt:
    mov al, [rsi]               ; Charger le caractère de la chaîne
    test al, al                 ; Vérifier si le caractère est nul
    jz xor_done                 ; Si oui, terminer
    xor al, [xor_key]           ; Appliquer XOR avec la clé
    mov [rsi], al               ; Stocker le caractère chiffré
    inc rsi                     ; Passer au caractère suivant
    jmp xor_encrypt             ; Répéter la boucle
xor_done:
    ret                         ; Retourner

; Fonction pour calculer la longueur d'une chaîne (strlen)
strlen:
    xor rax, rax                ; Initialiser RAX à 0 (compteur de longueur)
strlen_loop:
    cmp byte [rsi + rax], 0     ; Vérifier si le caractère actuel est nul
    je strlen_done              ; Si oui, terminer
    inc rax                     ; Sinon, incrémenter le compteur
    jmp strlen_loop             ; Répéter la boucle
strlen_done:
    ret                         ; Retourner la longueur dans RAX