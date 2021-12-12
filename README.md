# RISCV-CPU

## 总体框架

+ Tomasulo乱序执行

## 模块设计

+ Definition.v
+ cpu.v
+ Mem_ctrl.v
+ ICache.v (256*(1+24+32))
+ IF.v
+ IQ.v
+ ID.v
+ Dispatch.v
+ RS.v
+ LSB.v (WriteBuffer)
+ ROB.v
+ ALU.v
+ Regfile.v


## 上板参数

+ FPGA
+ 80 MHz
+ WNS: -3.315ns