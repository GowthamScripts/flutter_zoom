#!/usr/bin/env python3
import os
import struct
import sys
import tempfile
import shutil
import zipfile


ALIGN_MIN = 0x4000
DEFAULT_ABIS = {"arm64-v8a", "x86_64"}


def _iter_so_paths(root: str):
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn.endswith(".so"):
                yield os.path.join(dirpath, fn)


_EI_CLASS = 4
_EI_DATA = 5

_ELFCLASS32 = 1
_ELFCLASS64 = 2

_ELFDATA2LSB = 1
_ELFDATA2MSB = 2

_PT_LOAD = 1


def _elf_load_alignments(so_path: str) -> list[int]:
    with open(so_path, "rb") as f:
        ident = f.read(16)
        if len(ident) != 16 or ident[0:4] != b"\x7fELF":
            return []

        elf_class = ident[_EI_CLASS]
        elf_data = ident[_EI_DATA]
        if elf_data == _ELFDATA2LSB:
            endian = "<"
        elif elf_data == _ELFDATA2MSB:
            endian = ">"
        else:
            return []

        aligns: list[int] = []

        if elf_class == _ELFCLASS64:
            hdr_fmt = endian + "HHIQQQIHHHHHH"
            hdr_size = struct.calcsize(hdr_fmt)
            hdr = struct.unpack(hdr_fmt, f.read(hdr_size))
            e_phoff = hdr[4]
            e_phentsize = hdr[8]
            e_phnum = hdr[9]
            ph_fmt = endian + "IIQQQQQQ"  # type, flags, ..., align
            ph_size = struct.calcsize(ph_fmt)
        elif elf_class == _ELFCLASS32:
            hdr_fmt = endian + "HHIIIIIHHHHHH"
            hdr_size = struct.calcsize(hdr_fmt)
            hdr = struct.unpack(hdr_fmt, f.read(hdr_size))
            e_phoff = hdr[4]
            e_phentsize = hdr[8]
            e_phnum = hdr[9]
            ph_fmt = endian + "IIIIIIII"  # type, offset, vaddr, paddr, filesz, memsz, flags, align
            ph_size = struct.calcsize(ph_fmt)
        else:
            return []

        if e_phoff == 0 or e_phnum == 0:
            return []

        f.seek(e_phoff)
        for _ in range(e_phnum):
            blob = f.read(e_phentsize)
            if len(blob) < ph_size:
                break
            ph = struct.unpack(ph_fmt, blob[:ph_size])
            p_type = ph[0]
            p_align = ph[-1]
            if p_type == _PT_LOAD:
                aligns.append(int(p_align))

        return aligns


def _bad_alignments(so_path: str) -> list[int]:
    bad: set[int] = set()
    for align_val in _elf_load_alignments(so_path):
        if align_val < ALIGN_MIN or (align_val % ALIGN_MIN) != 0:
            bad.add(align_val)
    return sorted(bad)


def _abi_from_path(rel_path: str) -> str | None:
    # Common layouts:
    # - APK/AAB: lib/<abi>/*.so
    # - AAR: jni/<abi>/*.so
    parts = rel_path.replace("\\", "/").split("/")
    for i, p in enumerate(parts[:-1]):
        if p in ("lib", "jni") and i + 1 < len(parts):
            return parts[i + 1]
    return None


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: check_16kb_page_size.py <artifact.apk|artifact.aab|artifact.aar>", file=sys.stderr)
        print("Env:", file=sys.stderr)
        print("  CHECK_ALL_ABIS=1   (check all ABIs; default checks arm64-v8a,x86_64 only)", file=sys.stderr)
        return 2

    artifact = argv[1]
    if not os.path.isfile(artifact):
        print(f"Artifact not found: {artifact}", file=sys.stderr)
        return 2

    tmp = tempfile.mkdtemp(prefix="check16kb-")
    try:
        with zipfile.ZipFile(artifact, "r") as z:
            z.extractall(tmp)

        failures = []
        check_all = os.environ.get("CHECK_ALL_ABIS") == "1"
        for so_path in sorted(_iter_so_paths(tmp)):
            rel = os.path.relpath(so_path, tmp).replace("\\", "/")
            abi = _abi_from_path(rel)
            if not check_all and abi not in DEFAULT_ABIS:
                continue
            for align_val in _bad_alignments(so_path):
                failures.append(f"[bad align=0x{align_val:x}] abi={abi or 'unknown'} file={rel}")

        if failures:
            print("16KB page-size check failed:", file=sys.stderr)
            for f in failures:
                print(f, file=sys.stderr)
            return 1

        print("16KB page-size check OK")
        return 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

