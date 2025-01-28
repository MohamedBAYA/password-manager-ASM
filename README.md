# 💾 Gestionnaire de Mots de Passe (ASM) 🔐

## 📌 Description
Un gestionnaire de mots de passe simple, développé en assembleur **x64**, permettant de :  
✅ **Ajouter, consulter et supprimer** des mots de passe.  
✅ **Chiffrer** les mots de passe pour les protéger.  
✅ **Stocker** les mots de passe dans un fichier sécurisé.  

---

## 🎯 Objectifs
🎯 Appliquer les concepts **d'assembleur avancé**.  
🎯 Implémenter des **fonctionnalités essentielles** d'un gestionnaire de mots de passe.  
🎯 Mettre en œuvre un **chiffrement basique et efficace**.  

---

## 📌 Répartition des Tâches

👤 **Gestion des E/S utilisateur** (**[Nom du membre 1]**)  
➜ Développement des **entrées/sorties** : lecture du clavier, affichage du menu et interaction avec l'utilisateur.  
➜ Masquer la saisie des mots de passe lorsqu'ils sont tapés.  

🔐 **Chiffrement des mots de passe** (**[Nom du membre 2]**)  
➜ Implémentation d'un **chiffrement XOR** dans un premier temps.  
➜ Si le temps le permet, ajout d’un chiffrement plus avancé comme **AES** ou **SHA**.  

📁 **Gestion du stockage** (**[Nom du membre 3]**)  
➜ Lecture et écriture des mots de passe dans un **fichier sécurisé**.  
➜ Assurer la gestion des erreurs et la protection contre la corruption du fichier.  

🛠 **Intégration & Gestion globale** (**[Nom du membre 4]**)  
➜ **Assembler toutes les parties** en un programme fonctionnel.  
➜ Vérifier la **compatibilité des modules** et gérer les appels entre eux.  
➜ **Tests et débogage** pour s'assurer que chaque partie fonctionne correctement ensemble.  
➜ Éventuellement, gérer l’**optimisation** du programme pour de meilleures performances.  

---

## 📁 Structure du projet
📂 **`src/`** → Contient le **code source** divisé par modules.  
🛠 **`tests/`** → Contient les **scripts de test** pour chaque module individuellement.  
📜 **`docs/`** → Documentation technique et notes sur le projet.  

---

## 📌 Suivi & Améliorations
- ✅ **Phase 1** : Développement des modules individuels et attributions de rôles. (Réu 1 - Samedi 01 15h00)
- 🔄 **Phase 2** : Affinements des modules et intégration + tests. (Réu 2 - A définir)
- 📊 **Phase 3** : Finalisation et documentation (Réu 3 - A définir).  
