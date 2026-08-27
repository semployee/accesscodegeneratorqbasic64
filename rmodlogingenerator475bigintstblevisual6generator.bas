' ==============================================================
' ACCESS CODE GENERATOR - GRAFISCHE VERSIE (SCREEN 12)
' MET BIG-INTEGER SEED EN PEPPER
' Copyright (C) R.T.Somer
' ==============================================================

' 1. GLOBALE VARIABELEN & CONSTANTEN
Dim Shared mx As Integer, my As Integer, inWindow As Integer
Dim Shared leftDown As Integer, wasLeftDown As Integer
Dim Shared k$
Dim Shared active As Integer ' _WindowHasFocus status
Dim Shared BgColor As Integer ' Achtergrondkleur (0-15)
Dim Shared AccessCode$ ' Nu de AccessCode van 256 cijfers
Dim Shared IsRunning As Integer ' Vlag om de loop te stoppen
Dim Shared AccessCodeList$(10000)
Dim Shared AccessCodeCount%

' --- Variabelen voor de Integratie ---
Dim Shared UserInput$, PassInput$
Dim Shared CurrentInput As Integer ' 0 = UserInput, 1 = PassInput

' --- Coordinaten voor de 3 Hoofdknoppen ---
Const Y_START = 100
Const Y_EIND = 150
Const X1 = 50, X2 = 180 ' Knop 1: Afsluiten
Const X3 = 200, X4 = 330 ' Knop 2: Wis Velden (Clear)
Const X5 = 350, X6 = 550 ' Knop 3: Genereer Code (Berekening)

' --- Coordinaten voor de Output Window (Pixels) ---
Const OutputX1 = 50, OutputY1 = 250
Const OutputX2 = 550, OutputY2 = 400

' --- Coordinaten voor de Kopieer Knop ---
Const X_COPY_START = 180, X_COPY_EIND = 420 ' Gecentreerd onder output box
Const Y_COPY_START = OutputY2 + 10
Const Y_COPY_EIND = OutputY2 + 40

' --- Coordinaten voor Input Velden ---
Const InputX = 50
Const InputYUser = 30
Const InputYPass = 50

' --- CSV/File Handling Constanten ---
Dim Shared dirPath$, csvPath$

' --- R-MODULE Variabelen ---
Dim Shared state(1 To 500) As Integer
Dim Shared wave(1 To 500) As Integer
Dim Shared current_phi(1 To 500) As Integer
Dim Shared phi_arr(1 To 150) As Integer
Dim Shared big_temp(1 To 1000) As Integer

' ===== NIEUW: ANIMATIE VARIABELEN =====
Dim Shared particles(1 To 3000, 1 To 5) As Single
Dim Shared pCount As Integer
Const ANIM_CENTER_X = 320, ANIM_CENTER_Y = 240
Const ANIM_RADIUS = 220
' ======================================

' ===== NIEUW: VASTE PEPPER (GEHEIM) =====
' KIES HIER EEN EIGEN, LANGE, WILLEKEURIGE STRING
Const PEPPER = "MijnGeheimePepper123!@#$%^&*()_+"

' 2. SUB/FUNCTIE DECLARATIES
DECLARE SUB DrawUI (FgColor As Integer)
DECLARE SUB DrawButton (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, text As String, colorCode As Integer, FgColor As Integer)
DECLARE SUB DrawHover (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer)
DECLARE FUNCTION IIf$ (condition As Integer, trueVal As String, falseVal As String)
DECLARE SUB HandleKeyboardInput ()
DECLARE SUB GenerateAccessCodeHandler ()
DECLARE SUB CopyAccessCodeHandler ()
DECLARE SUB ClearFields ()

' --- Functies uit de AccessCode Generator Logica ---
DECLARE FUNCTION TrimStr$ (s$)
DECLARE SUB LoadCSVIntoMemory ()
DECLARE FUNCTION AppendCSVData% (filePath$, ts$, code$)

' ===== NIEUW: BIG-INTEGER SEED FUNCTIE =====
DECLARE SUB BuildBigSeed (username As String, password As String, pepper As String, seed_arr() As Integer, seed_len As Integer)

' ===== AANGEPASTE GENERATOR (met pepper) =====
DECLARE FUNCTION GenerateAccessCode256$ (username As String, password As String, pepper As String)

' --- R-MODULE Functies ---
' ===== AANGEPAST: nu met big-integer seed, phi_start en k_max =====
DECLARE FUNCTION RModuleWithParams$ (username As String, password As String, seed_arr() As Integer, seed_len As Integer, phi_start As Long, k_max As Integer)

' --- Big-Integer Routines (ongewijzigd) ---
DECLARE SUB FastPowerBinary (result() As Integer, result_len As Integer, base_arr() As Integer, base_len As Integer, exponent As Integer)
DECLARE SUB BigMulArray (num() As Integer, num_len As Integer, multiplier As Integer)
DECLARE SUB BigAddArrays (a() As Integer, a_len As Integer, b() As Integer, b_len As Integer)
DECLARE SUB BigSubArrays (a() As Integer, a_len As Integer, b() As Integer, b_len As Integer)
DECLARE SUB BigMulArrays (a() As Integer, a_len As Integer, b() As Integer, b_len As Integer)
DECLARE SUB CopyLastDigits (dest() As Integer, dest_len As Integer, src() As Integer, src_len As Integer, count As Integer)

' --- Animatie Helpers ---
DECLARE SUB AddParticle (x As Single, y As Single, col As Integer, ring As Integer)
DECLARE SUB Explosion (x As Single, y As Single, col As Integer, aantal As Integer)
DECLARE SUB DrawAll ()
DECLARE FUNCTION IIfInt% (c As Integer, t As Integer, f As Integer)

' ==============================================================
' PROGRAM START - SETUP
' ==============================================================
Screen 12 ' 640x480 grafische modus
Color 15, 0

_MouseHide ' Verberg de standaard muis
BgColor = 0
IsRunning = -1
AccessCode$ = "Voer gegevens in en klik op 'GENEREER CODE'."
UserInput$ = "": PassInput$ = ""
CurrentInput = 0

' --- Bestandspaden Initialiseren MET SHELL COMMANDS ---
$If QB64 Then
    If _OS = "WINDOWS" Then
    ' Windows: gebruik shell commands om directory en bestand af te dwingen
    Shell "MD C:\ACCESSCODE > NUL 2>&1"
    Shell "IF NOT EXIST C:\ACCESSCODE\ACCESSCODE.CSV ECHO timestamp,accesscode > C:\ACCESSCODE\ACCESSCODE.CSV"
    dirPath$ = "C:\ACCESSCODE"
    csvPath$ = "C:\ACCESSCODE\ACCESSCODE.CSV"
    Else
    ' Linux/Mac: gebruik shell commands om directory en bestand af te dwingen
    Shell "mkdir -p /ACCESSCODE"
    Shell "test -f /ACCESSCODE/ACCESSCODE.CSV || echo 'timestamp,accesscode' > /ACCESSCODE/ACCESSCODE.CSV"
    dirPath$ = "/ACCESSCODE"
    csvPath$ = "/ACCESSCODE/ACCESSCODE.CSV"
    End If
$Else
    ' QB45/DOS: gebruik DOS shell commands
    Shell "MD C:\ACCESSCODE > NUL 2>&1"
    Shell "IF NOT EXIST C:\ACCESSCODE\ACCESSCODE.CSV ECHO timestamp,accesscode > C:\ACCESSCODE\ACCESSCODE.CSV"
    dirPath$ = "C:\ACCESSCODE"
    csvPath$ = "C:\ACCESSCODE\ACCESSCODE.CSV"
$End If

' --- Laad bestaande codes (voor uniekheid check) ---
LoadCSVIntoMemory

' ==============================================================
' HOOFDLOOP - Input en Logica
' ==============================================================
Do While IsRunning

    ' --- 1. Muis- en Actief Status Ophalen (Input) ---
    active = _WindowHasFocus
    While _MouseInput: Wend
    mx = _MouseX
    my = _MouseY
    leftDown = _MouseButton(1)

    inWindow = -1 ' We nemen aan dat we altijd in het Canvas/Window zijn

    ' --- 2. Bepaal Contrast Kleuren ---
    Dim FgColor As Integer ' Voorgrondkleur (tekst)
    If BgColor >= 8 Then
        FgColor = 0
    Else
        FgColor = 15
    End If

    ' --- 3. Toetsenbord Input Verwerken ---
    HandleKeyboardInput

    ' --- 4. Klikdetectie en Actie (Logica) ---
    If leftDown And Not wasLeftDown And inWindow And active Then
        ' Klik op Hoofdknoppen
        If mx >= X1 And mx <= X2 And my >= Y_START And my <= Y_EIND Then
            AccessCode$ = "Afsluiten geklikt..."
            _Display: Sleep 1
            IsRunning = 0
        ElseIf mx >= X3 And mx <= X4 And my >= Y_START And my <= Y_EIND Then
            ClearFields ' Wis Velden
            AccessCode$ = "Invoervelden gewist."
        ElseIf mx >= X5 And mx <= X6 And my >= Y_START And my <= Y_EIND Then
            GenerateAccessCodeHandler ' Genereer de 256-cijferige code
            ' Klik op Kopieer Knop
        ElseIf mx >= X_COPY_START And mx <= X_COPY_EIND And my >= Y_COPY_START And my <= Y_COPY_EIND Then
            CopyAccessCodeHandler ' Kopieert de gegenereerde code
        End If

        ' Klik op Input Velden om Focus te wisselen
        If my >= InputYUser And my < InputYPass Then CurrentInput = 0
        If my >= InputYPass And my < Y_START Then CurrentInput = 1
    End If
    wasLeftDown = leftDown

    ' --- 5. Teken de UI (Output) ---
    DrawUI FgColor

    _Display
    _Limit 60 ' Limit aan 60 FPS
Loop

_MouseShow
End

' ==============================================================
' SUB: HandleKeyboardInput - Verwerkt InKey$ voor de 2 input velden
' ==============================================================
Sub HandleKeyboardInput
    k$ = InKey$
    If k$ = "" Then Exit Sub

    ' TAB: Wissel focus
    If k$ = Chr$(9) Then
        CurrentInput = 1 - CurrentInput
        Exit Sub
    End If

    ' ESC: Afsluiten
    If k$ = Chr$(27) Then IsRunning = 0: Exit Sub

    ' Enter/Ctrl+G: Genereer Code
    If k$ = Chr$(13) Or k$ = Chr$(7) Then ' Enter of Ctrl+G
        GenerateAccessCodeHandler
        Exit Sub
    End If

    ' Ctrl+X: Wis Velden
    If k$ = Chr$(24) Then
        ClearFields
        Exit Sub
    End If

    ' Ctrl+C: Kopieer
    If k$ = Chr$(3) Then
        CopyAccessCodeHandler
        Exit Sub
    End If

    ' Backspace
    If k$ = Chr$(8) Then
        If CurrentInput = 0 Then
            If Len(UserInput$) > 0 Then UserInput$ = Left$(UserInput$, Len(UserInput$) - 1)
        Else
            If Len(PassInput$) > 0 Then PassInput$ = Left$(PassInput$, Len(PassInput$) - 1)
        End If
        Exit Sub
    End If

    ' Normale karakter invoer (volledige ASCII tabel)
    If Len(k$) = 1 And Asc(k$) >= 1 Then
        If CurrentInput = 0 And Len(UserInput$) < 30 Then
            UserInput$ = UserInput$ + k$
        ElseIf CurrentInput = 1 And Len(PassInput$) < 30 Then
            PassInput$ = PassInput$ + k$
        End If
    End If
End Sub

' ==============================================================
' SUB: GenerateAccessCodeHandler - Logica voor de Genereer Knop
' ==============================================================
Sub GenerateAccessCodeHandler
    If Len(UserInput$) < 3 Or Len(PassInput$) < 5 Then
        AccessCode$ = "FOUT: Username (3+) en Password (5+) karakters nodig."
        Exit Sub
    End If

    Dim generatedCode$
    ' ===== PEPPER MEEGEVEN =====
    generatedCode$ = GenerateAccessCode256$(UserInput$, PassInput$, PEPPER)

    If Left$(generatedCode$, 4) <> "FOUT" And Left$(generatedCode$, 7) <> "Ongeldig" Then
        ts$ = Date$ + " " + Time$
        dummy% = AppendCSVData%(csvPath$, ts$, generatedCode$)
        AccessCode$ = generatedCode$ ' Bewaar de echte 256-cijferige code
    Else
        AccessCode$ = generatedCode$ ' Toon foutmelding
    End If
End Sub

' ==============================================================
' SUB: CopyAccessCodeHandler - Logica voor de Kopieer Knop
' ==============================================================
Sub CopyAccessCodeHandler
    ' Controleer of de AccessCode een geldige code is (256 cijfers)
    If Len(AccessCode$) < 256 Then
        AccessCode$ = "FOUT: Eerst een geldige 256-cijferige code genereren."
        Exit Sub
    End If

    ' Gebruik de ingebouwde QB64 klembord functie
    _Clipboard$ = AccessCode$
    AccessCode$ = "CODE KOPIEERD! (Naar klembord)"
End Sub

' ==============================================================
' SUB: ClearFields - Wis de invoer
' ==============================================================
Sub ClearFields
    UserInput$ = ""
    PassInput$ = ""
    AccessCode$ = "Invoervelden gewist. Voer nieuwe gegevens in."
    CurrentInput = 0
End Sub

' ==============================================================
' SUB: DrawUI (Tekent de volledige interface EN de cursor)
' ==============================================================
Sub DrawUI (FgColor As Integer)
    ' 1. WIS HET SCHERM
    Color FgColor, BgColor
    Cls

    ' 2. TITEL
    Color 15, BgColor
    _PrintString (180, 10), "ACCESSCODE GENERATOR - HOOFDLETTERGEVOELIGE SEED"

    ' 3. TEKEN DE INPUT VELDEN
    Color 15, BgColor
    ' Gebruik een cursor om de focus aan te geven
    cursor$ = IIf$(CurrentInput = 0, "_", " ")
    _PrintString (InputX, InputYUser), IIf$(CurrentInput = 0, Chr$(14), Chr$(7)) + "Username: " + UserInput$ + cursor$
    cursor$ = IIf$(CurrentInput = 1, "_", " ")
    passDisplay$ = String$(Len(PassInput$), "*")
    _PrintString (InputX, InputYPass), IIf$(CurrentInput = 1, Chr$(14), Chr$(7)) + "Password: " + passDisplay$ + cursor$

    ' 4. TEKEN DE KNOPPEN
    DrawButton X1, Y_START, X2, Y_EIND, "AFSLUITEN (ESC)", 12, FgColor
    DrawButton X3, Y_START, X4, Y_EIND, "WIS VELDEN (Tab)", 10, FgColor
    DrawButton X5, Y_START, X6, Y_EIND, "GENEREER CODE (Enter)", 11, FgColor

    ' 5. TEKEN KOPIEER KNOP
    DrawButton X_COPY_START, Y_COPY_START, X_COPY_EIND, Y_COPY_EIND, "KOPIEER LAATSTE CODE (Ctrl+C)", 9, FgColor

    ' 6. Muisover-effect (Hover)
    If inWindow Then
        DrawHover X1, Y_START, X2, Y_EIND
        DrawHover X3, Y_START, X4, Y_EIND
        DrawHover X5, Y_START, X6, Y_EIND
        DrawHover X_COPY_START, Y_COPY_START, X_COPY_EIND, Y_COPY_EIND ' Kopieer Knop Hover
    End If

    ' 7. TEKEN HET OUTPUT VENSTER (Access Code)
    Line (OutputX1, OutputY1)-(OutputX2, OutputY2), 8, BF
    Line (OutputX1, OutputY1)-(OutputX2, OutputY2), 14, B

    Color 15, 8
    _PrintString (OutputX1 + 10, OutputY1 + 10), "OUTPUT: ACCESCODE (Case-Sensitive R-Module)"

    ' --- VERBETERDE CODE WEERGAVE - VOLLEDIGE 256 CIJFERS ---
    If Len(AccessCode$) > 0 Then
        ' Controleer of het een echte 256-cijferige code is
        If Len(AccessCode$) = 256 Then
            ' Bereken hoeveel cijfers we per regel kunnen tonen
            boxWidth = OutputX2 - OutputX1 - 20 ' 10 pixels marge aan beide kanten
            digitsPerLine = boxWidth \ 8 ' 8 pixels per cijfer

            ' Toon de code over meerdere regels
            startY = OutputY1 + 30
            currentLine = 0

            For i = 1 To Len(AccessCode$) Step digitsPerLine
                chunk$ = Mid$(AccessCode$, i, digitsPerLine)
                If chunk$ <> "" Then
                    _PrintString (OutputX1 + 10, startY + currentLine * 16), chunk$
                    currentLine = currentLine + 1
                End If
            Next i

            ' Toon statistiek onderaan
            _PrintString (OutputX1 + 10, OutputY2 - 20), "Totaal: " + Str$(Len(AccessCode$)) + " cijfers gegenereerd"

        Else
            ' Toon statusbericht of foutmelding (geen 256 cijfers)
            _PrintString (OutputX1 + 10, OutputY1 + 35), AccessCode$
        End If
    Else
        _PrintString (OutputX1 + 10, OutputY1 + 35), "Voer gegevens in en klik op 'GENEREER CODE'."
    End If

    ' 8. TEKEN DE AANGEPASTE CURSOR (Crosshair)
    If active And inWindow Then
        If mx >= 0 And mx < 640 And my >= 0 And my < 480 Then
            Line (mx, my - 5)-(mx, my + 5), 15
            Line (mx - 5, my)-(mx + 5, my), 15
        End If
    End If

    Color FgColor, BgColor
End Sub

' ==============================================================
' SUB: DrawButton
' ==============================================================
Sub DrawButton (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, text As String, colorCode As Integer, FgColor As Integer)
    Line (x1, y1)-(x2, y2), colorCode, BF
    Line (x1 - 1, y1 - 1)-(x2 + 1, y2 + 1), 0, B

    TextWidth = Len(text) * 8
    TextX = x1 + (x2 - x1) \ 2 - TextWidth \ 2
    TextY = y1 + (y2 - y1) \ 2 - 4

    Color 15, colorCode
    _PrintString (TextX, TextY), text
End Sub

' ==============================================================
' SUB: DrawHover
' ==============================================================
Sub DrawHover (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer)
    If mx >= x1 And mx <= x2 And my >= y1 And my <= y2 Then
        Line (x1, y1)-(x2, y2), 15, B
    End If
End Sub

' ==============================================================
' FUNCTIE: IIf$
' ==============================================================
Function IIf$ (condition As Integer, trueVal As String, falseVal As String)
    If condition Then IIf$ = trueVal Else IIf$ = falseVal
End Function

' ==============================================================
' TRIM FUNCTIE (Van ASCII Code)
' ==============================================================
Function TrimStr$ (s$)
    While Left$(s$, 1) = " ": s$ = Mid$(s$, 2): Wend
    While Right$(s$, 1) = " ": s$ = Left$(s$, Len(s$) - 1): Wend
    TrimStr$ = s$
End Function

' ==============================================================
' CSV FUNCTIES (SHELL-BASED AANPAK zoals in jouw code)
' ==============================================================

Sub LoadCSVIntoMemory
    AccessCodeCount% = 0

    ' Gebruik shell om bestand te controleren en aan te maken indien nodig
    $If QB64 Then
        If _OS = "WINDOWS" Then
        Shell "IF NOT EXIST " + csvPath$ + " ECHO timestamp,accesscode > " + csvPath$
        Else
        Shell "test -f " + csvPath$ + " || echo 'timestamp,accesscode' > " + csvPath$
        End If
    $Else
        Shell "IF NOT EXIST " + csvPath$ + " ECHO timestamp,accesscode > " + csvPath$
    $End If

    Open csvPath$ For Input As #1
    Do While Not EOF(1)
        Line Input #1, line$
        line$ = TrimStr$(line$)
        If line$ <> "" And Left$(line$, 1) <> "t" Then
            csvPos = InStr(line$, ",")
            If csvPos > 0 Then
                code$ = TrimStr$(Mid$(line$, csvPos + 1))
                If code$ <> "" Then
                    AccessCodeCount% = AccessCodeCount% + 1
                    If AccessCodeCount% <= 10000 Then AccessCodeList$(AccessCodeCount%) = LCase$(code$)
                End If
            End If
        End If
    Loop
    Close #1
End Sub

Function AppendCSVData% (filePath$, ts$, code$)
    codeLC$ = LCase$(code$)
    For i = 1 To AccessCodeCount%
        If AccessCodeList$(i) = codeLC$ Then AppendCSVData% = 0: Exit Function
    Next
    AccessCodeCount% = AccessCodeCount% + 1
    If AccessCodeCount% <= 10000 Then AccessCodeList$(AccessCodeCount%) = codeLC$

    Open filePath$ For Append As #1
    Print #1, ts$; ","; code$
    Close #1
    AppendCSVData% = -1
End Function

' ==============================================================
' NIEUWE SUB: BuildBigSeed
' ==============================================================
Sub BuildBigSeed (username As String, password As String, pepper As String, seed_arr() As Integer, seed_len As Integer)
    Dim combined As String, i As Integer, digit As Integer
    combined = username + password + pepper
    seed_arr(1) = 1: seed_len = 1
    For i = 1 To Len(combined)
        digit = Asc(Mid$(combined, i, 1)) + i
        Call BigMulArray(seed_arr(), seed_len, digit)
    Next
    If seed_len = 1 And seed_arr(1) = 0 Then seed_arr(1) = 1
End Sub

' ==============================================================
' AANGEPASTE GENERATOR (met pepper)
' ==============================================================
Function GenerateAccessCode256$ (username As String, password As String, pepper As String)
    Dim seed_arr(1 To 500) As Integer, seed_len As Integer
    Dim phi_start As Long, k_max As Integer
    Dim RMODULE_HASH$, TRUNC$, FINAL$
    Dim STRAT_ID As Integer

    ' Bouw big-integer seed
    BuildBigSeed username, password, pepper, seed_arr(), seed_len

    ' Bepaal phi_start uit seed
    If seed_len >= 3 Then
        phi_start = seed_arr(seed_len) * 100 + seed_arr(seed_len - 1) * 10 + seed_arr(seed_len - 2)
    Else
        phi_start = 1
    End If
    If phi_start < 1 Then phi_start = 1

    ' Bepaal k_max (500-999)
    k_max = 500 + (seed_arr(seed_len) Mod 500)
    If k_max < 500 Then k_max = 500
    If k_max > 999 Then k_max = 999

    ' R-Module aanroepen
    RMODULE_HASH$ = RModuleWithParams$(username, password, seed_arr(), seed_len, phi_start, k_max)

    ' Bepaal STRAT_ID uit seed
    If seed_len >= 2 Then
        STRAT_ID = (seed_arr(seed_len) + seed_arr(seed_len - 1)) Mod 8
    Else
        STRAT_ID = seed_arr(seed_len) Mod 8
    End If

    ' === TRUNCATIE EN SCRAMBLING (zelfde structuur als origineel) ===
    Dim ACCESSCODE_1024$, BLOCK_A$, BLOCK_B$, BLOCK_C$, BLOCK_D$, PERMUTED_1024$
    Dim I, J, D_CURRENT, D_NEW, D_OUT, START_POS, SHIFT_AMOUNT, OLD_INDEX
    ACCESSCODE_1024$ = RMODULE_HASH$

    Select Case STRAT_ID
        Case 0: TRUNC$ = Left$(ACCESSCODE_1024$, 256)
        Case 1: TRUNC$ = Right$(ACCESSCODE_1024$, 256)
        Case 2: TRUNC$ = Mid$(ACCESSCODE_1024$, 257, 256)
        Case 3
            BLOCK_A$ = Mid$(ACCESSCODE_1024$, 1, 256)
            BLOCK_B$ = Mid$(ACCESSCODE_1024$, 257, 256)
            BLOCK_C$ = Mid$(ACCESSCODE_1024$, 513, 256)
            BLOCK_D$ = Mid$(ACCESSCODE_1024$, 769, 256)
            TRUNC$ = BLOCK_C$ + BLOCK_A$ + BLOCK_D$ + BLOCK_B$
            TRUNC$ = Left$(TRUNC$, 256)
        Case 4
            TRUNC$ = ""
            For I = 1 To 1023 Step 4
                TRUNC$ = TRUNC$ + Mid$(ACCESSCODE_1024$, I, 1)
                If Len(TRUNC$) = 256 Then Exit For
            Next
        Case 5
            TRUNC$ = ""
            For I = 2 To 1024 Step 3
                TRUNC$ = TRUNC$ + Mid$(ACCESSCODE_1024$, I, 1)
                If Len(TRUNC$) = 256 Then Exit For
            Next
        Case 6
            Dim FINAL_128 As String
            FINAL_128 = String$(128, "0")
            For J = 0 To 7
                START_POS = J * 128 + 1
                BLOCK$ = Mid$(ACCESSCODE_1024$, START_POS, 128)
                For I = 1 To 128
                    D_CURRENT = Val(Mid$(FINAL_128, I, 1))
                    D_NEW = Val(Mid$(BLOCK$, I, 1))
                    D_OUT = (D_CURRENT + D_NEW) Mod 10
                    Mid$(FINAL_128, I, 1) = LTrim$(Str$(D_OUT))
                Next
            Next J
            TRUNC$ = FINAL_128 + FINAL_128
        Case 7
            PERMUTED_1024$ = String$(1024, "0")
            SHIFT_AMOUNT = (seed_arr(seed_len) + seed_arr(seed_len - 1)) Mod 1023 + 1
            For I = 1 To 1024
                OLD_INDEX = ((I - 1) + SHIFT_AMOUNT) Mod 1024 + 1
                Mid$(PERMUTED_1024$, I, 1) = Mid$(ACCESSCODE_1024$, OLD_INDEX, 1)
            Next I
            TRUNC$ = Left$(PERMUTED_1024$, 256)
    End Select

    If Len(TRUNC$) < 256 Then
        FINAL$ = TRUNC$
        Do While Len(FINAL$) < 256
            FINAL$ = FINAL$ + Left$(TRUNC$, 256 - Len(FINAL$))
        Loop
        GenerateAccessCode256$ = FINAL$
    Else
        GenerateAccessCode256$ = Left$(TRUNC$, 256)
    End If
End Function

' ==============================================================
' AANGEPASTE R-MODULE MET BIG-INTEGER SEED
' ==============================================================
Function RModuleWithParams$ (username As String, password As String, seed_arr() As Integer, seed_len As Integer, phi_start As Long, k_max As Integer)
    ' ===== TIJDELIJK SCHERM WISSEL =====
    Dim savedScreen As Long
    savedScreen = _CopyImage(0) ' Bewaar huidige GUI scherm

    ' Schakel over naar 256-kleuren modus voor animatie
    Screen _NewImage(640, 480, 256)
    _ScreenMove _Middle
    ' ===================================

    Dim result$, stretched$, code$, tmp$, seed$, phi$
    Dim n As Integer, k As Integer, i As Long, j As Integer
    Dim digit As Integer, input_len As Integer, state_len As Integer, wave_len As Integer, current_phi_len As Integer
    Dim r As Integer, rep As Integer, col As Integer, d As Integer
    Dim angle As Single, px As Single, py As Single, a As Single, rad As Single
    Dim x2pos As Single, y2pos As Single, spiral_rad As Single
    Dim phi_total As Long, start_pos As Integer, phi_index As Integer

    pCount = 0
    Cls
    Locate 1, 20: Print "R-MODULE ACTIVE – 12 UNIVERSA WORDEN GEBOREN"
    Locate 2, 1: Print "Seed lengte: "; seed_len; " Phi Start: "; phi_start; " k_max: "; k_max

    For r = 20 To ANIM_RADIUS Step 18
        Circle (ANIM_CENTER_X, ANIM_CENTER_Y), r, 8
    Next

    ' === Initialiseer state met de big-integer seed ===
    ' (We gebruiken de globale state array, maar die wordt lokaal overschaduwd? Nee, we gebruiken een lokale versie.)
    ' Om verwarring te voorkomen, gebruiken we een lokale array.
    Dim state_local(1 To 500) As Integer
    state_len = seed_len
    If state_len > 500 Then state_len = 500
    For i = 1 To state_len
        state_local(i) = seed_arr(i)
    Next
    If state_len = 1 And state_local(1) = 0 Then state_local(1) = 1

    ' === Phi array ===
    phi$ = "16180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374847540880753868917521266338622235369317931800607667263544333890865959395829056383226613199282902678806752087668925017116962070322210432162695486262963136144381497587012203408058879544547492461856953648644492410443207713449470495658467885098743394422125448770664780915884607499887124007652170575179788341662562494075890697040002812104276217711177780531531714101170466659914669798731761356006708748071013179523689427521948435305678300228785699782977834784587822891109762500302696156170025046433824377648610283831268330372429267526311653392473167111211588186385133162038400522216579128667529465490681131715993432359734949850904094762132229810172610705961164562990981629055520852479035240602017279974717534277759277862561943208275051312181562855122248093947123414517022373580577278616008688382952304592647878017889921990270776903895321968198615143780314997411069260886742962267575605231727775203536139362"

    start_pos = phi_start
    If start_pos < 1 Then start_pos = 1
    If start_pos > Len(phi$) - 149 Then start_pos = (seed_arr(seed_len) Mod (Len(phi$) - 149)) + 1

    Locate 3, 1: Print "Phi selectie: positie"; start_pos; "van"; Len(phi$); "cijfers"

    Dim phi_arr_local(1 To 150) As Integer
    For i = 1 To 150
        phi_index = start_pos + i - 1
        ' Ring buffer: als we voorbij het einde komen, begin opnieuw
        If phi_index > Len(phi$) Then phi_index = phi_index - Len(phi$)
        phi_arr_local(i) = Val(Mid$(phi$, phi_index, 1))
    Next i

    input_len = Len(username) + Len(password)

    ' === HOOFDLOOP – 12 universa ===
    Dim wave_local(1 To 500) As Integer, current_phi_local(1 To 500) As Integer
    For n = 1 To 12
        For i = 1 To 500: wave_local(i) = 0: Next
        wave_len = 1
        For i = 1 To 500: current_phi_local(i) = 0: Next
        current_phi_local(1) = 1: current_phi_len = 1

        For k = 1 To k_max
            Call FastPowerBinary(current_phi_local(), current_phi_len, phi_arr_local(), 150, n * k)

            angle = (k / k_max) * 6.2832 + n * 0.5
            rad = 30 + n * 15
            px = ANIM_CENTER_X + Cos(angle) * rad
            py = ANIM_CENTER_Y + Sin(angle) * rad
            col = IIfInt(k Mod 2 = 1, 9, 12) ' 9=blauw (add), 12=rood (sub)
            For rep = 1 To 14
                Call AddParticle(px + Rnd * 16 - 8, py + Rnd * 16 - 8, col, n)
            Next

            If k Mod 2 = 0 Then Call BigMulArray(current_phi_local(), current_phi_len, k)
            If k Mod 2 = 1 Then
                Call BigAddArrays(wave_local(), wave_len, current_phi_local(), current_phi_len)
            Else
                Call BigSubArrays(wave_local(), wave_len, current_phi_local(), current_phi_len)
            End If

            If current_phi_len > 250 Then current_phi_len = 250
            If wave_len > 250 Then wave_len = 250

            Call DrawAll
            Locate 29, 1: Print "n="; n; " k="; k; "/"; k_max; " digits="; current_phi_len;
            _Display: _Limit 90
        Next

        ' === CopyLastDigits – groene laser ===
        For i = 1 To 64
            If i <= wave_len Then
                x2pos = ANIM_CENTER_X + ANIM_RADIUS + 60
                y2pos = 60 + i * 6
                Line (ANIM_CENTER_X + ANIM_RADIUS, y2pos)-(x2pos, y2pos), 10
                PSet (x2pos, y2pos), 10
                _Display: _Delay 0.0012
            End If
        Next
        Call CopyLastDigits(state_local(), state_len, wave_local(), wave_len, 64)
    Next

    ' === 4. Finale condensatie + gulden snede spiraal ===
    For i = 50 To 0 Step -1
        Circle (ANIM_CENTER_X, ANIM_CENTER_Y), i * 4.5, 15
        _Display: _Delay 0.014
    Next

    result$ = ""
    For i = 1 To state_len
        If i <= 500 Then result$ = result$ + Chr$(48 + state_local(i))
    Next

    ' ===== Genereer 1024 cijfers voor consistentie =====
    stretched$ = result$
    Do While Len(stretched$) < 1024
        tmp$ = Right$(result$, Len(result$) \ 2) + Left$(result$, Len(result$) \ 2)
        For j = 1 To Len(tmp$)
            d = (Asc(Mid$(tmp$, j, 1)) - 48 + j) Mod 10
            Mid$(tmp$, j, 1) = Chr$(48 + d)
        Next
        stretched$ = stretched$ + tmp$
        result$ = tmp$
    Loop
    code$ = Left$(stretched$, 1024)
    ' ===================================================

    ' Toon animatie van de code (eerste 256 cijfers)
    a = 0
    For i = 1 To 256
        a = a + 0.05235987756
        spiral_rad = i * 0.92
        px = ANIM_CENTER_X + Cos(a * 1.6180339887) * spiral_rad
        py = ANIM_CENTER_Y + Sin(a * 1.6180339887) * spiral_rad
        PSet (px, py), 14
        Locate 28, 1: Print "Jouw code: "; Left$(code$, i);
        _Display: _Delay 0.0038
    Next

    Locate 29, 18: Print "KLAAR – TERUG NAAR GUI..."
    _Display
    Sleep 2

    ' ===== TERUG NAAR GUI =====
    Screen 12
    _PutImage , savedScreen, 0
    _FreeImage savedScreen
    _Display
    ' ==========================

    RModuleWithParams$ = code$
End Function

' ==============================================================
' ANIMATIE HELPERS (blijven hetzelfde)
' ==============================================================
Sub AddParticle (x As Single, y As Single, col As Integer, ring As Integer)
    pCount = pCount + 1
    If pCount > 3000 Then pCount = 1
    particles(pCount, 1) = x
    particles(pCount, 2) = y
    particles(pCount, 3) = 0
    particles(pCount, 4) = col
    particles(pCount, 5) = ring
End Sub

Sub Explosion (x As Single, y As Single, col As Integer, aantal As Integer)
    Dim i As Integer
    For i = 1 To aantal
        Call AddParticle(x + Rnd * 45 - 22, y + Rnd * 45 - 22, col, 0)
    Next
End Sub

Sub DrawAll
    Dim i As Integer, age As Integer
    For i = 1 To pCount
        age = particles(i, 3)
        If age <= 90 Then
            PSet (particles(i, 1), particles(i, 2)), particles(i, 4)
            particles(i, 3) = age + 1
        End If
    Next
End Sub

Function IIfInt% (c As Integer, t As Integer, f As Integer)
    If c Then
        IIfInt% = t
    Else
        IIfInt% = f
    End If
End Function

' ==============================================================
' BINAIRE EXPONENTIATIE (blijft hetzelfde)
' ==============================================================

Sub FastPowerBinary (result() As Integer, result_len As Integer, base_arr() As Integer, base_len As Integer, exponent As Integer)
    Dim pow_arr(1 To 500) As Integer, pow_len As Integer
    Dim e As Integer, i As Integer

    pow_len = base_len
    For i = 1 To base_len
        If i <= 500 Then
            pow_arr(i) = base_arr(i)
        End If
    Next

    result(1) = 1
    result_len = 1

    If exponent < 0 Then exponent = 0
    If exponent > 1000 Then exponent = 1000

    Do While exponent > 0
        If (exponent And 1) Then
            Call BigMulArrays(result(), result_len, pow_arr(), pow_len)
            If result_len > 350 Then result_len = 350
        End If

        exponent = exponent \ 2

        If exponent > 0 Then
            Call BigMulArrays(pow_arr(), pow_len, pow_arr(), pow_len)
            If pow_len > 350 Then pow_len = 350
        End If
    Loop
End Sub

' ==============================================================
' BIGINT ROUTINES VOOR R-MODULE (blijven hetzelfde)
' ==============================================================

Sub BigMulArray (num() As Integer, num_len As Integer, multiplier As Integer)
    Dim i As Integer, carry As Integer, product As Long
    carry = 0

    If num_len > UBound(num) Then num_len = UBound(num)

    For i = 1 To num_len
        product = num(i) * multiplier + carry
        num(i) = product Mod 10
        carry = product \ 10
    Next

    Do While carry > 0 And num_len < UBound(num)
        num_len = num_len + 1
        If num_len > UBound(num) Then Exit Do
        num(num_len) = carry Mod 10
        carry = carry \ 10
    Loop
End Sub

Sub BigAddArrays (a() As Integer, a_len As Integer, b() As Integer, b_len As Integer)
    Dim i As Integer, carry As Integer, sum As Integer
    carry = 0

    If a_len > UBound(a) Then a_len = UBound(a)
    If b_len > UBound(b) Then b_len = UBound(b)

    If b_len > a_len And b_len <= UBound(a) Then a_len = b_len

    For i = 1 To a_len
        If i <= UBound(a) And i <= UBound(b) Then
            sum = a(i) + b(i) + carry
            a(i) = sum Mod 10
            carry = sum \ 10
        End If
    Next

    If carry > 0 And a_len < UBound(a) Then
        a_len = a_len + 1
        a(a_len) = carry
    End If
End Sub

Sub BigSubArrays (a() As Integer, a_len As Integer, b() As Integer, b_len As Integer)
    Dim i As Integer, borrow As Integer, diff As Integer
    borrow = 0

    If a_len > UBound(a) Then a_len = UBound(a)
    If b_len > UBound(b) Then b_len = UBound(b)

    If b_len > a_len Then b_len = a_len

    For i = 1 To a_len
        If i <= UBound(a) And i <= UBound(b) Then
            diff = a(i) - b(i) - borrow
            If diff < 0 Then
                diff = diff + 10
                borrow = 1
            Else
                borrow = 0
            End If
            a(i) = diff
        End If
    Next

    Do While a_len > 1 And a_len <= UBound(a) And a(a_len) = 0
        a_len = a_len - 1
    Loop
End Sub

Sub BigMulArrays (a() As Integer, a_len As Integer, b() As Integer, b_len As Integer)
    Dim i As Integer, j As Integer, carry As Integer, product As Long
    Dim max_a_len As Integer, max_b_len As Integer

    If a_len > UBound(a) Then a_len = UBound(a)
    If b_len > UBound(b) Then b_len = UBound(b)
    max_a_len = UBound(a)
    max_b_len = UBound(b)

    For i = 1 To 1000: big_temp(i) = 0: Next

    For i = 1 To a_len
        If i > max_a_len Then Exit For
        carry = 0
        For j = 1 To b_len
            If j > max_b_len Then Exit For
            product = a(i) * b(j) + big_temp(i + j - 1) + carry
            If (i + j - 1) <= 1000 Then
                big_temp(i + j - 1) = product Mod 10
            End If
            carry = product \ 10
        Next
        If carry > 0 And (i + b_len) <= 1000 Then
            big_temp(i + b_len) = carry
        End If
    Next

    a_len = a_len + b_len
    If a_len > 1000 Then a_len = 1000

    Do While a_len > 1 And a_len <= 1000 And big_temp(a_len) = 0
        a_len = a_len - 1
    Loop

    If a_len > max_a_len Then a_len = max_a_len
    For i = 1 To a_len
        If i <= max_a_len Then
            a(i) = big_temp(i)
        End If
    Next
End Sub

Sub CopyLastDigits (dest() As Integer, dest_len As Integer, src() As Integer, src_len As Integer, count As Integer)
    Dim i As Integer, start_pos As Integer

    If src_len > UBound(src) Then src_len = UBound(src)
    If count > UBound(dest) Then count = UBound(dest)

    If src_len <= count Then
        If src_len > UBound(dest) Then src_len = UBound(dest)
        dest_len = src_len
        For i = 1 To src_len
            If i <= UBound(dest) And i <= UBound(src) Then
                dest(i) = src(i)
            End If
        Next
    Else
        If count > UBound(dest) Then count = UBound(dest)
        dest_len = count
        start_pos = src_len - count + 1
        If start_pos < 1 Then start_pos = 1
        For i = 1 To count
            If i <= UBound(dest) And (start_pos + i - 1) <= UBound(src) Then
                dest(i) = src(start_pos + i - 1)
            End If
        Next
    End If
End Sub

