section .data
    message db "HELLO", 0  ; Message à chiffrer (NULL-terminé)
    key db "SECRET", 0     ; Clé de chiffrement (NULL-terminée)
    newline db 10, 0       ; Caractère de saut de ligne

section .bss
    encrypted resb 32       ; Espace réservé pour le message chiffré (longueur fixe)

section .text
global _start

_start:
    ; ======= Chiffrer le message =======
    mov rdi, message       ; Adresse du message
    mov rsi, key           ; Adresse de la clé
    mov rdx, 5             ; Longueur fixe du message (5 pour "HELLO")
    call xor_encrypt       ; Appel de la fonction XOR

    ; ======= Déchiffrer le message (XOR à nouveau) =======
    mov rdi, message       ; Adresse du message
    mov rsi, key           ; Adresse de la clé
    mov rdx, 5             ; Longueur fixe du message
    call xor_encrypt       ; Déchiffrement (XOR encore)

    jmp _exit

; ==========================
; Fonction xor_encrypt
; ==========================
; Arguments :
; rdi -> message (adresse)
; rsi -> clé (adresse)
; rdx -> longueur fixe du message
; 
; La fonction utilise une longueur fixe pour éviter les problèmes d'octets nuls
; ==========================
xor_encrypt:
    ; Vérifier si les pointeurs sont valides
    test rdi, rdi
    jz .error
    test rsi, rsi
    jz .error

    ; Réinitialisation des index
    xor r10, r10  ; Index pour parcourir le message (i = 0)
    xor r11, r11  ; Index pour parcourir la clé (j = 0)

.loop:
    cmp r10, rdx
    jge .done  ; Empêcher d'écrire au-delà de la mémoire allouée

    mov al, [rdi + r10]  ; Charger un octet du message
    mov bl, [rsi + r11]  ; Charger un octet de la clé
    xor al, bl           ; Appliquer XOR
    mov [rdi + r10], al  ; Stocker le résultat

    ; Incrémenter les index
    inc r10              ; i++
    inc r11              ; j++

    cmp r11, 40
    jne .skip_reset
    xor r11, r11         ; Réinitialiser j à 0 si clé épuisée

.skip_reset:
    jmp .loop

.done:
    ret

.error:
    mov rax, -1
    ret


_exit: 
    mov rax, 60
    xor rdi, rdi
    syscall