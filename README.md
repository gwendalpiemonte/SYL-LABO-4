# Labo 4 SYL Bras robot G.Piemontesi - G.Trueb

## Analyse des entrées/sorties

Le circuit d'origine comporte les entrées suivantes : `ready_i`, `color_i`, `clk_i`, et `reset_i`.

- `ready_i` : Arrive uniquement lorsque le bras est en position initiale, signalant qu'il est prêt à effectuer le scan d'une boîte.
- `color_i` : Arrive après qu'un scan a été effectué et définit la couleur de la boîte.
- `clk_i` : Signal d'horloge.
- `reset_i` : Réinitialisation asynchrone de l'ensemble du système.

Voici la table de vérité de color :
| Color Val | Signification           |
|-----------|-------------------------|
| 00        | Couleur indéterminée    |
| 01        | Rouge                   |
| 10        | Bleu                    |
| 11        | Erreur                  |

Ces entrées à elles seules ne permettent pas de réaliser tous les changements d'états comme requis. Pour cela, un compteur est nécessaire, générant la valeur 'compteur_done', qui indique si le bras a terminé son déplacement, car celui-ci prend 3 cycles d'horloge pour s'achever. Ce compteur renvoie la valeur 1 lorsqu'il atteint 1.

Les sorties correspondent simplement à la prochaine action à effectuer, c'est-à-dire le prochain état de la machine.
- `scan_o` : est à 1 si le système est pret a scanner une forme.
- `throw_o` : 1 lorsque le scan a produit la valeur 00, indiquant une couleur indéterminée.
- `move_o` : 1 lorsque le bras doit se déplacer, et cette sortie est activée simultanément avec la sortie définissant la destination de son déplacement.
- `dest_red_o` : 1 en même temps que `move_o` pour se déplacer vers la zone rouge.
- `dest_blue_o` : 1 en même temps que `move_o` pour se déplacer vers la zone bleue.
- `dest_init_o` : 1 en même temps que `move_o` pour se déplacer vers la zone initiale.
- `drop_o` : 1 lorsque le bras atteint la zone bleue/rouge et doit relâcher la pièce qu'il tient.

Étant donné que le bras fonctionne comme une machine d'état séquentielle de Moore, les sorties dépendent uniquement de l'état actuel et non des entrées.

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
   - Dès que le capteur de détection (ready_i) détecte une pièce, passer à l'état ScanColor.

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


## Table des états

## Equations des états furures et sorties

$$Wait^+ = Wait * \overline{ready} + Unknow * timer + ResetPos * timer$$
$$ScanColor^+ = Wait * ready + ScanColor * color0 * color1$$
$$Unknow^+ = ScanColor * \overline{color0} * \overline{color1}$$

