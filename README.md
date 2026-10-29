## Overview

오픈소스 AXI4 slave RAM([verilog-axi](https://github.com/alexforencich/verilog-axi)의 `axi_ram`)을 DUT로, 직접 설계한 UVM AXI4 Master Agent로 검증한 프로젝트입니다.

- Verification Plan 기반으로 handshake, burst(INCR/FIXED), narrow·unaligned 전송을 constrained random으로 검증
- spec 기반 SVA protocol checker로 버스 프로토콜 규칙 검증
- spec 기반 바이트 단위 메모리를 모델링하여 scoreboard로 write-read 데이터 무결성 검증
- seed 기반 regression으로 coverage hole을 분석하고 보완하여 functional coverage [90%] 달성

### Language and Tools

- **Language**: SystemVerilog
- **Methodology**: UVM 1.2
- **Assertions**: SystemVerilog Assertions (SVA)
- **Simulators**: Cadence Xcelium (EDA Playground), Vivado xsim 2023.2
- **Coverage**: xcrg (functional coverage merge / HTML report)
- **Scripting**: Windows Batch (regression, log parsing, coverage merge)

## Architecture

## Key Features
### Independent Channel Handshake
### Burst Transaction
-FIXED
-INCR
-WRAP
### Unaligned Transfer
### Narrow Transfer
