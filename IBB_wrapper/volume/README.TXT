NOTA INTERNA:

Tutti questi flag sono da testare.

In fondo e' riportato un vademecum sulle impostazioni dei flag per simulare le varie versioni.

				-------------------------------------------------------------

Flag nuovi aggiunti nel file di configurazione:

--------------------------------------------------------------------------
NewGMPeak=N		;Use new start point for GM peak searching ? Yes, {No}
NewR2=N			;Use new R2 calculation method ? Yes, {No}
NewR2Box=N		;Use new R2 box align method ? Yes, {No}
NewErode=N		;Use new mucosa erode method ? Yes, {No}
Piedistallo=0.1		;Fraction of peak value to which set the interval. {0.1 (10%)}

--------------------------------------------------------------------------

Modifiche al significato di
--------------------------------------------------------------------------
PDNoise=320.0		;Background noise for PDw signal. If it is less than zero, it will be estimated from the PDW signal. {320.0}

				-------------------------------------------------------------

Significato:


NewGMPeak:

se disabilitato, verra' usato il metodo presente nella versione 1.0.12
per cercare il picco della grigia:
partendo da un R1 di 50 in su per ricercare il picco della grigia. 
Se abilitato, parte dall'R1 inferiore del box della grigia.

Dovrebbe dare risultati differenti solo su Philips non corretto, 
dove il picco della grigia puo' essere inferiore a 0.5 sec-1.
Per altre macchine non dovrebbero esserci differenze di sorta.


NewR2:

se abilitato calcola R2 in modo piu' preciso, in particolare eliminando
errori di troncamento nella riscalatura a 210 dell'R2 ed eliminando la
saturazione a 210 su R2.

Dovrebbe dare risultati comparabili (differenti solo sulle cifre meno significative).
- DA TESTARE.


NewR2Box:

se abilitato sposta l'R2 dei box con uno shift anziche' una moltiplicazione.
- DA TESTARE.


NewErode:

se abilitato fa usare il nuovo algoritmo di erosione della mucosa.
- DA TESTARE.


Piedistallo:

consente di specificare la frazione del picco sull'istogramma di R1 in cui
settare l'intervallo per la soglia di separazione R1 G/W.

Il valore di 0.1 e' usato fino alla versione 1.0.14 compresa.
Lo 0.15 e' usato dalla 1.0.15 in poi. Usando un valore diverso da 0.1 andrebbe modificata 
di conseguenza la soglia di separazione Grigia/Bianca.
- DA TESTARE.


PDNoise:

da questa versione e' stata introdotta una nuova feature su PDNoise.

Per valori maggiori di zero, nulla cambia.

Per valore = -1.0, la soglia effettiva e' calcolata
come valore di picco del segnale PDW, diviso 5.0.

Per valori da -4.0 in giu', la soglia e' calcolata come valore di picco
di PDW diviso il modulo del valore.

Cioe' e' possibile impostare la soglia PDW
come MaxPDW/5, specificando -5.0, oppure MaxPDW/10 specificando -10.0, ecc...

In modalita' Debug e' stampata a video
la soglia effettiva usata.

- DA TESTARE.

				-------------------------------------------------------------

Distribuiti con il programma ci sono 4 file di coordinate tessuti:

box.dat						BOX DELLA VERSIONE FORTRAN
box_basso_R1_grigia.dat				BOX PER PHILIPS NON CORRETTO
box_nuclei.dat					BOX PER ATTIVARE NUCLEI
box_nuclei_basso_R1_grigia.dat			BOX PER PHILIPS E NUCLEI

Nuclei e' la procedura di ripulitura, che classifica per contiguita'.
Sono stati allargati i box di pallidus e putamen.

Non presente nelle versioni precedenti alla 1.0.16

- DA TESTARE

				-------------------------------------------------------------

VADEMECUM PER VERSIONI:

Versione | NewGMPeak | NewR2 | NewR2Box | NewErode | Piedistallo
1.0.12   |     N     |   N   |     N    |     N    |     0.1
1.0.13   |     N     |   N   |     N    |     N    |     0.1
1.0.14   |     N     |   N   |     N    |     N    |     0.1
1.0.15   |     Y     |   N   |     N    |     N    |     0.15
1.0.16   |     Y     |   N   |     N    |     N    |     0.15
1.0.17   |     Y     |   Y   |     Y    |     N    |     0.15
1.0.17a  |     Y     |   Y   |     Y    |     N    |     0.15
1.0.17c  |     Y     |   Y   |     Y    |     Y    |     0.15
1.0.17d  |     Y     |   Y   |     Y    |     Y    |     0.15

Per maggiore sicurezza e' ancora possibile usare il vecchio coor_segxxxx.dat

Se si usa il file di configurazione vecchio, sara' simulata la versione 1.0.12

Percio', per simulare le altre versioni, modificare il file di config scaricato
assieme ai sorgenti secondo la precedente tabella.

				-------------------------------------------------------------

Altre modifiche minori, presenti in questa versione che sono ininfluenti per il resto
dell'algoritmo sono:

 Aggiunta path per config da riga di comando --- (versione 1.0.17d)
 Ricerca inteligente del separatore dei path --- (nuova feature)
 Produzione incondizionata di QMCI.lis --- (nuova feature)
 Patch per mkdir per Windows --- (nuova feature: compilazione sotto WINDOWS nativa)
 Versione del programma usato riportata in GLOBAL.DAT e VOLUMES.DAT --- (nuova feature)
 Copia del file di configurazione e dei box usati nella directory di uscita --- (nuova feature)
 Ripetizione segmentazione se dopo erosione c'e' poca grigia o bianca --- (nuova feature)

