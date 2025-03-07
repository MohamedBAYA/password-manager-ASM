section .data
    space db " "                ; Caractère espace
    newline db 0xA              ; Caractère de nouvelle ligne

section .bss
    file_handle resq 1          ; Handle du fichier

section .text
    global _start

_start:
    ; Récupérer les arguments de la ligne de commande
    pop rcx                     ; Nombre d'arguments (argc)
    cmp rcx, 4                  ; Vérifier qu'il y a exactement 3 arguments (plus le nom du programme)
    jne exit_program            ; Si ce n'est pas le cas, quitter

    ; Récupérer les arguments
    pop rsi                     ; Ignorer le premier argument (nom du programme)
    pop rsi                     ; Récupérer le mot de passe (premier argument)
    mov r8, rsi                 ; Sauvegarder le mot de passe dans r8
    pop rsi                     ; Récupérer le site web (deuxième argument)
    mov r9, rsi                 ; Sauvegarder le site web dans r9
    pop rsi                     ; Récupérer le nom du fichier (troisième argument)
    mov r10, rsi                ; Sauvegarder le nom du fichier dans r10

    ; Ouvrir le fichier en mode append (O_WRONLY | O_APPEND | O_CREAT)
    mov rax, 2                  ; Appel système pour open
    mov rdi, r10                ; Nom du fichier
    mov rsi, 0x401              ; O_WRONLY | O_APPEND | O_CREAT
    mov rdx, 0o644              ; Permissions du fichier (rw-r--r--)
    syscall                     ; Appeler le noyau
    cmp rax, 0                  ; Vérifier si l'ouverture a réussi
    jl exit_program             ; Si échec, quitter
    mov [file_handle], rax      ; Stocker le handle du fichier

    ; Écrire le mot de passe dans le fichier
    mov rsi, r8                 ; Adresse du mot de passe
    call strlen                 ; Calculer la longueur du mot de passe
    mov rdx, rax                ; Longueur du mot de passe
    mov rax, 1                  ; Appel système pour write
    mov rdi, [file_handle]      ; Handle du fichier
    syscall                     ; Appeler le noyau

    ; Écrire un espace
    mov rax, 1                  ; Appel système pour write
    mov rdi, [file_handle]      ; Handle du fichier
    lea rsi, [rel space]        ; Adresse de l'espace
    mov rdx, 1                  ; Longueur de l'espace
    syscall                     ; Appeler le noyau

    ; Écrire le site web dans le fichier
    mov rsi, r9                 ; Adresse du site web
    call strlen                 ; Calculer la longueur du site web
    mov rdx, rax                ; Longueur du site web
    mov rax, 1                  ; Appel système pour write
    mov rdi, [file_handle]      ; Handle du fichier
    syscall                     ; Appeler le noyau

    ; Écrire une nouvelle ligne
    mov rax, 1                  ; Appel système pour write
    mov rdi, [file_handle]      ; Handle du fichier
    lea rsi, [rel newline]      ; Adresse de la nouvelle ligne
    mov rdx, 1                  ; Longueur de la nouvelle ligne
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