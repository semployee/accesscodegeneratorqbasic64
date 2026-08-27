#!/usr/bin/env python3
"""
QB64 AccessCode Generator Brute-Force Cracker
Attempts to crack the 256-digit hash by testing username/password combinations
with support for extended ASCII characters.
"""

import sys
from itertools import product
import time

# Constants from QB64 code
PEPPER = "MijnGeheimePepper123!@#$%^&*()_+"
HASH_TO_MATCH = "704382479557331984651638066712427985405440381425501749081891681069977400182826590685391048891489827738158569676552552862501360577289626153597999908231874424736007121207808305005710566666081"

PHI_STRING = "16180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374847540880753868917521266338622235369317931800607667263544333890865959395829056383226613"

def big_mul_array(num, multiplier):
    """Multiply a big-integer array by a single digit."""
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
    """Add two big-integer arrays."""
    carry = 0
    max_len = max(len(a), len(b))
    
    # Pad shorter array
    while len(a) < max_len:
        a.append(0)
    while len(b) < max_len:
        b.append(0)
    
    for i in range(max_len):
        s = a[i] + b[i] + carry
        a[i] = s % 10
        carry = s // 10
    
    if carry > 0:
        a.append(carry)
    
    return a

def big_sub_arrays(a, b):
    """Subtract b from a (big-integer arrays)."""
    borrow = 0
    
    for i in range(len(b)):
        diff = a[i] - b[i] - borrow
        if diff < 0:
            diff += 10
            borrow = 1
        else:
            borrow = 0
        a[i] = diff
    
    # Remove leading zeros
    while len(a) > 1 and a[-1] == 0:
        a.pop()
    
    return a

def big_mul_arrays(a, b):
    """Multiply two big-integer arrays."""
    result = [0] * (len(a) + len(b))
    
    for i in range(len(a)):
        carry = 0
        for j in range(len(b)):
            product = a[i] * b[j] + result[i + j] + carry
            result[i + j] = product % 10
            carry = product // 10
        if carry > 0:
            result[i + len(b)] = carry
    
    # Remove leading zeros
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    
    return result

def fast_power_binary(base, exponent):
    """Binary exponentiation for big-integer arrays."""
    result = [1]
    base = base.copy()
    
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
    """Build big-integer seed from username + password + pepper."""
    combined = username + password + pepper
    seed = [1]
    
    for i, char in enumerate(combined):
        # In QB64: Asc(char) + (i+1) because QB64 uses 1-based indexing
        digit = ord(char) + i + 1
        seed = big_mul_array(seed.copy(), digit)
    
    if len(seed) == 1 and seed[0] == 0:
        seed = [1]
    
    return seed

def copy_last_digits(dest, src, count):
    """Copy last 'count' digits from src to dest."""
    if len(src) <= count:
        return src.copy()
    else:
        return src[-count:]

def rmodule_with_params(username, password, seed, phi_start, k_max):
    """R-Module implementation (without animation)."""
    state = [1]
    
    # Initialize state with seed
    seedstr = username + password + username + password
    for i, char in enumerate(seedstr):
        digit = ord(char) + i + 1
        state = big_mul_array(state.copy(), digit)
    
    # Build phi array
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
                current_phi = big_mul_array(current_phi.copy(), k)
            
            if k % 2 == 1:
                wave = big_add_arrays(wave, current_phi)
            else:
                wave = big_sub_arrays(wave, current_phi)
            
            if len(current_phi) > 250:
                current_phi = current_phi[:250]
            if len(wave) > 250:
                wave = wave[:250]
        
        # Copy last 64 digits
        state = copy_last_digits(state, wave, 64)
    
    # Condense to string
    result = ''.join(str(d) for d in state)
    
    # Stretch to 1024 digits
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
    """Generate 256-digit access code."""
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
    
    # Truncation/scrambling based on strategy
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
    
    # Ensure 256 digits
    if len(trunc) < 256:
        final = trunc
        while len(final) < 256:
            final += trunc[:256 - len(final)]
        return final
    else:
        return trunc[:256]

def brute_force_crack():
    """Brute-force crack the hash."""
    print(f"[*] Target hash: {HASH_TO_MATCH}")
    print(f"[*] Hash length: {len(HASH_TO_MATCH)}")
    print(f"[*] Pepper: {PEPPER}")
    print()
    
    # Known username hint: "Luffy"
    username = "Luffy"
    
    attempts = 0
    start_time = time.time()
    
    # Strategy 1: Test standard ASCII passwords first (fast)
    print("[*] Strategy 1: Standard ASCII (32-126) passwords...")
    
    # Common password patterns
    common_passwords = [
        "password", "monkey", "qwerty", "123456", "admin", "letmein",
        "welcome", "monkey123", "password123", "qwerty123",
    ]
    
    for pwd in common_passwords:
        attempts += 1
        generated = generate_access_code_256(username, pwd, PEPPER)
        
        if generated == HASH_TO_MATCH:
            elapsed = time.time() - start_time
            print(f"\n[+] CRACKED in {elapsed:.2f}s!")
            print(f"[+] Username: {username}")
            print(f"[+] Password: {pwd}")
            print(f"[+] Attempts: {attempts}")
            return True
        
        if attempts % 100 == 0:
            elapsed = time.time() - start_time
            rate = attempts / elapsed
            print(f"  Attempts: {attempts} ({rate:.1f}/sec)")
    
    # Strategy 2: Extended ASCII (test possible byte values for the mystery character)
    print("\n[*] Strategy 2: Extended ASCII (0-255) byte values...")
    print(f"[*] Testing: Luffy + Monkey[BYTE] + D")
    
    for byte_val in range(256):
        for char_pos in range(1, 10):  # Try different positions
            pwd = "Monkey" + chr(byte_val) + "D"
            
            attempts += 1
            generated = generate_access_code_256(username, pwd, PEPPER)
            
            if generated == HASH_TO_MATCH:
                elapsed = time.time() - start_time
                print(f"\n[+] CRACKED in {elapsed:.2f}s!")
                print(f"[+] Username: {username}")
                print(f"[+] Password: {pwd}")
                print(f"[+] Password bytes: {[ord(c) for c in pwd]}")
                print(f"[+] Attempts: {attempts}")
                return True
            
            if attempts % 1000 == 0:
                elapsed = time.time() - start_time
                rate = attempts / elapsed
                print(f"  Attempts: {attempts} ({rate:.1f}/sec)")
    
    elapsed = time.time() - start_time
    print(f"\n[-] Not cracked after {attempts} attempts in {elapsed:.2f}s")
    return False

if __name__ == "__main__":
    brute_force_crack()
