section .data
    message db "HELLO", 0  ; Message à chiffrer (NULL-terminé)
    key db "SECRET", 0           ; Clé de chiffrement (NULL-terminée)
    newline db 10, 0             ; Caractère de saut de ligne

section .bss
    encrypted resb 12    ; Espace réservé pour le message chiffré

section .text
global _start


_start:
    ; ======= Chiffrer le message =======
    mov rdi, message  ; Adresse du message
    mov rsi, key      ; Adresse de la clé
    call xor_encrypt  ; Appel de la fonction XOR

    ; ======= Déchiffrer le message (XOR à nouveau) =======
    mov rdi, message  ; Adresse du message
    mov rsi, key      ; Adresse de la clé
    call xor_encrypt  ; Déchiffrement (XOR encore)

    jmp _exit

; ==========================
; Fonction xor_encrypt
; ==========================
; Arguments :
; rdi -> message (adresse, chaîne NULL-terminée)
; rsi -> clé (adresse, chaîne NULL-terminée)
; 
; La fonction détecte la taille du message et de la clé automatiquement
; ==========================
xor_encrypt:
    ; Vérifier si les pointeurs sont valides
    test rdi, rdi
    jz .error
    test rsi, rsi
    jz .error

    ; Calculer la longueur du message (chercher 0x00)
    mov rdx, rdi
    xor r8, r8  ; r8 = compteur longueur du message

.find_message_length:
    cmp byte [rdx], 0
    je .found_message_len
    inc rdx
    inc r8
    jmp .find_message_length

.found_message_len:
    ; r8 contient maintenant la longueur du message

    ; Calculer la longueur de la clé (chercher 0x00)
    mov rcx, rsi
    xor r9, r9  ; r9 = compteur longueur clé

.find_key_length:
    cmp byte [rcx], 0
    je .found_key_len
    inc rcx
    inc r9
    jmp .find_key_length

.found_key_len:
    test r9, r9
    jz .error  ; Vérifier si la clé est vide

    ; Réinitialisation des index (important pour éviter un comportement aléatoire après le premier appel)
    xor r10, r10  ; Index pour parcourir le message (i = 0)
    xor r11, r11  ; Index pour parcourir la clé (j = 0)

.loop:
    cmp r10, r8
    jge .done  ; Empêcher d'écrire au-delà de la mémoire allouée

    mov al, [rdi + r10]  ; Charger un octet du message
    mov bl, [rsi + r11]  ; Charger un octet de la clé
    xor al, bl           ; Appliquer XOR
    mov [rdi + r10], al  ; Stocker le résultat

    ; Vérifier si l'octet est devenu NULL (problème d'affichage avec `x/s`)
    test al, al
    jnz .continue_xor
    mov byte [rdi + r10], 1  ; Remplace le NULL par un caractère non NULL

.continue_xor:
    inc r10              ; i++
    inc r11              ; j++

    cmp r11, r9
    jne .skip_reset
    xor r11, r11         ; Réinitialiser j à 0 si clé épuisée

.skip_reset:
    cmp r10, r8
    jne .loop

    mov byte [rdi + r8], 0  ; Forcer la terminaison NULL

.done:
    mov rax, 0
    ret

.error:
    mov rax, -1
    ret

; TODO: Corriger la fonction dans le cas d'une gestion de caractère null
; ==========================
; Fonction print_string
; ==========================
; Arguments :
; - rdi = adresse du message (NULL-terminé)
;
; Après l'exécution :
; - Le message est affiché sur stdout
; - rax contient le nombre d'octets écrits
; ==========================
print_string:
    ; Trouver la longueur de la chaîne
    mov rsi, rdi
    xor rdx, rdx

.find_length:
    cmp byte [rsi], 0
    je .print
    inc rsi
    inc rdx
    jmp .find_length

.print:
    mov rax, 1  ; syscall: write
    mov rdi, 1  ; file descriptor: stdout
    syscall
    ret


_exit: 
    mov rax, 60
    xor rdi, rdi
    syscall