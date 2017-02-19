kivantium
==============
[![Build Status](https://travis-ci.org/kivantium/kivantium.svg?branch=master)](https://travis-ci.org/kivantium/kivantium)

The core of kivantium CPU.

For more information, please check [Wiki](https://github.com/kivantium/kivantium/wiki).

Progress
--------
- 2016/10/11 `syscall` and `ori` are partially implemented. (able to run `simulator/test/ori.asm`) 
- 2016/10/16 `addiu`, `addu`, `jr`, `ori`, `slti`, `syscall` are partially implemented (able to run each test case. However, there are many GACHA element to success.)
- 2016/10/19 learned how to use Block RAM
- 2016/10/24 instructions except `sw` and `lw` are working
- 2016/11/01 recursive fib succeeded. [Video](https://twitter.com/kivantium/status/793435185488404481)
- 2017/02/19 RISV-V based ISA worked in simulation.

LICENSE
--------
This project is licensed under the terms of the MIT license.
