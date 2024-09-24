/-
Copyright (c) 2023 Kim Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/
import Mathlib.Algebra.Group.Submonoid.Operations
import Mathlib.Algebra.Star.SelfAdjoint
import Mathlib.Algebra.Star.StarRingHom
import Mathlib.Algebra.Regular.Basic
import Mathlib.Tactic.ContinuousFunctionalCalculus

/-! # Star ordered rings

We define the class `StarOrderedRing R`, which says that the order on `R` respects the
star operation, i.e. an element `r` is nonnegative iff it is in the `AddSubmonoid` generated by
elements of the form `star s * s`. In many cases, including all C⋆-algebras, this can be reduced to
`0 ≤ r ↔ ∃ s, r = star s * s`. However, this generality is slightly more convenient (e.g., it
allows us to register a `StarOrderedRing` instance for `ℚ`), and more closely resembles the
literature (see the seminal paper [*The positive cone in Banach algebras*][kelleyVaught1953])

In order to accommodate `NonUnitalSemiring R`, we actually don't characterize nonnegativity, but
rather the entire `≤` relation with `StarOrderedRing.le_iff`. However, notice that when `R` is a
`NonUnitalRing`, these are equivalent (see `StarOrderedRing.nonneg_iff` and
`StarOrderedRing.of_nonneg_iff`).

It is important to note that while a `StarOrderedRing` is an `OrderedAddCommMonoid` it is often
*not* an `OrderedSemiring`.

## TODO

* In a Banach star algebra without a well-defined square root, the natural ordering is given by the
positive cone which is the _closure_ of the sums of elements `star r * r`. A weaker version of
`StarOrderedRing` could be defined for this case (again, see
[*The positive cone in Banach algebras*][kelleyVaught1953]). Note that the current definition has
the advantage of not requiring a topology.
-/

open Set
open scoped NNRat

universe u

variable {R : Type u}

/-- An ordered `*`-ring is a `*`ring with a partial order such that the nonnegative elements
constitute precisely the `AddSubmonoid` generated by elements of the form `star s * s`.

If you are working with a `NonUnitalRing` and not a `NonUnitalSemiring`, it may be more
convenient to declare instances using `StarOrderedRing.of_nonneg_iff`.

Porting note: dropped an unneeded assumption
`add_le_add_left : ∀ {x y}, x ≤ y → ∀ z, z + x ≤ z + y` -/
class StarOrderedRing (R : Type u) [NonUnitalSemiring R] [PartialOrder R]
    [StarRing R] : Prop where
  /-- characterization of the order in terms of the `StarRing` structure. -/
  le_iff :
    ∀ x y : R, x ≤ y ↔ ∃ p, p ∈ AddSubmonoid.closure (Set.range fun s => star s * s) ∧ y = x + p

namespace StarOrderedRing

-- see note [lower instance priority]
instance (priority := 100) toOrderedAddCommMonoid [NonUnitalSemiring R] [PartialOrder R]
    [StarRing R] [StarOrderedRing R] : OrderedAddCommMonoid R where
  add_le_add_left := fun x y hle z ↦ by
    rw [StarOrderedRing.le_iff] at hle ⊢
    refine hle.imp fun s hs ↦ ?_
    rw [hs.2, add_assoc]
    exact ⟨hs.1, rfl⟩

-- see note [lower instance priority]
instance (priority := 100) toExistsAddOfLE [NonUnitalSemiring R] [PartialOrder R]
    [StarRing R] [StarOrderedRing R] : ExistsAddOfLE R where
  exists_add_of_le h :=
    match (le_iff _ _).mp h with
    | ⟨p, _, hp⟩ => ⟨p, hp⟩

-- see note [lower instance priority]
instance (priority := 100) toOrderedAddCommGroup [NonUnitalRing R] [PartialOrder R]
    [StarRing R] [StarOrderedRing R] : OrderedAddCommGroup R where
  add_le_add_left := @add_le_add_left _ _ _ _

/-- To construct a `StarOrderedRing` instance it suffices to show that `x ≤ y` if and only if
`y = x + star s * s` for some `s : R`.

This is provided for convenience because it holds in some common scenarios (e.g.,`ℝ≥0`, `C(X, ℝ≥0)`)
and obviates the hassle of `AddSubmonoid.closure_induction` when creating those instances.

If you are working with a `NonUnitalRing` and not a `NonUnitalSemiring`, see
`StarOrderedRing.of_nonneg_iff` for a more convenient version.
 -/
lemma of_le_iff [NonUnitalSemiring R] [PartialOrder R] [StarRing R]
    (h_le_iff : ∀ x y : R, x ≤ y ↔ ∃ s, y = x + star s * s) : StarOrderedRing R where
  le_iff x y := by
    refine ⟨fun h => ?_, ?_⟩
    · obtain ⟨p, hp⟩ := (h_le_iff x y).mp h
      exact ⟨star p * p, AddSubmonoid.subset_closure ⟨p, rfl⟩, hp⟩
    · rintro ⟨p, hp, hpxy⟩
      revert x y hpxy
      refine AddSubmonoid.closure_induction hp ?_ (fun x y h => add_zero x ▸ h.ge) ?_
      · rintro _ ⟨s, rfl⟩ x y rfl
        exact (h_le_iff _ _).mpr ⟨s, rfl⟩
      · rintro a b ha hb x y rfl
        rw [← add_assoc]
        exact (ha _ _ rfl).trans (hb _ _ rfl)

/-- When `R` is a non-unital ring, to construct a `StarOrderedRing` instance it suffices to
show that the nonnegative elements are precisely those elements in the `AddSubmonoid` generated
by `star s * s` for `s : R`. -/
lemma of_nonneg_iff [NonUnitalRing R] [PartialOrder R] [StarRing R]
    (h_add : ∀ {x y : R}, x ≤ y → ∀ z, z + x ≤ z + y)
    (h_nonneg_iff : ∀ x : R, 0 ≤ x ↔ x ∈ AddSubmonoid.closure (Set.range fun s : R => star s * s)) :
    StarOrderedRing R where
  le_iff x y := by
    haveI : CovariantClass R R (· + ·) (· ≤ ·) := ⟨fun _ _ _ h => h_add h _⟩
    simpa only [← sub_eq_iff_eq_add', sub_nonneg, exists_eq_right'] using h_nonneg_iff (y - x)

/-- When `R` is a non-unital ring, to construct a `StarOrderedRing` instance it suffices to
show that the nonnegative elements are precisely those elements of the form `star s * s`
for `s : R`.

This is provided for convenience because it holds in many common scenarios (e.g.,`ℝ`, `ℂ`, or
any C⋆-algebra), and obviates the hassle of `AddSubmonoid.closure_induction` when creating those
instances. -/
lemma of_nonneg_iff' [NonUnitalRing R] [PartialOrder R] [StarRing R]
    (h_add : ∀ {x y : R}, x ≤ y → ∀ z, z + x ≤ z + y)
    (h_nonneg_iff : ∀ x : R, 0 ≤ x ↔ ∃ s, x = star s * s) : StarOrderedRing R :=
  of_le_iff <| by
    haveI : CovariantClass R R (· + ·) (· ≤ ·) := ⟨fun _ _ _ h => h_add h _⟩
    simpa [sub_eq_iff_eq_add', sub_nonneg] using fun x y => h_nonneg_iff (y - x)

theorem nonneg_iff [NonUnitalSemiring R] [PartialOrder R] [StarRing R] [StarOrderedRing R] {x : R} :
    0 ≤ x ↔ x ∈ AddSubmonoid.closure (Set.range fun s : R => star s * s) := by
  simp only [le_iff, zero_add, exists_eq_right']

end StarOrderedRing

section NonUnitalSemiring

variable [NonUnitalSemiring R] [PartialOrder R] [StarRing R] [StarOrderedRing R]

lemma IsSelfAdjoint.mono {x y : R} (h : x ≤ y) (hx : IsSelfAdjoint x) : IsSelfAdjoint y := by
  rw [StarOrderedRing.le_iff] at h
  obtain ⟨d, hd, rfl⟩ := h
  rw [IsSelfAdjoint, star_add, hx.star_eq]
  congr
  refine AddMonoidHom.eqOn_closureM (f := starAddEquiv (R := R)) (g := .id R) ?_ hd
  rintro - ⟨s, rfl⟩
  simp

@[aesop 10% apply]
lemma IsSelfAdjoint.of_nonneg {x : R} (hx : 0 ≤ x) : IsSelfAdjoint x :=
  .mono hx <| .zero R

theorem star_mul_self_nonneg (r : R) : 0 ≤ star r * r :=
  StarOrderedRing.nonneg_iff.mpr <| AddSubmonoid.subset_closure ⟨r, rfl⟩

theorem mul_star_self_nonneg (r : R) : 0 ≤ r * star r := by
  simpa only [star_star] using star_mul_self_nonneg (star r)

@[aesop safe apply]
theorem conjugate_nonneg {a : R} (ha : 0 ≤ a) (c : R) : 0 ≤ star c * a * c := by
  rw [StarOrderedRing.nonneg_iff] at ha
  refine AddSubmonoid.closure_induction ha (fun x hx => ?_)
    (by rw [mul_zero, zero_mul]) fun x y hx hy => ?_
  · obtain ⟨x, rfl⟩ := hx
    convert star_mul_self_nonneg (x * c) using 1
    rw [star_mul, ← mul_assoc, mul_assoc _ _ c]
  · calc
      0 ≤ star c * x * c + 0 := by rw [add_zero]; exact hx
      _ ≤ star c * x * c + star c * y * c := add_le_add_left hy _
      _ ≤ _ := by rw [mul_add, add_mul]

@[aesop safe apply]
theorem conjugate_nonneg' {a : R} (ha : 0 ≤ a) (c : R) : 0 ≤ c * a * star c := by
  simpa only [star_star] using conjugate_nonneg ha (star c)

@[aesop 90% apply (rule_sets := [CStarAlgebra])]
protected theorem IsSelfAdjoint.conjugate_nonneg {a : R} (ha : 0 ≤ a) {c : R}
    (hc : IsSelfAdjoint c) : 0 ≤ c * a * c := by
  nth_rewrite 2 [← hc]; exact conjugate_nonneg' ha c

theorem conjugate_nonneg_of_nonneg {a : R} (ha : 0 ≤ a) {c : R} (hc : 0 ≤ c) :
    0 ≤ c * a * c :=
  IsSelfAdjoint.of_nonneg hc |>.conjugate_nonneg ha

theorem conjugate_le_conjugate {a b : R} (hab : a ≤ b) (c : R) :
    star c * a * c ≤ star c * b * c := by
  rw [StarOrderedRing.le_iff] at hab ⊢
  obtain ⟨p, hp, rfl⟩ := hab
  simp_rw [← StarOrderedRing.nonneg_iff] at hp ⊢
  exact ⟨star c * p * c, conjugate_nonneg hp c, by simp only [add_mul, mul_add]⟩

theorem conjugate_le_conjugate' {a b : R} (hab : a ≤ b) (c : R) :
    c * a * star c ≤ c * b * star c := by
  simpa only [star_star] using conjugate_le_conjugate hab (star c)

protected theorem IsSelfAdjoint.conjugate_le_conjugate {a b : R} (hab : a ≤ b) {c : R}
    (hc : IsSelfAdjoint c) : c * a * c ≤ c * b * c := by
  simpa only [hc.star_eq] using conjugate_le_conjugate hab c

theorem conjugate_le_conjugate_of_nonneg {a b : R} (hab : a ≤ b) {c : R} (hc : 0 ≤ c) :
    c * a * c ≤ c * b * c :=
  IsSelfAdjoint.of_nonneg hc |>.conjugate_le_conjugate hab

@[simp]
lemma star_le_star_iff {x y : R} : star x ≤ star y ↔ x ≤ y := by
  suffices ∀ x y, x ≤ y → star x ≤ star y from
    ⟨by simpa only [star_star] using this (star x) (star y), this x y⟩
  intro x y h
  rw [StarOrderedRing.le_iff] at h ⊢
  obtain ⟨d, hd, rfl⟩ := h
  refine ⟨starAddEquiv d, ?_, star_add _ _⟩
  refine AddMonoidHom.mclosure_preimage_le _ _ <| AddSubmonoid.closure_mono ?_ hd
  rintro - ⟨s, rfl⟩
  exact ⟨s, by simp⟩

@[simp]
lemma star_lt_star_iff {x y : R} : star x < star y ↔ x < y := by
  by_cases h : x = y
  · simp [h]
  · simpa [le_iff_lt_or_eq, h] using star_le_star_iff (x := x) (y := y)

lemma star_le_iff {x y : R} : star x ≤ y ↔ x ≤ star y := by rw [← star_le_star_iff, star_star]

lemma star_lt_iff {x y : R} : star x < y ↔ x < star y := by rw [← star_lt_star_iff, star_star]

@[simp]
lemma star_nonneg_iff {x : R} : 0 ≤ star x ↔ 0 ≤ x := by
  simpa using star_le_star_iff (x := 0) (y := x)

@[simp]
lemma star_nonpos_iff {x : R} : star x ≤ 0 ↔ x ≤ 0 := by
  simpa using star_le_star_iff (x := x) (y := 0)

@[simp]
lemma star_pos_iff {x : R} : 0 < star x ↔ 0 < x := by
  simpa using star_lt_star_iff (x := 0) (y := x)

@[simp]
lemma star_neg_iff {x : R} : star x < 0 ↔ x < 0 := by
  simpa using star_lt_star_iff (x := x) (y := 0)

theorem conjugate_lt_conjugate {a b : R} (hab : a < b) {c : R} (hc : IsRegular c) :
    star c * a * c < star c * b * c := by
  rw [(conjugate_le_conjugate hab.le _).lt_iff_ne, hc.right.ne_iff, hc.star.left.ne_iff]
  exact hab.ne

theorem conjugate_lt_conjugate' {a b : R} (hab : a < b) {c : R} (hc : IsRegular c) :
    c * a * star c < c * b * star c := by
  simpa only [star_star] using conjugate_lt_conjugate hab hc.star

theorem conjugate_pos {a : R} (ha : 0 < a) {c : R} (hc : IsRegular c) : 0 < star c * a * c := by
  simpa only [mul_zero, zero_mul] using conjugate_lt_conjugate ha hc

theorem conjugate_pos' {a : R} (ha : 0 < a) {c : R} (hc : IsRegular c) : 0 < c * a * star c := by
  simpa only [star_star] using conjugate_pos ha hc.star

theorem star_mul_self_pos [Nontrivial R] {x : R} (hx : IsRegular x) : 0 < star x * x := by
  rw [(star_mul_self_nonneg _).lt_iff_ne, ← mul_zero (star x), hx.star.left.ne_iff]
  exact hx.ne_zero.symm

theorem mul_star_self_pos [Nontrivial R] {x : R} (hx : IsRegular x) : 0 < x * star x := by
  simpa using star_mul_self_pos hx.star

end NonUnitalSemiring

section Semiring
variable [Semiring R] [PartialOrder R] [StarRing R] [StarOrderedRing R]

instance : ZeroLEOneClass R where
  zero_le_one := by simpa using star_mul_self_nonneg (1 : R)

@[simp]
lemma one_le_star_iff {x : R} : 1 ≤ star x ↔ 1 ≤ x := by
  simpa using star_le_star_iff (x := 1) (y := x)

@[simp]
lemma star_le_one_iff {x : R} : star x ≤ 1 ↔ x ≤ 1 := by
  simpa using star_le_star_iff (x := x) (y := 1)

@[simp]
lemma one_lt_star_iff {x : R} : 1 < star x ↔ 1 < x := by
  simpa using star_lt_star_iff (x := 1) (y := x)

@[simp]
lemma star_lt_one_iff {x : R} : star x < 1 ↔ x < 1 := by
  simpa using star_lt_star_iff (x := x) (y := 1)

end Semiring

section StarModule

variable {A : Type*} [Semiring R] [PartialOrder R] [StarRing R] [StarOrderedRing R]
  [NonUnitalRing A] [StarRing A] [PartialOrder A] [StarOrderedRing A] [Module R A]
  [StarModule R A] [NoZeroSMulDivisors R A] [IsScalarTower R A A] [SMulCommClass R A A]

lemma StarModule.smul_lt_smul_of_pos {a b : A} {c : R} (hab : a < b) (hc : 0 < c) :
    c • a < c • b := by
  rw [← sub_pos] at hab ⊢
  rw [← smul_sub]
  refine lt_of_le_of_ne ?le ?ne
  case le =>
    have hab := le_of_lt hab
    rw [StarOrderedRing.nonneg_iff] at hab ⊢
    refine AddSubmonoid.closure_induction hab ?mem ?zero ?add
    case mem =>
      intro x hx
      have hc := le_of_lt hc
      rw [StarOrderedRing.nonneg_iff] at hc
      refine AddSubmonoid.closure_induction hc ?memc ?zeroc ?addc
      case memc =>
        intro c' hc'
        obtain ⟨z, hz⟩ := hc'
        obtain ⟨y, hy⟩ := hx
        apply AddSubmonoid.subset_closure
        refine ⟨z • y, ?_⟩
        simp only [star_smul, smul_mul_smul_comm, hz, hy]
      case zeroc => simpa only [zero_smul] using zero_mem _
      case addc => exact fun c' d ↦ by simpa only [add_smul] using add_mem
    case zero => simpa only [smul_zero] using zero_mem _
    case add => exact fun x y ↦ by simpa only [smul_add] using add_mem
  case ne =>
    refine (smul_ne_zero ?_ ?_).symm
    · exact (ne_of_lt hc).symm
    · exact (ne_of_lt hab).symm

end StarModule

section OrderClass

variable {F R S : Type*} [NonUnitalSemiring R] [PartialOrder R] [StarRing R]
  [StarOrderedRing R]
variable [NonUnitalSemiring S] [PartialOrder S] [StarRing S] [StarOrderedRing S]

-- we prove this auxiliary lemma in order to avoid duplicating the proof twice below.
lemma NonUnitalStarRingHom.map_le_map_of_map_star (f : R →⋆ₙ+* S) {x y : R} (hxy : x ≤ y) :
    f x ≤ f y := by
  rw [StarOrderedRing.le_iff] at hxy ⊢
  obtain ⟨p, hp, rfl⟩ := hxy
  refine ⟨f p, ?_, map_add f _ _⟩
  have hf : ∀ r, f (star r) = star (f r) := map_star _
  induction hp using AddSubmonoid.closure_induction'
  all_goals aesop

instance (priority := 100) StarRingHomClass.instOrderHomClass [FunLike F R S]
    [NonUnitalSemiring R] [StarRing R] [StarOrderedRing R] [NonUnitalSemiring S]
    [StarRing S] [StarOrderedRing S] [NonUnitalRingHomClass F R S]
    [NonUnitalStarRingHomClass F R S] : OrderHomClass F R S where
  map_rel f := (f : R →⋆ₙ+* S).map_le_map_of_map_star

instance (priority := 100) StarRingEquivClass.instOrderIsoClass [EquivLike F R S]
    [StarRingEquivClass F R S] : OrderIsoClass F R S where
  map_le_map_iff f x y := by
    refine ⟨fun h ↦ ?_, map_rel f⟩
    let f_inv : S →⋆ₙ+* R := (f : R ≃⋆+* S).symm
    have f_inv_f (r : R) : f_inv (f r) = r := EquivLike.inv_apply_apply f r
    rw [← f_inv_f x, ← f_inv_f y]
    exact NonUnitalStarRingHom.map_le_map_of_map_star f_inv h

end OrderClass

instance Nat.instStarOrderedRing : StarOrderedRing ℕ where
  le_iff a b := by
    have : AddSubmonoid.closure (range fun x : ℕ ↦ x * x) = ⊤ :=
      eq_top_mono
        (AddSubmonoid.closure_mono <| singleton_subset_iff.2 <| mem_range.2 ⟨1, one_mul _⟩)
        Nat.addSubmonoid_closure_one
    simp [this, le_iff_exists_add]
