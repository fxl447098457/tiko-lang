import io
p = 'src/codegen/llvmemit.tiko'
s = io.open(p, encoding='utf-8', newline='').read()

def find1(needle):
    i = s.find(needle)
    assert i > 0, 'not found: ' + needle[:60]
    return i

# 1. delete the orphaned BYVAL intro comment (up to the blank line before ParamList)
m_start = find1("'' BYVAL, for a SysV MEMORY-class aggregate.")
m_end = s.find("private function ParamList _", m_start)
assert m_end > 0
s = s[:m_start] + s[m_end:]

# 2. extract the SretAttr block (comment + function) and delete its forward declare
sa_start = find1("''     declare dso_local void @r12(ptr dead_on_unwind writable sret(%struct.S12) align 4)")
sa_end = s.find("\nprivate function ParamList _", sa_start)
assert sa_end > 0
sret_block = s[sa_start:sa_end] + "\n"
s = s[:sa_start] + s[sa_end+1:]

fwd_old = "'' Forward for the same reason: a CALL carries the sret attribute too, and call\n'' emission comes before the signature emission that defines it.\ndeclare function SretAttr _\n    ( byref e as EmitCtx, byval f as MirFunction ptr ) as string\n"
assert fwd_old in s, 'fwd not found'
s = s.replace(fwd_old, "'' Forward for the same reason: a CALL carries the sret attribute too, and call\n'' emission comes before the signature emission that defines it. SretAttr stands with\n'' ByvalAttr and CallConvAttr ahead of EmitInst; the rest emit after their use.\n", 1)

# 3. insert SretAttr before the CallConvAttr block
anchor = "'' THE CALLING CONVENTION IN THE IR:"
idx = s.find(anchor)
assert idx > 0
s = s[:idx] + sret_block + s[idx:]

# 4. squeeze the two comment blocks
s = s.replace(
"'' THE CALLING CONVENTION IN THE IR: 'x86_stdcallcc' on a win32 stdcall, nothing else --\n"
"'' x86-64 collapsed stdcall into cdecl, so none was ever spelled here, and i386 keeps\n"
"'' them apart over the decorated name the mangler writes (measured, clang 21.1.3).\n"
"'' Like byval and sret it must read the same at declare/define and every call.\n",
"'' THE CALLING CONVENTION IN THE IR: 'x86_stdcallcc' on a win32 stdcall, nothing else --\n"
"'' x86-64 collapsed the two, so none was ever spelled here; i386 keeps them apart over\n"
"'' the decorated name the mangler writes (measured, clang 21.1.3). Like byval and sret\n"
"'' it must read the same at declare/define and every call.\n", 1)
s = s.replace(
"'' Byval: identical on the signature and at the call site, like sret. The alignment is\n"
"'' the class's when it says ALIGN16, else the natural one -- EXCEPT i386, which hands\n"
"'' every stack argument a 4-aligned slot: clang writes 'byval(%struct.B24) align 4' even\n"
"'' for an 8-aligned struct (measured, clang 21.1.3, {long long x 3}).\n",
"'' Byval: identical on the signature and at the call site, like sret. The alignment is\n"
"'' the class's when it says ALIGN16, else the natural one -- EXCEPT i386, which hands\n"
"'' every stack argument a 4-aligned slot (measured, clang 21.1.3, {long long x 3}).\n", 1)

io.open(p, 'w', encoding='utf-8', newline='').write(s)
print('done')
