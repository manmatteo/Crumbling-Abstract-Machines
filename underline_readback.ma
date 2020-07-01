
(**************************************************************************)
(*       ___                                                              *)
(*      ||M||                                                             *)
(*      ||A||       A project by Andrea Asperti                           *)
(*      ||T||                                                             *)
(*      ||I||       Developers:                                           *)
(*      ||T||         The HELM team.                                      *)
(*      ||A||         http://helm.cs.unibo.it                             *)
(*      \   /                                                             *)
(*       \ /        This file is distributed under the terms of the       *)
(*        v         GNU General Public License Version 2                  *)
(*                                                                        *)
(**************************************************************************)

include "crumbles.ma".
include "basics/types.ma".
include "libnat.ma".

notation "[ term 19 v ← term 19 b ]" non associative with precedence 90 for @{ 'substitution $v $b }.
interpretation "Substitution" 'substitution v b =(subst v b).

(*notation "〈 b break, e 〉" non associative with precedence 90 for @{ 'ccrumble $b $e }.
*)
interpretation "Crumble creation" 'pair b e =(CCrumble b e).

notation "𝛌 x . y" right associative with precedence 40 for @{ 'lambda $x $y}.
interpretation "Abstraction" 'lambda x y = (lambda x y ).

notation "ν x" non associative with precedence 90 for @{ 'variable $x}.
interpretation "Variable contruction" 'variable x = (variable x).

notation "hvbox(c @ e)" with precedence 35 for @{ 'at $c $e }.
interpretation "@ operation" 'at c e =(at c e).

let rec domb x c on c ≝
 match c with
 [ CCrumble b e ⇒ domb_e x e ]

and domb_e x e on e ≝
 match e with
 [ Epsilon ⇒ false
 | Cons e s ⇒ match s with [ subst y b ⇒ (veqb x y) ∨ (domb_e x e)]
 ].

let rec free_occ_t x t on t ≝
 match t with
 [val_to_term v ⇒ free_occ_v x v
 |appl t1 t2 ⇒ (free_occ_t x t1)+(free_occ_t x t2)
 ]

and free_occ_v x v on v ≝
 match v with
 [ pvar y ⇒ match veqb x y with [ true ⇒ 1 | false ⇒ 0]
 | abstr y t ⇒ match (veqb x y) with [ true ⇒ 0 | false ⇒ (free_occ_t x t)]
 ]
.

let rec gtb n m on n ≝
 match n with
 [ O ⇒ false
 | S n' ⇒ match m with [ O ⇒ true | S m' ⇒ gtb n' m']
 ]
.

definition fv_t ≝ λx.λt. (free_occ_t x t)>0.
definition fv_v ≝ λx.λv. (free_occ_v x v)>0.
definition fvb_t ≝ λx.λt. gtb (free_occ_t x t) 0.
definition fvb_tv ≝ λx.λv. gtb (free_occ_v x v) 0.

let rec fvb x c on c : bool ≝
 match c with
 [ CCrumble b e ⇒ ((fvb_b x b) ∧ ¬(domb_e x e)) ∨ fvb_e x e ]

and fvb_b x b on b ≝
 match b with
 [ CValue v ⇒ fvb_v x v
 | AppValue v w ⇒ (fvb_v x v) ∨ (fvb_v x w)
 ]

and fvb_e x e on e ≝
 match e with
 [ Epsilon ⇒ false
 | Cons e s ⇒ match s with [subst y b ⇒ ((fvb_e y e) ∧ (¬ veqb x y)) ∨ fvb_b x b]
 ]

and fvb_v x v on v ≝
 match v with
 [ var y ⇒ veqb x y
 | lambda y c ⇒ (¬(veqb y x) ∧ fvb x c)
 ]
 .
 
let rec fvb_s x s on s ≝
 match s with
 [subst y b ⇒ (¬ veqb x y) ∨ fvb_b x b]
 .

let rec fresh_var c on c ≝
 match c with
 [ CCrumble b e ⇒  max (fresh_var_b b) (fresh_var_e e)]

and fresh_var_b b on b ≝
 match b with
 [ CValue v ⇒ fresh_var_v v
 | AppValue v w ⇒ max (fresh_var_v v) (fresh_var_v w)
 ]

and fresh_var_e e on e ≝
 match e with
 [ Epsilon ⇒ O
 | Cons e s ⇒ max (fresh_var_e e) (fresh_var_s s)
 ]

and fresh_var_v v on v ≝
 match v with
 [ var y ⇒ match y with [ variable x ⇒ S x ]
 | lambda y c ⇒ match y with [ variable x ⇒ max (S x) (fresh_var c)]
 ]

and fresh_var_s s on s ≝
 match s with
 [ subst x b ⇒ match x with [ variable x ⇒ max (S x) (fresh_var_b b)] ]
 .

lemma foo:
 ∀A,P.
  ∀Q: A → Prop.
   ∀c: Σx:A.P x.
   (∀z. z = pi1 ?? c → P z → Q z) →
     Q (pi1 ?? c).
#A #P #Q * /2/
qed.

lemma leq_to_geq: ∀x,y. x ≤ y → y ≥ x.
#x #y #H // qed.

let rec fresh_var_t_Sig t on t : Σn: nat. (∀x. (free_occ_t (νx) t ≥ 1) → (n > x)) ≝
 match t return λt. Σn: nat. (∀x. (free_occ_t (νx) t ≥ 1) → (n > x)) with
 [ val_to_term v ⇒ mk_Sig nat ? (pi1 nat ? (fresh_var_tv_Sig v)) ?
 | appl v w ⇒ mk_Sig nat ? (max (pi1 nat ? (fresh_var_t_Sig v)) (pi1 nat ? (fresh_var_t_Sig w))) ?
 ]

and fresh_var_tv_Sig v on v : Σn: nat. (∀x. (free_occ_v (νx) v ≥ 1) → (n > x)) ≝
 match v return λv. Σn: nat. (∀x. (free_occ_v (νx) v ≥ 1) → (n > x)) with
 [ pvar y ⇒ match y return λy. Σn: nat. (∀x. (free_occ_v (νx) (pvar y) ≥ 1) → (n > x)) with [variable x ⇒ mk_Sig … (S x) ?]
 | abstr y t ⇒ match y return λy. Σn: nat. (∀x. (free_occ_v (νx) (abstr y t) ≥ 1) → (n > x)) with [variable x ⇒ mk_Sig … (max (S x) (pi1 nat ? (fresh_var_t_Sig t))) ?]
 ]
 .
[ @foo #z #z_def #H #x  #H1 normalize in H1; cut (free_occ_v (νx) v ≥1)
  [ /2/ assumption
  | -H1 #H1 @((H x) H1)
  ]
| @foo #z #z_def @foo #z1 #z1_def #H1 #H #x #HH normalize in HH;
  lapply HH lapply (H x) cases (free_occ_t (νx) v)
  [ #_ -HH #HH lapply (H1 x) -H1 #H1 cut (z1 > x)
    /2/ -H1 #H1  normalize cut (leb z z1= true ∨ leb z z1= false) // * #Htf >Htf
    normalize /2/ lapply(leb_false_to_not_le z z1 Htf )
    -Htf #Htf lapply (not_le_to_lt z z1 Htf) #Hgt normalize in H1;
    @(lt_to_le (S x) z (le_to_lt_to_lt (S x) z1 z H1 Hgt))
  | #n #Hzx cut (z>x)[ /2/ | -Hzx #Hzx  #Hok normalize
    cut (leb z z1= true ∨ leb z z1= false) // * #Htf >Htf
    normalize[ lapply(leb_true_to_le z z1 Htf)
    normalize in Hzx; /2/ | /2/]]
  ]
| #z  normalize cut (neqb z x=true ∨ neqb z x=false) // * #Htf >Htf normalize
  [ #_ lapply(neqb_iff_eq z x) * #Heq #_ lapply (Heq Htf) -Heq #Heq destruct //
  | #Abs @False_ind /2/
  ]
| @foo #z #z_def #H #y normalize cut (neqb y x = true ∨ neqb y x = false) // * #Htf
  >Htf normalize
  [ #Abs @False_ind /2/
  | #HH lapply ((H y) ((leq_to_geq 1 (free_occ_t (νy) t)) HH)) #Hgt
    change with (leb (S ?) ?) in match ( match z in nat return λ_:ℕ.bool with [O⇒false|S (q:ℕ)⇒leb x q]) ;
    cut (leb (S x) z=true ∨ leb (S x) z=false)  // * #Htf2 >Htf2 normalize
    normalize in Hgt; [ assumption |
    lapply(not_le_to_lt (S x) z ((leb_false_to_not_le (S x) z) Htf2))
    #Hgt2 @(lt_to_le … (le_to_lt_to_lt (S y) z (S x) Hgt Hgt2))
] qed.

definition fresh_var_t  ≝  λt: pifTerm. pi1 nat ? (fresh_var_t_Sig t).
definition fresh_var_tv  ≝  λv: pifValue. pi1 nat ? (fresh_var_tv_Sig v).

lemma fresh_var_gt: ∀x.(∀t. (free_occ_t (νx) t ≥ 1) → (fresh_var_t t) > x) ∧
                        (∀v. (free_occ_v (νx) v ≥ 1) → (fresh_var_tv) v > x).
#x % [ #t normalize @foo #z #z_def #H /2/
| #v normalize @foo #z #z_def #H /2/].qed.

(*
let rec fresh_var e ≝
 match e with
 [ Epsilon ⇒  O
 | Cons e' s ⇒  match s with [ subst v b ⇒ match v with [ variable n ⇒ max (S n) (fresh_var e')]]
 ]
 .

let rec underline_pifTerm (t: pifTerm) :Crumble ≝
 match t with
 [ val_to_term v ⇒ 〈CValue (overline v), Epsilon〉
 | appl t1 t2 ⇒ match t2 with
                [ val_to_term v2 ⇒ match t1 with
                                   [ val_to_term v1 ⇒ 〈AppValue (overline v1) (overline v2), Epsilon 〉
                                   | appl u1 u2 ⇒ match underline_pifTerm t1 with [CCrumble b e ⇒ 〈AppValue (var ν(fresh_var e)) (overline v2), push e [ν(fresh_var e)←b]〉]
                                   ]
                | appl u1 u2 ⇒ match underline_pifTerm t2 with [ CCrumble b e ⇒ at (underline_pifTerm (appl t1 (val_to_term (pvar ν(fresh_var e))))) (push e [ν(fresh_var e)←b]) ]
                ]
 ]
*)
(* deve restituire una coppia 〈crumble, numero di variabili già inserite〉 per usare il parametro destro sommato al numero di variabili presenti nel termine all'inizio per dare sempre una variabile fresca*)

let rec underline_pifTerm (t: pifTerm) (s: nat): Crumble × nat≝
 match t with
 [ val_to_term v ⇒ match overline v s with
   [ mk_Prod vv n ⇒  mk_Prod Crumble nat 〈(CValue vv), Epsilon 〉 n]
 | appl t1 t2 ⇒ match t2 with
   [ val_to_term v2 ⇒ match t1 with
     [ val_to_term v1 ⇒ match overline v1 s with
       [ mk_Prod vv n ⇒ match overline v2 (s+n) with
         [ mk_Prod ww m ⇒ mk_Prod Crumble nat 〈AppValue (vv) (ww), Epsilon〉 (m+n) ]
       ]
     | appl u1 u2 ⇒ match underline_pifTerm t1 s with
       [ mk_Prod c n ⇒ match c with
         [ CCrumble b e ⇒ match overline v2 (s+n) with
           [ mk_Prod vv m ⇒ mk_Prod Crumble nat 〈AppValue (var ν(s+n+m)) (vv), push e [(ν(s+n+m)) ← b]〉 (S (s+n+m))]
         ]
       ]
     ]
   | appl u1 u2 ⇒ match underline_pifTerm t2 s with
     [ mk_Prod c n ⇒ match c with
       [ CCrumble b1 e1 ⇒ match t1 with
         [ val_to_term v1 ⇒ match overline v1 (s+n) with
           [ mk_Prod vv m ⇒  mk_Prod Crumble nat (at 〈AppValue (vv) (var ν(s+n+m)), Epsilon〉 (push e1 [ν(s+n)←b1])) (S n)]
         | appl u1 u2 ⇒ match underline_pifTerm t1 (s+n) with
          [ mk_Prod c1 n1 ⇒ match c1 with
            [ CCrumble b e ⇒ mk_Prod Crumble nat 〈AppValue (var (ν(s+n+n1))) (var (ν(S(s+n+n1)))), concat (push e1 [ν(s+n+n1) ← b1]) (push e [ν(S(s+n+n1)) ← b])〉 (S (S (s + n + n1)))]
          ]
         ]
       ]
     ]
   ]
 ]

and

overline (x:pifValue) (s: nat): Value × nat≝
 match x with
 [ pvar v ⇒ mk_Prod Value nat (var v) O
 | abstr v t ⇒ match underline_pifTerm t s with
   [ mk_Prod c n ⇒ mk_Prod Value nat (lambda (v) (c)) n ]
 ]
 .
 (*
let rec rename_aux (x: Variable) (x':Variable) (t:pifTerm) on t :pifTerm ≝
 match t with
 [ val_to_term v ⇒ val_to_term (rename_aux_v x x' v)
 | appl t1 t2 ⇒ appl (rename_aux x x' t1) (rename_aux x x' t2)
 ]

and rename_aux_v (x: Variable) (x':Variable) (v:pifValue) on v ≝
 match v with
 [ pvar y ⇒ match veqb x y with [true ⇒ pvar x' | false ⇒ pvar y]
 | abstr y t ⇒ match veqb x y with [true ⇒ abstr x' t | false ⇒ abstr y (rename_aux x x' t)]
 ]
 .

let rec rename x x' t on t≝
 match t with
 [ val_to_term v ⇒ val_to_term (rename_v x x' v)
 | appl t1 t2 ⇒ appl (rename x x' t1) (rename x x' t2)
 ]

and rename_v x x' v on v≝
 match v with
 [ pvar y ⇒ pvar y
 | abstr y t ⇒ match veqb x y with [true ⇒ abstr x' (rename_aux x x' t) | false ⇒ abstr y (rename x x' t)]
 ]
 .
 *)
let rec t_size t on t ≝
 match t with
 [ val_to_term v ⇒ v_size v
 | appl t1 t2 ⇒ S ((t_size t1) + (t_size t2))
 ]

and v_size v on v ≝
 match v with
 [ pvar v ⇒ 1
 | abstr x t ⇒ S (t_size t)
 ]
.

lemma pif_size_not_zero: (∀t. t_size t ≥ O) ∧ (∀v. v_size v ≥ O).
@pifValueTerm_ind
[ #v #H normalize /2/
| #t1 #t2 #H1 #H2 /2/
| #x normalize //
| #t #x #H normalize //
]
qed.

lemma pif_subst_axu1: (∀t. S (t_size t -1)=t_size t) ∧ (∀v. S (v_size v -1)=v_size v).
@pifValueTerm_ind
[ #v #H normalize //
| #t1 #t2 #H1 #H2 normalize //
| #x normalize //
| #t #x #H normalize //]
qed.
 (*
lemma rename_aux_lemma:
 (∀t.∀x,y. t_size t = t_size (rename_aux x y t)) ∧
  (∀v.∀x,y. v_size v = v_size (rename_aux_v x y v)).

@pifValueTerm_ind
[ #v #H #x #y normalize >(H x y) //
| #t1 #t2 #H1 #H2 #x #y normalize >(H1 x y) >(H2 x y) //
| #t #x #y normalize cases (veqb x t) normalize //
| #t #x #H #x' #y normalize cases (veqb x' x) normalize //
] qed.

lemma rename_lemma:
 (∀t.∀x,y. t_size t = t_size (rename x y t)) ∧
  (∀v.∀x,y. v_size v = v_size (rename_v x y v)).
 @pifValueTerm_ind

[ #v #H #x #y normalize >(H x y) //
| #t1 #t2 #H1 #H2 #x #y normalize >(H1 x y) >(H2 x y) //
| #v #x #y normalize //
| #t #x #H #x' #y normalize cases (veqb x' x) normalize
  [ lapply rename_aux_lemma * #Haux #_ >(Haux t x' y ) //
  | >(H x' y) //
  ]
] qed.
*)

theorem ex_falso: ∀P: Prop. False → P.
#P #False @(False_ind … P) assumption qed.


(*
let rec pif_subst (n: nat) s: Πt. (t_size t ≤ n) → Σu: pifTerm. t_size u = (t_size t)+ (free_occ_t (pi1ps s) t) * ((t_size (pi2ps s)) - 1)≝
 match n return λn. Πt. (t_size t ≤ n) → Σu: pifTerm. t_size u = (t_size t)+ (free_occ_t (pi1ps s) t) * ((t_size (pi2ps s)) - 1) with
 [ O ⇒ λt.?
 | S m ⇒ λt. match t return λt.t_size t ≤ S m → Σu: pifTerm. t_size u = (t_size t)+ (free_occ_t (pi1ps s) t) * ((t_size (pi2ps s)) - 1) with
   [ val_to_term v ⇒ λp. mk_Sig … (Sig_fst … (pif_subst_v m s v ?)) ?
   | appl t' u ⇒  λp. mk_Sig … (appl (Sig_fst … (pif_subst m s t' ? )) (Sig_fst … (pif_subst m s u ?))) ?
   ]
 ]

and pif_subst_v (n: nat) s: Πv. (v_size v  ≤ n) → Σu: pifTerm. t_size u = (v_size v)+ (free_occ_v (pi1ps s) v) * ((t_size (pi2ps s)) - 1) ≝
 match n return λn. Πv.v_size v ≤ n → Σu: pifTerm. t_size u = (v_size v)+ (free_occ_v (pi1ps s) v) * ((t_size (pi2ps s)) - 1) with
 [ O ⇒ λv.?
 | S m ⇒ λv. match v return λv. v_size v ≤ S m → Σu: pifTerm. t_size u = (v_size v)+ (free_occ_v (pi1ps s) v) * ((t_size (pi2ps s)) - 1) with
              [ pvar x ⇒ match s return λs. v_size (pvar x) ≤ S m → Σu: pifTerm. t_size u = (v_size (pvar x))+ (free_occ_v (pi1ps s) (pvar x)) * ((t_size (pi2ps s)) - 1) with
                              [psubst y t' ⇒ λp.mk_Sig … (match veqb y x with [true ⇒ t' | false ⇒ (val_to_term (pvar x))]) ?
                              ]
              | abstr x t1 ⇒  match s return λb. v_size (abstr x t1) ≤ S m → Σu: pifTerm. t_size u = (v_size (abstr x t1))+ (free_occ_v (pi1ps s) (abstr x t1)) * ((t_size (pi2ps s)) - 1) with
                                  [ psubst y t' ⇒ match veqb y x return λb. v_size (abstr x t1) ≤ S m → Σu: pifTerm. t_size u = (v_size (abstr x t1))+ (free_occ_v (pi1ps s) (abstr x t1)) * ((t_size (pi2ps s)) - 1) with
                                                  [ true ⇒ λp. mk_Sig … (val_to_term v) ?
                                                  | false ⇒ match fvb_t x t' return λb. v_size (abstr x t1) ≤ S m → Σu: pifTerm. t_size u = (v_size (abstr x t1))+ (free_occ_v (pi1ps s) (abstr x t1)) * ((t_size (pi2ps s)) - 1) with
                                                            [ true ⇒ match (pif_subst m (psubst x (val_to_term (pvar ν(fresh_var_t t')))) t1 ?) return λb. v_size (abstr x t1) ≤ S m → Σu: pifTerm. t_size u = (v_size (abstr x t1))+ (free_occ_v (pi1ps s) (abstr x t1)) * ((t_size (pi2ps s)) - 1) with
                                                                      [ mk_Sig a h ⇒ λp. mk_Sig … (val_to_term (abstr (ν(fresh_var_t t')) (Sig_fst … (pif_subst m (psubst y a) t1 ?)))) ?]
                                                            | false ⇒ λp. mk_Sig … (val_to_term (abstr x (Sig_fst … (pif_subst m s t1 ?)))) ?
                                                            ]
                                                  ]
                                  ]
              ]
]
.
*)


(*
lemma generalize_foo:
 ∀n,s,p,P.
  (∀q. P (pif_subst n s t q)) →
    P (pif_subst n s t p).
*)

lemma free_occ_max: ∀x, t. free_occ_t (variable (max (fresh_var_t t) x)) t=0.
#x #t normalize cut (leb (fresh_var_t t) x= true ∨  leb (fresh_var_t t) x= false)
// * #Htf >Htf normalize
[ lapply (leb_true_to_le … Htf) -Htf #Hle lapply (fresh_var_gt x) * #H1
  lapply (H1 t) -H1 #H1 #_ lapply(inverse … H1) -H1 #H1 normalize in match (¬? ≥1) in H1;
  normalize cut ((fresh_var_t t)≤x→free_occ_t (νx) t=0)
   [ lapply (not_ge_1_to_O … (H1 ((le_to_not_gt … (fresh_var_t t) x) Hle))) //
   | #H2 @(H2 Hle)
   ]
| @foo #z #z_def #Hz lapply(leb_false_to_not_le (fresh_var_t t) x Htf)
  -Htf #H1 lapply((not_le_to_lt (fresh_var_t t) x) H1) -H1 #H1
  lapply (Hz z) -Hz #Hx lapply (inverse … Hx) normalize
  cut (S z ≰ z) // #H1 #H2  @(not_ge_1_to_O … (H2 H1))
]
qed.

lemma veqb_comm: ∀x.∀y. veqb x y  = veqb y x.
#x #y elim x #nx elim y #ny normalize //. qed.

lemma veqb_true: ∀x. veqb x x = true.
#x elim x #nx elim nx normalize // qed.

lemma gtb_O: ∀x. gtb x O = false → x=0.
#x cases x normalize // #nx #abs destruct qed.

let rec pif_subst_sig (n: nat) s: Πt. (t_size t ≤ n) →
 Σu: pifTerm. ((t_size u = (t_size t)+ (free_occ_t (match s with [psubst x t ⇒ x]) t) * ((t_size (match s with [psubst x t ⇒ t])) - 1)) ∧
  (∀z. free_occ_t z u = match veqb (match s with [psubst y t' ⇒ y]) z with
   [ true ⇒ (free_occ_t z t) * (free_occ_t z match s with [psubst y t' ⇒ t'])
   | false ⇒ (free_occ_t (match s with [psubst y t' ⇒ y]) t) * (free_occ_t z match s with [psubst y t' ⇒ t']) + (free_occ_t z t)
   ])) ≝

 match n return λn. Πt. (t_size t ≤ n) → Σu: pifTerm. ((t_size u = (t_size t)+ (free_occ_t (match s with [psubst x t ⇒ x]) t) * ((t_size (match s with [psubst x t ⇒ t])) - 1)) ∧
  (∀z. free_occ_t z u = match veqb (match s with [psubst y t' ⇒ y]) z with
   [ true ⇒ (free_occ_t z t) * (free_occ_t z match s with [psubst y t' ⇒ t'])
   | false ⇒ (free_occ_t (match s with [psubst y t' ⇒ y]) t) * (free_occ_t z match s with [psubst y t' ⇒ t']) + (free_occ_t z t)
   ]))
  with
 [ O ⇒ λt.?
 | S m ⇒ λt. match t return λt.t_size t ≤ S m → Σu: pifTerm. ((t_size u = (t_size t)+ (free_occ_t (match s with [psubst x t ⇒ x]) t) * ((t_size (match s with [psubst x t ⇒ t])) - 1)) ∧
   (∀z. free_occ_t z u = match veqb (match s with [psubst y t' ⇒ y]) z with
   [ true ⇒ (free_occ_t z t) * (free_occ_t z match s with [psubst y t' ⇒ t'])
   | false ⇒ (free_occ_t (match s with [psubst y t' ⇒ y]) t) * (free_occ_t z match s with [psubst y t' ⇒ t']) + (free_occ_t z t)
   ]))
  with
   [ val_to_term v ⇒ match v return λv. t_size (val_to_term v) ≤ S m → Σu: pifTerm. (t_size u = (t_size (val_to_term v))+ (free_occ_v (match s with [psubst x t ⇒ x]) v) * ((t_size (match s with [psubst x t ⇒ t])) - 1) ∧
     (∀z. free_occ_t z u = match veqb (match s with [psubst y t' ⇒ y]) z with
      [ true ⇒ (free_occ_v z v) * (free_occ_t z match s with [psubst y t' ⇒ t'])
      | false ⇒ (free_occ_v (match s with [psubst y t' ⇒ y]) v) * (free_occ_t z match s with [psubst y t' ⇒ t']) + (free_occ_v z v)
      ]))
     with
    [ pvar x ⇒ match s return λs. t_size (val_to_term (pvar x)) ≤ S m → Σu: pifTerm. (t_size u = (t_size (val_to_term (pvar x)))+ (free_occ_v (match s with [psubst x t ⇒ x]) (pvar x)) * ((t_size (match s with [psubst x t ⇒ t])) - 1) ∧
     (∀z. free_occ_t z u = match veqb (match s with [psubst y t' ⇒ y]) z with
      [ true ⇒ (free_occ_v z (pvar x)) * (free_occ_t z match s with [psubst y t' ⇒ t'])
      | false ⇒ (free_occ_v (match s with [psubst y t' ⇒ y]) (pvar x)) * (free_occ_t z match s with [psubst y t' ⇒ t']) + (free_occ_v z (pvar x))
      ]))
       with
      [ psubst y t' ⇒ match veqb y x return λb. veqb y x = b → t_size (val_to_term (pvar x)) ≤ S m → Σu: pifTerm. (t_size u = (t_size (val_to_term (pvar x)))+ (free_occ_v (match (psubst y t') with [psubst x t ⇒ x]) (pvar x)) * ((t_size (match (psubst y t') with [psubst x t ⇒ t])) - 1) ∧
       (∀z. free_occ_t z u = match veqb (match (psubst y t') with [psubst y t' ⇒ y]) z with
         [ true ⇒ (free_occ_v z (pvar x)) * (free_occ_t z match (psubst y t') with [psubst y t' ⇒ t'])
         | false ⇒ (free_occ_v (match (psubst y t') with [psubst y t' ⇒ y]) (pvar x)) * (free_occ_t z match (psubst y t') with [psubst y t' ⇒ t']) + (free_occ_v z (pvar x))
         ]))
       with
        [true ⇒λH.λp.mk_Sig … t' ? | false ⇒ λH.λp.mk_Sig … (val_to_term (pvar x)) ?] (refl …)
      ]
    | abstr x t1 ⇒ match veqb (match s with [psubst x t ⇒ x]) x return λb. veqb (match s with [psubst x t ⇒ x]) x = b → t_size (val_to_term (abstr x t1)) ≤ S m → Σu: pifTerm. (t_size u = (t_size (val_to_term (abstr x t1)))+ (free_occ_v match s with [psubst x t ⇒ x] (abstr x t1)) * ((t_size match s with [psubst x t ⇒ t]) - 1) ∧
       (∀z. free_occ_t z u = match veqb (match s with [psubst y t' ⇒ y]) z with
         [ true ⇒ (free_occ_v z (abstr x t1)) * (free_occ_t z match s with [psubst y t' ⇒ t'])
         | false ⇒ (free_occ_v (match s with [psubst y t' ⇒ y]) (abstr x t1)) * (free_occ_t z match s with [psubst y t' ⇒ t']) + (free_occ_v z (abstr x t1))
         ]))
      with
       [ true ⇒ λH.λp. mk_Sig …  (val_to_term (abstr x t1)) ?
       | false ⇒ λH. match fvb_t x (match s with [psubst x t ⇒ t]) return λb. fvb_t x (match s with [psubst x t ⇒ t])=b → t_size (val_to_term (abstr x t1)) ≤ S m → Σu: pifTerm. (t_size u = (t_size (val_to_term (abstr x t1)))+ (free_occ_v match s with [psubst x t ⇒ x] (abstr x t1)) * ((t_size match s with [psubst x t ⇒ t]) - 1) ∧
         (∀z. free_occ_t z u = match veqb (match s with [psubst y t' ⇒ y]) z with
           [ true ⇒ (free_occ_v z (abstr x t1)) * (free_occ_t z match s with [psubst y t' ⇒ t'])
           | false ⇒ (free_occ_v (match s with [psubst y t' ⇒ y]) (abstr x t1)) * (free_occ_t z match s with [psubst y t' ⇒ t']) + (free_occ_v z (abstr x t1))
           ]))
        with
         [ true ⇒ λHH. λp. let z ≝ (max (S match s with [psubst x t ⇒ match x with [variable n ⇒ n]]) (max (S match x with [variable nx⇒ nx]) (max (fresh_var_t t1) (fresh_var_t match s with [psubst x t ⇒ t]))))
                  in match (pif_subst_sig m (psubst x (val_to_term (pvar ν(z)))) t1 ?) with
           [ mk_Sig a h ⇒ mk_Sig …  (val_to_term (abstr (ν(z)) (pi1 … (pif_subst_sig m s a ?)))) ?]
         | false ⇒ λHH. λp. mk_Sig … (val_to_term (abstr x (pi1 … (pif_subst_sig m s t1 ?)))) ?
         ] (refl …)
       ] (refl …)
    ]
   | appl t' u ⇒  λp. mk_Sig … (appl (pi1 …(pif_subst_sig m s t' ? )) (pi1 … (pif_subst_sig m s u ?))) ?
   ]
 ]
.
[ cases t    [ #v cases v [#x normalize #Abs lapply (leq_zero 0 Abs) -Abs #Abs elim Abs
          | #x #t normalize #Abs lapply (leq_zero (t_size t) Abs) -Abs #Abs elim Abs]
| #t1 #t2 normalize #Abs lapply (leq_zero ((t_size t1)+(t_size t2)) Abs) -Abs #Abs elim Abs]
| normalize in p; normalize >H normalize <(plus_n_O (t_size t' -1)) lapply(pif_subst_axu1) * #H1 #_ >(H1 t') % //
  #z lapply (veqb_true_to_eq y x) * #H' #_ lapply (H' H) -H -H' #H destruct
  cut (veqb x z =veqb z x) [@(veqb_comm …) | cut (veqb x z =true ∨ veqb x z =false) // * #Hxz
  #Heq <Heq >Hxz normalize //]
| normalize normalize >H normalize in p; normalize % // #z
  cut (veqb z x = true ∨ veqb z x = false) // * #Hzx
   [ lapply (veqb_true_to_eq z x) * #Heq #_ lapply (Heq Hzx) -Heq #Heq destruct >H
   >(veqb_true x) normalize //
   | cut (veqb y z = true ∨ veqb y z = false) // * #Hyz
     lapply (veqb_true_to_eq y z) * #Heq #_
      [ lapply (Heq Hyz) -Heq #Heq destruct >Hzx >Hyz normalize //
      | >Hzx >Hyz normalize //
      ]
   ]
| lapply H cases s #y #t' normalize #H1 >H1 normalize % //
  lapply (veqb_true_to_eq y x) * #Heq #_ lapply (Heq H1) -Heq #Heq destruct
  #z lapply (veqb_comm x z) #Hcomm >Hcomm -Hcomm cases (veqb z x) normalize //
| normalize in h; lapply h * -h #h #_ normalize in p; /2/
| @foo #k #k_def #k_size whd in match (t_size ?) in ⊢ %;
  whd in match (t_size (val_to_term ?)) in ⊢ %;
  lapply k_size * -k_size #k_size #k_fv >k_size lapply h -h * #a_size #a_fv >a_size lapply H
   normalize in a_fv; lapply a_fv lapply k_fv normalize cases s #y #t -k_fv #k_fv normalize
  -H normalize -a_fv #a_fv #H >H normalize lapply (a_fv y) normalize lapply (veqb_comm x y)
  #Hcomm >Hcomm >H normalize change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
  lapply a_fv lapply k_fv
  lapply H
  elim y #ny
  -H #H
  #k_fv_ny #a_fv_ny normalize change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
  change with (leb (S ?) ?) in match ( match max (fresh_var_t t1) (fresh_var_t t) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb ny q]);
  change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
  >(neqb_x_max_Sx ny ?) whd in match (if false then 1 else O); #Hfva >Hfva % [ /2/
  | #ww lapply k_fv_ny lapply (a_fv_ny ww) normalize
    -k_fv_ny -a_fv_ny #a_fv_ny #k_fv_ny >(k_fv_ny ww) lapply (a_fv_ny) elim ww #nww
    lapply H elim x #nx -H normalize #H
    change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
    change with (leb (S ?) ?) in match ( match max (fresh_var_t t1) (fresh_var_t t) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb ny q]);
    change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
    -a_fv_ny #a_fv_ny >a_fv_ny
    cut (neqb nww nx = true ∨ neqb nww nx=false) // * #Hzx lapply (neqb_iff_eq nww nx) *
    #Heq #_
    [ lapply (Heq Hzx) -Heq #Heq destruct >(rifle_neqb … nx) normalize
      cut (neqb nx ny = true ∨neqb nx ny = false) // * #Hxy lapply (neqb_iff_eq nx ny) *
      #Heq2 #_
      [ lapply (Heq2 Hxy) -Heq2 #Heq2 destruct >Hxy >(rifle_neqb … ny) normalize
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        change with (leb (S ?) ?) in match ( match max (fresh_var_t t1) (fresh_var_t t) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb ny q]);
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        change with (leb (S ?) ?) in match ( match  max (S ny) (max (fresh_var_t t1) (fresh_var_t t)) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb ny q]);
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        >(neqb_x_max_Sx ny (max (S ny) (max (fresh_var_t t1) (fresh_var_t t)))) normalize /2/
      | -Heq2 >(neq_simm ny nx) >Hxy normalize
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        change with (leb (S nx) ?) in match ( match max (fresh_var_t t1) (fresh_var_t t) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb nx q]);
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        change with (leb (S ?) ?) in match ( match  max (S nx) (max (fresh_var_t t1) (fresh_var_t t)) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb ny q]);
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        cut ( neqb nx (max (S ny) (max (S nx) (max (fresh_var_t t1) (fresh_var_t t)))) = false)
        [ /2/ | #Hfalse >Hfalse normalize >Hfva /2/]
      ]
    | -Heq cut (neqb ny nww =true ∨ neqb ny nww = false) // * #Hyz >Hyz
      [ lapply (neqb_iff_eq ny nww) * #Heq #_ lapply (Heq Hyz) -Heq #Heq
        destruct normalize
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        change with (leb (S nx) ?) in match ( match max (fresh_var_t t1) (fresh_var_t t) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb nx q]);
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        change with (leb (S ?) ?) in match ( match  max (S nx) (max (fresh_var_t t1) (fresh_var_t t)) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb nww q]);
        change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
        cut ( neqb nww (max (S nww) (max (S nx) (max (fresh_var_t t1) (fresh_var_t t)))) = false)
        [/2/ | #Hfalse >Hfalse normalize >(neq_simm nx nww) >Hzx normalize /2/]
      | lapply H -H #Hxy >(neq_simm ny nx) >(neq_simm nww ny) >(neq_simm nx nww) >Hxy >Hyz >Hzx normalize
          change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
          change with (leb (S nx) ?) in match ( match max (fresh_var_t t1) (fresh_var_t t) in nat return λ_:ℕ.bool
                   with [O⇒false|S (q:ℕ)⇒leb nx q]);
          change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
          change with (leb (S ?) ?) in match ( match  max (S nx) (max (fresh_var_t t1) (fresh_var_t t)) in nat return λ_:ℕ.bool
                   with [O⇒false|S (q:ℕ)⇒leb ny q]);
          change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
          cut (neqb nww (max (S ny) (max (S nx) (max (fresh_var_t t1) (fresh_var_t t))))=true ∨ neqb nww (max (S ny) (max (S nx) (max (fresh_var_t t1) (fresh_var_t t))))=false)
          // * #Htf
          [ >Htf normalize lapply (neqb_iff_eq nww (max (S ny) (max (S nx) (max (fresh_var_t t1) (fresh_var_t t)))))
            * #Heq #_ lapply (Heq Htf) -Heq -Htf #Heq >Heq normalize
            change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
            change with (leb (S nx) ?) in match ( match max (fresh_var_t t1) (fresh_var_t t) in nat return λ_:ℕ.bool
                   with [O⇒false|S (q:ℕ)⇒leb nx q]);
             change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
             change with (leb (S ?) ?) in match ( match  max (S nx) (max (fresh_var_t t1) (fresh_var_t t)) in nat return λ_:ℕ.bool
                   with [O⇒false|S (q:ℕ)⇒leb ny q]);
             change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
             >(max_comm (fresh_var_t t1) (fresh_var_t t)) in match ((free_occ_t (νny) t1)*free_occ_t (ν(max (S ny) (max (S nx) (max (fresh_var_t t1) (fresh_var_t t))))) t);
             >(max_swap (S nx) (fresh_var_t t) (fresh_var_t t1))
             >(max_swap (S ny) (fresh_var_t t) (max (S nx) (fresh_var_t t1)))
             >(max_swap (S nx) (fresh_var_t t1) (fresh_var_t t))
             >(max_swap (S ny) (fresh_var_t t1) (max (S nx) (fresh_var_t t)))
             /2/ |>Hfva >Htf normalize /2/
          ]
      ]
    ]
  ]
| 7,8: normalize in p; lapply p /2/
| @foo #k #k_def lapply HH lapply H elim s #y #t'
  whd in match (match psubst y t' in pifSubst return λ_:pifSubst.Variable with 
    [psubst (x0:Variable)   (t0:pifTerm)⇒x0]) in ⊢ %;
  whd in match (match psubst y t' in pifSubst return λ_:pifSubst.pifTerm with 
    [psubst (x0:Variable)   (t0:pifTerm)⇒t0]) in ⊢ %;
  -H #H -HH #HH lapply (gtb_O (free_occ_t x t')) normalize in HH;
  lapply HH -HH #HH #HHH lapply(HHH HH) -HH -HHH #HH * #Hk_size #Hfok
  whd in match (t_size (val_to_term ?));
  whd in match (t_size (val_to_term ?));
  whd in match (free_occ_v y (abstr x t1));
  >H %
  [ >Hk_size normalize //
  | #z normalize cut ( veqb z x = true ∨ veqb z x = false) // * #Hzx >Hzx
    [ normalize lapply (veqb_true_to_eq z x) * #Heq #_ lapply (Heq Hzx)
      -Heq -Hzx #Heq destruct >HH >H normalize //
    | normalize >(Hfok z) //
    ]
  ]
| 10,11: normalize in p; /3/
| @foo #k #k_def
  @foo #j #j_def
  elim s #y #t'
  whd in match (match psubst y t' in pifSubst return λ_:pifSubst.Variable with 
    [psubst (x0:Variable)   (t0:pifTerm)⇒x0]) in ⊢ %;
  whd in match (match psubst y t' in pifSubst return λ_:pifSubst.pifTerm with 
    [psubst (x0:Variable)   (t0:pifTerm)⇒t0]) in ⊢ %;
  * #Hj_size #Hfoj * #Hk_size #Hfok %
  [ normalize >Hk_size >Hj_size cases ((t_size t'-1)) normalize //
  | #z normalize >(Hfoj z) >(Hfok z) normalize
    cut (veqb y z= true ∨ veqb y z= false) // * #Hyz >Hyz normalize //
  ]
]
qed.

definition pif_subst ≝ λt.λs. pi1 … (pif_subst_sig (t_size t) s t ?).// qed.
definition pif_subst_v ≝ λv.λs. pi1 … (pif_subst_sig (t_size (val_to_term v)) s (val_to_term v) ?).// qed.

(*
let rec c_size c on c ≝
 match c with
 [ CCrumble b e ⇒ c_size_b b + c_size_e e ]

and

c_size_b b on b ≝
 match b with
 [ CValue v ⇒ c_size_v v
 | AppValue v w ⇒ c_size_v v + c_size_v w
 ]

and

c_size_e e on e ≝
 match e with
 [ Epsilon ⇒ O
 | Cons e s ⇒ S (c_size_e e)
 ]

and

c_size_v v on v ≝
 match v with
 [ var x ⇒ O
 | lambda x c ⇒ c_size c
 ]
 .*)

let rec c_size c on c ≝
 match c with
 [ CCrumble b e ⇒ S (c_size_b b + c_size_e e) ]

and

c_size_b b on b ≝
 match b with
 [ CValue v ⇒ c_size_v v
 | AppValue v w ⇒ S (c_size_v v + c_size_v w)
 ]

and

c_size_e e on e ≝
 match e with
 [ Epsilon ⇒ O
 | Cons e s ⇒(c_size_e e) + c_size_s s
 ]

and

c_size_v v on v ≝
 match v with
 [ var x ⇒ S O
 | lambda x c ⇒ S (c_size c)
 ]

and

c_size_s s on s ≝
 match s with
 [ subst x b ⇒ S (c_size_b b)]
 .

let rec c_len_e e on e ≝ match e with [Epsilon ⇒ O | Cons e s ⇒ 1 + c_len_e e].

let rec c_len c on c ≝
 match c with
 [ CCrumble b e ⇒ c_len_e e].

let rec e_pop e on e ≝
 match e with
 [ Epsilon ⇒ e
 | Cons e s ⇒ e
 ]
 .

let rec fv_pt x t on t≝
 match t with
 [ val_to_term v ⇒ fv_pv x v
 | appl t1 t2 ⇒  orb (fv_pt x t1) (fv_pt x t2)
 ]

and fv_pv x v on v ≝
 match v with
 [ pvar y ⇒ veqb x y
 | abstr y t ⇒ if veqb x y then false else fv_pt x t
 ]
 .

lemma env_len: ∀e: Environment. (e = Epsilon → False ) →  S (c_len_e (e_pop e))=(c_len_e e).
#e cases e [ normalize #Abs cut False [ cut (Epsilon=Epsilon) [ //| @Abs] | #Abs
@False_ind] @Abs | #e1 #s #H1 normalize //] qed.

(* Definizione 1: naïve, restituisce il clasico errore: *)
(* NTypeChecker failure: Recursive call (read_back_b b), b is not smaller.

let rec read_back x on x ≝
 match x with
 [ CCrumble b e ⇒ match e with
                  [ Epsilon ⇒ read_back_b b
                  | Cons e1 s ⇒ match s with [ subst x' b1 ⇒ pif_subst (read_back 〈b, e1〉) (psubst x' (read_back_b b1))]
                  ]
 ]

and

read_back_b b ≝
 match b with
 [ CValue v ⇒ read_back_v v
 | AppValue v w ⇒ appl (read_back_v v) (read_back_v w)
 ]

and

read_back_v v ≝
 match v with
 [ var x ⇒ val_to_term (pvar x)
 | lambda x c ⇒ val_to_term (abstr x (read_back c))
 ]
 .
*)

(* Definizione 2: come da lei consigliato, spezzo la read_back c in read_back b e *)
(* in modo che l'induzione su e mi assicuri la diminuzione della dimensione del termine*)
(* purtroppo però, la chiamata ricorsiva sul byte non mi assicura che la dimensione diminuisca*)
(* suppongo che questo sia dovuto al fatto che un byte può a sua volta contenere un  *)
(* crumble la cui dimensione è arbitraria *)


let rec aux_read_back rbb e on e ≝
 match e with
 
 [ Epsilon ⇒ rbb
 | Cons e1 s ⇒ match s with [ subst x' b1 ⇒ pif_subst (aux_read_back rbb e1) (psubst x' (read_back_b b1))]
 ]

and

read_back_b b ≝
 match b with
 [ CValue v ⇒ read_back_v v
 | AppValue v w ⇒ appl (read_back_v v) (read_back_v w)
 ]

and

read_back_v v ≝
 match v with
 [ var x ⇒ val_to_term (pvar x)
 | lambda x c ⇒ match c with
                [ CCrumble b e ⇒ val_to_term (abstr x (aux_read_back (read_back_b b) e))]
 ]
 .

let rec read_back c on c ≝
 match c with
 [ CCrumble b e ⇒ aux_read_back (read_back_b b) e]
 .

(* Definizione 3: ragionevolmente giusta, ma dà il seguente errore: read_back_b b *)
(* is not smaller. Faccio fatica a capirne il motivo, perché il fatto che la *)
(* lunghezza degli environment dei crumble di livello più esterno diminuisca ad *)
(* ogni chiamata, dovrebbe assicurare la terminazione, ma suppongo anche *)
(* che Matita si aspetti che le chiamate per induzione sulla dimensione di *)
(* un termine abbiano come taglia un intero sempre decrescente, cosa che, con *)
(* la definizione di taglia data da c_len non si verifica. L'errore, dunque, *)
(* dovrebbe somigliare a quello del punto precedente.
*)

(*
let rec read_back (n: nat) : Πc: Crumble. c_len c = n → pifTerm ≝
 match n return λn.Πc: Crumble. c_len c = n → pifTerm with
 [ O ⇒ λc. match c return λc.c_len c = O → pifTerm with
          [ CCrumble b e ⇒ λp.(read_back_b b)]
 | S m ⇒ λc. match c return λc.c_len c = S m → pifTerm with
    [ CCrumble b e ⇒ match e with
        [ Epsilon ⇒  λabs.(read_back_b b)
        | Cons e1 s ⇒ λp.match s with [ subst x' b1 ⇒ pif_subst (read_back m 〈b, e_pop e〉 ?) (psubst x' (read_back_b b1))]
        ]
    ]
 ]

and

read_back_b b ≝
 match b with
 [ CValue v ⇒ read_back_v v
 | AppValue v w ⇒ appl (read_back_v v) (read_back_v w)
 ]

and

read_back_v v ≝
 match v with
 [ var x ⇒ val_to_term (pvar x)
 | lambda x c ⇒ val_to_term (abstr x (read_back (c_len c) c (refl …)))
 ]
 .

lapply p
normalize cases e normalize [ #H destruct | #e1 #s1 // ]
qed.
*)

(* Definizione 4: provo a definire una funzione size più accurata: la taglia *)
(* di un crumble equivale alla lunghezza ti tutti gli environment in esso *)
(* annidati ney byte al primo membro. In questo modo dovrei riuscire ad evitare l'errore perché *)
(* la suddetta definizione mi garantirebbe la diminuzione della taglia del *)
(* termine ad ogni chiamata ricorsiva. Ma quando vado a fornire la dimostrazione *)
(* mi si solleva un altro problema: come faccio ad esprimere il fatto che e = Cons e1 s ?
*)
(*

let rec read_back (n: nat) : Πc: Crumble. c_size c = n → pifTerm ≝
 match n return λn.Πc: Crumble. c_size c = n → pifTerm with
 [ O ⇒ λc.λabs. ?
 | S m ⇒ λc. match c return λc.c_size c = S m → pifTerm with
    [ CCrumble b e ⇒ match e return λe. c_size (CCrumble b e) = S m → pifTerm with

        [ Epsilon ⇒  λp.(read_back_b (m) b (?))
        | Cons e1 s ⇒ match s return λs. c_size (CCrumble b (Cons e1 s)) = S m → pifTerm with [ subst x' b1 ⇒ λp. pif_subst (read_back ((S m) - (c_size_s [x'← b1])) 〈b, e1〉 ?) (psubst x' (read_back_b (m - c_size 〈b, e1〉) b1 ?))]
        ]
    ]
 ]


and

read_back_b (n: nat): Πb: Byte. c_size_b b = n → pifTerm ≝
 match n return λn.Πb: Byte. c_size_b b = n → pifTerm with
 [ O ⇒ λb. match b return λb. c_size_b b = O → pifTerm with
    [ CValue v ⇒ λp. read_back_v (c_size_v v) v (refl …)
    | AppValue v w ⇒ λabs. ?
    ]
 | S m ⇒ λb. match b return λb. c_size_b b = S m → pifTerm with
    [ CValue v ⇒ λp. read_back_v (c_size_v v) v (refl …)
    | AppValue v w ⇒ λp. appl (read_back_v (c_size_v v) v (refl …)) (read_back_v (c_size_v w) w (refl …))
    ]
 ]

and

read_back_v (n: nat): Πv: Value. c_size_v v = n → pifTerm≝
 match n return λn.Πv: Value. c_size_v v = n → pifTerm with
 [ O ⇒ λv. match v return λv. c_size_v v = O → pifTerm with
     [ var x ⇒ λp.val_to_term (pvar x)
     | lambda x c ⇒ λp.val_to_term (abstr x (read_back (c_size c) c (refl …)))
     ]
 | S m ⇒ λv. match v return λv. c_size_v v = S m → pifTerm with
     [ var x ⇒ λp. val_to_term (pvar x)
     | lambda x c ⇒ λp. val_to_term (abstr x (read_back (c_size c) c (refl …)))
     ]
 ]

 .


(*
[lapply p normalize cases (c_size_b b) [ normalize // | #n cases (c_size_e e1) [
#H // | #p #H cut (S ((S n)+(S p))=S m) [ // | @succ_eq] ] ]  qed.
*)
[ lapply abs cases c #b #e normalize cases (b) [ #v cases (v)[ #x normalize #abs
destruct | #x #d normalize #abs destruct] | #v #w normalize #abs destruct ]
| lapply p normalize //
| normalize in p; destruct normalize cases (c_size_b b1)
 [ normalize // | #q normalize /2/]
|  lapply p normalize #H destruct /2/
| normalize in abs; destruct] qed.
*)
(*
lemma value_lemma: ∀v: pifValue. read_back_v (overline v) = val_to_term v.
#v cases v
 [ #x normalize //
 | #x #t elim x #nx cases nx
  [ normalize cases t [ normalize #v'
*)
(*
lemma c4: ∀e: Environment. ∀x:Variable. ((has_member (dom_list e) x) = false)  → ((has_member (fv_env e) x) = false) →
          ∀c: Crumble. ∀b: Byte. read_back (at c (push e [x←b]))= pif_subst (read_back (at c e)) (psubst x  (read_back 〈b, e〉)).
#e #x #H1 #H2 #c #b elim c
*)

definition ol ≝ λv. fst Value nat (overline v (fresh_var_tv v)).
definition ul ≝ λt. fst Crumble nat (underline_pifTerm t (fresh_var_t t)).

lemma veqb_trans: ∀x,y,z. (veqb x y) = true → (veqb y z) = true → (veqb x z)=true.
#x #y #z lapply ((veqb_true_to_eq x y)) #H1 lapply ((veqb_true_to_eq y z)) #H2
#H3 #H4 normalize in H1; normalize in H2; cut (x=z)
[ @(And_ind … H1) #H1' #H1'' -H1 @(And_ind … H2) #H2' #H2'' -H2 lapply (H1' H3) lapply (H2' H4) //
| #H destruct -H1 -H2 -H3 -H4 elim z #nz normalize //] qed.

lemma veqb_simm: ∀x,y. (veqb x y) = veqb y x.
#x #y elim x #nx elim y #ny normalize /2/ qed.

lemma veqb_fv: ∀x,z.∀t. veqb x z =true →  fvb_t x t = fvb_t z t.
#x #z #t #h lapply (veqb_true_to_eq x z) normalize #H @(And_ind … H) -H
#H' #H'' lapply (H' h) #Heq destruct //. qed.

lemma if_id_f: if false then true else false = false. // qed.
lemma if_id_t: if true then true else false = true. // qed.

lemma if_not_t: if true then false else true = false. // qed.
lemma if_not_f: if false then false else true = true. // qed.
lemma if_then_false_else_false: ∀b. if b then false else false = false. #b cases b // qed. 
(*
lemma fv_lemma:
 (∀c.∀x. fvb x c = fvb_t x (read_back c)) ∧
  (∀b.∀x. fvb_b x b = fvb_t x (read_back_b b)) ∧
   (∀e.∀b.∀x. fvb_b x b = fvb_t x (read_back_b b) → fvb x 〈b, e〉 = fvb_t x (read_back 〈b,e〉)) ∧
    (∀v.∀x. fvb_v x v = fvb_t x (read_back_v v)) ∧
     (∀s.∀b.∀e.∀x. (fvb_s x s=false) → fvb_b x b = fvb_t x (read_back_b b) →  fvb x 〈b, (Cons e s)〉 = fvb_t x (read_back 〈b, (Cons e s)〉)).
     
@Crumble_mutual_ind
[ #b #e #H1 #H2 #x lapply (H1 x) lapply (H2 b x) /2/
| #v #H normalize assumption
| #v #w #H1 #H2 #x normalize >(H1 x) >(H2 x) normalize
  cases (free_occ_t x (read_back_v v)) cases (free_occ_t x (read_back_v w)) normalize //
| #x #y normalize cases (veqb y x) //
| #x #c cases c #b #e normalize #H #y lapply (H y) >(veqb_comm y x) elim (veqb x y) normalize
 [ #Hinutile  // | #Hutile @Hutile]
| #b #x normalize #H <H cases (fvb_b x b) //
| #e #s #H1 #H2 #b #x #H3 lapply (H1 b x) lapply (H2 b e x) -H1 -H2 cases s #y #b1
  normalize in ⊢  ((% → ?) → ?) ; #H1 #H2 normalize @foo
  #z #z_def * #_ #z_prop lapply (z_prop x) #z_propx >z_propx -z_propx
  cut (veqb x y = true ∨ veqb x y =false) // *
  [ #Heq lapply (veqb_true_to_eq x y)
    * #Heq1 #_ lapply(Heq1 Heq) -Heq -Heq1 #Heq destruct lapply (H2 H3) cut (veqb y y=true)
    [ @(eq_to_veq …) // | #Hbanale >Hbanale normalize >if_then_false_else_false
      normalize >if_then_false_else_false normalize -H2 #H2 lapply (z_prop y) * 
      >Hbanale in H1; normalize #H1 
    | @foo #z #z_def #z_prop  #Hf @foo
  normalize #H1 #H2 @(H1 H3)
| #x #b #H #b' #e #y  cases x #nx cases y #ny  normalize @foo #z #z_def #z_prop
  normalize #H1 cut (neqb ny nx=true ∨ neqb nx ny=false) // * #Htf
  [ lapply H1 lapply (neqb_iff_eq ny nx) * #H2 #_ lapply (H2 Htf) -H2 -Htf #Heq >Heq 
    lapply (rifle_neqb … nx) #Heq1 >Heq1 normalize -H1 #H1 >(if_then_false_else_false …)
    normalize >(if_then_false_else_false …) normalize (lapply z_prop) * #_ #Hz
    lapply  (Hz νnx) -Hz #Hz >Hz normalize >Heq1 normalize lapply (H νnx) -H #H >H
     normalize
 [ #v

lemma fv_push_e: ∀e, x, b. fresh_var_e (push e [νx ← b]) = max (max (fresh_var_e e) (S x)) (fresh_var_b b).

<<<<<<< HEAD
#e #x #b cases e
[ normalize //
| #e #s normalize change with (max ? ?) in match (if ? then ? else ?);
*)
=======
<<<<<<< HEAD
>>>>>>> edd9902... progress
lemma four_dot_two:  
    (∀t.∀s. (s ≥ fresh_var_t t) → read_back (fst ?? (underline_pifTerm t s)) = t ∧
      (snd ?? (underline_pifTerm t s) + s ≥ (fresh_var (fst ?? (underline_pifTerm t s))))) ∧
    (∀v.∀s. (s ≥ fresh_var_tv v) →read_back_v (fst ?? (overline v s)) = val_to_term v ∧
      ((snd ?? (overline v s)) + s ≥ fresh_var_v (fst ?? (overline v s)))).
      
@(pifValueTerm_ind (λt.∀s. (s ≥ fresh_var_t t) → read_back (fst ?? (underline_pifTerm t s)) = t ∧
      (snd ?? (underline_pifTerm t s) + s ≥ (fresh_var (fst ?? (underline_pifTerm t s))))) 
      (λv.∀ s. (s ≥ fresh_var_tv v) →read_back_v (fst ?? (overline v s)) = val_to_term v ∧
      ((snd ?? (overline v s)) + s ≥ fresh_var_v (fst ?? (overline v s)))))
[ #v normalize in match (fresh_var_tv ?); @foo #z #z_def #z_prop #HI #s #Hsz lapply (HI s Hsz)
 -HI -Hsz * normalize cases (overline v s) #vv #nn normalize #H1 #H2 % // lapply H2
 cases (fresh_var_v vv) normalize //
| #t1 #t2 cases t2 #v2
  [ cut (t1=t1) // #Ht1 
    cases t1  
    [ #v1 normalize @foo #zv1 #zv1_def #zv1_prop @foo #zv2 #zv2_def #zv2_prop #H1 #H2 
      #s lapply (H1 s) cases (overline v1 s) #vv #n -H1 #H1 normalize lapply (H2 (s+n))
      cases (overline v2 (s+n)) #ww #m -H2 #H2 change with (max ? ?) in match (if ? then ? else ?);
      #Hmax lapply (le_maxl … Hmax) lapply (le_maxr … Hmax) -Hmax lapply H2 lapply H1
      normalize -H1 -H2 #H1 #H2 #Hzv2 #Hzv1 cut (zv2≤s+n) /2/ -Hzv2 #Hzv2
      lapply (H2 Hzv2) lapply (H1 Hzv1) -H1 -H2 #H1 #H2
      change with (max ? ?) in match (if ? then ? else ?);
      change with (max (max ? ?) ?) in match (max (if leb ? ? then ? else ?) ?);
      change with (max ? ?) in match (if ? then ? else ?) in H1;
      change with (max ? ?) in match (if ? then ? else ?) in H2;
      >(max_O ?) >(max_O ?) in H2; >(max_O ?) in H1; * #H1a #H1b * #H2a #H2b
      >H1a >H2a % // @(to_max …) /2/
      #s
    | #u1 #u2 normalize @foo #zu1 #zu1_def #zu1_prop normalize @foo #zu2 #zu2_def #zu2_prop
      @foo #zv2 #zv2_def #zv2_prop normalize #Hu1u2 #Hv2 #s lapply (Hu1u2 s) 
      change with (underline_pifTerm (appl u1 u2) s) in match 
      (match u2 in pifTerm return λ_:pifTerm.(Crumble×ℕ) with 
                 [val_to_term (v20:pifValue)⇒
                  match u1 in pifTerm return λ_:pifTerm.(Crumble×ℕ) with 
                  [val_to_term (v1:pifValue)⇒
                   let 〈vv,n〉 ≝overline v1 s in 
                   let 〈ww,m〉 ≝overline v20 (s+n) in 〈〈AppValue vv ww,Epsilon〉,m+n〉
                  |appl (u10:pifTerm)   (u20:pifTerm)⇒
                   let 〈c,n〉 ≝underline_pifTerm u1 s in 
                   match c in Crumble return λ_:Crumble.(Crumble×ℕ) with 
                   [CCrumble (b:Byte)   (e:Environment)⇒
                    let 〈vv,m〉 ≝overline v20 (s+n) in 
                    〈〈AppValue (var ν(s+n+m)) vv,push e [ν(s+n+m)←b]〉,S (s+n+m)〉]]
                 |appl (u10:pifTerm)   (u20:pifTerm)⇒
                  let 〈c,n〉 ≝underline_pifTerm u2 s in 
                  match c in Crumble return λ_:Crumble.(Crumble×ℕ) with 
                  [CCrumble (b1:Byte)   (e1:Environment)⇒
                   match u1 in pifTerm return λ_:pifTerm.(Crumble×ℕ) with 
                   [val_to_term (v1:pifValue)⇒
                    let 〈vv,m〉 ≝overline v1 (s+n) in 
                    〈〈AppValue vv (var ν(s+n+m)),push e1 [ν(s+n)←b1]〉,S n〉
                   |appl (u100:pifTerm)   (u200:pifTerm)⇒
                    let 〈c1,n1〉 ≝underline_pifTerm u1 (s+n) in 
                    match c1 in Crumble return λ_:Crumble.(Crumble×ℕ) with 
                    [CCrumble (b:Byte)   (e:Environment)⇒
                     〈〈AppValue (var ν(s+n+n1)) (var ν(S (s+n+n1))),
                      concat (push e1 [ν(s+n+n1)←b1]) (push e [ν(S (s+n+n1))←b])〉,
                     S (S (s+n+n1))〉]]]]);
        cases (underline_pifTerm (appl u1 u2) s) #c #n -Hu1u2 lapply (Hv2 (s+n))
        normalize cases c #b #e cases (overline v2 (s+n)) #vv #m normalize
        change with (max ? ?) in match (if leb ? ? then ?  else ?);
        change with (max ? ?) in match (if leb zu1 zu2 then zu2 else zu1 );
        change with (max ? ?) in match (if leb (max zu1 zu2) zv2 then zv2 else max zu1 zu2);
        change with (leb (S ?) ?) in match (match fresh_var_v vv in nat return λ_:ℕ.bool with 
                [O⇒false|S (q:ℕ)⇒leb (s+n+m) q]);
        change with (max ? ?) in match (if leb ? ? then ?  else ?);
        change with (max ? ?) in match (if leb (S (s+n+m)) (fresh_var_v vv) then fresh_var_v vv else S (s+n+m));
        change with (max ? ?) in match (if leb (max (S (s+n+m)) (fresh_var_v vv))
          (fresh_var_e (push e [ν(s+n+m)←b])) 
     then fresh_var_e (push e [ν(s+n+m)←b]) 
     else max (S (s+n+m)) (fresh_var_v vv));
        change with (max ? ?) in match (if leb (fresh_var_b b) (fresh_var_e e) 
      then fresh_var_e e 
      else fresh_var_b b);
        #Hv2 #Hu1u2 #Hmax lapply (le_maxl … Hmax) lapply (le_maxr … Hmax)
        #Hmax1 #Hmax2 lapply (Hu1u2 Hmax2) -Hu1u2 * #Hu1u21 #Hu1u22
        cut (zv2 ≤ s+n) /2/ -Hmax1 -Hmax2 -Hmax #Hmax lapply (Hv2 Hmax)
        -Hv2 * #Hv21 #Hv22 %
        [
        | @(to_max …) [@(to_max …) /2/ | normalize lapply Hu1u22
          @(Environment_simple_ind2 … e)
          [ normalize change with (leb (S ?) ?) in match (match fresh_var_b b in nat return λ_:ℕ.bool with 
              [O⇒false|S (q:ℕ)⇒leb (s+n+m) q]);
            change with (max ? ?) in match(if ? then ? else ?);
            change with (max ? ?) in match (if leb (S (s+n+m)) (fresh_var_b b) then fresh_var_b b else S (s+n+m));
            #HI @(to_max ? ?) // lapply (le_maxl … HI) /2/
          | #e' #s' #HI #H1 lapply (le_maxl … H1) #H2 lapply (le_maxr … H1) -H1 #H1
            lapply (le_maxl … Hu1u22) #H3 lapply (le_maxr … Hu1u22) #H4 -Hu1u22
            normalize normalize in H1; change with (max ? ?) in match (if ? then ? else ?) in H1;
            lapply (le_maxl … H1) #H5 lapply (le_maxr … H1) -H1 #H1
            cut (max (fresh_var_b b) (fresh_var_e e')≤n+s)
            [ @(to_max …) //
            | #H6 lapply (HI H6) -HI #HI cases (leb (fresh_var_e (push e' [ν(s+n+m)←b])) (fresh_var_s s'))
              normalize /2/
            ]
          ]  ]
        ]
        
    
      
  
(*
lemma pif_subst_fv_lemma:
 (∀t.∀x.∀t'.∀y. fvb_t y (pif_subst (t) (psubst x t')) = ((fvb_t x t) ∧ (fvb_t y t') ∨ (fvb_t y t) ∧ ¬(veqb x y))) ∧
  (∀v. ∀x. ∀t'.∀y. fvb_t y (pif_subst_v v (psubst x t')) = ((fvb_tv x v) ∧ (fvb_t y t') ∨ (fvb_tv y v)∧ ¬(veqb x y))).


@pifValueTerm_ind
[ #pV #H assumption
| #t1 #t2 #H1 #H2 #x #t' #y normalize @foo #z #z_def #z_prop lapply(H1 x t' y)  >(H2 x t' y) cases (fvb_t y t2) cases (fvb_t y t1) cases (fvb_t y t') cases (fvb_t x t1) cases (fvb_t x t2) cases (veqb x y) normalize //
| #z #x #t' #y cut (veqb x z=true ∨ veqb x z=false) // cut (veqb y z=true ∨ veqb y z=false) // * #H1 * #H2
   [ lapply(veqb_true_to_eq … x z) * #Heq #_ lapply (Heq H2) -Heq #Heq destruct
     >H2 -H2 lapply (veqb_true_to_eq y z) * #Heq #_ lapply (Heq H1) -Heq #Heq
     destruct normalize >H1 normalize cases (fvb_t z t') //
   | normalize >H2 lapply(veqb_true_to_eq … y z) * #Heq #_ lapply (Heq H1) -Heq #Heq destruct >H1
     normalize >H2 normalize assumption
   | lapply(veqb_true_to_eq … x z) * #Heq #_ lapply (Heq H2) -Heq #Heq destruct
   normalize >H2 normalize >H1 normalize cases (fvb_t y t') //
   | cut (veqb x y = true ∨ veqb x y =false) // * #H3
     [ lapply (veqb_true_to_eq … x y) * #Heq #_ lapply (Heq H3) -Heq #Heq destruct
     normalize >H2 >H3 normalize assumption
     | normalize >H1 >H2 >H3 normalize assumption
   ]
   ]
| #t #z #H1 #x #t' #y normalize cut (veqb x z = true ∨ veqb x z= false) // * #Hxz
  >Hxz normalize  cut (veqb x y = true ∨ veqb x y= false) // * #Hxy >Hxy normalize
  [ lapply (veqb_true_to_eq … x y) * #Heq #_ lapply (Heq Hxy) -Heq #Heq destruct
    lapply (veqb_true_to_eq … y z) * #Heq #_ lapply (Heq Hxz) -Heq #Heq destruct
    >Hxz normalize //
  | lapply (veqb_true_to_eq … x z) * #Heq #_ lapply (Heq Hxz) -Heq #Heq destruct
    >(veqb_simm y z) >Hxy normalize cases (fvb_t y t) //
  | lapply (veqb_true_to_eq … x y) * #Heq #_ lapply (Heq Hxy) -Heq #Heq destruct
    >Hxz normalize cut (fvb_t z t =true ∨ fvb_t z t=false) // * #Hfvzt >Hfvzt
    normalize


lemma fv_lemma:
 (∀c.∀x. fvb x c = fvb_t x (read_back c)) ∧
  (∀b.∀x. fvb_b x b = fvb_t x (read_back_b b)) ∧
   (∀e.∀b.∀x. fvb_b x b = fvb_t x (read_back_b b) → fvb x 〈b, e〉 = fvb_t x (read_back 〈b,e〉)) ∧
    (∀v.∀x. fvb_v x v = fvb_t x (read_back_v v)) ∧
     (∀s.∀b.∀e.∀x. fvb_b x b = fvb_t x (read_back_b b) →  fvb x 〈b, (Cons e s)〉 = fvb_t x (read_back 〈b, (Cons e s)〉)).

@Crumble_mutual_ind
[ #b #e #H1 #H2 #x lapply (H1 x) lapply (H2 b x) /2/
| #v #H normalize assumption
| #v #w #H1 #H2 #x normalize >(H1 x) >(H2 x) //
| #x #y normalize //
| #x #c cases c #b #e normalize #H #y lapply (H y) >(veqb_comm y x) elim (veqb x y) normalize
 [ #Hinutile  // | #Hutile @Hutile]
| #b #x normalize #H <H cases (fvb_b x b) //
| #e #s #H1 #H2 #b #x #H3 @(H2 b e x) //
| #x #b #H #b' #e #y #H1  normalize cases e normalize cases (read_back_b b')
 [ #v



lemma fesh_lemma:
 (∀c. fresh_var c = fresh_var_t (read_back c)) ∧
  (∀b. fresh_var_b b = fresh_var_t (read_back_b b)) ∧
   (∀e.∀b. fresh_var 〈b, e〉 = fresh_var_t (read_back 〈b,e〉)) ∧
    (∀v. fresh_var_v v = fresh_var_t (read_back_v v)) ∧
     (∀s.∀b.∀e. fresh_var 〈b, (Cons e s)〉 = fresh_var_t (read_back 〈b, (Cons e s)〉)).

@Crumble_mutual_ind
[ #b #e #H1 #H2 lapply (H2 b) -H2 #H2 assumption
| #v #H normalize assumption
| #v #w #H1 #H2 normalize change with (max ? ?) in match  (if ? then ? else ?) in ⊢ % ;
  change with (max ? ?) in match (if leb (fresh_var_t (read_back_v v)) (fresh_var_t (read_back_v w))  then ? else ? ) in ⊢%;
  >H1 >H2 //
| #x normalize //
| #x #c elim x #nx cases c #b #e normalize change with (max ? ?) in match  ( if leb (fresh_var_b b) (fresh_var_e e)  then ? else ?) in ⊢ % ;
  #H >H //
| #b normalize change with (max ? ?) in match  ( if ? then ? else ?) in ⊢ %; >max_O
 [ #v normalize cases v
  [ #x normalize //
  | #x #c elim x #nx cases c #b #e normalize change with (max ? ?) in match  ( if leb ? ? then ? else ?) in ⊢ %;

   #s #H1 #H2 #b @ (H2 b e)
| #x #b #H #b #e normalize
 #b normalize cases b
 [#v normalize change with (max ? ?) in match  ( if ? then ? else ?) in ⊢ %; >max_O cases v #x normalize //
  #c elim x #nx normalize cases c #b #e change with (max ? ?) in match  ( if leb (fresh_var_b b) (fresh_var_e e)  then ? else ?) in ⊢ % ;
  normalize
  change with (fresh_var_v (lambda (ν?) 〈?, ? 〉)) in match  ( if ? then ? else ?) in ⊢ %;
  change with (fresh_var_tv (abstr (ν?) 〈?, ? 〉)) in match  ( if ? then ? else ?) in ⊢ %;
  case


lemma value_lemma:
  ∀v: pifValue. ∀ n. n ≥ fresh_var_tv v →
  match (overline v n) with
   [ mk_Prod v' m ⇒ (read_back_v v') = (val_to_term v) ∧ (m + n ≥ (fresh_var_v v')) ].

#v @(pifValue_ind … v)
[ @(λt. ∀n. n ≥ fresh_var_t t →
  match (underline_pifTerm t n) with
  [ mk_Prod c m ⇒ read_back c = t ∧ m+n ≥ fresh_var c])
| #v0 cases v0 (*devo dimostrare per ogni v0*)
 [#x elim x #nx normalize /2/
 | #x elim x #nx #t normalize #HI #m lapply (HI m ) cases (underline_pifTerm t m)
   #c #fv_c normalize cases c #b #e normalize
   change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
   change with (leb (S ?) ?) in match ( match max (fresh_var_b b) (fresh_var_e e) in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb nx q]);
   change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
   change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
   @foo #z #z_def #z_prop
   change with (leb (S ?) ?) in match ( match  z in nat return λ_:ℕ.bool
                 with [O⇒false|S (q:ℕ)⇒leb nx q]);
   change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
   #H1 #H2 lapply (H1 H2) * -H1 #H1 #H3  % /2/
   ]
| #t1 #t2 cases t2
 [ #v2 cases t1
  [ #v1 normalize #H1 #H2 #n lapply (H1 n) cases (overline v1 n) #vv #m lapply (H2 (n+m)) normalize
    cases (overline v2 (n+m)) #ww #mm normalize
    change with (max ? ?) in match  (if ? then ? else ?) in ⊢ % ;
    change with (max ? ?) in match  (if leb (fresh_var_v vv) (fresh_var_v ww)  then ? else ?) in ⊢ % ;
    change with (max ? ?) in match  (if leb (max (fresh_var_v vv) (fresh_var_v ww)) O then ? else ?)  in ⊢ % ;
    >max_O >max_O
    @foo #z #z_def #z_prop #Hz
    @foo #y #y_def #y_prop #Hy
    change with (max ? ?) in match  (if ? then ? else ?) in Hy ;
    >max_O in Hy;
    #Hy change with (max ? ?) in match  (if ? then ? else ?) in ⊢ % ;
    #Hmax lapply (le_maxl … Hmax) #Hyhead lapply (le_maxr … Hmax) #Hzhead
    cut (z≤n+m) /2/ -Hzhead #Hzhead lapply(Hz Hzhead) * -Hz -Hzhead #Hz1 #Hz2
    lapply(Hy Hyhead) * -Hy -Hyhead #Hy1 #Hy2 %
    [ >Hz1 >Hy1 // | normalize cases (leb (fresh_var_v vv) (fresh_var_v ww))
      normalize /2/]
  | #u1 #u2  #H1 #H2 #n lapply (H1 n) whd in match (underline_pifTerm ? ?) in ⊢ (? → %); -H1 cases (underline_pifTerm (appl u1 u2) n)
#c #m normalize lapply (H2 (n+m)) cases (overline v2 (n+m)) #vv #mm
change with (max ? ?) in match  (if leb ? ? then ? else ?) in ⊢ % ;
change with (max ? ?) in match (if leb (max ? ?) ? then ? else ?) in ⊢ %; -H2
@foo #z #z_def #z_prop
@foo #y #y_def #y_prop
@foo #w #w_def #w_prop #H2 #H1 #H3
change with (fresh_var_t (appl ? ?)) in match (max (fresh_var_t ?) (fresh_var_t ?)) in H3;
change with (fresh_var_t (val_to_term ?)) in match (fresh_var_tv ?) in H3;
change with (fresh_var_t (appl ? ?)) in match (max (fresh_var_t ?) ?) in H3;
lapply H1 cases c #b #e -H1 #H1 whd in ⊢ %;
whd in match (read_back ?) ; % [ | lapply (le_maxl … H3) #H4 lapply (le_maxr … H3) -H3
lapply (H1 H4) -H1 #H1 #H3 lapply(le_maxl … H4) #H5 lapply(le_maxr … H4) -H4 #H4
lapply H1 * #_ -H1 #H1 normalize
change with (leb (S ?) ?) in match (match fresh_var_v vv in nat return λ_:ℕ.bool with 
             [O⇒false|S (q:ℕ)⇒leb (n+m+mm) q]) in ⊢ %;
change with (max ? ?) in match  (if ? then ? else ?) in ⊢ % ;
    change with (max ? ?) in match (if leb (S (n+m+mm)) (fresh_var_v vv) then fresh_var_v vv else S (n+m+mm)) in ⊢ % ;
 normalize
change with (max ? ?) in match  (if ? then ? else ?) in ⊢ % ;
change with (?) in match (match fresh_var_v vv in nat return λ_:ℕ.bool with 
         [O⇒false|S (q:ℕ)⇒leb (n+m+mm) q]) in ⊢ %;
 cases (fresh_var_v vv) normalize

lemma term_lemma:
 ∀t: pifTerm. ∀n. n= fresh_var_t t →
  match (underline_pifTerm t n) with
  [ mk_Prod c m ⇒ read_back c = t ∧ m+n=fresh_var c].
#t @(pifTerm_ind … t)
[ @(λv.∀ n. n = fresh_var_tv v →
  match (overline v n) with
   [ mk_Prod v' m ⇒ (read_back_v v') = (val_to_term v) ∧ (m + n = (fresh_var_v v')) ])
| (*#v cases v [ #x  #Hv normalize cases x #nx normalize /2/
 | #x #t1 elim x #nx normalize cases (fresh_var_t t1)
  [ normalize #H #n #Hn cases (underline_pifTerm t1 n) #c #m normalize*)
| #t1 #t2 #Hind1 #Hind2 #n #Hn cases (underline_pifTerm (appl t1 t2)) #c #m
 normalize


lemma value_lemma: ∀v: pifValue. read_back_v (ol v) = val_to_term v.
#v @(pifValue_ind … v)
[ @(λt. (read_back (ul t) = t))
| #v0 #Hind normalize lapply Hind cases v0
 [ #x normalize //
 | #x #t normalize cases x normalize #n /2/
|
| #x normalize //
| #t1 #x #Hind elim x #n elim n
 [ normalize lapply Hind cases t1
  [ normalize #v #H >H //
  | #t1 #t2 cases (t1) normalize  #H




 #t1 #t2
*)
=======
lemma if_t: ∀A.∀x:A.∀y:A. if true then x else y = x.
#A #x #y normalize // qed.

lemma if_f: ∀A.∀x:A.∀y:A. if false then x else y = y.
#A #x #y normalize // qed. 
>>>>>>> c0f8d5b... progress
