/-
Copyright (c) 2018 Kim Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison, Reid Barton
-/
import Mathlib.Logic.UnivLE
import Mathlib.CategoryTheory.Limits.HasLimits

/-!
# Colimits in the category of types

We show that the category of types has all colimits, by providing the usual concrete models.

-/

universe u' v u w

namespace CategoryTheory.Limits.Types

variable {J : Type v} [Category.{w} J] {F : J ⥤ Type u}

/--
The relation defining the quotient type which implements the colimit of a functor `F : J ⥤ Type u`.
See `CategoryTheory.Limits.Types.Quot`.
-/
def Quot.Rel (F : J ⥤ Type u) : (Σ j, F.obj j) → (Σ j, F.obj j) → Prop := fun p p' =>
  ∃ f : p.1 ⟶ p'.1, p'.2 = F.map f p.2

/-- A quotient type implementing the colimit of a functor `F : J ⥤ Type u`,
as pairs `⟨j, x⟩` where `x : F.obj j`, modulo the equivalence relation generated by
`⟨j, x⟩ ~ ⟨j', x'⟩` whenever there is a morphism `f : j ⟶ j'` so `F.map f x = x'`.
-/
def Quot (F : J ⥤ Type u) : Type (max v u) :=
  _root_.Quot (Quot.Rel F)

instance [Small.{u} J] (F : J ⥤ Type u) : Small.{u} (Quot F) :=
  small_of_surjective Quot.mk_surjective

/-- Inclusion into the quotient type implementing the colimit. -/
def Quot.ι (F : J ⥤ Type u) (j : J) : F.obj j → Quot F :=
  fun x => Quot.mk _ ⟨j, x⟩

lemma Quot.jointly_surjective {F : J ⥤ Type u} (x : Quot F) : ∃ j y, x = Quot.ι F j y :=
  Quot.ind (β := fun x => ∃ j y, x = Quot.ι F j y) (fun ⟨j, y⟩ => ⟨j, y, rfl⟩) x

section

variable {F : J ⥤ Type u} (c : Cocone F)

/-- (implementation detail) Part of the universal property of the colimit cocone, but without
    assuming that `Quot F` lives in the correct universe. -/
def Quot.desc : Quot F → c.pt :=
  Quot.lift (fun x => c.ι.app x.1 x.2) <| by
    rintro ⟨j, x⟩ ⟨j', _⟩ ⟨φ : j ⟶ j', rfl : _ = F.map φ x⟩
    exact congr_fun (c.ι.naturality φ).symm x

@[simp]
lemma Quot.ι_desc (j : J) (x : F.obj j) : Quot.desc c (Quot.ι F j x) = c.ι.app j x := rfl

@[simp]
lemma Quot.map_ι {j j' : J} {f : j ⟶ j'} (x : F.obj j) : Quot.ι F j' (F.map f x) = Quot.ι F j x :=
  (Quot.sound ⟨f, rfl⟩).symm

/--
The obvious map from `Quot F` to `Quot (F ⋙ uliftFunctor.{u'})`.
-/
def quotToQuotUlift (F : J ⥤ Type u) : Quot F → Quot (F ⋙ uliftFunctor.{u'}) := by
  refine Quot.lift (fun ⟨j, x⟩ ↦ Quot.ι _ j (ULift.up x)) ?_
  intro ⟨j, x⟩ ⟨j', y⟩ ⟨(f : j ⟶ j'), (eq : y = F.map f x)⟩
  dsimp
  have eq : ULift.up y = (F ⋙ uliftFunctor.{u'}).map f (ULift.up x) := by
    rw [eq]
    dsimp
  rw [eq, Quot.map_ι]

@[simp]
lemma quotToQuotUlift_ι (F : J ⥤ Type u) (j : J) (x : F.obj j) :
    quotToQuotUlift F (Quot.ι F j x) = Quot.ι _ j (ULift.up x) := by
  dsimp [quotToQuotUlift, Quot.ι]

/--
The obvious map from `Quot (F ⋙ uliftFunctor.{u'})` to `Quot F`.
-/
def quotUliftToQuot (F : J ⥤ Type u) : Quot (F ⋙ uliftFunctor.{u'}) → Quot F :=
  Quot.lift (fun ⟨j, x⟩ ↦ Quot.ι _ j x.down)
  (fun ⟨_, x⟩ ⟨_, y⟩ ⟨f, (eq : y = ULift.up (F.map f x.down))⟩ ↦ by simp [eq, Quot.map_ι])

@[simp]
lemma quotUliftToQuot_ι (F : J ⥤ Type u) (j : J) (x : (F ⋙ uliftFunctor.{u'}).obj j) :
    quotUliftToQuot F (Quot.ι _ j x) = Quot.ι F j x.down := by
  dsimp [quotUliftToQuot, Quot.ι]

/--
The equivalence between `Quot F` and `Quot (F ⋙ uliftFunctor.{u'})`.
-/
@[simp]
def quotQuotUliftEquiv (F : J ⥤ Type u) : Quot F ≃ Quot (F ⋙ uliftFunctor.{u'}) where
  toFun := quotToQuotUlift F
  invFun := quotUliftToQuot F
  left_inv x := by
    obtain ⟨j, y, rfl⟩ := Quot.jointly_surjective x
    rw [quotToQuotUlift_ι, quotUliftToQuot_ι]
  right_inv x := by
    obtain ⟨j, y, rfl⟩ := Quot.jointly_surjective x
    rw [quotUliftToQuot_ι, quotToQuotUlift_ι]
    rfl

lemma Quot.desc_quotQuotUliftEquiv {F : J ⥤ Type u} (c : Cocone F) :
    Quot.desc (uliftFunctor.{u'}.mapCocone c) ∘ quotQuotUliftEquiv F = ULift.up ∘ Quot.desc c := by
  ext x
  obtain ⟨_, _, rfl⟩ := Quot.jointly_surjective x
  dsimp

/-- (implementation detail) A function `Quot F → α` induces a cocone on `F` as long as the universes
    work out. -/
@[simps]
def toCocone {α : Type u} (f : Quot F → α) : Cocone F where
  pt := α
  ι := { app := fun j => f ∘ Quot.ι F j }

lemma Quot.desc_toCocone_desc {α : Type u} (f : Quot F → α) (hc : IsColimit c) (x : Quot F) :
    hc.desc (toCocone f) (Quot.desc c x) = f x := by
  obtain ⟨j, y, rfl⟩ := Quot.jointly_surjective x
  simpa using congrFun (hc.fac _ j) y

theorem isColimit_iff_bijective_desc : Nonempty (IsColimit c) ↔ (Quot.desc c).Bijective := by
  classical
  refine ⟨?_, ?_⟩
  · refine fun ⟨hc⟩ => ⟨fun x y h => ?_, fun x => ?_⟩
    · let f : Quot F → ULift.{u} Bool := fun z => ULift.up (x = z)
      suffices f x = f y by simpa [f] using this
      rw [← Quot.desc_toCocone_desc c f hc x, h, Quot.desc_toCocone_desc]
    · let f₁ : c.pt ⟶ ULift.{u} Bool := fun _ => ULift.up true
      let f₂ : c.pt ⟶ ULift.{u} Bool := fun x => ULift.up (∃ a, Quot.desc c a = x)
      suffices f₁ = f₂ by simpa [f₁, f₂] using congrFun this x
      refine hc.hom_ext fun j => funext fun x => ?_
      simpa [f₁, f₂] using ⟨Quot.ι F j x, by simp⟩
  · refine fun h => ⟨?_⟩
    let e := Equiv.ofBijective _ h
    have h : ∀ j x, e.symm (c.ι.app j x) = Quot.ι F j x :=
      fun j x => e.injective (Equiv.ofBijective_apply_symm_apply _ _ _)
    exact
      { desc := fun s => Quot.desc s ∘ e.symm
        fac := fun s j => by
          ext x
          simp [h]
        uniq := fun s m hm => by
          ext x
          obtain ⟨x, rfl⟩ := e.surjective x
          obtain ⟨j, x, rfl⟩ := Quot.jointly_surjective x
          rw [← h, Equiv.apply_symm_apply]
          simpa [h] using congrFun (hm j) x }

end

/-- (internal implementation) the colimit cocone of a functor,
implemented as a quotient of a sigma type
-/
@[simps]
noncomputable def colimitCocone (F : J ⥤ Type u) [Small.{u} (Quot F)] : Cocone F where
  pt := Shrink (Quot F)
  ι :=
    { app := fun j x => equivShrink.{u} _ (Quot.mk _ ⟨j, x⟩)
      naturality := fun _ _ f => funext fun _ => congrArg _ (Quot.sound ⟨f, rfl⟩).symm }

@[simp]
theorem Quot.desc_colimitCocone (F : J ⥤ Type u) [Small.{u} (Quot F)] :
    Quot.desc (colimitCocone F) = equivShrink.{u} (Quot F) := by
  ext ⟨j, x⟩
  rfl

/-- (internal implementation) the fact that the proposed colimit cocone is the colimit -/
noncomputable def colimitCoconeIsColimit (F : J ⥤ Type u) [Small.{u} (Quot F)] :
    IsColimit (colimitCocone F) :=
  Nonempty.some <| by
    rw [isColimit_iff_bijective_desc, Quot.desc_colimitCocone]
    exact (equivShrink _).bijective

theorem hasColimit_iff_small_quot (F : J ⥤ Type u) : HasColimit F ↔ Small.{u} (Quot F) :=
  ⟨fun _ => .mk ⟨_, ⟨(Equiv.ofBijective _
    ((isColimit_iff_bijective_desc (colimit.cocone F)).mp ⟨colimit.isColimit _⟩))⟩⟩,
   fun _ => ⟨_, colimitCoconeIsColimit F⟩⟩

theorem small_quot_of_hasColimit (F : J ⥤ Type u) [HasColimit F] : Small.{u} (Quot F) :=
  (hasColimit_iff_small_quot F).mp inferInstance

instance hasColimit [Small.{u} J] (F : J ⥤ Type u) : HasColimit F :=
  (hasColimit_iff_small_quot F).mpr inferInstance

instance hasColimitsOfShape [Small.{u} J] : HasColimitsOfShape J (Type u) where

/-- The category of types has all colimits. -/
@[stacks 002U]
instance (priority := 1300) hasColimitsOfSize [UnivLE.{v, u}] :
    HasColimitsOfSize.{w, v} (Type u) where

section instances

example : HasColimitsOfSize.{w, w, max v w, max (v + 1) (w + 1)} (Type max w v) := inferInstance
example : HasColimitsOfSize.{w, w, max v w, max (v + 1) (w + 1)} (Type max v w) := inferInstance

example : HasColimitsOfSize.{0, 0, v, v+1} (Type v) := inferInstance
example : HasColimitsOfSize.{v, v, v, v+1} (Type v) := inferInstance

example [UnivLE.{v, u}] : HasColimitsOfSize.{v, v, u, u+1} (Type u) := inferInstance

end instances

namespace TypeMax

/-- (internal implementation) the colimit cocone of a functor,
implemented as a quotient of a sigma type
-/
@[simps]
def colimitCocone (F : J ⥤ Type max v u) : Cocone F where
  pt := Quot F
  ι :=
    { app := fun j x => Quot.mk (Quot.Rel F) ⟨j, x⟩
      naturality := fun _ _ f => funext fun _ => (Quot.sound ⟨f, rfl⟩).symm }

/-- (internal implementation) the fact that the proposed colimit cocone is the colimit -/
def colimitCoconeIsColimit (F : J ⥤ Type max v u) : IsColimit (colimitCocone F) where
  desc s :=
    Quot.lift (fun p : Σj, F.obj j => s.ι.app p.1 p.2) fun ⟨j, x⟩ ⟨j', x'⟩ ⟨f, hf⟩ => by
      dsimp at hf
      rw [hf]
      exact (congr_fun (Cocone.w s f) x).symm
  uniq s m hm := by
    funext x
    induction' x using Quot.ind with x
    exact congr_fun (hm x.1) x.2

end TypeMax

variable (F : J ⥤ Type u) [HasColimit F]

attribute [local instance] small_quot_of_hasColimit

/-- The equivalence between the abstract colimit of `F` in `Type u`
and the "concrete" definition as a quotient.
-/
noncomputable def colimitEquivQuot : colimit F ≃ Quot F :=
  (IsColimit.coconePointUniqueUpToIso
    (colimit.isColimit F) (colimitCoconeIsColimit F)).toEquiv.trans (equivShrink _).symm

@[simp]
theorem colimitEquivQuot_symm_apply (j : J) (x : F.obj j) :
    (colimitEquivQuot F).symm (Quot.mk _ ⟨j, x⟩) = colimit.ι F j x :=
  congrFun (IsColimit.comp_coconePointUniqueUpToIso_inv (colimit.isColimit F) _ _) x

@[simp]
theorem colimitEquivQuot_apply (j : J) (x : F.obj j) :
    (colimitEquivQuot F) (colimit.ι F j x) = Quot.mk _ ⟨j, x⟩ := by
  apply (colimitEquivQuot F).symm.injective
  simp

-- Porting note (https://github.com/leanprover-community/mathlib4/issues/11119): @[simp] was removed because the linter said it was useless
variable {F} in
theorem Colimit.w_apply {j j' : J} {x : F.obj j} (f : j ⟶ j') :
    colimit.ι F j' (F.map f x) = colimit.ι F j x :=
  congr_fun (colimit.w F f) x

-- Porting note (https://github.com/leanprover-community/mathlib4/issues/11119): @[simp] was removed because the linter said it was useless
theorem Colimit.ι_desc_apply (s : Cocone F) (j : J) (x : F.obj j) :
    colimit.desc F s (colimit.ι F j x) = s.ι.app j x :=
   congr_fun (colimit.ι_desc s j) x

-- Porting note (https://github.com/leanprover-community/mathlib4/issues/11119): @[simp] was removed because the linter said it was useless
theorem Colimit.ι_map_apply {F G : J ⥤ Type u} [HasColimitsOfShape J (Type u)] (α : F ⟶ G) (j : J)
    (x : F.obj j) : colim.map α (colimit.ι F j x) = colimit.ι G j (α.app j x) :=
  congr_fun (colimit.ι_map α j) x

@[simp]
theorem Colimit.w_apply' {F : J ⥤ Type v} {j j' : J} {x : F.obj j} (f : j ⟶ j') :
    colimit.ι F j' (F.map f x) = colimit.ι F j x :=
  congr_fun (colimit.w F f) x

@[simp]
theorem Colimit.ι_desc_apply' (F : J ⥤ Type v) (s : Cocone F) (j : J) (x : F.obj j) :
    colimit.desc F s (colimit.ι F j x) = s.ι.app j x :=
  congr_fun (colimit.ι_desc s j) x

@[simp]
theorem Colimit.ι_map_apply' {F G : J ⥤ Type v} (α : F ⟶ G) (j : J) (x) :
    colim.map α (colimit.ι F j x) = colimit.ι G j (α.app j x) :=
  congr_fun (colimit.ι_map α j) x

variable {F} in
theorem colimit_sound {j j' : J} {x : F.obj j} {x' : F.obj j'} (f : j ⟶ j')
    (w : F.map f x = x') : colimit.ι F j x = colimit.ι F j' x' := by
  rw [← w, Colimit.w_apply]

variable {F} in
theorem colimit_sound' {j j' : J} {x : F.obj j} {x' : F.obj j'} {j'' : J}
    (f : j ⟶ j'') (f' : j' ⟶ j'') (w : F.map f x = F.map f' x') :
    colimit.ι F j x = colimit.ι F j' x' := by
  rw [← colimit.w _ f, ← colimit.w _ f']
  rw [types_comp_apply, types_comp_apply, w]

variable {F} in
theorem colimit_eq {j j' : J} {x : F.obj j} {x' : F.obj j'}
    (w : colimit.ι F j x = colimit.ι F j' x') :
      Relation.EqvGen (Quot.Rel F) ⟨j, x⟩ ⟨j', x'⟩ := by
  apply Quot.eq.1
  simpa using congr_arg (colimitEquivQuot F) w

theorem jointly_surjective_of_isColimit {F : J ⥤ Type u} {t : Cocone F} (h : IsColimit t)
    (x : t.pt) : ∃ j y, t.ι.app j y = x := by
  by_contra hx
  simp_rw [not_exists] at hx
  apply (_ : (fun _ ↦ ULift.up True) ≠ (⟨· ≠ x⟩))
  · refine h.hom_ext fun j ↦ ?_
    ext y
    exact (true_iff _).mpr (hx j y)
  · exact fun he ↦ of_eq_true (congr_arg ULift.down <| congr_fun he x).symm rfl

theorem jointly_surjective (F : J ⥤ Type u) {t : Cocone F} (h : IsColimit t) (x : t.pt) :
    ∃ j y, t.ι.app j y = x := jointly_surjective_of_isColimit h x

variable {F} in
/-- A variant of `jointly_surjective` for `x : colimit F`. -/
theorem jointly_surjective' (x : colimit F) :
    ∃ j y, colimit.ι F j y = x :=
  jointly_surjective F (colimit.isColimit F) x

/-- If a colimit is nonempty, also its index category is nonempty. -/
theorem nonempty_of_nonempty_colimit {F : J ⥤ Type u} [HasColimit F] :
    Nonempty (colimit F) → Nonempty J :=
  Nonempty.map <| Sigma.fst ∘ Quot.out ∘ (colimitEquivQuot F).toFun

end CategoryTheory.Limits.Types
