section .data
    sha256sum db "/usr/bin/sha256sum", 0  ; Chemin de la commande sha256sum
    arg0 db "sha256sum", 0                ; Premier argument (nom de la commande)

section .bss
    argv resq 3                           ; Tableau d'arguments pour execve

section .text
    global _start

_start:
    ; Récupérer le nom du fichier passé en argument
    pop rcx                     ; Nombre d'arguments (argc)
    cmp rcx, 2                  ; Vérifier qu'il y a exactement 1 argument (plus le nom du programme)
    jne exit_program            ; Si ce n'est pas le cas, quitter

    pop rsi                     ; Ignorer le premier argument (nom du programme)
    pop rsi                     ; Récupérer le nom du fichier (premier argument)

    ; Préparer les arguments pour execve
    mov qword [argv], arg0      ; Premier argument : "sha256sum"
    mov qword [argv + 8], rsi   ; Deuxième argument : nom du fichier
    mov qword [argv + 16], 0    ; Terminer le tableau d'arguments par NULL

    ; Appeler execve
    mov rax, 59                 ; Appel système pour execve
    mov rdi, sha256sum           ; Chemin de la commande
    mov rsi, argv                ; Tableau d'arguments
    mov rdx, 0                   ; Environnement (NULL)
    syscall

    ; Si execve échoue, quitter le programme
exit_program:
    mov rax, 60                 ; Appel système pour exit
    xor rdi, rdi                ; Code de retour 0
    syscall