' ==============================================================
' 256-DIGIT ACCESSCODE LOGIN VALIDATOR (PEPPER-VERSIE)
' Copyright (C) R.T.Somer
' Oneindige loop - stopt alleen bij correcte login
' Hardcoded hash (plak hem uit de generator)
' Gebruikt EXACT dezelfde R-module als grafische versie
'
' Big-integer basisroutines gebaseerd op de BigInt-library van
' PetesQBSite (http://www.petesqbsite.com/downloads/bigint.zip),
' oorspronkelijk geschreven door Deus Ex Machina.
' ==============================================================

Const PEPPER = "MijnGeheimePepper123!@#$%^&*()_+"

' === PLAK HIER DE 256-CIJFERIGE HASH (uit de generator) ===
Const HASH_TO_MATCH = "7043824795573319846516380667124279854054403814255017490818916810699774001828265906853910488914898277381585696765525528625013605772896261535979990823187442473600712120780830500574754144547182786133542476206239204331568469384784131839436103457613200896938415"

' === Declaraties ===
DECLARE FUNCTION GenerateAccessCode256$ (username AS STRING, password AS STRING, pepper AS STRING)
DECLARE SUB BuildBigSeed (username AS STRING, password AS STRING, pepper AS STRING, seed_arr() AS INTEGER, seed_len AS INTEGER)
DECLARE FUNCTION RModuleWithParams$ (username AS STRING, password AS STRING, seed_arr() AS INTEGER, seed_len AS INTEGER, phi_start AS LONG, k_max AS INTEGER)
DECLARE SUB FastPowerBinary (result() AS INTEGER, result_len AS INTEGER, base_arr() AS INTEGER, base_len AS INTEGER, exponent AS INTEGER)
DECLARE SUB BigMulArray (num() AS INTEGER, num_len AS INTEGER, multiplier AS INTEGER)
DECLARE SUB BigAddArrays (a() AS INTEGER, a_len AS INTEGER, b() AS INTEGER, b_len AS INTEGER)
DECLARE SUB BigSubArrays (a() AS INTEGER, a_len AS INTEGER, b() AS INTEGER, b_len AS INTEGER)
DECLARE SUB BigMulArrays (a() AS INTEGER, a_len AS INTEGER, b() AS INTEGER, b_len AS INTEGER)
DECLARE SUB CopyLastDigits (dest() AS INTEGER, dest_len AS INTEGER, src() AS INTEGER, src_len AS INTEGER, count AS INTEGER)
DECLARE FUNCTION IIf$ (c AS INTEGER, t AS STRING, f AS STRING)

' === GRAFISCHE INTERFACE ===
Screen 12
_MouseHide
Color 15, 0
Cls

' Coördinaten
userX = 100: userY = 100
passX = 100: passY = 140
outX = 100: outY = 200

user$ = ""
pass$ = ""
currentInput = 0 ' 0 = username, 1 = password
errorMsg$ = ""

Do
    ' --- Toetsenbord ---
    k$ = InKey$
    If Len(k$) = 1 Then
        Select Case Asc(k$)
            Case 13 ' Enter
                If currentInput = 0 Then
                    currentInput = 1
                Else
                    ' Controleer login
                    errorMsg$ = ""
                    generated$ = GenerateAccessCode256$(user$, pass$, PEPPER)
                    If generated$ = HASH_TO_MATCH Then
                        Cls
                        _PrintString (200, 200), "LOGIN OK"
                        _PrintString (200, 220), "Welkom!"
                        _Display
                        Sleep 3
                        End
                    Else
                        errorMsg$ = "Ongeldige combinatie, probeer opnieuw."
                        user$ = ""
                        pass$ = ""
                        currentInput = 0
                    End If
                End If
            Case 8 ' Backspace
                If currentInput = 0 Then
                    If Len(user$) > 0 Then user$ = Left$(user$, Len(user$) - 1)
                Else
                    If Len(pass$) > 0 Then pass$ = Left$(pass$, Len(pass$) - 1)
                End If
            Case 9 ' Tab
                currentInput = 1 - currentInput
            Case Else
                If Asc(k$) >= 32 And Asc(k$) <= 126 Then
                    If currentInput = 0 Then
                        If Len(user$) < 30 Then user$ = user$ + k$
                    Else
                        If Len(pass$) < 30 Then pass$ = pass$ + k$
                    End If
                End If
        End Select
    End If

    ' --- Scherm tekenen ---
    Cls
    _PrintString (200, 20), "=== ACCESSCODE LOGIN ==="

    ' Username
    cursor$ = IIf(currentInput = 0, "_", " ")
    _PrintString (userX, userY), "Username: " + user$ + cursor$

    ' Password
    cursor$ = IIf(currentInput = 1, "_", " ")
    _PrintString (passX, passY), "Password: " + String$(Len(pass$), "*") + cursor$

    ' Foutmelding
    If errorMsg$ <> "" Then
        Color 12
        _PrintString (outX, outY), errorMsg$
        Color 15
    End If

    _Display
    _Limit 60
Loop

' ==============================================================
' ===============  HULPFUNCTIE ==================================
' ==============================================================
Function IIf$ (c As Integer, t As String, f As String)
    If c Then IIf$ = t Else IIf$ = f
End Function

' ==============================================================
' ===============  GENERATOR LOGICA (PEPPER-VERSIE) ============
' ==============================================================

Function GenerateAccessCode256$ (username As String, password As String, pepper As String)
    Dim seed_arr(1 To 500) As Integer, seed_len As Integer
    Dim phi_start As Long, k_max As Integer
    Dim RMODULE_HASH As String, TRUNC As String, FINAL As String
    Dim STRAT_ID As Integer

    BuildBigSeed username, password, pepper, seed_arr(), seed_len

    If seed_len >= 3 Then
        phi_start = seed_arr(seed_len) * 100 + seed_arr(seed_len - 1) * 10 + seed_arr(seed_len - 2)
    Else
        phi_start = 1
    End If
    If phi_start < 1 Then phi_start = 1

    k_max = 500 + (seed_arr(seed_len) Mod 500)
    If k_max < 500 Then k_max = 500
    If k_max > 999 Then k_max = 999

    RMODULE_HASH = RModuleWithParams$(username, password, seed_arr(), seed_len, phi_start, k_max)

    If seed_len >= 2 Then
        STRAT_ID = (seed_arr(seed_len) + seed_arr(seed_len - 1)) Mod 8
    Else
        STRAT_ID = seed_arr(seed_len) Mod 8
    End If

    Dim ACCESSCODE_1024 As String, BLOCK_A As String, BLOCK_B As String, BLOCK_C As String, BLOCK_D As String
    Dim PERMUTED_1024 As String
    Dim I As Integer, J As Integer, D_CURRENT As Integer, D_NEW As Integer, D_OUT As Integer
    Dim START_POS As Integer, SHIFT_AMOUNT As Integer, OLD_INDEX As Integer

    ACCESSCODE_1024 = RMODULE_HASH

    Select Case STRAT_ID
        Case 0: TRUNC = Left$(ACCESSCODE_1024, 256)
        Case 1: TRUNC = Right$(ACCESSCODE_1024, 256)
        Case 2: TRUNC = Mid$(ACCESSCODE_1024, 257, 256)
        Case 3
            BLOCK_A = Mid$(ACCESSCODE_1024, 1, 256)
            BLOCK_B = Mid$(ACCESSCODE_1024, 257, 256)
            BLOCK_C = Mid$(ACCESSCODE_1024, 513, 256)
            BLOCK_D = Mid$(ACCESSCODE_1024, 769, 256)
            TRUNC = BLOCK_C + BLOCK_A + BLOCK_D + BLOCK_B
            TRUNC = Left$(TRUNC, 256)
        Case 4
            TRUNC = ""
            For I = 1 To 1023 Step 4
                TRUNC = TRUNC + Mid$(ACCESSCODE_1024, I, 1)
                If Len(TRUNC) = 256 Then Exit For
            Next
        Case 5
            TRUNC = ""
            For I = 2 To 1024 Step 3
                TRUNC = TRUNC + Mid$(ACCESSCODE_1024, I, 1)
                If Len(TRUNC) = 256 Then Exit For
            Next
        Case 6
            Dim FINAL_128 As String
            FINAL_128 = String$(128, "0")
            For J = 0 To 7
                START_POS = J * 128 + 1
                BLOCK$ = Mid$(ACCESSCODE_1024, START_POS, 128)
                For I = 1 To 128
                    D_CURRENT = Val(Mid$(FINAL_128, I, 1))
                    D_NEW = Val(Mid$(BLOCK$, I, 1))
                    D_OUT = (D_CURRENT + D_NEW) Mod 10
                    Mid$(FINAL_128, I, 1) = Chr$(48 + D_OUT)
                Next
            Next
            TRUNC = FINAL_128 + FINAL_128
        Case 7
            PERMUTED_1024 = String$(1024, "0")
            SHIFT_AMOUNT = (seed_arr(seed_len) + seed_arr(seed_len - 1)) Mod 1023 + 1
            For I = 1 To 1024
                OLD_INDEX = ((I - 1) + SHIFT_AMOUNT) Mod 1024 + 1
                Mid$(PERMUTED_1024, I, 1) = Mid$(ACCESSCODE_1024, OLD_INDEX, 1)
            Next
            TRUNC = Left$(PERMUTED_1024, 256)
    End Select

    If Len(TRUNC) < 256 Then
        FINAL = TRUNC
        Do While Len(FINAL) < 256
            FINAL = FINAL + Left$(TRUNC, 256 - Len(FINAL))
        Loop
        GenerateAccessCode256$ = FINAL
    Else
        GenerateAccessCode256$ = Left$(TRUNC, 256)
    End If
End Function

' ==============================================================
' BIG-INTEGER SEED
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
' R-MODULE (EXACTE KOPIE VAN GRAFISCHE VERSIE, ZONDER ANIMATIE)
' ==============================================================

Function RModuleWithParams$ (username As String, password As String, seed_arr() As Integer, seed_len As Integer, phi_start As Long, k_max As Integer)
    Dim state(1 To 500) As Integer
    Dim wave(1 To 500) As Integer
    Dim current_phi(1 To 500) As Integer
    Dim phi_arr(1 To 150) As Integer
    Dim result As String, stretched As String, code As String, tmp As String
    Dim n As Integer, k As Integer, i As Long, j As Integer
    Dim state_len As Integer, wave_len As Integer, current_phi_len As Integer
    Dim start_pos As Integer, phi_index As Integer, d As Integer

    ' === INITIALISEER state MET DEZELFDE INJECTIE ALS GRAFISCHE VERSIE ===
    Dim seedStr As String
    seedStr = username + password + username + password
    state(1) = 1: state_len = 1
    For i = 1 To Len(seedStr)
        digit = Asc(Mid$(seedStr, i, 1)) + i
        Call BigMulArray(state(), state_len, digit)
    Next

    ' === PHI ARRAY ===
    phi$ = "16180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374847540880753868917521266338622235369317931800607667263544333890865959395829056383226613199282902678806752087668925017116962070322210432162695486262963136144381497587012203408058879544547492461856953648644492410443207713449470495658467885098743394422125448770664780915884607499887124007652170575179788341662562494075890697040002812104276217711177780531531714101170466659914669798731761356006708748071013179523689427521948435305678300228785699782977834784587822891109762500302696156170025046433824377648610283831268330372429267526311653392473167111211588186385133162038400522216579128667529465490681131715993432359734949850904094762132229810172610705961164562990981629055520852479035240602017279974717534277759277862561943208275051312181562855122248093947123414517022373580577278616008688382952304592647878017889921990270776903895321968198615143780314997411069260886742962267575605231727775203536139362"

    start_pos = phi_start
    If start_pos < 1 Then start_pos = 1
    If start_pos > Len(phi$) - 149 Then start_pos = (seed_arr(seed_len) Mod (Len(phi$) - 149)) + 1

    For i = 1 To 150
        phi_index = start_pos + i - 1
        If phi_index > Len(phi$) Then phi_index = phi_index - Len(phi$)
        phi_arr(i) = Val(Mid$(phi$, phi_index, 1))
    Next

    ' === 12 UNIVERSA (precies zoals in grafische versie) ===
    For n = 1 To 12
        For i = 1 To 500: wave(i) = 0: Next
        wave_len = 1
        For i = 1 To 500: current_phi(i) = 0: Next
        current_phi(1) = 1: current_phi_len = 1

        For k = 1 To k_max
            Call FastPowerBinary(current_phi(), current_phi_len, phi_arr(), 150, n * k)

            If k Mod 2 = 0 Then
                Call BigMulArray(current_phi(), current_phi_len, k)
            End If
            If k Mod 2 = 1 Then
                Call BigAddArrays(wave(), wave_len, current_phi(), current_phi_len)
            Else
                Call BigSubArrays(wave(), wave_len, current_phi(), current_phi_len)
            End If

            If current_phi_len > 250 Then current_phi_len = 250
            If wave_len > 250 Then wave_len = 250
        Next

        Call CopyLastDigits(state(), state_len, wave(), wave_len, 64)
    Next

    ' === CONDENSATIE ===
    result = ""
    For i = 1 To state_len
        If i <= 500 Then result = result + Chr$(48 + state(i))
    Next

    stretched = result
    Do While Len(stretched) < 1024
        tmp = Right$(result, Len(result) \ 2) + Left$(result, Len(result) \ 2)
        For j = 1 To Len(tmp)
            d = (Asc(Mid$(tmp, j, 1)) - 48 + j) Mod 10
            Mid$(tmp, j, 1) = Chr$(48 + d)
        Next
        stretched = stretched + tmp
        result = tmp
    Loop
    code = Left$(stretched, 1024)

    RModuleWithParams$ = code
End Function

' ==============================================================
' BIG INTEGER OPERATIES (IDENTIEK AAN GRAFISCHE VERSIE)
' ==============================================================

Sub FastPowerBinary (result() As Integer, result_len As Integer, base_arr() As Integer, base_len As Integer, exponent As Integer)
    Dim pow_arr(1 To 500) As Integer, pow_len As Integer
    Dim e As Integer, i As Integer

    pow_len = base_len
    For i = 1 To base_len
        If i <= 500 Then pow_arr(i) = base_arr(i)
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
    Dim big_temp(1 To 1000) As Integer

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
            If (i + j - 1) <= 1000 Then big_temp(i + j - 1) = product Mod 10
            carry = product \ 10
        Next
        If carry > 0 And (i + b_len) <= 1000 Then big_temp(i + b_len) = carry
    Next

    a_len = a_len + b_len
    If a_len > 1000 Then a_len = 1000

    Do While a_len > 1 And a_len <= 1000 And big_temp(a_len) = 0
        a_len = a_len - 1
    Loop

    If a_len > max_a_len Then a_len = max_a_len
    For i = 1 To a_len
        If i <= max_a_len Then a(i) = big_temp(i)
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
            If i <= UBound(dest) And i <= UBound(src) Then dest(i) = src(i)
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

