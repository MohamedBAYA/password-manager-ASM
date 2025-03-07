section .data
    xor_key db 0xAA             ; Clé XOR (doit correspondre à celle utilisée pour le chiffrement)

section .bss
    file_handle resq 1          ; Handle du fichier
    buffer resb 256             ; Buffer pour lire le fichier

section .text
    global _start

_start:
    ; Récupérer les arguments de la ligne de commande
    pop rcx                     ; Nombre d'arguments (argc)
    cmp rcx, 2                  ; Vérifier qu'il y a exactement 1 argument (plus le nom du programme)
    jne exit_program            ; Si ce n'est pas le cas, quitter

    ; Récupérer le nom du fichier
    pop rsi                     ; Ignorer le premier argument (nom du programme)
    pop rsi                     ; Récupérer le nom du fichier (premier argument)
    mov r8, rsi                 ; Sauvegarder le nom du fichier dans r8

    ; Ouvrir le fichier en mode lecture (O_RDONLY)
    mov rax, 2                  ; Appel système pour open
    mov rdi, r8                 ; Nom du fichier
    mov rsi, 0                  ; O_RDONLY
    syscall                     ; Appeler le noyau
    cmp rax, 0                  ; Vérifier si l'ouverture a réussi
    jl exit_program             ; Si échec, quitter
    mov [file_handle], rax      ; Stocker le handle du fichier

read_file:
    ; Lire le fichier dans le buffer
    mov rax, 0                  ; Appel système pour read
    mov rdi, [file_handle]      ; Handle du fichier
    mov rsi, buffer             ; Adresse du buffer
    mov rdx, 256                ; Taille du buffer
    syscall                     ; Appeler le noyau
    test rax, rax               ; Vérifier si la lecture est terminée
    jz close_file               ; Si 0 octets lus, fermer le fichier
    js exit_program             ; Si erreur (< 0), quitter

    ; Déchiffrer le buffer avec XOR
    mov rsi, buffer             ; Adresse du buffer
    call xor_decrypt            ; Déchiffrer le buffer

    ; Afficher le buffer déchiffré
    mov rax, 1                  ; Appel système pour write
    mov rdi, 1                  ; Descripteur de fichier (stdout)
    mov rsi, buffer             ; Adresse du buffer
    mov rdx, 256                ; Taille du buffer
    syscall                     ; Appeler le noyau

    jmp read_file               ; Continuer à lire le fichier

close_file:
    ; Fermer le fichier
    mov rax, 3                  ; Appel système pour close
    mov rdi, [file_handle]      ; Handle du fichier
    syscall                     ; Appeler le noyau

exit_program:
    ; Quitter le programme
    mov rax, 60                 ; Appel système pour exit
    xor rdi, rdi                ; Code de retour 0
    syscall                     ; Appeler le noyau

; Fonction pour déchiffrer une chaîne avec XOR
xor_decrypt:
    mov al, [rsi]               ; Charger le caractère de la chaîne
    test al, al                 ; Vérifier si le caractère est nul
    jz xor_done                 ; Si oui, terminer
    xor al, [xor_key]           ; Appliquer XOR avec la clé
    mov [rsi], al               ; Stocker le caractère déchiffré
    inc rsi                     ; Passer au caractère suivant
    jmp xor_decrypt             ; Répéter la boucle
xor_done:
    ret                         ; Retourner