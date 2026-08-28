English:
# AccessCode Generator & Verificator (QB64)

A QB64(PE) BASIC project that generates a unique, 256-digit numeric "access code" token based on a username and password (plus a secret "pepper"), using a custom big-integer/φ-based algorithm ("R-Module"). The project consists of two parts: a graphical **generator** and a console-based **verificator (login)**.

This project was built primarily as a **technical proof-of-concept**: to demonstrate that you can build big-integer arithmetic, a custom hash-like algorithm, and a matching graphical interface with animations entirely within QBasic/QB64—not primarily as a ready-to-use, production-ready authentication solution.

## ✨ Features

* **Graphical generator** (`SCREEN 12`) with mouse and keyboard controls:
* Input fields for username and password (with masked password field)
* Buttons to generate, clear fields, and copy the code to the clipboard
* Live animation (particles/spiral) while generating the code
* Automatic storage of generated codes in a CSV file, with checks for unique codes


* **Console verificator**:
* Prompts for username and password in an infinite loop
* Recalculates the exact same 256-digit code using identical R-Module logic
* Compares it against a hardcoded hash value from the generator


* **Custom big-integer implementation** (addition, subtraction, multiplication, exponentiation) to handle very large numbers without external libraries
* Seed is (partially) derived from the first 500+ digits of $\pi\sqrt{5}\approx\phi$ (the golden ratio $\phi$) to add extra entropy/variation

## 📁 Files

| File | Description |
| --- | --- |
| `rmodlogingenerator475bigintstblevisual6generator.bas` | Graphical generator: inputs username/password, calculates the 256-digit code, and logs it to a CSV file |
| `rmodlogingenerator475bigintstblevisual6verificator.bas` | Console login: recalculates the code and compares it with a hardcoded hash |

> **Note:** GitHub/uploads often convert files to `.txt`. Rename them to `.bas` before opening them in QB64.

## ⚙️ Requirements

* [QB64](https://www.qb64.org/) or [QB64PE](https://qb64phoenix.com/) (recommended, actively maintained fork)
* Works on Windows, Linux, and macOS (the script detects the OS and adjusts shell commands)

## 🚀 Usage

### 1. Generate an access code

1. Open `generator.bas` in QB64(PE) and compile/run it.
2. Enter a username (min. 3 characters) and password (min. 5 characters).
3. Click **GENERATE CODE** (or press Enter).
4. View the animation and the resulting 256-digit code in the output window.
5. Click **COPY LATEST CODE** (or Ctrl+C) to copy the code to the clipboard.
6. The code is automatically written to a CSV file along with a timestamp (see below).

**Generator shortcut keys:**

| Key | Action |
| --- | --- |
| `Tab` | Switch between username/password field |
| `Enter` | Generate code |
| `Ctrl+X` | Clear input fields |
| `Ctrl+C` | Copy latest code |
| `Esc` | Exit |

### 2. Verify a login

1. Open `verificator.bas`, paste the generated 256-digit code as the value of `HASH_TO_MATCH` (line at the top of the file).
2. Compile/run the file.
3. Enter the same username and password at the prompt as you used during generation.
4. If it matches, the script displays `LOGIN OK`; otherwise, you can try again (infinite loop).

### 3. Verify your own credentials

Want to test if your username/password combination matches a generated code?

1. First, generate an access code using `generator.bas` for your desired username + password.
2. Copy the resulting 256-digit code.
3. Paste it into `verificator.bas` as the value of the constant `HASH_TO_MATCH`.
4. Run the verificator and log in with the same username and password—this should result in `LOGIN OK`.

## 🏆 Challenge

Do you think the underlying algorithm (how a 256-digit code is derived from username + password + pepper) contains weaknesses? Anyone who succeeds in cracking the corresponding username/password logic given a `HASH_TO_MATCH` (e.g., by recovering a valid combination without knowing the original input) will receive recognition that the system is demonstrably insecure—with acknowledgment of that person as the one who proved it.

> **Premise for the challenge:** the included demo `PEPPER` is right there in the repo and thus known to anyone attempting the challenge—it does not need to be guessed separately. The challenge specifically tests whether the combination of username + password can be found with a reasonable effort, given that the complete algorithm and pepper are public (just like in a "worst-case" scenario where the source code has leaked).

### CSV Storage

The generator automatically creates a directory and CSV file to log generated codes and prevent duplicate codes:

* Windows: `C:\ACCESSCODE\ACCESSCODE.CSV`
* Linux/macOS: `/ACCESSCODE/ACCESSCODE.CSV`

Format: `timestamp,accesscode`

## 🔧 Configuration

Both files contain a constant `PEPPER` at the top of the file:

```basic
Const PEPPER = "MySecretPepper123!@#$%^&*()_+"

```

This **must be identical** in both the generator and the verificator, otherwise the calculated codes will never match.

> **Note:** the value included in this project is an **example/demo pepper**, intentionally filled in so you can test the generator and verificator immediately without having to configure anything yourself. In a real application, every user/installation provides their **own, secret, unshared value**—and keeps it secret, meaning it shouldn't be published on GitHub like the demo value is here.

## 🔍 How hard is this system to actually crack?

It has sometimes been claimed that the truncation step (from 1024 to 256 digits) makes reconstruction "mathematically impossible" and that this system is therefore a proven one-way function. That deserves a more nuanced answer:

* The truncation/permutation/modulo addition does indeed ensure that you **cannot exactly reverse-engineer the internal 1024-digit intermediate result** from the 256-digit output. That is correct.
* But that is not the relevant attack. No one needs to invert the intermediate steps: an attacker simply tests combinations of username + password **forward** by running them through the algorithm and comparing them with the target code—just like any other hash-based system (brute force / dictionary attack).
* The real difficulty therefore lies in the **size of the username/password search space** and the **computational cost per guess** (12 rounds × hundreds of big-integer multiplications makes each attempt relatively slow, comparable to the idea behind slow KDFs like bcrypt/Argon2)—not in the irreversibility of the truncation itself.
* Because the included `PEPPER` is a published demo value, that factor falls away as an extra defense layer for anyone reading the repo. Therefore, always apply your own secret pepper before using this for anything real.

### Special characters and code pages

The input fields accept the full byte-value range (1–255), not just printable ASCII—which theoretically increases the search space per character. Important caveat: QB64 reads characters via `Asc()` as **raw byte values**, and for characters outside the basic ASCII range (like ©), that byte value depends on the **console's input code page**, not the compiled program itself. Windows uses a separate input code page per console that can vary per system/regional setting. This concretely means:

* Two machines running the exact same compiled `.exe` (same compiler, same source file) can still produce a different byte result for the same typed character if their console code page is configured differently.
* This is therefore not a consciously built-in extra security layer, but a **portability/reliability risk**: a user who uses a special character like © in their password may no longer be able to log in with the same visible password on another machine with a different code page setting.
* This does not apply to passwords within the standard ASCII range (32–126), as code pages are identical there.

### Collisions: investigated or assumed?

With a 256-digit output ($10^{256}$ possible values), the chance of accidental collisions between random inputs is intuitively low, and even factoring in the birthday paradox effect (where the first collision is statistically expected around $\sim 10^{128}$ attempts rather than $10^{256}$), that remains practically an enormous number of attempts. However, that is only valid **if the output is uniformly distributed** across the entire digit space. Whether that is actually true for this algorithm—meaning whether certain digit patterns systematically occur more frequently than others due to modulo addition, permutation, or truncation—has not been tested separately (for example, with a chi-squared test on the digit distribution, or by generating millions of combinations and checking for clustering). This therefore remains an **open question**, not a confirmed result in either direction.

## 🧠 How it works (briefly)

1. **Build seed** (`BuildBigSeed`): username + password + pepper are converted character by character into a large number (big-integer array).
2. **R-Module**: using that seed, via 12 iteration rounds and exponentiation with digits from $\phi$ (golden ratio), large numbers are added and subtracted until a sequence of 1024 digits is formed.
3. **Truncation/scrambling**: depending on a strategy derived from the seed (0–7), a block of exactly 256 digits is selected/rearranged from this.
4. The result is the final, deterministic 256-digit access code for that combination of username + password + pepper.

## ⚠️ Caveat: Proof-of-concept, not verified crypto

This is a **custom-designed hash-like algorithm**, consciously built (seed from username/password/pepper, multiple calculation rounds with big integers, $\phi$ digits as an extra source of variation, scrambling/truncation)—not just some random steps pasted together. At the same time, it is **not a standardized or independently audited cryptographic hash function** (such as bcrypt, Argon2, or SHA-256): no formal analysis has been done on, for example, collision probabilities, predictability, or statistical distribution of the output.

A few practical points to keep in mind:

* The `PEPPER` is in plain text in the source code; anyone with access to the `.bas`/compiled `.exe` can retrieve it.
* The generated codes are saved in plain text in a CSV file.
* Without independent verification, you cannot give hard guarantees about security, even though the design is well-thought-out.

In short: an impressive technical demonstration of what is possible in QB64—treat it as such, and be cautious if you want to use it for anything with truly sensitive data without further verification.

### Historical footnote: could this have been done in 1996?

The core arithmetic of the R-Module (digits in arrays, digit-by-digit addition/subtraction/multiplication, $\phi$ digits as an exponent source) does not use QB64-specific datatypes and could logically have run fine in native DOS QuickBASIC/QBasic from the '90s. The graphical shell is a different story: mouse support via `_MOUSEX`/`_MOUSEBUTTON` and the system-wide clipboard via `CLIPBOARD$` are modern QB64 runtime conveniences. In native DOS, you would have had to build mouse input via direct `INT 33h` interrupt calls and a custom clipboard routine via memory pokes (with inline assembly, for example via `CALL ABSOLUTE`)—that was common practice back then and technically feasible, but considerably more manual work than modern QB64 functions.

Interesting consequence: on the slow hardware of that time (interpreter instead of compiler, hundreds of MHz instead of GHz), repeatedly calculating 12 rounds of big-integer multiplication per login attempt **would have been noticeably slow per guess**, which would have made brute-forcing practically more difficult back then. However, that mostly says something about the processing power-to-time ratio of back then (every computationally expensive operation was harder to brute-force back then) and not about a unique cryptographic property of this specific algorithm—on today's hardware, that time advantage largely disappears.

## 🙏 Credits / Attribution

The big-integer base routines in this project are based on the **BigInt** library from [PetesQBSite](http://www.petesqbsite.com/downloads/bigint.zip) (added August 31, 2004 by Pete). This library works with unsigned "big integers" in the range of 0 to $9.999...9 \times 10^{31999}$, intended for advanced mathematical functions and precise calculations. Parts of that logic have been adopted and processed into the R-Module implementation of this project.

Nederlands:
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
| `rmodlogingenerator475bigintstblevisual6generator.bas | Grafische generator: voert username/password in, berekent de 256-cijferige code en logt deze in een CSV-bestand |
| `rmodlogingenerator475bigintstblevisual6verificator.bas | Console-login: herberekent de code en vergelijkt met een hardcoded hash |

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

> **Uitgangspunt voor de challenge:** de meegeleverde demo-`PEPPER` staat gewoon in de repo en is dus bekend bij iedereen die de challenge probeert — die hoeft niet apart geraden te worden. De challenge test dus specifiek of de combinatie van username + password binnen een redelijke inspanning te vinden is, gegeven dat het volledige algoritme én de pepper openbaar zijn (zoals ook bij een "worst-case"-scenario waarbij de broncode is uitgelekt).

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

### Speciale tekens en codepages

De invoervelden accepteren de volledige bytewaarde-ruimte (1–255), niet alleen printbare ASCII — dat vergroot in theorie de zoekruimte per teken. Belangrijke kanttekening daarbij: QB64 leest karakters via `Asc()` als **ruwe bytewaarde**, en die bytewaarde hangt bij tekens buiten de basis-ASCII-range (zoals ©) af van de **invoercodepage van de console**, niet van het gecompileerde programma zelf. Windows kent per console een aparte invoercodepage die per systeem/regio-instelling kan verschillen. Dat betekent concreet:

- Twee machines die exact hetzelfde gecompileerde `.exe` draaien (zelfde compiler, zelfde bronbestand) kunnen alsnog een ander byteresultaat geven voor hetzelfde getypte teken, als hun console-codepage anders staat ingesteld.
- Dit is dus geen bewust ingebouwde extra beveiligingslaag, maar een **portabiliteits-/betrouwbaarheidsrisico**: een gebruiker die een speciaal teken als © in zijn wachtwoord gebruikt, kan op een andere machine met een andere codepage-instelling mogelijk niet meer inloggen met hetzelfde zichtbare wachtwoord.
- Voor wachtwoorden binnen de standaard-ASCII-range (32–126) speelt dit niet, aangezien codepages daar onderling identiek zijn.

### Botsingen: onderzocht of aangenomen?

Met een 256-cijferige output (10^256 mogelijke waarden) is de kans op toevallige botsingen tussen willekeurige inputs intuïtief laag, en zelfs rekening houdend met het geboortedagparadox-effect (waarbij de eerste botsing statistisch al rond ~10^128 pogingen verwacht kan worden in plaats van pas bij 10^256) blijft dat praktisch een enorm aantal pogingen. Dat is echter alleen geldig **als de output uniform verdeeld is** over de volledige cijferruimte. Of dat voor dit algoritme daadwerkelijk zo is — dus of bepaalde cijferpatronen door de modulo-optelling, permutatie of truncatie systematisch vaker voorkomen dan andere — is niet los getest (bijvoorbeeld met een chi-kwadraattoets op de cijferverdeling, of door miljoenen combinaties te genereren en te controleren op clustering). Dit blijft dus een **open vraag**, geen bevestigd resultaat in beide richtingen.

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

Kortom: een indrukwekkende technische demonstratie van wat er mogelijk is in QB64 — behandel het als zodanig, en wees terughoudend als je het voor iets met echte gevoelige data zou willen inzetten zonder verdere verificatie.

### Historische kanttekening: had dit in 1996 gekund?

De kernrekenkunde van het R-Module (cijfers in arrays, digit-voor-digit optellen/aftrekken/vermenigvuldigen, φ-cijfers als exponentbron) gebruikt geen QB64-specifieke datatypes en had qua logica prima in native DOS-QuickBASIC/QBasic uit de jaren '90 kunnen draaien. De grafische schil is een ander verhaal: muisondersteuning via `_MOUSEX`/`_MOUSEBUTTON` en het systeembrede klembord via `CLIPBOARD$` zijn moderne QB64-runtime-gemakken. In native DOS had je muisinvoer via directe `INT 33h`-interruptaanroepen en een eigen klembordroutine via geheugen-pokes (met inline assembly, bijvoorbeeld via `CALL ABSOLUTE`) moeten bouwen — dat was destijds gangbare praktijk en technisch haalbaar, maar wel aanzienlijk meer handwerk dan de moderne QB64-functies.

Interessant gevolg: op de trage hardware van die tijd (interpreter in plaats van compiler, honderden MHz in plaats van GHz) zou het herhaaldelijk doorrekenen van 12 rondes big-integer-vermenigvuldiging per login-poging **per gok merkbaar traag** zijn geweest, wat brute force destijds praktisch lastiger zou hebben gemaakt. Dat zegt echter vooral iets over de rekenkracht-tijdsverhouding van toen (elke rekenkundig dure bewerking was toen moeilijker te bruteforcen) en niet over een unieke cryptografische eigenschap van dit specifieke algoritme — op de hardware van vandaag vervalt dat tijdsvoordeel grotendeels.



## 🙏 Credits / Attributie

De big-integer-basisroutines in dit project zijn gebaseerd op de **BigInt**-library van [PetesQBSite](http://www.petesqbsite.com/downloads/bigint.zip) (toegevoegd 31 augustus 2004 door Pete). Deze library werkt met unsigned "big integers" in het bereik van 0 tot 9.999...9 × 10^31999, bedoeld voor geavanceerde wiskundige functies en precieze berekeningen. Delen van die logica zijn overgenomen en verwerkt in de R-Module-implementatie van dit project.

