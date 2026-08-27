# accesscodegeneratorqbasic64
GoldenRatio-Auth: A QBasic/QB64 Big-Integer Security Proof-of-Concept
# AccessCode Generator & Verificator (QB64)

Een QB64(PE) BASIC project dat een uniek, 256-cijferig numeriek "toegangscode"-token genereert op basis van een gebruikersnaam en wachtwoord (plus een geheime "pepper"), via een eigen big-integer/φ-gebaseerd algoritme ("R-Module"). Het project bestaat uit twee onderdelen: een grafische **generator** en een console-gebaseerde **verificator (login)**.

Dit project is in de eerste plaats gebouwd als **technische proof-of-concept**: om te laten zien dat je in QBasic/QB64 zelf big-integer-rekenkunde, een eigen hash-achtig algoritme én een bijpassende grafische interface met animaties kan bouwen — niet primair als kant-en-klare, productierijpe authenticatie-oplossing.

## ✨ Features

- **Grafische generator** (`SCREEN 12`) met muis- en toetsenbordbediening:
  - Invoervelden voor gebruikersnaam en wachtwoord (met gemaskeerd wachtwoordveld)
  - Knoppen om te genereren, velden te wissen en de code te kopiëren naar het klembord
  - Live animatie (deeltjes/spiraal) tijdens het genereren van de code
  - Automatische opslag van gegenereerde codes in een CSV-bestand, met controle op unieke codes
- **Console-verificator**:
  - Vraagt om gebruikersnaam en wachtwoord in een oneindige loop
  - Herberekent dezelfde 256-cijferige code met exact dezelfde R-Module-logica
  - Vergelijkt met een hardcoded hash-waarde uit de generator
- **Eigen big-integer implementatie** (optellen, aftrekken, vermenigvuldigen, machtsverheffen) om met zeer grote getallen te kunnen rekenen zonder externe libraries
- Seed wordt (mede) afgeleid uit de eerste 500+ cijfers van π√5≈φ (het getal φ, de gulden snede) om extra entropie/variatie toe te voegen

## 📁 Bestanden

| Bestand | Beschrijving |
|---|---|
| `rmodlogingenerator475bigintstblevisual6generator.txt` (hernoem naar `.bas`) | Grafische generator: voert username/password in, berekent de 256-cijferige code en logt deze in een CSV-bestand |
| `rmodlogingenerator475bigintstblevisual6verificator.txt` (hernoem naar `.bas`) | Console-login: herberekent de code en vergelijkt met een hardcoded hash |

> **Let op:** GitHub/uploads zetten de bestanden vaak om naar `.txt`. Hernoem ze naar `.bas` voordat je ze in QB64 opent.

## ⚙️ Vereisten

- [QB64](https://www.qb64.org/) of [QB64PE](https://qb64phoenix.com/) (aanbevolen, actief onderhouden fork)
- Werkt op Windows, Linux en macOS (het script detecteert het OS en past shell-commando's aan)

## 🚀 Gebruik

### 1. Genereer een accesscode

1. Open `generator.bas` in QB64(PE) en compileer/run het.
2. Vul een gebruikersnaam (min. 3 tekens) en wachtwoord (min. 5 tekens) in.
3. Klik op **GENEREER CODE** (of druk op Enter).
4. Bekijk de animatie en de resulterende 256-cijferige code in het outputvenster.
5. Klik op **KOPIEER LAATSTE CODE** (of Ctrl+C) om de code naar het klembord te kopiëren.
6. De code wordt automatisch, samen met een timestamp, weggeschreven naar een CSV-bestand (zie hieronder).

**Sneltoetsen generator:**

| Toets | Actie |
|---|---|
| `Tab` | Wissel tussen gebruikersnaam-/wachtwoordveld |
| `Enter` | Genereer code |
| `Ctrl+X` | Wis invoervelden |
| `Ctrl+C` | Kopieer laatste code |
| `Esc` | Afsluiten |

### 2. Verifieer een login

1. Open `verificator.bas`, plak de gegenereerde 256-cijferige code als waarde van `HASH_TO_MATCH` (regel bovenin het bestand).
2. Compileer/run het bestand.
3. Voer bij de prompt dezelfde gebruikersnaam en wachtwoord in als bij het genereren.
4. Bij een match toont het script `LOGIN OK`; anders kun je het opnieuw proberen (oneindige loop).

### 3. Eigen credentials verifiëren

Wil je zelf testen of jouw combinatie van gebruikersnaam/wachtwoord klopt tegen een gegenereerde code?

1. Genereer eerst een accesscode met `generator.bas` voor jouw gewenste gebruikersnaam + wachtwoord.
2. Kopieer de resulterende 256-cijferige code.
3. Plak deze in `verificator.bas` als waarde van de constante `HASH_TO_MATCH`.
4. Run de verificator en log in met dezelfde gebruikersnaam en wachtwoord — dit zou `LOGIN OK` moeten geven.

## 🏆 Challenge

Denk je dat het onderliggende algoritme (de manier waarop uit gebruikersnaam + wachtwoord + pepper een 256-cijferige code wordt afgeleid) zwakheden bevat? Iedereen die erin slaagt om, gegeven een `HASH_TO_MATCH`, de bijbehorende gebruikersnaam/wachtwoord-logica te kraken (bijvoorbeeld door een geldige combinatie terug te vinden zonder de originele invoer te kennen), krijgt hiermee erkenning dat het systeem aantoonbaar onveilig is — met vermelding van die persoon als degene die dit heeft aangetoond.

### CSV-opslag

De generator maakt automatisch een map en CSV-bestand aan om gegenereerde codes te loggen en dubbele codes te voorkomen:

- Windows: `C:\ACCESSCODE\ACCESSCODE.CSV`
- Linux/macOS: `/ACCESSCODE/ACCESSCODE.CSV`

Formaat: `timestamp,accesscode`

## 🔧 Configuratie

Beide bestanden bevatten een constante `PEPPER` bovenaan het bestand:

```basic
Const PEPPER = "MijnGeheimePepper123!@#$%^&*()_+"
```

Deze **moet identiek zijn** in generator en verificator, anders komen de berekende codes nooit overeen.

> **Let op:** de waarde die in dit project staat is een **voorbeeld-/demo-pepper**, bewust ingevuld zodat je de generator en verificator meteen kan uittesten zonder eerst zelf iets te hoeven configureren. In een echte toepassing vult elke gebruiker/installatie hier een **eigen, geheime, niet-gedeelde waarde** in — en houdt die geheim, dus ook niet gepubliceerd op GitHub zoals nu het geval is met de demo-waarde.

## 🔍 Hoe moeilijk is dit systeem echt te kraken?

Er is weleens beweerd dat de truncatiestap (van 1024 naar 256 cijfers) reconstructie "mathematisch onmogelijk" maakt en dat dit systeem daarom een bewezen one-way function is. Dat verdient een genuanceerder antwoord:

- De truncatie/permutatie/modulo-optelling zorgt er inderdaad voor dat je het **interne 1024-cijferige tussenresultaat niet exact kan terugrekenen** uit de 256-cijferige output. Dat klopt.
- Maar dat is niet de relevante aanval. Niemand hoeft de tussenstappen te inverteren: een aanvaller test simpelweg combinaties van username + password **voorwaarts** door ze door het algoritme te halen en te vergelijken met de doelcode — precies zoals bij elk ander hash-gebaseerd systeem (brute force / woordenboekaanval).
- De echte moeilijkheidsgraad zit dus in de **grootte van de username/password-zoekruimte** en de **rekenkosten per gok** (12 rondes × honderden big-integer-vermenigvuldigingen maakt elke poging relatief traag, vergelijkbaar met het idee achter trage KDF's als bcrypt/Argon2) — niet in de onomkeerbaarheid van de truncatie zelf.
- Omdat de meegeleverde `PEPPER` een gepubliceerde demo-waarde is, valt die factor in dit voorbeeldproject als extra verdedigingslaag weg voor iedereen die de repo leest. Pas dus altijd een eigen, geheime pepper toe voordat je dit voor iets echts gebruikt.

## 🧠 Hoe het werkt (kort)

1. **Seed opbouwen** (`BuildBigSeed`): gebruikersnaam + wachtwoord + pepper worden karakter voor karakter omgezet naar een groot getal (big-integer array).
2. **R-Module**: met die seed worden, via 12 iteratieronden en machtsverheffing met cijfers uit φ (gulden snede), grote getallen op- en afgeteld tot een reeks van 1024 cijfers ontstaat.
3. **Truncatie/scrambling**: afhankelijk van een uit de seed afgeleide strategie (0–7) wordt hieruit een blok van exact 256 cijfers gekozen/herschikt.
4. Het resultaat is de uiteindelijke, deterministische 256-cijferige accesscode voor die combinatie van gebruikersnaam + wachtwoord + pepper.

## ⚠️ Kanttekening: proof-of-concept, geen geverifieerde crypto

Dit is een **zelfontworpen hash-achtig algoritme**, bewust opgebouwd (seed uit username/password/pepper, meerdere rekenrondes met big-integers, φ-cijfers als extra bron van variatie, scrambling/truncatie) — niet zomaar wat willekeurige stappen aan elkaar geplakt. Tegelijk is het **geen gestandaardiseerde of onafhankelijk geaudite cryptografische hashfunctie** (zoals bcrypt, Argon2 of SHA-256): er is geen formele analyse gedaan op bijvoorbeeld botsingskansen, voorspelbaarheid of statistische verdeling van de output.

Een paar praktische punten om in het achterhoofd te houden:

- De `PEPPER` staat in leesbare tekst in de broncode; iedereen met toegang tot de `.bas`/gecompileerde `.exe` kan die achterhalen.
- De gegenereerde codes worden in platte tekst in een CSV-bestand opgeslagen.
- Zonder onafhankelijke verificatie kun je geen harde garanties geven over de veiligheid, ook al is het ontwerp doordacht.

Kortom: een kleine technische demonstratie van wat er mogelijk is in QB64 — behandel het als zodanig, en wees terughoudend als je het voor iets met echte gevoelige data zou willen inzetten zonder verdere verificatie.

