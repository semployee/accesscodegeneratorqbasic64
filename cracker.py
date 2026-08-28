#!/usr/bin/env python3
"""
QB64 AccessCode Generator Brute-Force Cracker - WERKENDE VERSIE
Reverse-engineered uit de QB64 generator en verificator
"""

import time
import sys

# Constanten (moet identiek zijn aan generator/verificator)
PEPPER = "MijnGeheimePepper123!@#$%^&*()_+"
HASH_TO_MATCH = "70438247955733198465163806671242798540544038142550174908189168106997740018282659068539104889148982773815856967655255286250136057728962615359799990823187442473600712120780830500571"

PHI_STRING = "161803398874989484820458683436563811772030917980576286213544862270526046281890244970720720418939113748475408807538689175212663386222353693179318006076672635443338908659593958290563832676030360985010748866852605239"

def big_mul_array(num, multiplier):
    """Vermenigvuldig big-integer array met enkel getal."""
    num = num[:]  # Copy
    carry = 0
    for i in range(len(num)):
        product = num[i] * multiplier + carry
        num[i] = product % 10
        carry = product // 10
    
    while carry > 0:
        num.append(carry % 10)
        carry = carry // 10
    
    return num

def big_add_arrays(a, b):
    """Tel twee big-integer arrays op."""
    a = a[:]  # Copy
    b = b[:]
    
    max_len = max(len(a), len(b))
    while len(a) < max_len:
        a.append(0)
    while len(b) < max_len:
        b.append(0)
    
    carry = 0
    for i in range(max_len):
        s = a[i] + b[i] + carry
        a[i] = s % 10
        carry = s // 10
    
    if carry > 0:
        a.append(carry)
    
    return a

def big_sub_arrays(a, b):
    """Trek b af van a (big-integer arrays)."""
    a = a[:]
    b = b[:]
    
    max_len = max(len(a), len(b))
    if len(a) < max_len:
        a.extend([0] * (max_len - len(a)))
    if len(b) < max_len:
        b.extend([0] * (max_len - len(b)))
    
    borrow = 0
    for i in range(max_len):
        diff = a[i] - b[i] - borrow
        if diff < 0:
            diff += 10
            borrow = 1
        else:
            borrow = 0
        a[i] = diff
    
    # Verwerk resterende borrow
    i = max_len
    while borrow and i < len(a):
        diff = a[i] - borrow
        if diff < 0:
            a[i] = diff + 10
            borrow = 1
        else:
            a[i] = diff
            borrow = 0
        i += 1
    
    if borrow:
        return [0]
    
    # Verwijder voorloopnullen
    while len(a) > 1 and a[-1] == 0:
        a.pop()
    
    return a

def big_mul_arrays(a, b):
    """Vermenigvuldig twee big-integer arrays."""
    result = [0] * (len(a) + len(b))
    
    for i in range(len(a)):
        carry = 0
        for j in range(len(b)):
            product = a[i] * b[j] + result[i + j] + carry
            result[i + j] = product % 10
            carry = product // 10
        if carry > 0:
            result[i + len(b)] = carry
    
    # Verwijder voorloopnullen
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    
    return result

def fast_power_binary(base, exponent):
    """Binaire exponentiatie voor big-integer arrays."""
    result = [1]
    base = base[:]
    
    if exponent < 0:
        exponent = 0
    if exponent > 1000:
        exponent = 1000
    
    while exponent > 0:
        if exponent & 1:
            result = big_mul_arrays(result, base)
            if len(result) > 350:
                result = result[:350]
        
        exponent >>= 1
        
        if exponent > 0:
            base = big_mul_arrays(base, base)
            if len(base) > 350:
                base = base[:350]
    
    return result

def build_big_seed(username, password, pepper):
    """Bouw big-integer seed uit username + password + pepper."""
    combined = username + password + pepper
    seed = [1]
    
    for i, char in enumerate(combined):
        digit = ord(char) + i + 1
        seed = big_mul_array(seed, digit)
    
    if len(seed) == 1 and seed[0] == 0:
        seed = [1]
    
    return seed

def copy_last_digits(src, count):
    """Kopieer laatste 'count' cijfers uit src."""
    if len(src) <= count:
        return src[:]
    else:
        return src[-count:]

def rmodule_with_params(username, password, seed, phi_start, k_max):
    """R-Module implementatie (zonder animatie)."""
    state = [1]
    
    # Initialiseer state met seed
    seedstr = username + password + username + password
    for i, char in enumerate(seedstr):
        digit = ord(char) + i + 1
        state = big_mul_array(state, digit)
    
    # Bouw phi array
    phi_start = max(1, phi_start)
    if phi_start > len(PHI_STRING) - 149:
        phi_start = (seed[-1] % (len(PHI_STRING) - 149)) + 1
    
    phi_arr = []
    for i in range(150):
        phi_index = phi_start - 1 + i
        if phi_index >= len(PHI_STRING):
            phi_index = phi_index % len(PHI_STRING)
        phi_arr.append(int(PHI_STRING[phi_index]))
    
    # 12 universa
    for n in range(1, 13):
        wave = [1]
        current_phi = [1]
        
        for k in range(1, k_max + 1):
            current_phi = fast_power_binary(phi_arr, n * k)
            
            if k % 2 == 0:
                current_phi = big_mul_array(current_phi, k)
            
            if k % 2 == 1:
                wave = big_add_arrays(wave, current_phi)
            else:
                wave = big_sub_arrays(wave, current_phi)
            
            if len(current_phi) > 250:
                current_phi = current_phi[:250]
            if len(wave) > 250:
                wave = wave[:250]
        
        # Kopieer laatste 64 cijfers
        state = copy_last_digits(wave, 64)
    
    # Condenseer naar string
    result = ''.join(str(d) for d in state)
    
    # Rek uit naar 1024 cijfers
    stretched = result
    while len(stretched) < 1024:
        tmp = result[::-1][:len(result)//2][::-1] + result[:len(result)//2]
        tmp_list = [int(c) for c in tmp]
        for j in range(len(tmp_list)):
            tmp_list[j] = (tmp_list[j] + j + 1) % 10
        tmp = ''.join(str(d) for d in tmp_list)
        stretched += tmp
        result = tmp
    
    return stretched[:1024]

def generate_access_code_256(username, password, pepper):
    """Genereer 256-cijferige accesscode."""
    seed = build_big_seed(username, password, pepper)
    
    if len(seed) >= 3:
        phi_start = seed[-1] * 100 + seed[-2] * 10 + seed[-3]
    else:
        phi_start = 1
    
    if phi_start < 1:
        phi_start = 1
    
    k_max = 500 + (seed[-1] % 500)
    if k_max < 500:
        k_max = 500
    if k_max > 999:
        k_max = 999
    
    rmodule_hash = rmodule_with_params(username, password, seed, phi_start, k_max)
    
    if len(seed) >= 2:
        strat_id = (seed[-1] + seed[-2]) % 8
    else:
        strat_id = seed[-1] % 8
    
    # Truncatie/scrambling op basis van strategie
    accesscode_1024 = rmodule_hash
    
    if strat_id == 0:
        trunc = accesscode_1024[:256]
    elif strat_id == 1:
        trunc = accesscode_1024[-256:]
    elif strat_id == 2:
        trunc = accesscode_1024[256:512]
    elif strat_id == 3:
        block_a = accesscode_1024[0:256]
        block_b = accesscode_1024[256:512]
        block_c = accesscode_1024[512:768]
        block_d = accesscode_1024[768:1024]
        trunc = (block_c + block_a + block_d + block_b)[:256]
    elif strat_id == 4:
        trunc = ''
        for i in range(0, 1023, 4):
            trunc += accesscode_1024[i]
            if len(trunc) == 256:
                break
    elif strat_id == 5:
        trunc = ''
        for i in range(1, 1024, 3):
            trunc += accesscode_1024[i]
            if len(trunc) == 256:
                break
    elif strat_id == 6:
        final_128 = '0' * 128
        final_128_list = list(final_128)
        for j in range(8):
            start_pos = j * 128
            block = accesscode_1024[start_pos:start_pos + 128]
            for i in range(128):
                if i < len(block):
                    d_out = (int(final_128_list[i]) + int(block[i])) % 10
                    final_128_list[i] = str(d_out)
        final_128 = ''.join(final_128_list)
        trunc = final_128 + final_128
    elif strat_id == 7:
        shift_amount = (seed[-1] + seed[-2]) % 1023 + 1
        permuted = '0' * 1024
        permuted_list = list(permuted)
        for i in range(1024):
            old_index = ((i) + shift_amount) % 1024
            permuted_list[i] = accesscode_1024[old_index]
        trunc = ''.join(permuted_list)[:256]
    
    # Zorg dat het 256 cijfers is
    if len(trunc) < 256:
        final = trunc
        while len(final) < 256:
            final += trunc[:256 - len(final)]
        return final
    else:
        return trunc[:256]

def main():
    print("=" * 70)
    print("QB64 AccessCode Generator - Brute Force Cracker")
    print("=" * 70)
    print(f"Target hash: {HASH_TO_MATCH}")
    print(f"Hash lengte: {len(HASH_TO_MATCH)}")
    print(f"Pepper: {PEPPER}")
    print()
    
    attempts = 0
    start_time = time.time()
    
    # Strategie 1: Standaard ASCII wachtwoorden
    print("[*] Strategie 1: Standaard ASCII wachtwoorden testen...")
    common_passwords = [
        "password", "monkey", "qwerty", "123456", "admin", "letmein",
        "welcome", "monkey123", "password123", "qwerty123", "test",
        "Monkey", "Luffy", "Zoro", "Nami", "Usopp",
    ]
    
    for username in ["Luffy", "admin", "test", "user"]:
        for pwd in common_passwords:
            attempts += 1
            generated = generate_access_code_256(username, pwd, PEPPER)
            
            if generated == HASH_TO_MATCH:
                elapsed = time.time() - start_time
                print(f"\n[+] GEVONDEN in {elapsed:.2f}s!")
                print(f"[+] Username: {username}")
                print(f"[+] Password: {pwd}")
                print(f"[+] Pogingen: {attempts}")
                return True
            
            if attempts % 50 == 0:
                elapsed = time.time() - start_time
                rate = attempts / elapsed if elapsed > 0 else 0
                print(f"  Pogingen: {attempts} ({rate:.1f}/sec)")
    
    # Strategie 2: Brute force met korte wachtwoorden (5-8 karakters)
    print("\n[*] Strategie 2: Korte wachtwoorden (5-8 karakters)...")
    
    charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    for username in ["Luffy", "admin", "test"]:
        # Maak alle combinaties van 5-char wachtwoorden
        for len_pwd in range(5, 9):
            print(f"\n  Testing {username} met {len_pwd}-char wachtwoorden...")
            
            # Vereenvoudigd: test alleen enkele combinaties per lengte
            test_patterns = [
                "a" * len_pwd,
                "1" * len_pwd,
                "A" * len_pwd,
                "M" + "o" * (len_pwd - 1),
                "L" + "u" * (len_pwd - 1),
            ]
            
            for pwd in test_patterns:
                attempts += 1
                generated = generate_access_code_256(username, pwd, PEPPER)
                
                if generated == HASH_TO_MATCH:
                    elapsed = time.time() - start_time
                    print(f"\n[+] GEVONDEN in {elapsed:.2f}s!")
                    print(f"[+] Username: {username}")
                    print(f"[+] Password: {pwd}")
                    print(f"[+] Pogingen: {attempts}")
                    return True
                
                if attempts % 100 == 0:
                    elapsed = time.time() - start_time
                    rate = attempts / elapsed if elapsed > 0 else 0
                    print(f"    Pogingen: {attempts} ({rate:.1f}/sec)")
    
    elapsed = time.time() - start_time
    print(f"\n[-] Niet gevonden na {attempts} pogingen in {elapsed:.2f}s")
    print("\nTips:")
    print("- Controleer of HASH_TO_MATCH correct is gekopieerd (256 cijfers)")
    print("- Zorg dat PEPPER identiek is aan de generator")
    print("- Probeer manuelle username/password combinaties")
    
    return False

if __name__ == "__main__":
    main()
