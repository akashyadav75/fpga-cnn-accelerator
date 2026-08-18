"""
convert_testvector.py
Converts input_1000.txt from space-separated-per-row format
to one-hex-value-per-line format required by Verilog $readmemh.

Usage:  python hardware/scripts/convert_testvector.py
"""
import os

src = "hardware/testvector/input_1000.txt"
dst = "hardware/testvector/input_1000_flat.txt"

values = []
with open(src, "r") as f:
    for line in f:
        tokens = line.strip().split()
        for t in tokens:
            if t:  # skip empty tokens
                values.append(t)

print(f"Total pixel values read: {len(values)}")
expected = 1000 * 784
print(f"Expected:                {expected}")

if len(values) != expected:
    print(f"WARNING: count mismatch! Got {len(values)}, expected {expected}")
else:
    print("Count OK - writing flat file...")

with open(dst, "w") as f:
    for v in values:
        f.write(v + "\n")

print(f"Written to: {dst}")
