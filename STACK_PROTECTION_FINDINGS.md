# `Builtin.addressOfBorrow` vs `Builtin.unprotectedAddressOfBorrow` in `IPv{4,6}Address.bytes`

Scratch findings doc. Untracked. Written 2026-09-09 against toolchain
`Apple Swift version 6.4 (swiftlang-6.4.0.33.1)`, `arm64-apple-macos`, swift repo checkout
at `/Users/mahdibm/Github/swift` (branch `mmbm-fix-openbsd-clock`, base `040001b9f5f`).

Everything below was measured, not inferred, unless a line says otherwise.

---

## 0. The question

`Sources/IPAddress/IPv4Address/IPv4Address.swift` and
`Sources/IPAddress/IPv6Address/IPv6Address.swift` both do:

```swift
import func Builtin.addressOfBorrow

@_addressableForDependencies
public struct IPv4Address { ... }

@inlinable
public var bytes: Span<UInt8> {
    @_lifetime(borrow self)
    get {
        let pointer = UnsafeRawPointer(Builtin.addressOfBorrow(self))
        let span = unsafe Span<UInt8>(_unsafeStart: pointer, byteCount: Self.size)
        return unsafe _overrideLifetime(span, borrowing: self)
    }
}
```

Should this be `Builtin.unprotectedAddressOfBorrow` instead?

---

## 1. What the two builtins actually differ in

Nothing except one flag on one SIL instruction. From
`include/swift/AST/Builtins.def:335-357`:

```
/// addressOfBorrow (__shared T) -> Builtin.RawPointer
BUILTIN_SIL_OPERATION(AddressOfBorrow, "addressOfBorrow", Special)

/// unprotectedAddressOfBorrow (__shared T) -> Builtin.RawPointer
/// In contrast to `addressOfBorrow`, this builtin doesn't trigger an insertion of
/// stack protectors.
BUILTIN_SIL_OPERATION(UnprotectedAddressOfBorrow, "unprotectedAddressOfBorrow", Special)
```

Both lower via the same `emitBuiltinAddressOfBorrowBuiltins` in
`lib/SILGen/SILGenBuiltin.cpp:491-560`, differing only in a
`bool stackProtected` that becomes the `[stack_protection]` flag on
`address_to_pointer`.

There are also `*Opaque` variants (`addressOfBorrowOpaque`,
`unprotectedAddressOfBorrowOpaque`, `Builtins.def:1021-1037`) used only when opaque
values are enabled. Irrelevant here.

Stack protection is **on by default**: `include/swift/AST/SILOptions.h:139`
`bool EnableStackProtection = true;`, overridable with
`-enable-stack-protector` / `-disable-stack-protector`
(`lib/Frontend/CompilerInvocation.cpp:3415`).

`BuiltinUnprotectedAddressOf` is a **baseline** language feature
(`include/swift/Basic/Features.def:214`) — per commit `969efc84136`,
"present in the compiler since at least Swift 5.8". At tools-version 6.3 this package
needs **no `#if $BuiltinUnprotectedAddressOf` guard**.

---

## 2. Commit history (5-year pickaxe)

Commands used, in `/Users/mahdibm/Github/swift`:

```bash
git log --since=2021-09-09 --format='%h|%ad|%an|%s' --date=short \
  -G "unprotectedAddressOf|UnprotectedAddressOf" \
  -- stdlib/ lib/ include/ SwiftCompilerSources/ docs/ test/
git log --since=2021-09-09 --format='%h|%ad|%an|%s' --date=short \
  -G "Builtin\.addressOfBorrow|Builtin\.addressof\(" -- stdlib/
git log --merges --ancestry-path --format='%h %s' <sha>..origin/main | tail -1   # -> PR number
```

### 2a. The policy-setting cluster — PR #60933, Erik Eckstein, merged 2022-09-08

| commit | content |
|---|---|
| `97b2354be62` | Adds `needsStackProtection` to `address_to_pointer` / `index_addr`, plus both `unprotected*` builtins. |
| `ba135dc4937` | Adds `_withUnprotectedUnsafeMutablePointer`, `_withUnprotectedUnsafePointer`, `_withUnprotectedUnsafeBytes` x2. |
| `0f8dd3a5517` | The rationale. Commit message: *"We trust the internal implementation of the stdlib to not cause any unintentional buffer overflows. In such cases we can use the 'unprotected' address-to-pointer conversions. This avoids inserting stack protections where it's not needed."* |
| `5eff9066cc1` | Replaces raw `Builtin.unprotectedAddressOf` with the scoped `_withUnprotected*` helpers. Direct response to karwa's review: *"Can this use the scoped `_withUnprotectedUnsafePointer` function rather than using the Builtin to get an unscoped pointer?"* → eeckstein: *"yeah, that's a good idea"*. |
| `d8aa7a3c307` | Adds the `$BuiltinUnprotectedAddressOf` language feature. |
| `9c1e7cac0f7` | PR #61009, fixes a missing `#if` guard (rdar://99713099). |

Also in that PR's discussion: aschwaighofer asked for
`StackProtectStrong` → `StackProtectReq` in IRGen; lorentey approved the stdlib
parts and asked whether `withUnsafeTemporaryAllocation` also triggers it (it now does,
via `builtin "stackAlloc"`).

### 2b. The commit that decides it for span getters — PR #80858, Alejandro Alonso, 2025

`8058bd26f64` "Remove underscored with buffer pointer APIs on InlineArray"
(fixup `6953a7c6f9f` fixes `Builtin.addressOf` → `Builtin.addressof`).

PR body: *"Also, add protected address and buffer variants for the span APIs and the
unchecked subscript access **so that we get stack checking enabled for those APIs**."*
Resolves rdar://145487409. Approved by glessard.

Before this PR, `InlineArray.span` / `.mutableSpan` used the **unprotected** builtin.
The PR switched them to protected and introduced the split that still exists today
in `stdlib/public/core/InlineArray.swift:119-235`:

```swift
internal var _address: UnsafePointer<Element> {          // unprotected
    unsafe UnsafePointer<Element>(Builtin.unprotectedAddressOfBorrow(_storage))
}

/// Returns a pointer to the first element in the array while performing stack
/// checking.
///
/// Use this when the value of the pointer could potentially be directly used
/// by users (e.g. through the use of span or the unchecked subscript).
internal var _protectedAddress: UnsafePointer<Element> { // protected
    unsafe UnsafePointer<Element>(Builtin.addressOfBorrow(_storage))
}
```

Use sites in that file: `span` (line 603) and `mutableSpan` (line 624) and
`subscript(unchecked:)` (lines 535, 541) use the **protected** form; internal
operations such as `swapAt` (lines 575-578) use the unprotected form.

### 2c. Everything else the pickaxe found, classified

Substantive:
- `782b777658a` (2023-05-04, Eckstein) — clang importer, imported C union setters switched to `unprotectedAddressOf`. rdar://108867547.
- `a4c20e043be` (PR #76446, Stephen Canon) — adds a `borrowing` overload of `_withUnprotectedUnsafePointer`. rdar://135889076. No design discussion in the PR.
- `520dfc26cd9` + `ae7c69b1af0` (Nate Chandler) — opaque-value variants, lowered in AddressLowering.
- `f7471620849` / `2a60c88457d` / `f867d0bb05a` — Atomic / Mutex / Vector used `unprotectedAddressOfBorrow`, later migrated to `Builtin.addressOfRawLayout` (`e99268864c2`, `19b8bed8842`).
- `ab51f1630c2` (lorentey) — noncopyable primitives, `swap(_:_:)` rewrite.
- `207ae32107b` (glessard) — `_withUnprotectedUnsafeMutableBytes()`, adds cases to `test/SILOptimizer/stack_protection.swift`.
- `a25edb2185f` (Joe Groff) — `addressForBorrow` with addressable parameters.
- `6363ad36550`, `921f59e32ce`, `c8d495f1cf3` — later InlineArray accessor churn, preserves the protected/unprotected split.
- `b78d91d6ed3` (PR #90002) — span getters switched from `Span(_unsafeStart:)` to `Span(_unchecked:)`. **Orthogonal to protection, but directly relevant to this package** — see §7.

Feature-flag plumbing only: `0dbc63a00b5`, `596b015994b`, `ec8dcc98ad5`, `b69d5fe40c0`, `dd006e073aa`.
Mechanical: `5cb2409ba6a`, `239807faa1c`, `22eecacc357`, `969efc84136`, `65e8ce54250`, `d51c58a6f9a`.

### 2d. Current stdlib state — who uses which

Protected (`Builtin.addressOfBorrow` / `Builtin.addressof`):
`CollectionOfOne.span` + `.mutableSpan`, `InlineArray.span` + `.mutableSpan` + `subscript(unchecked:)`,
`UTF8Span` (lines 244, 345), `String.UTF8View` storage (`StringUTF8View.swift:336`),
`Substring` (line 803), `withUnsafeBytes(of:)` (both forms), `withUnsafe{,Mutable}Pointer`.

Unprotected: `_withUnprotected*` family, `InlineArray._address`/`_mutableAddress`,
`StringSwitch.swift:73`, `MutableRef.swift:29`, and **`Optional._span()`**
(`Optional.swift:425`) — the one span getter that uses the unprotected builtin. It is
still underscored. Introduced by `856b2051705` (Nate Cook), reshaped by `51cc0a2a009`
(glessard).

**Conclusion of §2:** the stdlib convention for a public `Span` getter over inline
storage is the **protected** builtin, and they moved *toward* it deliberately in 2025.

---

## 3. Measured cost in this package

Method: two SwiftPM consumer packages, one depending on the live checkout
(protected, as-is), one on a `git worktree` copy with both files `sed`-flipped to
`unprotectedAddressOfBorrow`. `swift build -c release`, then
`objdump --disassemble-symbols`. Instruction counts are of the whole function body.

```swift
@inline(never) func sumV4(_ v: UInt32) -> UInt8 {
    let a = IPv4Address(v); let b = a.bytes
    return b[0] &+ b[1] &+ b[2] &+ b[3]
}
@inline(never) func sumV6(_ v: UInt128) -> UInt8 {
    let a = IPv6Address(UnsignedInteger128(v)); let b = a.bytes
    var s: UInt8 = 0; for i in b.indices { s = s &+ b[i] }; return s
}
```

| caller | protected | unprotected | delta |
|---|---|---|---|
| `sumV4` | 21 instructions | 5 | −16 |
| `sumV6` | 48 instructions | 32 | −16 |

The 16 are: `sub sp` / `stp x29,x30` / `add x29` frame setup, two `adrp`+`ldr`+`ldr`
GOT loads of `___stack_chk_guard`, `str`+`ldr` of the canary to/from the frame,
`cmp`+`b.ne`, `ldp`+`add sp` teardown, and a `bl ___stack_chk_fail` edge.
`sumV4` goes from a framed function to a 5-instruction leaf.

Per the user's standing rule: instruction count is a coarse screen and is **not**
evidence of speed. What is defensible here is the *nature* of the delta — two GOT
memory loads and a stack frame, and leaf-vs-non-leaf. **No wall-clock benchmark was
run.** If a decision needs timing, run it on `het-gha` per `AGENTS.md`.

Correctness of the unprotected variant was checked: full `swift test` (151 tests, 11
suites) passes on the flipped worktree, plus a 200k-iteration randomized check of
`IPv4Address.bytes` against `withUnsafeBytes(of:)`.

---

## 4. When the canary can actually fire

Demo package: `/tmp/spchk/demo` (protected lib, points at the live checkout).
A C target `COverflow` provides `void badCFunction(unsigned char *p, size_t n)`,
`__attribute__((noinline))`, which writes `n` bytes.

Run with:
```bash
cd /tmp/spchk/demo && swift build -c release
lldb -b -o "b __stack_chk_fail" -o "run <CASE> 64" -o "quit" ./.build/release/App
```

**Judge by the `__stack_chk_fail` breakpoint, not by exit code** — both outcomes abort.

| case | body | protected lib | unprotected lib |
|---|---|---|---|
| A | `withUnsafeMutablePointer(to:&x)` → C overflow, no `bytes` | canary | canary |
| B | `_withUnprotectedUnsafeMutablePointer` → C overflow, no `bytes` | silent smash | silent smash |
| C | `bytes` → `withUnsafeBufferPointer` → cast const away → C overflow | **canary** | silent smash |
| D | `bytes` → reinterpret Span layout → C overflow | **canary** | silent smash |
| E | `bytes` read correctly + **unrelated** overflow via `_withUnprotected*` | **canary** | silent smash |
| F | **E minus the two `bytes` lines** | silent smash | silent smash |
| G | as E but `bytes` on a **global** `let` | silent smash | silent smash |
| H | as E but `bytes` on a **class stored property** | canary | (not run) |

"silent smash" = `EXC_BAD_ACCESS (code=257, address=0x24232221201f1e1d)` — the saved link
register overwritten with the C function's fill bytes 29-36, CPU jumps to it.

**E vs F is the load-bearing result.** They are identical except E contains
`let b = a.bytes; let sum = b[0] &+ b[1] &+ b[2] &+ b[3]`. A correct, read-only,
bounds-checked use of `bytes` is what installs the canary; the canary then catches an
overflow that has nothing to do with `IPv4Address`.

**G vs E**: a canary only guards stack memory, so `bytes` on a global installs nothing.
**H**: reading the address out of a class copies it into a local first, so it does.

Threshold: case C fires at `n >= 8`, not at `n = 4`. The canary does **not** protect
the address's own bytes — corrupting all 4 of them is invisible. It protects one 8-byte
slot between the frame's locals and the saved FP/LR, frame-wide, from any source.

Only writes can trip it. An out-of-bounds *read* leaves it untouched.

`Span<UInt8>` cannot supply the write on its own: no mutating API, every subscript
bounds-checked. Reaching C or D requires `UnsafeMutableRawPointer(mutating:)` on a
pointer obtained from an immutable borrow — already UB before the canary matters.
`unsafeBitCast` is refused outright (`requires that 'Span<UInt8>' conform to 'Escapable'`);
D has to go via `withUnsafeBytes(of: &b)` on the span *value*.

---

## 5. The read-only bailout, and why it almost never helps

`StackProtection.swift:476-513` runs a `NoStores` walk from each
`address_to_pointer [stack_protection]`; if it proves no stores, the flag is dropped.
The stdlib's own `test/SILOptimizer/stack_protection.swift` asserts this via `onlyLoads`.

Measured, same build:

| caller body | instructions | canary |
|---|---|---|
| `a.bytes[0]` | 2 | **no** |
| `a.bytes[1]` | 18 | yes |
| `b[0] &+ b[1]` | 19 | yes |
| `b[0] &+ b[1] &+ b[2] &+ b[3]` | 21 | yes |
| `withUnsafeBytes(of: v) { $0[0]…$0[3] }` (stdlib's own API) | 20 | yes |

So the bailout only catches element 0. Everything real — a loop, a comparison,
`ContiguousArray(copying:)`, any index != 0 — keeps the canary.

Worse: it is decided on SIL, before LLVM optimizes. `b[0] &+ b[1] &+ b[2] &+ b[3]`
emits `rev w8, w0` + three `add` — **four register instructions, zero memory access** —
and still carries the canary. You pay to guard a pointer that no longer exists in the
final code.

---

## 6. Is that a compiler deficiency? (partly inference — flagged)

**Verified.** SIL for `a.bytes[1]`, from the SwiftPM `-O` build:

```
%26 = pointer_to_address %25 to $*UInt8
%27 = integer_literal $Builtin.Word, 1
%28 = index_addr %26, %27          // NOTE: no [stack_protection] flag
%29 = load %28                     // the only use
```

`SwiftCompilerSources/Sources/SIL/Utilities/WalkUtils.swift:532` walks through
`index_addr` only when `ia.isProjection`. Per `include/swift/SIL/SILInstruction.h:10410-10416`,
`isProjection` means "projects a single array element address from an array base, as
opposed to being used for general pointer arithmetic". `Span`'s subscript is raw-pointer
arithmetic, so the flag is off, the walker falls to `default:`, hits
`NoStores.leafUse(address:)`, sees a non-`LoadInst`, and returns `.abortWalk`.

(Note `unmatchedPath` defaults to `.continueWalk` — `WalkUtils.swift:485` — which in this
walker means "safe". So the abort is definitely coming from the `default:` →
`leafUse` path, not from a path mismatch.)

**Two reasons this looks like fixable conservatism rather than a real limit:**

1. `NoStores` answers one yes/no question — "is there any store downstream?" — and does
   not need projection-path precision. Walking through a non-projection `index_addr`
   and then checking *its* uses is sound for that question. `isProjection` exists to
   bound whether the result can reach *other* elements, which matters to precise-path
   walkers, not to this one.
2. SILGen did **not** put `[stack_protection]` on that `index_addr`. The pass's own
   second trigger already judged the instruction safe; the first trigger's walk then
   treats it as opaque. Those two judgements contradict on the same instruction.

**Inference, not verified.** There is probably a deeper cause. The
`mark_dependence [nonescaping] %14 on %2` keeps the `alloc_stack` alive, so SIL never
promotes `IPv4Address` to a register — even though LLVM later proves the loads
unnecessary and emits none. If the `alloc_stack` were promoted there would be no
`address_to_pointer` and no canary at all. Not confirmed by patching the compiler.

**If this is to be filed upstream:** it needs a minimal reproducer against a
mainline toolchain (not the 6.4 Xcode one), and per the user's rules the issue must be
drafted for them to file — do not file it, and do not run mutating `gh` commands.

---

## 7. Loose end worth a separate look

`b78d91d6ed3` (PR #90002, "Collection span getters can use the unchecked initializer",
resolves swiftlang/swift#89954) moved the stdlib's span getters from
`Span(_unsafeStart:count:)` to `Span(_unchecked:count:)`, eliding the alignment and count
checks, and made the alignment check conditional on `MemoryLayout<Element>.alignment > 1`.
This package still uses `Span<UInt8>(_unsafeStart:byteCount:)` in both `bytes` getters.
For `Element == UInt8` the alignment check is vacuous. Unmeasured here; plausible free win.

---

## 8. Reproduction recipes

Protected side (live checkout):
```bash
cd /tmp/spchk/demo && swift build -c release
for c in A B C D E F G H; do
  printf "%s: " $c
  lldb -b -o "b __stack_chk_fail" -o "run $c 64" -o "quit" ./.build/release/App 2>&1 \
    | grep -oE "breakpoint 1.1|EXC_BAD_ACCESS" | head -1
done
```

Unprotected side (recreate; the worktree was removed after use):
```bash
cd /Users/mahdibm/Github/swift-endpoint && git worktree add /tmp/spchk/wt2 HEAD --detach
rsync -a --delete Sources/ /tmp/spchk/wt2/Sources/
rsync -a Package.swift Package@swift-6.3.swift /tmp/spchk/wt2/
sed -i '' 's/Builtin\.addressOfBorrow/Builtin.unprotectedAddressOfBorrow/g' \
  /tmp/spchk/wt2/Sources/IPAddress/IPv4Address/IPv4Address.swift \
  /tmp/spchk/wt2/Sources/IPAddress/IPv6Address/IPv6Address.swift
cp -R /tmp/spchk/demo /tmp/spchk/demoB && rm -rf /tmp/spchk/demoB/.build
sed -i '' 's#path: "/Users/mahdibm/Github/swift-endpoint"#path: "/tmp/spchk/wt2"#; s/package: "swift-endpoint"/package: "wt2"/' \
  /tmp/spchk/demoB/Package.swift
cd /tmp/spchk/demoB && swift build -c release
# afterwards: git -C /Users/mahdibm/Github/swift-endpoint worktree remove --force /tmp/spchk/wt2
```

Detecting the canary in a disassembly — the GOT slot for `___stack_chk_guard` is labelled
with the nearest symbol by objdump, so grep the offset instead. Find it once from a
function known to have it, then:
```bash
objdump --disassemble-symbols='<mangled>' .build/release/App | grep -c '#0xae8'
```
(The `0xae8` is binary-specific. Re-derive it per build.)

Emitting SIL for a SwiftPM target — `swift build -Xswiftc -emit-sil` swallows the output.
Instead: `touch` a source, `swift build -c release -v`, grab the `swiftc` line, replace
`-c` with `-emit-sil`, and re-run it; SIL lands on **stderr**.

### Traps hit while doing this — do not repeat

- Hand-rolled `swiftc -I .build/release` against this package produces **wrong results**
  (`bytes` returned garbage; a `realV4` folded to a constant `255`). The `alloc_stack`
  had no `store`. Reproducing through a real SwiftPM consumer package gives correct
  results. Always use SwiftPM; do not trust ad-hoc `swiftc` here.
- `@inline(never)` does not guarantee a symbol survives — several probe functions were
  folded away entirely and vanished from `nm`.
- Mangled names carry a length prefix (`_$s3App6case_A…`, `_$s3App7case_R1…`); a grep
  without the digit silently matches nothing and looks like "no canary".

---

## 9. Open decision

Not decided as of writing. The three options put to the user were: keep
`addressOfBorrow` (match stdlib), switch to `unprotectedAddressOfBorrow`
(take the −16), or split it the way `InlineArray` does (`_address` vs
`_protectedAddress`) so internal call sites are cheap and the public getter stays
protected. The user has not chosen — **do not change the source without asking.**

Note the IDE selection at the time of writing showed `_unprotectedBytes` in
`IPv6Address.swift:367`, which suggests the split may already be in progress in the
working tree. Check the current state before acting.
