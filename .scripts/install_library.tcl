

#set pjroot $env(G2_SYS)/projs/G2_demo_sky130
set pjroot [pwd]


set pdk    [file normalize $env(G2_ROOT)/../]/pdk/sky130
set g2root $env(G2_ROOT)


# stdcell : sky130_fd_sc_hd
cd $pjroot/lim/stdcell

  stdcell_new sky130_fd_sc_hd
  cd sky130_fd_sc_hd

    stdcell_new_version v0.0.2
    cd v0.0.2
      gset . srcpath $pdk/stdcell/sky130_fd_sc_hd
      lim-build-liblist
      lim-build-all-libcells
      lim-ai-fill
      
# stdcell : sky130_fd_sc_hdll
cd $pjroot/lim/stdcell

  stdcell_new sky130_fd_sc_hdll
  cd sky130_fd_sc_hdll

    stdcell_new_version v0.0.2
    cd v0.0.2
      gset . srcpath $pdk/stdcell/sky130_fd_sc_hdll
      lim-build-liblist
      lim-build-all-libcells
      lim-ai-fill

# mem : fakeram45_1024x32
cd $pjroot/lim/mem

  mem_new fakeram45_1024x32
  cd fakeram45_1024x32

    mem_new_version v01
    cd v01
      gset . srcpath $pdk/mem/fakeram45_1024x32
      lim-build-liblist
      lim-build-all-libcells
      lim-ai-fill

# mem : fakeram45_256x16
cd $pjroot/lim/mem

  mem_new fakeram45_256x16
  cd fakeram45_256x16

    mem_new_version v01
    cd v01
      gset . srcpath $pdk/mem/fakeram45_256x16
      lim-build-liblist
      lim-build-all-libcells
      lim-ai-fill
 
