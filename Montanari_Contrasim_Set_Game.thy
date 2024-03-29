theory Montanari_Contrasim_Set_Game
imports
  Simple_Game
  Montanari_Weak_Relations
  Montanari_Weak_Transition_Systems
begin

subsection \<open>The Contrasimulation Preorder Set Game\<close>

datatype ('s, 'a) c_set_game_node =
  AttackerNode 's "'s set" |
  DefenderSimNode 'a 's "'s set" |
  DefenderSwapNode 's "'s set"
                                                           
fun (in lts_tau) c_set_game_moves ::      
  \<open>('s, 'a) c_set_game_node \<Rightarrow> ('s, 'a) c_set_game_node \<Rightarrow> bool\<close> where
                             
  simulation_challenge:
   \<open>c_set_game_moves (AttackerNode p Q) (DefenderSimNode a p1 Q0) =
     (p \<Rightarrow>a p1 \<and> Q = Q0 \<and> \<not> tau a)\<close> |  

  simulation_answer:                        
    \<open>c_set_game_moves (DefenderSimNode a p1 Q) (AttackerNode p10 Q1) =   
      (p1 = p10 \<and> Q1 = succs a Q \<and> Q1 \<noteq> {})\<close> |                                             

  swap_challenge:
    \<open>c_set_game_moves (AttackerNode p Q) (DefenderSwapNode p1 Q0) =
     (p \<Rightarrow>^\<tau> p1 \<and> Q = Q0)\<close> |  

  swap_answer:
    \<open>c_set_game_moves (DefenderSwapNode p1 Q) (AttackerNode q1 P1) =   
      (q1 \<in> succs \<tau> Q \<and> P1 = {p1})\<close> |                                         

  c_set_game_moves_no_step:               
    \<open>c_set_game_moves _ _ = False\<close>

fun c_set_game_defender_node :: \<open>('s, 'a) c_set_game_node \<Rightarrow> bool\<close> where
  \<open>c_set_game_defender_node (AttackerNode _ _) = False\<close> |
  \<open>c_set_game_defender_node (DefenderSimNode _ _ _) = True\<close> |
  \<open>c_set_game_defender_node (DefenderSwapNode _ _) = True\<close>

subsection \<open>Contrasimulation Implies Winning Strategy (Completeness)\<close>

locale c_set_game =
  lts_tau trans \<tau> +
  simple_game c_set_game_moves c_set_game_defender_node initial
for
  trans :: \<open>'s \<Rightarrow> 'a \<Rightarrow> 's \<Rightarrow> bool\<close> and
  \<tau> :: \<open>'a\<close> and 
  initial :: \<open>('s, 'a) c_set_game_node\<close> 
begin

fun strategy_from_ZR_C :: \<open>('s \<Rightarrow> ('s set) \<Rightarrow> bool) \<Rightarrow> ('s, 'a) c_set_game_node strategy\<close>
  where

  \<open>strategy_from_ZR_C R ((DefenderSwapNode p1 Q)#play) = 
    (AttackerNode (SOME q1 . (\<exists>q. (q \<in> Q \<and> q  \<Rightarrow>^\<tau> q1)) \<and> R q1 {p1}) {p1})\<close> |

  \<open>strategy_from_ZR_C R ((DefenderSimNode a p1 Q)#play) = 
    (AttackerNode p1 (SOME Q1 . Q1 = succs a Q \<and> R p1 Q1 \<and> Q1 \<noteq> {}))\<close> |
 
  \<open>strategy_from_ZR_C _ _ = undefined\<close>

lemma set_defender_pred_is_attacker: 
  assumes 
    \<open>c_set_game_defender_node n0\<close>
    \<open>(n0#play) \<in> plays\<close>
    \<open>initial = AttackerNode p0 Q0\<close>
  shows \<open>\<exists>p Q. (hd play) = AttackerNode p Q \<and> c_set_game_moves (hd play) n0\<close>
proof -
  have \<open>n0 \<noteq> initial\<close> using assms (1, 3) by auto
  hence mov: \<open>c_set_game_moves (hd play) n0\<close> using assms(2)
    by (metis list.inject list.sel(1) plays.cases) 
  from assms(1) have def_cases: \<open>\<exists>p1 Q. ((\<exists>a. n0 = DefenderSimNode a p1 Q) \<or> n0 = DefenderSwapNode p1 Q)\<close>  
    using c_set_game_defender_node.elims(2) by blast
  then obtain p1 Q where pQ_def: \<open>(\<exists>a. n0 = DefenderSimNode a p1 Q) \<or> n0 = DefenderSwapNode p1 Q\<close> 
    by auto
  hence \<open>\<exists>p. (hd play) = AttackerNode p Q\<close>
  proof (rule disjE)
    assume \<open>\<exists>a. n0 = DefenderSimNode a p1 Q\<close>
    then obtain a where a_def: \<open>n0 = DefenderSimNode a p1 Q\<close> ..
    thus ?thesis using  c_set_game_moves.elims(2)[OF mov] c_set_game_node.distinct(5) by auto
  next 
    assume \<open>n0 = DefenderSwapNode p1 Q\<close>
    thus ?thesis using c_set_game_moves.elims(2)[OF mov] c_set_game_node.distinct(5) by auto
  qed
  thus ?thesis using mov by auto
qed

lemma second_elem_in_play_set : 
  assumes 
    \<open>(n0#play) \<in> plays\<close>
    \<open>initial = AttackerNode p0 Q0\<close>
    \<open>c_set_game_defender_node n0\<close>
  shows \<open>hd play \<in> set (n0 # play)\<close>
proof - 
  from assms(2, 3) have \<open>n0 \<noteq> initial\<close>by auto 
  hence \<open>play \<in> plays\<close> using assms(1) plays.cases no_empty_plays by blast
  hence play_split: \<open>\<exists>x xs. play = x#xs\<close> using no_empty_plays
    using plays.cases by blast 
  then obtain x where x_def: \<open>\<exists>xs. play = x#xs\<close> ..
  have x_in_set: \<open>x \<in> set (n0#play)\<close> using x_def by auto
  have x_head: \<open>x = hd play\<close> using x_def by auto
  from x_in_set x_head show \<open>hd play \<in> set (n0 # play)\<close> by auto
qed

lemma def_sim_or_swap_before_atkNode: 
  assumes  
    \<open>c_set_game_moves n0 n1\<close>
    \<open>n1 = AttackerNode p Q\<close>
  shows 
    \<open>(\<exists>Qpred a. n0 = (DefenderSimNode a p Qpred)) \<or> (\<exists>q Ppred. n0 = (DefenderSwapNode q Ppred) \<and> Q = {q})\<close>
proof (cases n0 rule: c_set_game_node.exhaust)
  case (AttackerNode s T)
  hence \<open>c_set_game_moves (AttackerNode s T) (AttackerNode p Q)\<close> using assms by auto 
  hence \<open>False\<close> by simp
  then show ?thesis by auto
next
  case (DefenderSimNode a s T)
  then show ?thesis using assms by auto
next
  case (DefenderSwapNode s T)
  hence \<open>c_set_game_moves (DefenderSwapNode s T) (AttackerNode p Q)\<close> using assms by auto 
  then show ?thesis using DefenderSwapNode by auto
qed

lemma set_game_all_f_consistent_atk_pos_in_ZR:
  assumes
    \<open>contrasim C\<close>
    \<open>C p0 q0\<close>
    \<open>initial = AttackerNode p0 {q0}\<close>
    \<open>play \<in> plays_for_strategy (strategy_from_ZR_C (ZR (set_type C)))\<close>
  shows \<open>n = AttackerNode p Q \<Longrightarrow> n \<in> set play \<Longrightarrow> ZR (set_type C) p Q \<close>
proof (induct arbitrary: n p Q rule: plays_for_strategy.induct[OF assms(4)])
  case init: 1
  hence \<open>n = initial\<close> by auto
  hence \<open>p = p0 \<and> Q = {q0}\<close> using assms(3) init.prems(1) by auto 
  thus  \<open>ZR (set_type C) p Q\<close> using assms R_is_in_ZR set_type_def by simp
next
  case p0moved: (2 n0 play) 
  hence \<open>(n = strategy_from_ZR_C (ZR (set_type C)) (n0 # play)) \<or> (n \<in> set (n0#play))\<close> by auto
  thus ?case
  proof(rule disjE)
    assume \<open>n \<in> set (n0#play)\<close>
    thus ?thesis using p0moved.prems p0moved.hyps(1,2) by blast 
  next
    assume strat: \<open>n = strategy_from_ZR_C (ZR (set_type C)) (n0 # play)\<close>
    hence \<open>(\<exists>a Qpred. n0 = DefenderSimNode a p Qpred) \<or> (\<exists>q Ppred. n0 = DefenderSwapNode q Ppred \<and> Q = {q})\<close>
      using def_sim_or_swap_before_atkNode[OF p0moved.hyps(4), of \<open>p\<close> \<open>Q\<close>] p0moved.prems(1) by blast 
    thus ?case 
    proof (rule disjE)
      assume \<open>\<exists>a Qpred. n0 = DefenderSimNode a p Qpred\<close>
      then obtain a Qpred where n0_def: \<open>n0 = DefenderSimNode a p Qpred\<close> by auto
      hence \<open>strategy_from_ZR_C (ZR (set_type C)) (n0#play) 
          = AttackerNode p (SOME Q1. Q1 = succs a Qpred \<and> (ZR (set_type C)) p Q1 \<and> Q1 \<noteq> {})\<close> 
        using strategy_from_ZR_C.simps(2) by auto
      hence Q_def: \<open>Q = (SOME Q1. Q1 = succs a Qpred \<and> (ZR (set_type C)) p Q1  \<and> Q1 \<noteq> {})\<close> 
        using strat by (simp add: p0moved.prems(1))
      have \<open>\<exists>ppred. hd play = (AttackerNode ppred Qpred) \<and> c_set_game_moves (hd play) n0\<close> 
        using set_defender_pred_is_attacker strategy_plays_subset[OF p0moved.hyps(1)] 
          assms(3, 4) n0_def by force 
      then obtain ppred where ppred_def: \<open>hd play = (AttackerNode ppred Qpred)\<close> 
          and \<open>c_set_game_moves (hd play) n0\<close> by auto
      hence \<open>ppred \<Rightarrow>a p\<close> \<open>a \<noteq> \<tau>\<close> using n0_def by auto
      hence \<open>hd play \<in> set (n0 # play)\<close> 
        using second_elem_in_play_set strategy_plays_subset[OF p0moved.hyps(1)] assms(3) n0_def
        by (simp add: assms(4))
      hence \<open>ZR (set_type C) ppred Qpred\<close> using p0moved.hyps(2) ppred_def by blast
      hence \<open>succs a Qpred \<noteq> {} \<and> ZR (set_type C) p (succs a Qpred)\<close> 
       using \<open>ppred \<Rightarrow>a p\<close> assms(1,2,4) ZR_C_guarantees_action_succ \<open>a \<noteq> \<tau>\<close> by auto
      hence \<open>\<exists>Q. Q = (succs a Qpred) \<and> ZR (set_type C) p Q\<close> by auto
      from someI_ex[OF this] show \<open>ZR (set_type C) p Q\<close> 
        unfolding Q_def
        using n0_def p0moved.hyps(4) by auto
    next
      assume \<open>(\<exists>q Ppred. n0 = DefenderSwapNode q Ppred \<and> Q = {q})\<close>
      then obtain q Ppred where n0_def: \<open>n0 = DefenderSwapNode q Ppred\<close> and Q_def: \<open>Q = {q}\<close> 
        by auto
      hence \<open>strategy_from_ZR_C (ZR (set_type C)) (n0#play)
         = AttackerNode (SOME p1. (\<exists>p. p \<in> Ppred \<and> p \<Rightarrow>^\<tau> p1) \<and> (ZR (set_type C)) p1 {q}) {q}\<close> 
        using strategy_from_ZR_C.simps(1) by auto
      hence p_def: \<open>p = (SOME p1. (\<exists>p. p \<in> Ppred \<and> p \<Rightarrow>^\<tau> p1) \<and> (ZR (set_type C)) p1 {q})\<close> 
        using strat p0moved.prems by auto
      have \<open>\<exists>qpred. hd play = (AttackerNode qpred Ppred) \<and> c_set_game_moves (hd play) n0\<close> 
        using set_defender_pred_is_attacker strategy_plays_subset[OF p0moved.hyps(1)] 
          assms(3, 4) n0_def 
        by force 
      then obtain qpred where qpred_def: \<open>hd play = (AttackerNode qpred Ppred)\<close> 
        and qpred_move: \<open>c_set_game_moves (hd play) n0\<close> by auto
      hence p1: \<open>player1_position (hd play)\<close> by (simp add: player1_position_def) 
      have qpred_q_move: \<open>qpred \<Rightarrow>^\<tau> q\<close> using qpred_def qpred_move n0_def by simp
      have \<open>hd play \<in> set (n0 # play)\<close> 
        using second_elem_in_play_set strategy_plays_subset[OF p0moved.hyps(1)] assms(3) n0_def
        by (simp add: assms(4)) 
      hence \<open>ZR (set_type C) qpred Ppred\<close> using p0moved.hyps(2) qpred_def by blast
      hence \<open>\<exists>p. p \<in> succs \<tau> Ppred \<and> ZR (set_type C) p {q}\<close> 
        using qpred_q_move assms(1,2) ZR_C_guarantees_tau_succ by blast
      hence \<open>\<exists>p. (\<exists>p0. p0 \<in> Ppred \<and> p0 \<Rightarrow>^\<tau>  p) \<and> ZR (set_type C) p {q}\<close> 
        using succs_def[of \<open>\<tau>\<close> \<open>Ppred\<close>] by blast
      from someI_ex[OF this] p_def have \<open>ZR (set_type C) p {q}\<close> by simp
      thus \<open>ZR (set_type C) p Q\<close> using Q_def by blast
    qed
  qed
next  
  case p1moved: (3 n1 play n1') 
  hence \<open>(n = n1') \<or> (n \<in> set (n1#play))\<close> by auto
  thus ?case
  proof (rule disjE)
    assume \<open>n \<in> set (n1#play)\<close>
    thus ?case using p1moved.prems p1moved.hyps(1,2) by blast 
  next
    assume A1: \<open>n = n1'\<close>
    hence \<open>c_set_game_defender_node n1'\<close>
      using def_sim_or_swap_before_atkNode p1moved.hyps(3, 4) p1moved.prems(1)
        player1_position_def by fastforce
    hence \<open>False\<close> using A1 p1moved.prems(1) by auto
    thus ?case by auto
  qed
qed

lemma set_contrasim_game_complete:
  assumes
    \<open>contrasim C\<close>
    \<open>C p0 q0\<close>
    \<open>initial = AttackerNode p0 {q0}\<close>
  shows \<open>player0_winning_strategy (strategy_from_ZR_C (ZR (set_type C)))\<close>
  unfolding player0_winning_strategy_def
proof (safe)
  fix play
  assume A1: \<open>play \<in> (plays_for_strategy (strategy_from_ZR_C (ZR (set_type C))))\<close>
  thus \<open>player1_wins play \<Longrightarrow> False\<close>
    unfolding player1_wins_def
  proof - 
    assume A: \<open>c_set_game_defender_node (hd play) \<and> (\<nexists>p'. c_set_game_moves (hd play) p')\<close> 
    have player0_has_succ_node: \<open>c_set_game_defender_node (hd play) \<Longrightarrow> \<exists>p'. c_set_game_moves (hd play) p'\<close>
    proof (induct rule: simple_game.plays_for_strategy.induct[OF A1])
      case init: 1 
      have \<open>\<not>c_set_game_defender_node (hd [initial])\<close> by (simp add: assms) 
      hence \<open>False\<close> using init.prems by simp
      then show ?case ..
    next
      case p0moved: (2 n0 play)
      from p0moved.hyps have \<open>c_set_game_defender_node n0\<close> by simp
      hence \<open>(\<exists>a p1 q. n0 = (DefenderSimNode a p1 q)) \<or> (\<exists>q P. n0 = DefenderSwapNode q P)\<close>
        by (meson c_set_game_defender_node.elims(2)) 
      hence \<open>\<not>c_set_game_defender_node (strategy_from_ZR_C (ZR (set_type C)) (n0#play))\<close>
        using p0moved.hyps(4) 
          c_set_game_moves.elims(2)[of \<open>n0\<close> \<open>strategy_from_ZR_C (ZR (set_type C)) (n0#play)\<close>]
        by force 
      hence \<open>\<not>c_set_game_defender_node (hd (strategy_from_ZR_C (ZR (set_type C)) (n0 # play) # n0 # play))\<close> 
        by simp
      hence \<open>False\<close> using p0moved.prems ..
      then show ?case ..
    next
      case p1moved: (3 n1 play n1') 
      hence \<open>\<not>c_set_game_defender_node n1\<close> using p1moved.hyps and player1_position_def by simp
      then obtain p Q where n1_def: \<open>n1 = AttackerNode p Q\<close>
        using c_set_game_defender_node.elims(3) by auto
      hence ZR: \<open>ZR (set_type C) p Q\<close> 
        using set_game_all_f_consistent_atk_pos_in_ZR[OF assms(1-3), of \<open>n1#play\<close>, OF p1moved.hyps(1)] 
        by auto
      have \<open>(\<exists>a p1. n1' = DefenderSimNode a p1 Q) \<or> (\<exists>p1. n1' = DefenderSwapNode p1 Q)\<close> 
        using p1moved.prems n1_def p1moved.hyps(4)
        by (metis c_set_game_defender_node.elims(2) list.sel(1) local.simulation_challenge local.swap_challenge)
      thus ?case
      proof (rule disjE)
        assume A: \<open>\<exists>a p1. n1' = DefenderSimNode a p1 Q\<close>
        then obtain a p1 where n1'_def : \<open>n1' = DefenderSimNode a p1 Q\<close> by auto
        have move: \<open>c_set_game_moves (AttackerNode p Q) (DefenderSimNode a p1 Q)\<close> 
          using p1moved.hyps n1_def n1'_def by auto
        hence \<open>p \<Rightarrow>a p1\<close> by auto
        hence \<open>p \<Rightarrow>^a p1\<close> using weak_step_impl_weak_tau by blast
        hence \<open>succs a Q \<noteq> {} \<and> ZR (set_type C) p1 (succs a Q)\<close> 
          using ZR_C_guarantees_action_succ move
          by (metis ZR assms(1) simulation_challenge tau_tau) 
        then obtain Q1 where \<open>Q1 = succs a Q \<and> ZR (set_type C) p1 Q1 \<and> Q1 \<noteq> {}\<close> by blast
        hence \<open>c_set_game_moves n1' (AttackerNode p1 Q1)\<close> 
          using A n1'_def by auto
        thus \<open>\<exists>a. c_set_game_moves (hd (n1' # n1 # play)) a\<close> by auto
      next
        assume  \<open>\<exists>p1. n1' = DefenderSwapNode p1 Q\<close>
        then obtain p1 where n1'_def: \<open>n1' = DefenderSwapNode p1 Q\<close> ..
        hence \<open>c_set_game_moves (AttackerNode p Q) (DefenderSwapNode p1 Q)\<close> 
          using p1moved.hyps(4) n1_def by auto
        hence p_succ: \<open>p \<Rightarrow>^\<tau> p1\<close> by auto
        hence \<open>\<exists>q'. q' \<in> succs \<tau> Q \<and> ZR (set_type C) q' {p1}\<close> 
          using ZR ZR_C_guarantees_tau_succ assms(1) by auto
        hence \<open>\<exists>q1. q1 \<in> succs \<tau> Q \<and> ZR (set_type C) q1 {p1}\<close> by auto
        hence \<open>\<exists>q1 P1. c_set_game_moves n1' (AttackerNode q1 P1)\<close> using n1'_def  by auto  
        thus \<open>\<exists>a. c_set_game_moves (hd (n1' # n1 # play)) a\<close> by auto
      qed
    qed
    hence \<open>False\<close> using A by auto
    thus ?thesis by auto
  qed
qed

lemma strategy_from_set_contrasim_sound : 
  assumes
    \<open>contrasim C\<close>
    \<open>C p0 q0\<close>
    \<open>initial = AttackerNode p0 {q0}\<close>
  shows
    \<open>sound_strategy (strategy_from_ZR_C (ZR (set_type C)))\<close>
  unfolding sound_strategy_def
proof (safe)
  fix n0 play
  assume A: 
    \<open>n0 # play \<in> plays_for_strategy (strategy_from_ZR_C (ZR (set_type C)))\<close>
    \<open>c_set_game_defender_node n0\<close>
  hence \<open>(\<exists>a p' Q. n0 = DefenderSimNode a p' Q) \<or> (\<exists>p' Q. n0 = DefenderSwapNode p' Q)\<close>
    by (meson c_set_game_defender_node.elims(2)) 
  thus \<open>c_set_game_moves n0 (strategy_from_ZR_C (ZR (set_type C)) (n0 # play))\<close>
  proof(rule disjE)
    assume \<open>\<exists>a p' Q. n0 = DefenderSimNode a p' Q\<close>
    then obtain a p' Q where n0_def: \<open>n0 = DefenderSimNode a p' Q\<close> by auto
    then obtain p where p_def: \<open>hd play = AttackerNode p Q\<close> using A
      by (metis assms(3) set_defender_pred_is_attacker simulation_challenge strategy_plays_subset) 
    hence \<open>c_set_game_moves (AttackerNode p Q) (DefenderSimNode a p' Q)\<close>
      by (metis A n0_def assms(3) set_defender_pred_is_attacker strategy_plays_subset) 
    hence \<open>p \<Rightarrow>a p'\<close> \<open>\<not> tau a\<close> by auto
    hence \<open>ZR (set_type C) p Q\<close>
      using set_game_all_f_consistent_atk_pos_in_ZR[OF assms] A p_def
        assms(3) second_elem_in_play_set strategy_plays_subset 
      by fastforce
    hence  \<open>succs a Q \<noteq> {} \<and> ZR (set_type C) p' (succs a Q)\<close>
      using ZR_C_guarantees_action_succ \<open>\<not> tau a\<close> \<open>p \<Rightarrow>a p'\<close> assms(1) tau_tau by blast 
    hence Q1_ex: \<open>\<exists>Q'. Q' = succs a Q \<and> ZR (set_type C) p' Q' \<and> Q' \<noteq> {}\<close> by auto
    from n0_def have st: \<open>strategy_from_ZR_C (ZR (set_type C)) (n0#play) = 
    (AttackerNode p' (SOME Q1 . Q1 = succs a Q \<and> (ZR (set_type C)) p' Q1 \<and> Q1 \<noteq> {}))\<close> by auto
    then obtain Q1 where 
      \<open>AttackerNode p' (SOME Q1 . Q1 = succs a Q \<and> (ZR (set_type C)) p' Q1  \<and> Q1 \<noteq> {}) = AttackerNode p' Q1\<close>
      by blast
    hence Q1_def: \<open>Q1 = (SOME Q1 . Q1 = succs a Q \<and> (ZR (set_type C)) p' Q1 \<and> Q1 \<noteq> {})\<close>
      by auto
    have next_is_atk: \<open>strategy_from_ZR_C (ZR (set_type C)) (n0#play) = (AttackerNode p' Q1)\<close> 
      using st Q1_def by auto
    with someI_ex[OF Q1_ex] Q1_def have mov_cond: \<open>Q1 = succs a Q \<and> ZR (set_type C) p' Q1 \<and> Q1 \<noteq> {}\<close>
      by blast
    have \<open>c_set_game_moves n0 (AttackerNode p' Q1)\<close> using n0_def mov_cond by auto
    thus ?thesis using next_is_atk by auto
  next 
    assume \<open>\<exists>p' Q. n0 = DefenderSwapNode p' Q\<close>
    then obtain p' Q where n0_def: \<open>n0 = DefenderSwapNode p' Q\<close> by auto
    then obtain p where  p_def: \<open>hd play = AttackerNode p Q\<close> using A
      by (metis assms(3) set_defender_pred_is_attacker swap_challenge strategy_plays_subset) 
    hence \<open>c_set_game_moves (AttackerNode p Q) (DefenderSwapNode p' Q)\<close>
      by (metis A n0_def assms(3) set_defender_pred_is_attacker strategy_plays_subset)
    hence \<open>p \<Rightarrow>^\<tau> p'\<close> by auto
    hence \<open>ZR (set_type C) p Q\<close>
      using set_game_all_f_consistent_atk_pos_in_ZR[OF assms] A p_def
        assms(3) second_elem_in_play_set strategy_plays_subset 
      by fastforce 
    hence  \<open>\<exists>q'. q' \<in> succs \<tau> Q \<and> ZR (set_type C) q' {p'}\<close>
      using ZR_C_guarantees_tau_succ \<open>p \<Rightarrow>^\<tau> p'\<close> assms(1) by auto 
    hence q1_ex: \<open>\<exists>q1. (\<exists>q.(q \<in> Q \<and> q  \<Rightarrow>^\<tau> q1)) \<and> ZR (set_type C) q1 {p'}\<close> using succs_def by auto
    hence strat: \<open>strategy_from_ZR_C (ZR (set_type C)) (n0#play) = 
    AttackerNode (SOME q1 . (\<exists>q. (q \<in> Q \<and> q  \<Rightarrow>^\<tau> q1)) \<and> (ZR (set_type C)) q1 {p'}) {p'}\<close>
      using n0_def by auto
    then obtain q1 where 
      \<open>AttackerNode (SOME q1 . (\<exists>q. (q \<in> Q \<and> q  \<Rightarrow>^\<tau> q1)) \<and> (ZR (set_type C)) q1 {p'}) {p'}
      = AttackerNode q1 {p'}\<close> by blast
    hence q1_def: \<open>q1 = (SOME q1 . (\<exists>q. (q \<in> Q \<and> q  \<Rightarrow>^\<tau> q1)) \<and> (ZR (set_type C)) q1 {p'})\<close>
      by auto
    with someI_ex[OF q1_ex] have X: \<open>\<exists>q. (q \<in> Q \<and> q  \<Rightarrow>^\<tau> q1) \<and> ZR (set_type C) q1 {p'}\<close> 
      by blast
    hence \<open>q1 \<in> succs \<tau> Q \<and> {p'} = {p'}\<close>using succs_def by auto
    thus ?thesis  using n0_def strat q1_def by auto
  qed
qed

subsection \<open>Winning Strategy Implies Contrasimulation (Soundness)\<close>

lemma move_DefSim_to_AtkNode : 
  assumes 
    \<open>c_set_game_moves (DefenderSimNode a p Q) n0\<close>
  shows \<open>n0 = AttackerNode p (succs a Q)\<close>
proof - 
  have \<open>\<exists>p1 Q1. n0 = AttackerNode p1 Q1\<close>
    by (metis assms c_set_game_defender_node.elims(2) c_set_game_defender_node.elims(3) local.c_set_game_moves_no_step(1) local.c_set_game_moves_no_step(6)) 
  then obtain p1 Q1 where n0_def: \<open>n0 = AttackerNode p1 Q1\<close> by auto
  hence \<open>p = p1\<close> using assms local.simulation_answer by blast 
  from n0_def have \<open>Q1 = succs a Q\<close> 
    using assms local.simulation_answer by blast
  thus ?thesis using \<open>p = p1\<close> n0_def by auto
qed


lemma defSimNode_with_prefix_in_play: 
  assumes 
    \<open>A \<noteq> []\<close>
    \<open>p \<Rightarrow>$A p1\<close> 
    \<open>\<forall>a\<in>set A. a \<noteq> \<tau>\<close>
    \<open>player0_winning_strategy f\<close>
    \<open>sound_strategy f\<close>
    \<open>play \<in> plays_for_strategy f\<close>
    \<open>hd play = AttackerNode p {q}\<close>
  shows \<open>\<exists>play. ((DefenderSimNode (last A) p1 (succs_seq_rec (rev (butlast A)) {q}))#play) 
      \<in> plays_for_strategy f\<close> 
proof - 
  have  \<open>\<not>player1_wins play\<close> using assms(4, 6) player0_winning_strategy_def by auto
  hence \<open>(c_set_game_defender_node (hd play) \<and> (\<nexists>p'. c_set_game_moves (hd play) p')) \<Longrightarrow> False\<close> 
    using player1_wins_def by auto
  hence Def_not_stuck: \<open>c_set_game_defender_node (hd play) \<Longrightarrow> (\<exists>p'. c_set_game_moves (hd play) p')\<close> 
    by auto
  show ?thesis using assms(1-3)
  proof (induct arbitrary: p1 rule: rev_nonempty_induct[OF assms(1)])
    case single: (1 a)
    hence \<open>\<not>tau a\<close> using \<open>\<forall>a\<in>set A. a \<noteq> \<tau>\<close> by (simp add: tau_def) 
    hence \<open>p \<Rightarrow>$[a] p1\<close> using single by auto
    hence p_step: \<open>p \<Rightarrow>^a p1\<close> by blast
    hence \<open>p \<Rightarrow>a p1\<close> using Cons \<open>\<not>tau a\<close> by auto
    hence \<open>\<exists>n0. n0  = DefenderSimNode a p1 {q} \<and> c_set_game_moves (AttackerNode p {q}) n0\<close> 
      using assms(4) \<open>\<not> tau a\<close> by simp
    hence \<open>((DefenderSimNode a p1 {q})#play) \<in> plays_for_strategy f\<close> using assms(6,7)
      by (metis c_set_game_defender_node.simps(1) list.collapse no_empty_plays 
            player1_position_def plays_for_strategy.p1move strategy_plays_subset)
    then show ?case  by auto
  next
    case snoc: (2 a as)
    hence \<open>\<not>tau a\<close> using \<open>\<forall>a\<in>set A. a \<noteq> \<tau>\<close> by (simp add: tau_def) 
    then obtain a2 as2 where as_def: \<open>as = as2@[a2]\<close> using list_rev_split[OF snoc.hyps(1)] by auto
    have \<open>\<exists>p'. p \<Rightarrow>$ as  p' \<and> p' \<Rightarrow>$[a]  p1\<close> using rev_seq_split[OF snoc.prems(2)] by blast
    hence \<open>\<exists>p'. p \<Rightarrow>$ as  p' \<and> p' \<Rightarrow>^a  p1\<close> by blast
    hence \<open>\<exists>p'. p \<Rightarrow>$ as  p' \<and> p' \<Rightarrow>a  p1\<close> using  \<open>\<not>tau a\<close> by simp
    then obtain p' where p'_def: \<open>p \<Rightarrow>$ as  p'\<close> and p'_step: \<open>p' \<Rightarrow>a  p1\<close> by auto
    then obtain play 
      where play_def: \<open>DefenderSimNode (last as) p' (succs_seq_rec (rev (butlast as)) {q}) # play 
                \<in> plays_for_strategy f\<close> using snoc by auto
    hence \<open>DefenderSimNode a2 p' (succs_seq_rec (rev as2) {q}) # play 
                \<in> plays_for_strategy f\<close> using as_def by auto
    then obtain n0 where n0_def: \<open>n0 = DefenderSimNode a2 p' (succs_seq_rec (rev as2) {q})\<close> 
          and n0_in_play: \<open>n0#play \<in> plays_for_strategy f\<close> by auto
    hence \<open>\<exists>n1. c_set_game_moves (DefenderSimNode a2 p' (succs_seq_rec (rev as2) {q})) n1\<close> 
      using Def_not_stuck by (meson assms(5) c_set_game_defender_node.simps(2) sound_strategy_def) 
    then obtain n1 
      where n1_def: \<open>c_set_game_moves (DefenderSimNode a2 p' (succs_seq_rec (rev as2) {q})) n1\<close> 
      by auto
    hence n1_atk: \<open>n1 = AttackerNode p' (succs a2 ((succs_seq_rec (rev as2) {q})))\<close> 
      using move_DefSim_to_AtkNode[OF n1_def] by auto
    have n1_in_play: \<open>n1#n0#play \<in> plays_for_strategy f\<close> using n1_def n0_in_play n0_def
      by (metis assms(5) move_DefSim_to_AtkNode c_set_game_defender_node.simps(2) 
          plays_for_strategy.simps sound_strategy_def) 
    then obtain n0' 
      where n0'_def : \<open>n0' = DefenderSimNode a p1 (succs a2 ((succs_seq_rec (rev as2) {q})))\<close> 
      and n0'_mov: \<open>c_set_game_moves n1 n0'\<close> using p'_step n1_atk by (simp add: \<open>\<not> tau a\<close>)
    hence in_play: \<open>n0'#n1#n0#play \<in> plays_for_strategy f\<close> using n1_in_play
      by (simp add: n1_atk player1_position_def plays_for_strategy.p1move) 
    hence simnode: \<open>n0' = DefenderSimNode a p1 (succs a2 ((succs_seq_rec(rev as2) {q})))\<close> 
      using n0'_def n0'_mov by auto
    hence \<open>n0' = DefenderSimNode a p1 (succs_seq_rec (rev (as2@[a2])) {q})\<close> using simnode by auto
    hence \<open>n0' = DefenderSimNode a p1 (succs_seq_rec (rev (as)) {q})\<close> using as_def by auto
    then show ?case using in_play by auto
  qed
qed

lemma set_contrasim_game_sound: 
  assumes
    \<open>player0_winning_strategy f\<close>
    \<open>sound_strategy f\<close>
  defines
    \<open>C == \<lambda> p q . (\<exists> play \<in> plays_for_strategy f . hd play = AttackerNode p {q} \<and> (hd play = initial \<or> (\<exists>P. hd (tl play) = DefenderSwapNode q P)))\<close>
  shows
    \<open>contrasim C\<close>  unfolding contrasim_def
proof (safe) 
  fix p q p1 A
  assume \<open>\<forall>a\<in>set A. a \<noteq> \<tau>\<close> \<open>p \<Rightarrow>$A p1\<close> and \<open>C p q\<close> 
  hence \<open>p \<Rightarrow>$(taufree A) p1\<close> by (simp add: weak_step_over_tau) 
  hence \<open>(\<exists> play \<in> plays_for_strategy f . hd play = AttackerNode p {q} \<and> (hd play = initial \<or> (\<exists>P. hd (tl play) = DefenderSwapNode q P)))\<close> 
    using C_def \<open>p \<Rightarrow>$A p1\<close> and \<open>C p q\<close>  by auto
  from this obtain play where play_def: \<open>play \<in> plays_for_strategy f\<close> 
    and play_hd: \<open>hd play = AttackerNode p {q}\<close> 
    and \<open>hd play = initial \<or> (\<exists>P. hd (tl play) = DefenderSwapNode q P)\<close> 
    by auto
  hence \<open>\<not>player1_wins play\<close> using assms(1) player0_winning_strategy_def by auto
  hence \<open>(c_set_game_defender_node (hd play) \<and> (\<nexists>p'. c_set_game_moves (hd play) p')) \<Longrightarrow> False\<close> 
    using player1_wins_def by auto
  hence Def_not_stuck: \<open>c_set_game_defender_node (hd play) \<Longrightarrow> (\<exists>p'. c_set_game_moves (hd play) p')\<close> by auto
  from \<open>p \<Rightarrow>$A p1\<close> \<open>p \<Rightarrow>$(taufree A) p1\<close> \<open>C p q\<close> show \<open>\<exists>q'. q \<Rightarrow>$ A q' \<and> C q' p1\<close>
  proof (cases A rule: rev_cases)
    case Nil
    hence \<open>p \<Rightarrow>^\<tau> p1\<close> using \<open>p \<Rightarrow>$A p1\<close> by auto
    hence \<open>\<exists>n0. n0 = DefenderSwapNode p1 {q} \<and> c_set_game_moves (AttackerNode p {q}) n0\<close> by simp 
    from this obtain n0 where n0_def: \<open>n0 = DefenderSwapNode p1 {q}\<close> 
      and n0_move: \<open>c_set_game_moves (AttackerNode p {q}) n0\<close> by auto
    have \<open>play = (hd play)#(tl play)\<close>
      by (metis hd_Cons_tl no_empty_plays play_def strategy_plays_subset)
    hence \<open>n0#play \<in> plays_for_strategy f\<close> using n0_def n0_move play_def play_hd
      by (metis c_set_game_defender_node.simps(1) play_def 
          player1_position_def plays_for_strategy.p1move) 
    hence \<open>\<exists>n1'. c_set_game_moves n0 n1' \<and> n1'#n0#play \<in> plays_for_strategy f\<close>
      using assms(2) n0_def sound_strategy_def
      by (meson c_set_game_defender_node.simps(3) plays_for_strategy.p0move) 
    then obtain n1' where n1'_mov: \<open>c_set_game_moves n0 n1'\<close> 
      and in_play: \<open>n1'#n0#play \<in> plays_for_strategy f\<close> by auto
    hence \<open>\<exists>q1. n1' = AttackerNode q1 {p1} \<and> (q1 \<in> succs \<tau> {q})\<close>
      by (metis c_set_game_defender_node.elims(2, 3) c_set_game_moves_no_step(3, 4) swap_answer n0_def) 
    then obtain q1 where q1_def: \<open>n1' = AttackerNode q1 {p1}\<close> 
      and q_succ: \<open>q1 \<in> succs \<tau> {q}\<close> by auto
    hence q_tau: \<open>q \<Rightarrow>^\<tau> q1\<close> using succs_def by auto
    from in_play q1_def n0_def have \<open>C q1 p1\<close> unfolding C_def by force 
    then show ?thesis using q_tau Nil by auto 
  next
    case (snoc as a)
    hence \<open>A \<noteq> []\<close> by auto
    hence \<open>\<not>tau a\<close> using \<open>\<forall>a\<in>set A. a \<noteq> \<tau>\<close> snoc  by (simp add: tau_def) 
    have gotoA: \<open>\<exists>play. ((DefenderSimNode (last A) p1 (succs_seq_rec (rev (butlast A)) {q}))#play) 
      \<in> plays_for_strategy f\<close> 
      using defSimNode_with_prefix_in_play \<open>p \<Rightarrow>$A p1\<close> 
        \<open>\<forall>a\<in>set A. a \<noteq> \<tau>\<close> \<open>A \<noteq> []\<close> assms(1,2) play_def play_hd by auto
    then obtain Q where Q_def: \<open>Q = succs_seq_rec (rev (butlast A)) {q}\<close> by auto
    hence Q_all: \<open>\<forall>q' \<in> Q.  q \<Rightarrow>$(butlast A) q'\<close> using in_s_implies_word_reachable by auto
    then obtain n0 where n0_def: \<open>n0 = DefenderSimNode a p1 (succs_seq_rec (rev as) {q})\<close> by auto
    then obtain A_play 
      where A_play_def: \<open>n0#A_play \<in> plays_for_strategy f\<close> 
      using gotoA snoc by auto
    then obtain n1 where n1_move: \<open>c_set_game_moves n0 n1\<close>
      using n0_def by (meson assms(2) c_set_game_defender_node.simps(2) sound_strategy_def)
    hence \<open>n1 = AttackerNode p1 (succs a (succs_seq_rec (rev as) {q}))\<close> 
      using move_DefSim_to_AtkNode n0_def by blast
    hence \<open>n1 = AttackerNode p1 (succs_seq_rec (a#(rev as)) {q})\<close>  
      using succs_seq_rec.simps(2) by auto
    hence \<open>n1 = AttackerNode p1 (succs_seq_rec (rev (as@[a])) {q})\<close> by auto
    hence n1_def: \<open>n1 = AttackerNode p1 (succs_seq_rec (rev A) {q})\<close> using snoc by auto
    hence n1_in_play: \<open>n1#n0#A_play \<in> plays_for_strategy f\<close>
      using n0_def A_play_def n1_move assms(2) move_DefSim_to_AtkNode 
        plays_for_strategy.p0move sound_strategy_def 
      by fastforce 
    from n1_def obtain n0' where n0'_move: \<open>c_set_game_moves n1 n0'\<close> 
      and n0'_def: \<open>n0' = DefenderSwapNode p1 (succs_seq_rec (rev A) {q})\<close>
      using steps.refl local.swap_challenge tau_tau by blast
    hence n0'_in_play: \<open>n0'#n1#n0#A_play \<in> plays_for_strategy f\<close>
      using n1_in_play by (simp add: n1_def player1_position_def plays_for_strategy.p1move) 
    then obtain n1' where n1'_move: \<open>c_set_game_moves n0' n1'\<close>
      and in_strat: \<open>n1' = f(n0'#n1#n0#A_play)\<close> 
      using Def_not_stuck n0'_def  assms(2) sound_strategy_def by auto
    then obtain q1 where q1_def: \<open>q1 \<in> succs \<tau> (succs_seq_rec (rev A) {q})\<close> 
      and n1'_def: \<open>n1'  = AttackerNode q1 {p1}\<close> using n0'_def
      by (metis c_set_game_defender_node.cases c_set_game_moves_no_step(3, 7) swap_answer) 
    hence \<open>q1 \<in> {q1. \<exists>q0 \<in> (succs_seq_rec (rev A) {q}). q0 \<Rightarrow>^\<tau> q1}\<close> using succs_def by auto
    also have \<open>... = {q1. \<exists>q0 \<in> (succs_seq_rec (rev A) {q}). q \<Rightarrow>$A q0 \<and> q0 \<Rightarrow>^\<tau> q1}\<close>
      using in_s_implies_word_reachable by auto
    also have \<open>... \<subseteq> {q1. \<exists>q0 \<in> (succs_seq_rec (rev A) {q}). q \<Rightarrow>$A q1}\<close> 
      using word_tau_concat by auto
    also have \<open>... \<subseteq> {q1. q \<Rightarrow>$A q1}\<close> by auto
    finally have \<open>q1 \<in> {q1. q \<Rightarrow>$A q1}\<close> .
    hence q_goal: \<open>q \<Rightarrow>$A q1\<close> by auto
    from n1'_move in_strat have move_f: \<open>c_set_game_moves n0' (f(n0'#n1#n0#A_play))\<close> by auto
    hence  \<open>n1'#n0'#n1#n0#A_play \<in> plays_for_strategy f\<close>
      using in_strat plays_for_strategy.p0move[OF n0'_in_play _ move_f] n0'_def by auto
    hence \<open>C q1 p1\<close> unfolding C_def using n1'_def n0'_def by force 
    thus ?thesis using q_goal by auto
  qed
qed

theorem winning_strategy_in_set_game_iff_contrasim:
  assumes
    \<open>initial = AttackerNode p {q}\<close>
  shows 
    \<open>(\<exists> f . player0_winning_strategy f \<and> sound_strategy f) = (\<exists> C. contrasim C \<and> C p q)\<close>
proof 
  assume
    \<open>(\<exists>f. player0_winning_strategy f \<and> sound_strategy f)\<close>
  then obtain f where
    \<open>contrasim
      (\<lambda>p q. \<exists>play\<in>plays_for_strategy f.
                 hd play = AttackerNode p {q} \<and>
                 (hd play = initial \<or> (\<exists>P. hd (tl play) = DefenderSwapNode q P)))\<close>
    using set_contrasim_game_sound by blast
  moreover have \<open>(\<lambda>p q. \<exists>play\<in>plays_for_strategy f.
                 hd play = AttackerNode p {q} \<and>
                 (hd play = initial \<or> (\<exists>P. hd (tl play) = DefenderSwapNode q P))) p q\<close>
     using assms plays_for_strategy.init[of f] by (meson list.sel(1))
  ultimately show \<open>\<exists> C. contrasim C \<and> C p q\<close> by blast
next
  assume
    \<open>\<exists> C. contrasim C \<and> C p q\<close>
  thus \<open>(\<exists>f. player0_winning_strategy f \<and> sound_strategy f)\<close>
    using set_contrasim_game_complete[OF _ _ assms]
         strategy_from_set_contrasim_sound[OF _ _ assms] by blast
qed

end
end