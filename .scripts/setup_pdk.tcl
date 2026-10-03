
#set pjroot $env(G2_SYS)/projs/G2_demo_sky130
set pjroot [pwd]


set pdk    [file normalize $env(G2_ROOT)/../]/pdk/sky130
set g2root $env(G2_ROOT)

# spec/pdk

cd $pjroot/spec/pdk

gset . tech_lef          $pdk/tech/tlef/sky130hd.tlef
gset . tech_fvar         $pdk/openroad/tvars.tcl
gset . create_tracks     $pdk/openroad/create_tracks.tcl
gset . create_pdn        $pdk/openroad/create_pdn.tcl
gset . layer_rc          $pdk/openroad/set_layer_rc.tcl
gset . klayout_lym       $pdk/tech/klayout/pymacros/sky130.lym
gset . klayout_lyp       $pdk/tech/klayout/tech/sky130A.lyp
gset . klayout_lyt       $pdk/tech/klayout/tech/sky130A.lyt

gset . rcx_rules,cbest   $pdk/openroad/sky130hd.rcx_rules
gset . rcx_rules,cworst  $pdk/openroad/sky130hd.rcx_rules
gset . rcx_rules,typical $pdk/openroad/sky130hd.rcx_rules

# spec/global

cd $pjroot/spec/global

gset . syn_corner      func.max_ss1p600v100c_cworst
gset . unit,time       ns

# spec/pdk/.vars.tcl now holds machine-specific PDK paths: hide the local
# change from git status (-C: we are in spec/global; catch: no .git if the
# project was downloaded as a zip)
catch {exec git -C $pjroot update-index --skip-worktree spec/pdk/.vars.tcl}
