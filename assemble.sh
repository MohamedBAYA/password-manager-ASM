#!/bin/bash
# Assembler l'interface
nasm -f elf64 -o tests/io.o src/io.asm

# Assembler les modules de gestion de mot de passe
nasm -f elf64 -o tests/add_password.o src/functions/add_password.asm
nasm -f elf64 -o tests/retrieve_password.o src/functions/retrieve_password.asm
nasm -f elf64 -o tests/modify_password.o src/functions/modify_password.asm
nasm -f elf64 -o tests/master_password.o src/functions/master_password.asm
nasm -f elf64 -o tests/delete_password.o src/functions/delete_password.asm

# Assembler les modules de chiffrement (modifié pour être utilisé comme librairie)
nasm -f elf64 -o tests/chiffrement.o src/chiffrement.asm
nasm -f elf64 -o tests/dechiffrement.o src/dechiffrement.asm

# Lier les objets pour créer l'exécutable final
ld -o tests/password-manager tests/io.o tests/add_password.o tests/retrieve_password.o tests/modify_password.o tests/master_password.o tests/delete_password.o tests/chiffrement.o tests/dechiffrement.o

# Lancer l'exécutable
./tests/password-manager
