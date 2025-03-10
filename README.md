# 💾 Gestionnaire de Mots de Passe (ASM) 🔐
## Groupe 10 & 11 - (4Si3)

Le gestionnaire de mots de passe développé entièrement en assembleur x64 pour une gestion sécurisée et optimisée des mots de passe.

<p align="center">
  <img src="img/logo/password-manager.webp" alt="Logo">
</p>

---

## 🚀 Fonctionnalités

- ✅ **Ajouter** un nouveau mot de passe
- ✅ **Retrouver** un mot de passe existant
- ✅ **Modifier** un mot de passe
- ✅ **Supprimer** un mot de passe existant
- 🔐 **Protection avec un mot de passe maître** (stocké et chiffré)
- ❌ **Quitter le programme**

---

## 🛠 Installation

Clonez le dépôt :

```bash
# En https
git clone https://github.com/MohamedBAYA/password-manager-ASM.git
cd password-manager-ASM

# En ssh
git clone git@github.com:MohamedBAYA/password-manager-ASM.git
cd password-manager-ASM
```

Compilation du programme :

```bash
chmod +x assemble.sh
./assemble.sh
```

---

## 🚀 Lancement du programme

Si le fichier bash n'as pas lancer le binaire correctement, où que vous ne souhaitez pas le recompiler/assembler, exécutez simplement le gestionnaire de mots de passe avec la commande ci dessous :

```bash
./tests/password-manager
```

Lors du premier lancement, définissez votre mot de passe maître. Celui-ci sera demandé à chaque démarrage pour garantir la sécurité de vos données.

---

## 🗂 Structure du projet

- `src/`
  - `io.asm` *(Interface utilisateur et interactions)*
  - `functions/`
    - `add_password.asm` *(Fonction d'ajout de mot de passe - Option 1)*
    - `retrieve_password.asm` *(Fonction de récupération de mot de passe - Option 2)*
    - `modify_password.asm` *(Fonction de modification de mot de passe - Option 3)*
    - `delete_password.asm` *(Fonction de suppression de mot de passe - Option 4)*
    - `master_password.asm` *(Fonction d'ajout/verification du mot de passe maître - Au lancement + Option 4)*
  - `chiffrement.asm` *(Fonction de chiffrement de mot de passe + création de fichier sécurisé - Option 1/3)*
  - `dechiffrement.asm` *(Fonction de dechiffrement de mot de passe - Option 1/2)*

- `tests/`
  - Contient les fichiers objet et le binaire final après l'assemblage et la compilation.

- `src/config/`
  - `master/`
    - Stockage sécurisé du mot de passe maître (chiffré).
  - `passwords/`
    - Stockage sécurisé des mots de passe utilisateur (chiffrés).

---

## 🚀 Compilation et exécution

Exécutez simplement le script `assemble.sh` à la racine du projet :

```bash
./assemble.sh
```

Ce script génère l'exécutable nommé `password-manager` et le lance directement après compilation.

---

## 🚀 Contributions

Si vous souhaitez contribuer au projet, vous pouvez améliorer la sécurité en implémentant des algorithmes de chiffrement plus robustes (AES, SHA256, etc.) en assembleur.

---

## 📋 Équipe

| Rôle                    | Membre        |
|--------------------------|------------------|
| Interface utilisateur | Dylan |
| Chiffrement             | Clément x Jordan          |
| Intégration & Tests       | All             |
| Débogage et optimisation | Mohamed          |
| Documentation | Mohamed |

---

## 📅 Roadmap

- [x] Interface utilisateur fonctionnelle
- [x] Ajouter / Retrouver / Modifier un mot de passe
- [x] Supprimer un mot de passe
- [x] Mot de passe maître opérationnel

---

© 2025 ESGI – Projet Assembleur Avancé.