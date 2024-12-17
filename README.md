# Micro-ondes-VHDL

## Cahier des Charges

Ce projet consiste à réaliser le système contrôlant un micro-onde en VHDL sur une carte BASYS3. Les spécifications du système sont les suivantes :

### Composants

- **2 LEDs** : Simulent le buzzer et l’activation du magnétron.
- **1 Interrupteur** : Sert de capteur pour indiquer si la porte est fermée.
- **Des interrupteurs** : Permettent de sélectionner le temps de fonctionnement.
- **Le bouton central** : Utilisé pour lancer le système.
- **Les afficheurs 7 segments** : Affichent le temps restant.

### Fonctionnalités

1. **Activation du magnétron et du buzzer** :
    - Les LEDs simulent l'activation du magnétron et du buzzer.
    
2. **Capteur de porte** :
    - Un interrupteur sert de capteur pour détecter si la porte du micro-onde est fermée.
    
3. **Sélection du temps de fonctionnement** :
    - Des interrupteurs permettent de sélectionner le temps de fonctionnement du micro-onde.
    
4. **Lancement du système** :
    - Le bouton central est utilisé pour démarrer le micro-onde.
    
5. **Affichage du temps restant** :
    - Les afficheurs 7 segments montrent le temps restant de cuisson.

### Schéma de Connexion

```mermaid
graph TD;
     A[LEDs] -->|Activation du magnétron| B[led_magnetron_o];
     A -->|Buzzer| C[led_buzzer_o];
     D[Interrupteurs] -->|Porte fermée| E[porte_ferme];
     D -->|Sélection du temps| F[selection_temps];
     G[Bouton central] -->|Démarrer/Arrêter| H[start_stop];
     I[Afficheurs 7 segments] -->|Temps restant| J[afficheur_temps];
```

### Diagramme de Fonctionnement

```mermaid
sequenceDiagram
     participant Utilisateur
     participant Micro-onde

     Utilisateur->>Micro-onde: Ferme la porte
     Micro-onde-->>Utilisateur: Porte détectée fermée
     Utilisateur->>Micro-onde: Sélectionne le temps
     Utilisateur->>Micro-onde: Appuie sur le bouton central
     Micro-onde-->>Utilisateur: Démarrage du micro-onde
     Micro-onde-->>Utilisateur: Affichage du temps restant
     Micro-onde-->>Utilisateur: Fin de cuisson, buzzer activé
```

### Schéma de la Machine à État

```mermaid
stateDiagram
    [*] --> Idle
    Idle --> DoorClosed : Porte fermée
    DoorClosed --> TimeSelected : Temps sélectionné
    TimeSelected --> Cooking : Bouton central appuyé
    Cooking --> Idle : Temps écoulé / Buzzer activé
    Cooking --> Idle : Bouton central appuyé / Arrêt manuel
    DoorClosed --> Idle : Porte ouverte
    TimeSelected --> Idle : Porte ouverte
```

### Images des Composants

![Carte BASYS3](https://example.com/basys3.jpg)
![LEDs](https://example.com/leds.jpg)
![Interrupteurs](https://example.com/switches.jpg)
![Bouton central](https://example.com/button.jpg)
![Afficheurs 7 segments](https://example.com/7segments.jpg)

## Conclusion

Ce projet permet de simuler le fonctionnement d'un micro-onde en utilisant VHDL sur une carte BASYS3. Les différentes fonctionnalités sont implémentées à l'aide de LEDs, interrupteurs, un bouton central et des afficheurs 7 segments pour offrir une expérience utilisateur complète.