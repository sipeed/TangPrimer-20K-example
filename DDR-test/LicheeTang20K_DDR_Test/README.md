# LicheeTang20K_DDR_Test
The DDR Test Firmware for LicheeTang20K.

## Environment
GOWIN FPGA IDE V1.9.8.05 

## Output
8-bit data, 1 stop bit, no parity, 115200 baud 

## Others
Perform Reset Every 100s.  
The fill rate and the check rate is limited by the LFSR, whose output rate is about 12MBps.  
For a 1Gbits version, each fill/check stage consumes about 11s.  
And for a 2Gbits version, each fill/check stage consumes about 22s.  

## Example Output
Perform Reset  
Auto Reset Every 100s  
Init Complete  
DDR Size: 1G  
Begin to Fill  
Fill Stage 1 Finished  
Begin to Check Stage 1 
Check Stage 1 Finished without Mismatch  
Begin to Fill Stage 2  
Fill Stage 2 Finished  
Begin to Check Stage 2  
Check Stage 2 Finished without Mismatch  
Test Finished  

---

In this firmware, the DDR3 interface belongs to Gowin, and is limited to be used in the GOWIN FPGA Designer.  
In the branch __slowDDR3__, there is a open source DDR3 interface.

The Gowin DDR3 IP is faster than the __slowDDR3__ and larger than it.  
If you wish to use the __slowDDR3__, please checkout to __slowDDR3__ branch.  

This DDR3 IP runs at DDR-800.  
Its maxium read/write rate is about 11,000MBits/s (when using 64 bursts).  

The __slowDDR3__ runs at DDR-80.  
Its write rate is about 240Mbits/s and the read rate is about 300Mbits/s.  

Gowin DDR3 IP consumes 1288 Regs, 1363 LUTs, 102 ALUs, 8 BSRAMs and 110 SSRAMs.  
While __slowDDR3__ consumes 147 Regs and 216 LUTs.  
