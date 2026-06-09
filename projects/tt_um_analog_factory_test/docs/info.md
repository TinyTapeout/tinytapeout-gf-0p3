## How it works

It's a couple of big current mirror loads.

A reference current is input, it's multiplied internally by about 50x and draws
from selected power rail.

A few sense wires are routed out allowing to measure both voltage drop of the
power rails as well as the voltage raise of the VGND rail.


## How to test

Provide a test current to the iref input, then toggle the appropriate enable
pin to enable to current mirror load on the power rail to be tested.


## External hardware

* Programmable current source
* Precision multimeter
