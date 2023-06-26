import Aesop
import Lean.Data.Json
-- import Lean.Data.Parsec
-- import Lean.Parser.Term
import Mathlib.SetTheory.Cardinal.Cofinality
import Mathlib.Tactic.SlimCheck
-- import Mathlib.Testing.SlimCheck.Testable
import Smt
import Std.Data.HashMap.Basic
import Std.Lean.PersistentHashMap

-- import Std.Lean.Parser

-- import Std.Data.Array.Basic
namespace Statics

macro "derive" "stuff" "for" id:ident : command
=> `(
  deriving instance
    BEq, Hashable, Repr,
    Lean.FromJson, Lean.ToJson
  for $id
)

/-
  Set this to have a lower priority than the default so that it's automatically
  defeated by other instances, if there are any.
-/
@[default_instance low]
instance [Repr α] : ToString α where
  toString := toString ∘ repr

declare_syntax_cat fieldDecl
syntax ident "IS" "A" term : fieldDecl

syntax
  "DECLARE" ident ("IS" "A" ident)?
  ("HAS" sepBy1(fieldDecl, "HAS"))?
  : command

macro_rules
| `(DECLARE $className)
=> `(
  structure $className
  derive stuff for $className
)
| `(DECLARE $className IS A $superClassName) => `(
  structure $className extends $superClassName
  derive stuff for $className
)

| `(DECLARE $className HAS $[$fieldName:ident IS A $fieldType:term] HAS*)
=> `(
    structure $className where
      $[{ $fieldName : $fieldType }]*
    derive stuff for $className
)

  | `(DECLARE $className IS A $superClassName HAS $[$fieldName:ident IS A $fieldType:term] HAS*)
  => `(
      structure $className extends $superClassName where
        $[{ $fieldName : $fieldType }]*
      derive stuff for $className
  )

  -- | `(
  --     DECLARE $className IS A $superClassName
  --     HAS $fieldName:ident IS A $fieldType
  --   )
  -- => `(
  --   structure $className extends $superClassName where
  --     { $fieldName : $fieldType }
  --   derive stuff for $className
  -- )

declare_syntax_cat fieldDef
syntax term "IS" "THE" ident : fieldDef

-- syntax term "IS" "THE" Lean.Parser.Term.structInstLVal : fieldDef

-- set_option trace.Elab.command true in
syntax
  "DEFINE" ident "IS" "A" ident
  ("HAS" sepBy1(fieldDef, "HAS"))?
  : command

macro_rules
  | `(DEFINE $id IS A $className)
  => `(
    def $id : $className where
  )
  | `(DEFINE $id IS A $className HAS $[$fieldVal:term IS THE $fieldName:ident] HAS*)
  => `(
    def $id : $className where
      $[$fieldName := $fieldVal]*
  )

-- open Lean.Parser.Command

-- declare_syntax_cat enums
-- syntax ident : enums
-- syntax ident "PLUS" enums : enums

syntax "DECLARE" ident "IS" sepBy1(ident, "PLUS") : command

notation t0 "AND" t1 => t0 ∧ t1
notation t0 "OR" t1 => t0 ∨ t1

macro_rules
  | `(DECLARE $name:ident IS $[$ids:ident] PLUS*)
  => `(
    inductive $name where
      $[| $ids:ident]*
    derive stuff for $name

    deriving instance Ord for $name
  )

syntax term "OF" sepBy1(term, "AND") : term
macro_rules
  | `($fn OF $[$arg:term] AND*) =>
    `($fn $arg*)

-- instance : ToStream (Lean.PArray T) (List T) where
--   toStream xs := xs.toList

-- instance [BEq T] : BEq (Lean.PArray T) where
--   beq xs ys := Id.run <| do
--     for x in xs, y in ys do
--       if x != y then return false
--     return true
section
variable [BEq α] [Hashable α]

instance [BEq β] : BEq (Lean.PHashMap α β) where
  beq m0 m1 := m0.toArray == m1.toArray

instance [BEq β] : BEq (Std.HashMap α β) where
  beq m0 m1 := m0.toArray == m1.toArray

-- instance [DecidableEq α] [DecidableEq β] : DecidableEq (Lean.PHashMap α β) :=
--   λ m0 m1 => decEq m0.toArray m1.toArray 

instance [Hashable β] : Hashable (Lean.PHashMap α β) where
  hash := hash ∘ Lean.PersistentHashMap.toArray

instance [Hashable β] : Hashable (Std.HashMap α β) where
  hash := hash ∘ Std.HashMap.toArray

instance [Repr α] [Repr β] : Repr (Lean.PHashMap α β) where
  reprPrec := reprPrec ∘ Lean.PersistentHashMap.toArray

instance [Repr α] [Repr β] : Repr (Std.HashMap α β) where
  reprPrec := reprPrec ∘ Std.HashMap.toArray
end

-- instance [Ord (List (α × β))] : Ord (Lean.PHashMap α β) where
--   compare m0 m1 := compare m0.toList m1.toList

-- def List.toPHashMap (xs : List (α × β)) : Lean.PHashMap α β :=
--   xs.foldl (init := Lean.PersistentHashMap.empty) <|
--     λ hashMap (k, v) => hashMap.insert k v

notation "MAP" "FROM" key "TO" val => Array (key × val)
-- Lean.PHashMap key val
notation x "EQUALS" y => x == y

syntax Lean.binderIdent "FROM" term "TO" term : term

syntax "FOR EVERY" many1(ident <|> bracketedBinder) "," term : term
macro_rules
  | `(FOR EVERY $binders:ident, $prop) =>
    `(∀ $binders, $prop)
  | `(FOR EVERY $binders:bracketedBinder, $prop) =>
    `(∀ $binders, $prop)

syntax "THERE" "IS" "SOME" term "SUCH" "THAT" term : term
syntax "THERE" "IS" "SOME" Lean.explicitBinders "SUCH" "THAT" term : term
macro_rules
  | `(THERE IS SOME $f:binderIdent FROM $α TO $β SUCH THAT $prop) =>
    `(∃ ($f : $α → $β), $prop)
  | `(THERE IS SOME $var:explicitBinders SUCH THAT $prop) =>
    `(∃ $var, $prop)

syntax "RELATION" "BETWEEN" sepBy1(term, "AND") : term
macro_rules
  | `(RELATION BETWEEN $t0 AND $t1) => `($t0 → $t1 → Prop)

notation relation "RELATES" t0 "TO" t1 => relation t0 t1

-- Horn claues.
syntax
  "§" ident
  ("GIVEN" sepBy1(ident "IS" "A" term, ","))?
  "DECIDE" term "IF" term
  : command

macro_rules
  | `(
    § $ruleName
    DECIDE $concl:ident IF $hypo
  ) => `(
    def $ruleName : Prop := $hypo → $concl
  )
  | `(
    § $ruleName
    GIVEN $[$var0:ident IS A $type0],*
    DECIDE $concl:ident OF $[$var:ident] AND* IF $hypo
  ) => `(
    -- Extract signature of the uninterpreted predicate.
    axiom $concl $[($var0 : $type0)]* : Prop

    -- Rule definition.
    def $ruleName : Prop :=
      ∀ $[($var0 : $type0)]*, $hypo → ($concl OF $[$var] AND*)
  )
  | `(
    § $ruleName
    GIVEN $[$var IS A $type],*
    DECIDE $concl:term IF $hypo
  ) => `(
    def $ruleName : Prop := ∀ $[($var : $type)]*, $hypo → $concl
  )

macro "THE" fieldName:ident "OF" record:term : term => `($record.$fieldName)

macro recordName:ident fieldName:ident : term =>
  match recordName |> toString |>.drop 1 |>.splitOn "'s" with
  | [recordName, ""] =>
    -- In this case, recordName is an identifier ending with 's, eg: person's
    let recordNameIdent := Lean.mkIdent recordName
    `($recordNameIdent.$fieldName)
  | _ => `($recordName $fieldName)

macro "#APPLY TACTIC" ruleName:ident tactic:tactic : command =>
  `(example : $ruleName := by unfold $ruleName; $tactic)

macro "#TEST" ruleName:ident : command =>
  `(#APPLY TACTIC $ruleName slim_check)

macro "#SMT" ruleName:ident : command =>
  `(#APPLY TACTIC $ruleName smt)

macro "#PROOF SEARCH" ruleName:ident : command =>
  `(#APPLY TACTIC $ruleName aesop)

set_option smt.solver.kind "z3"

-- set_option trace.Elab.command true
-- set_option trace.Elab.step true

DECLARE Agreement

DECLARE Role IS Borrower PLUS Lender

DECLARE Party
HAS role IS A Role
HAS bankBalance IS A Int

DECLARE Loan IS A Agreement
HAS Parties IS A MAP FROM Role TO Party
HAS PrincipalAmt IS A Nat

DEFINE B IS A Party
HAS Role.Borrower IS THE role
HAS 100 IS THE bankBalance

DEFINE L IS A Party
HAS Role.Lender IS THE role
HAS 0 IS THE bankBalance

DEFINE SimpleLoan IS A Loan
HAS #[(Role.Borrower, B), (Role.Lender, L)] IS THE Parties
HAS 1000 IS THE PrincipalAmt

-- #eval Lean.toJson SimpleLoan

-- TODO: Fix this.
-- § testRule
-- GIVEN p1 IS A Party, n IS A Int, p2 IS A Party
-- DECIDE canTransfer OF p1 AND n AND p2 IF p1's bankBalance > 0

-- DECIDE isLender IF (Party.role OF p) EQUALS Role.Lender

§ goodRule
GIVEN n IS A Int
DECIDE n < 0 IF THERE IS SOME m SUCH THAT (0 < m) AND m + n = 0

-- #SMT goodRule

§ badRule1
GIVEN m IS A Int, n IS A Int
DECIDE m < n IF True

-- #print badRule1

-- #SMT badRule1

§ badRule2
GIVEN xs IS A List OF Int
DECIDE xs's sum EQUALS 0 IF 0 EQUALS
  Id.run do
    let mut result := 1
    for x in xs do
      result := x * result
    return result

-- #print badRule2

-- #TEST badRule2

section
variable {α β : Type}

§ skolemize
GIVEN R IS A RELATION BETWEEN α AND β
DECIDE THERE IS SOME f FROM _ TO _ SUCH THAT FOR EVERY a, R RELATES a TO f a
IF FOR EVERY a, THERE IS SOME b SUCH THAT R RELATES a TO b

-- #print skolemize
end

open Cardinal

universe u

§ InaccessibleCardinal'
GIVEN κ IS A Cardinal.{u}
DECIDE IsInaccessible' OF κ
IF (κ > ℵ₀) AND (Cardinal.IsRegular κ) AND IsStrongLimit κ

-- set_option trace.aesop.ruleSet true in
-- example : ¬ (p ∨ q) ↔ ¬ p ∧ ¬ q := by aesop

end Statics