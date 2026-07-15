copy /B tpp2-c.7a + tpp2-c.7b + tpp2-c.7c + tpp2-c.7e popeye_cpu_protected.bin
make_vhdl_prom popeye_cpu_protected.bin popeye_cpu_protected.vhd

make_vhdl_prom tpp2-c.4a popeye_bg_palette_rgb.vhd
make_vhdl_prom tpp2-c.5b popeye_sp_palette_rg.vhd
make_vhdl_prom tpp2-c.5a popeye_sp_palette_gb.vhd
make_vhdl_prom tpp2-c.3a popeye_ch_palette_rgb.vhd

make_vhdl_prom tpp2-v.1e popeye_sp_bits_1.vhd
make_vhdl_prom tpp2-v.1f popeye_sp_bits_2.vhd
make_vhdl_prom tpp2-v.1j popeye_sp_bits_3.vhd
make_vhdl_prom tpp2-v.1k popeye_sp_bits_4.vhd

make_vhdl_prom tpp2-v.5n popeye_ch_bits.vhd

pause
