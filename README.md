# RISCV-CPU

`Run on XC7A35T-ICPG236C FPGA board`

A toy CPU supporting part of RV32I Instruction set, implementing dynamic scheduling by tomasulo algorithm, providing speculation and precise exception.

## Feature

+ Out-of-order execution by Tomasulo Algorithm.
+ 16 entries RS, 16 entries LSB and 16 entries ROB.
+ 256 entries Direct-Mapped I-Cache.

## Performance

`Time tested on 80Mhz FPGA board`

WNS: -3.315ns

## Schematic

![](https://github.com/hyj542682306/RISCV-CPU/blob/main/img/Device.png)

![](https://github.com/hyj542682306/RISCV-CPU/blob/main/img/cpu.png)

![](https://github.com/hyj542682306/RISCV-CPU/blob/main/img/riscv_top.png)

## Structure

```
📦CPU
 ┣ 📂img                                    Some images
 ┣ 📂src                                    My code
 ┃ ┣ 📂common                               Provided UART and RAM
 ┃ ┃ ┣ 📂block_ram                          RAM
 ┃ ┃ ┣ 📂fifo                               FIFO queue for io buffer
 ┃ ┃ ┗ 📂uart                               Universal Asynchronous Receiver/Transmitter
 ┃ ┣ 📜ALU.v                                Arithmetic logic unit
 ┃ ┣ 📜Basys-3-Master.xdc                   Constraint file provided for creating project in vivado
 ┃ ┣ 📜Definition.v                         Defines statement
 ┃ ┣ 📜Dispatch.v                           Dispatch instructions to corresponding parts
 ┃ ┣ 📜ICache.v                             Instruction cache
 ┃ ┣ 📜ID.v                                 Instruction decode
 ┃ ┣ 📜IF.v                                 Fetch instructions from cache
 ┃ ┣ 📜IQ.v                                 Instruction queue
 ┃ ┣ 📜LSB.v                                Load store buffer
 ┃ ┣ 📜Mem_ctrl.v                           Interface with RAM, deal with structure hazard
 ┃ ┣ 📜ROB.v                                Reorder buffer
 ┃ ┣ 📜RS.v                                 Reservation station
 ┃ ┣ 📜Regfile.v                            Register file
 ┃ ┣ 📜cpu.v                                Connect all submodule together
 ┃ ┣ 📜hci.v                                A data bus between UART/RAM and CPU
 ┃ ┣ 📜ram.v                                RAM
 ┃ ┗ 📜riscv_top.v                          Top design

```