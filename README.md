# Labo 4 SYL Bras robot G.Piemontesi - G.Trueb

## Élaboration du graphe des états
Selon les comportements suivants du bras :

- Lorsqu'une pièce arrive devant le bras, le capteur de détection (ready_i) monte son signal à '1'.   
- Pour permettre la détection d'une couleur, le signal scan_o doit être mis à '1'.   
- Le scan effectué par le capteur de couleur se fait en un seul coup d'horloge du système.   
- Si la couleur est inconnue, alors le signal throw_o doit être mis à '1' pendant un cycle.   
- Si une des couleurs est connue, alors le bras doit se diriger au-dessus du compartiment correspondant.   
- Tant qu'il y a une erreur de scan, le système doit continuer à scanner jusqu'à obtenir l'un des trois résultats attendus.   
- Pour déplacer le bras, le signal move_o ainsi que l'un des signaux dest_red_o, dest_blue_o ou dest_init_o doivent être mis à '1' afin d'indiquer la direction du mouvement. Ceci pendant toute la durée du déplacement.   
- Le bras met du temps à se déplacer. Il est nécessaire d'attendre la fin du déplacement du bras.   
- Une fois au-dessus de l'un des compartiments, le signal drop_o doit être mis à '1' durant un cycle d'horloge avant de replacer le bras dans sa position initiale (en prenant à nouveau en compte le temps de déplacement du bras).   

Il nous a été possible d'élaborer un graphe d'état que voici.

<img src="/StateGraph.drawio.png" width="1000"/>

1. **Wait :**
   - Attente de l'arrivée d'une pièce devant le bras.
   - Dès que le capteur de détection (ready_i) détecte une pièce, passer à l'état suivant.

2. **ScanColor :**
   - Mettre le signal scan_o à '1' pour permettre la détection de la couleur.
   - Le scan de couleur se fait en un seul coup de clock.
   - Tant qu'il y a une erreur de scan, continuer à scanner jusqu'à obtenir l'un des trois résultats attendus.

3. **Unknow :**
   - Si la couleur est inconnue, activer le signal throw_o pendant un cycle et retourner à l'état Wait.

4. **Blue/Red :**
   - Si la couleur est connue, diriger le bras au-dessus du compartiment correspondant.
   - Mettre le signal move_o à '1' et l'un des signaux dest_red_o, dest_blue_o, ou dest_init_o pour indiquer la direction du mouvement.
   - Maintenir ces signaux activés pendant toute la durée du déplacement du bras.
   - Attendre la fin du déplacement du bras avant de passer à l'état suivant.

5. **Drop :**
   - Une fois au-dessus de l'un des compartiments, activer le signal drop_o pendant un cycle d'horloge.

6. **ResetPos :**
   - Retourner à l'état initial en prenant en compte le temps de déplacement du bras.

Ce schéma des états décrit le fonctionnement du bras en réponse aux différents événements et conditions spécifiés.

