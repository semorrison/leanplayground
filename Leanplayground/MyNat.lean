import Mathlib.Algebra.Group.Defs
import Mathlib.Data.Nat.Basic
import Mathlib.Tactic

namespace MyNat

inductive Leq : (m n : ℕ) → Prop
| LeqSelf : Leq m m
| LeqSucc (m_leq_n : Leq m n) : Leq m (n + 1)

infix:50 "leq" => Leq

lemma zero_leq : ∀ {m}, 0 leq m
| 0 => Leq.LeqSelf
| m + 1 =>
  haveI : 0 leq m := zero_leq
  show 0 leq m.succ from Leq.LeqSucc this

macro m:term "leq'" n:term : term => `(∃ d : ℕ, $m + d = $n)

private lemma eq_zero_or_succ : ∀ {n}, n = 0 ∨ ∃ m, n = m + 1
| 0 => show _ from Or.inl rfl
| n + 1 =>
  suffices ∃ m, n + 1 = m + 1 from Or.inr this

  haveI : n = 0 ∨ ∃ m, n = m + 1 := eq_zero_or_succ
  match this with
  | Or.inl (h : n = 0) =>
    haveI : n + 1 = 0 + 1 := by rw [h]
    show ∃ m, n + 1 = m + 1 from ⟨0, this⟩

  | Or.inr (⟨m, h⟩ : ∃ _m, n = _m + 1) =>
    haveI : n + 1 = (m + 1) + 1 := by rw [h]
    show ∃ m', n + 1 = m' + 1 from ⟨m + 1, this⟩

private lemma leq'_of_leq : ∀ {n}, m leq n → m leq' n
| _, (Leq.LeqSelf : m leq m) =>
  show ∃ d, m + d = m from ⟨0, rfl⟩
| .(_ + 1), (Leq.LeqSucc m_leq_n) =>
  haveI : m leq' _ := leq'_of_leq m_leq_n
  let ⟨d, h⟩ := this
  haveI : m + (d + 1) = _ + 1 := by rw [←add_assoc, h]
  show ∃ d, m + d = _ + 1 from ⟨d + 1, this⟩

private lemma leq_of_leq' : ∀ {n}, (∃ d, m + d = n) → m leq n
| n, ⟨0, h⟩ =>
  haveI : m = n := by simp at h; exact h
  show m leq n by rw [this]; exact Leq.LeqSelf

| n + 1, ⟨d + 1, h⟩ =>
  haveI : (m + d) + 1 = n + 1 := by rw [add_assoc, h]
  haveI : ∃ d, m + d = n := ⟨d, by simp at this; exact this⟩
  haveI : m leq n := leq_of_leq' this
  show m leq n + 1 from Leq.LeqSucc this

@[simp]
theorem leq_iff_leq' : (m leq n) ↔ m leq' n :=
  ⟨leq'_of_leq, leq_of_leq'⟩

private lemma Leq.reflexive : x leq x := Leq.LeqSelf

private lemma Leq.transitive : (x leq y) → (y leq z) → x leq z
| h1, h2 =>
  have ⟨d1, h1⟩ : ∃ d1, x + d1 = y := by simp [leq_iff_leq'] at h1; exact h1
  have ⟨d2, h2⟩ : ∃ d2, y + d2 = z := by simp [leq_iff_leq'] at h2; exact h2
  haveI : ∃ d, x + d = z := ⟨d1 + d2, by ring_nf; rw [h1, h2]⟩
  show x leq z by simp [leq_iff_leq'] at *; exact this

private lemma Leq.antisymmetric : x leq y → y leq x → x = y
| x_leq_y, y_leq_x =>
  have ⟨d1, h1⟩ : ∃ d1, x + d1 = y :=
    by simp [leq_iff_leq'] at x_leq_y; exact x_leq_y
  have ⟨d2, h2⟩ : ∃ d2, y + d2 = x :=
    by simp [leq_iff_leq'] at y_leq_x; exact y_leq_x
  haveI : x + (d1 + d2) = x + 0 := by rw [←h1, add_assoc] at h2; exact h2
  haveI d1_plus_d2_eq_zero : d1 + d2 = 0 := Nat.add_left_cancel this
  haveI : d1 = 0 :=
    haveI : d1 = 0 ∨ ∃ d, d1 = d + 1 := eq_zero_or_succ
    match this with
    | Or.inl d1_eq_zero => d1_eq_zero
    | Or.inr ⟨d, d1_eq_d_succ⟩ =>
      suffices ⊥ from False.elim this
      haveI : d + d2 + 1 = 0 := by ring_nf; simp [d1_eq_d_succ] at d1_plus_d2_eq_zero
      show ⊥ from Nat.succ_ne_zero _ this
  show x = y by simp [this] at h1; exact h1

instance : Trans Leq Leq Leq where
  trans := Leq.transitive

end MyNat