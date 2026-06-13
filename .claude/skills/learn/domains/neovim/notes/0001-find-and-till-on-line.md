# 0001 — Find & till on line (f/t/F/T, ;/,)

date: 2026-06-13
area: core
topic: Find and till on line
sources: `:help f`, `:help t`, `:help left-right-motions`, `:help inclusive`, `:help cpo-;`

Single-line, character-targeting motions. In my config they are **vanilla Neovim** —
no flash/leap/clever-f/sneak, and treesitter-textobjects `move` does NOT rebind `;`/`,`.

## The four motions — where they land

| Motion | Direction | Lands… | With operator |
|--------|-----------|--------|---------------|
| `f{c}` | forward  | **on** next `{c}`        | inclusive (eats the `{c}`) |
| `t{c}` | forward  | **just before** next `{c}` | inclusive (stops one short of `{c}`) |
| `F{c}` | backward | **on** prev `{c}`        | exclusive → deletes back **through/including** target |
| `T{c}` | backward | **just after** prev `{c}` | exclusive → **keeps** the target |

Mnemonic: `f`/`F` land **on**, `t`/`T` (till) land **adjacent**. With an operator,
`f`/`t` are *inclusive*; `F`/`T` are *exclusive*. f→includes target, t→stops short;
F→deletes through target, T→spares it.

```
foo(bar, baz)        obj->method()
█                    █
f)  → foo(bar, baz█  (on ')')      dt-  → ->method()   (t- stops before '-', incl landing → "obj" gone)
t)  → foo(bar, ba█z  (one before)  df-  → >method()    (f- on '-', inclusive → "obj-" gone)
```

## Operator composition (the payoff)
- `dt{c}` / `ct{c}` — up to **but not including** `{c}` (workhorse: `ct.`, `dt;`, `dt)`).
- `df{c}` / `cf{c}` — up to **and including** `{c}`.
- Backward: `dF{c}` deletes back through+including target; `dT{c}` keeps the target.

```
std::string name = getName();   cursor on 'g' of getName
ct(  → std::string name = █();   change call name, keep parens
```

## Count goes BEFORE the motion  ⭐ (resolves weak area, record 0001)
Form: `[count]{op}[count]f{c}` — count attaches to the motion char, before it.
```
a.b.c.d.e
█
2f.  → a.b█.c.d.e     jump to 2nd '.'
d2f. → c.d.e          delete THROUGH 2nd '.'
d2t. → .c.d.e         delete UP TO before 2nd '.'
```
Trap: **`dt2` ≠ "till 2nd"** — it searches the literal char `2`. Counted till = `d2t<c>`.
Counts multiply: `2dt.` == `d2t.`. (For ">2nd", `;` is usually cleaner than a computed count.)

## Repeat with ; and ,
After any `f`/`t`/`F`/`T`: `;` repeats in the **issued direction**, `,` reverses it.
So after `f.` → `;` forward, `,` backward; after `F.` → `;` backward, `,` forward (mirror).
```
book.getLevel(0).getPrice().raw()
█  f. → 1st '.'  ;→ 2nd  ;→ 3rd  ,→ back to 2nd
```
`t`-repeat gotcha: Neovim's default `cpoptions` omits the `;` flag, so `;` after `t{c}`
correctly skips to the **next** occurrence. (`set cpo+=;` makes it stop — `:help cpo-;`.)
My config doesn't touch `cpoptions` → helpful behavior.

## When to reach for it
- Punctuation-dense code surgery: `ct.` (rename one segment of `a.b.c`), `df,` (drop one
  arg+comma), `cT(` backward.
- Horizontal counts are hard to eyeball → prefer `f`+`;` over `3f.`. (Vertical counts are
  easy — `relativenumber` is on; that's the *Count composition* topic, not this one.)
- f/t never cross a newline — current line only. Cross-line → `/` search or treesitter moves.

## Takeaway
`f`/`t` forward, `F`/`T` backward; `f`/`F` include the target, `t`/`T` stop one short;
counts ride *before* the motion char (`d2t.`); `;`/`,` repeat/reverse in the issued direction.
