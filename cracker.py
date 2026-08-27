#!/usr/bin/env python3
"""
QB64 AccessCode Generator Brute-Force Cracker
Attempts to crack the 256-digit hash by testing username/password combinations
with support for extended ASCII characters.
"""

import sys
from itertools import product
import time
import argparse

# Test / override globals (can be set via CLI)
OVERRIDE_KMAX = None
TEST_FAST = False

# Constants from QB64 code
PEPPER = "MijnGeheimePepper123!@#$%^&*()_+"
HASH_TO_MATCH = "70438247955733198465163806671242798540544038142550174908189168106997740018282659068539104889148982773815856967655255286250136057728962615359799990823187442473600712120780830500571[...]
"

PHI_STRING = "161803398874989484820458683436563811772030917980576286213544862270526046281890244970720720418939113748475408807538689175212663386222353693179318006076672635443338908659593958290563832266[...]
"

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
    """Subtract b from a (big-integer arrays).

    This version is robust to the case where 'b' is longer than 'a' by
    padding both arrays to the same length and returning a new list.
    It does not mutate the input lists.
    """
    borrow = 0

    # Work on local copies so we don't alter the caller's lists unexpectedly
    a_local = a.copy()
    b_local = b.copy()

    max_len = max(len(a_local), len(b_local))
    if len(a_local) < max_len:
        a_local.extend([0] * (max_len - len(a_local)))
    if len(b_local) < max_len:
        b_local.extend([0] * (max_len - len(b_local)))

    for i in range(max_len):
        diff = a_local[i] - b_local[i] - borrow
        if diff < 0:
            diff += 10
            borrow = 1
        else:
            borrow = 0
        a_local[i] = diff

    # If borrow remains after processing all digits, propagate across
    # any higher-order digits (extend if necessary). This handles the
    # unlikely case where input 'a' is numerically smaller than 'b'.
    i = max_len
    while borrow and i < len(a_local):
        diff = a_local[i] - borrow
        if diff < 0:
            a_local[i] = diff + 10
            borrow = 1
        else:
            a_local[i] = diff
            borrow = 0
        i += 1

    # If there is still a borrow, it means a < b; represent as zero
    # (this mimics QB64 behavior more safely for this algorithm).
    if borrow:
        # return zero
        return [0]

    # Remove leading zeros
    while len(a_local) > 1 and a_local[-1] == 0:
        a_local.pop()

    return a_local

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
                # use the robust subtraction that returns a new list
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

    # respect override for testing
    if OVERRIDE_KMAX is not None:
        k_max = OVERRIDE_KMAX
    
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

    byte_range = range(256)
    char_pos_range = range(1, 10)
    if TEST_FAST:
        # reduce search space for quick testing
        byte_range = range(32)  # printable + some control characters
        char_pos_range = range(1, 3)

    for byte_val in byte_range:
        for char_pos in char_pos_range:  # Try different positions
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
    parser = argparse.ArgumentParser(description="QB64 AccessCode brute-force tester")
    parser.add_argument('--kmax', type=int, help='Override k_max used in generator (for testing)')
    parser.add_argument('--test', action='store_true', help='Enable fast test mode (smaller search space)')
    args = parser.parse_args()

    if args.kmax is not None:
        OVERRIDE_KMAX = args.kmax
    if args.test:
        TEST_FAST = True

    brute_force_crack()
