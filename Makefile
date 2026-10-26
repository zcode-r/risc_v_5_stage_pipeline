IVERILOG ?= iverilog
VVP ?= vvp

RTL_SOURCES = \
	rtl/pack.sv \
	rtl/alu_control.sv \
	rtl/alu.sv \
	rtl/control_unit.sv \
	rtl/imm.sv \
	rtl/instruction_mem.sv \
	rtl/data_mem.sv \
	rtl/reg_file.sv \
	rtl/forwarding_unit.sv \
	rtl/hazard_unit.sv \
	rtl/riscv_top.sv

.PHONY: build-sw test-sw test-hw test

build-sw:
	./sw/build.sh

test-sw: build-sw
	$(IVERILOG) -g2012 -s riscv_sw_tb $(RTL_SOURCES) tb/riscv_sw_tb.sv -o sim_sw
	$(VVP) sim_sw

test-hw:
	$(IVERILOG) -g2012 -s riscv_top_tb $(RTL_SOURCES) tb/riscv_top_tb.sv -o sim_hardware
	$(VVP) sim_hardware

test: test-hw test-sw
