# Gestionnaire de Mots de Passe en Assembleur

Ce projet est un gestionnaire de mots de passe développé en assembleur x86_64. Il a pour objectif de mettre en œuvre des fonctionnalités de base (ajout, récupération, modification et suppression de mots de passe) tout en intégrant des mesures de sécurité (mot de passe maître, chiffrement par XOR, stockage dans des répertoires dédiés).

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Structure du projet](#structure-du-projet)
- [Fonctionnalités](#fonctionnalités)
  - [Mot de passe maître](#mot-de-passe-maître)
  - [Ajouter un mot de passe](#ajouter-un-mot-de-passe)
  - [Récupérer un mot de passe](#récupérer-un-mot-de-passe)
  - [Modifier un mot de passe](#modifier-un-mot-de-passe)
  - [Supprimer un mot de passe](#supprimer-un-mot-de-passe)
- [Modules de chiffrement](#modules-de-chiffrement)
- [Instructions d'assemblage et de lancement](#instructions-dassemblage-et-de-lancement)
- [Améliorations futures](#améliorations-futures)

## Vue d'ensemble

Le gestionnaire de mots de passe permet à un utilisateur, après authentification via un mot de passe maître, de :
- Ajouter un nouveau mot de passe (création d'un fichier chiffré dans `src/config/passwords/`).
- Récupérer (lire et déchiffrer) un mot de passe existant.
- Modifier un mot de passe existant (en vérifiant que le nouveau mot de passe diffère de l'ancien).
- Supprimer un mot de passe en supprimant le fichier correspondant.

Pour le chiffrement, une méthode simple basée sur l'opération XOR est utilisée pour chiffrer et déchiffrer les mots de passe.

## Structure du projet

```
password-manager-ASM/
├── assemble.sh
├── README.md
├── docs/
│   └── docs.md
├── src/
│   ├── io.asm
│   ├── chiffrement.asm
│   ├── dechiffrement.asm
│   ├── config/
│   │   ├── passwords/
│   │   └── master/
│   └── functions/
│       ├── add_password.asm
│       ├── retrieve_password.asm
│       ├── modify_password.asm
│       ├── delete_password.asm
│       └── master_password.asm
└── tests/
    ├── io.o
    ├── add_password.o
    ├── retrieve_password.o
    ├── modify_password.o
    ├── delete_password.o
    ├── master_password.o
    ├── chiffrement.o
    └── dechiffrement.o
    └── password-manager
```

## Fonctionnalités

### Mot de passe maître

Permet de sécuriser l'application via un mot de passe maître, demandé à chaque lancement & pour la suppression d'un mot de passe également.

### Ajouter un mot de passe

Permet d'ajouter et chiffrer un nouveau mot de passe dans un fichier.

### Récupérer un mot de passe

Permet de lire et déchiffrer un mot de passe existant.

### Modifier un mot de passe

Permet de modifier un mot de passe existant, après vérification qu'il est différent de l'ancien.

### Supprimer un mot de passe

Permet de supprimer un mot de passe existant après vérification du mot de passe maître.

## Modules de chiffrement

Utilisent une clé XOR simple (`0xAA`) pour chiffrer et déchiffrer les données stockées.

## Instructions d'assemblage et de lancement

Voici le script d'assemblage complet :

```bash
#!/bin/bash
# Assembler l'interface
nasm -f elf64 -o tests/io.o src/io.asm

# Assembler les modules de gestion de mot de passe
nasm -f elf64 -o tests/add_password.o src/functions/add_password.asm
nasm -f elf64 -o tests/retrieve_password.o src/functions/retrieve_password.asm
nasm -f elf64 -o tests/modify_password.o src/functions/modify_password.asm
nasm -f elf64 -o tests/master_password.o src/functions/master_password.asm
nasm -f elf64 -o tests/delete_password.o src/functions/delete_password.asm

# Assembler les modules de chiffrement
nasm -f elf64 -o tests/chiffrement.o src/chiffrement.asm
nasm -f elf64 -o tests/dechiffrement.o src/dechiffrement.asm

# Lier les objets pour créer l'exécutable final
ld -o tests/password-manager tests/io.o tests/add_password.o tests/retrieve_password.o tests/modify_password.o tests/master_password.o tests/delete_password.o tests/chiffrement.o tests/dechiffrement.o

# Lancer l'exécutable
./tests/password-manager
```

## Améliorations futures

- Utiliser un algorithme de hachage plus sécurisé (SHA-256).
- Ajouter des confirmations supplémentaires lors des suppressions.
- Améliorer l'interface utilisateur.
- Ajouter des fonctions avancées de gestion des mots de passe.