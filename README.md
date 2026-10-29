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
<img width="1280" height="720" alt="슬라이드1" src="https://github.com/user-attachments/assets/639a3b83-a88c-47da-8475-d173c9b772b2" />

## Key Features
#### Independent Channel Handshake
#### Burst Transaction
-FIXED
-INCR
-WRAP
#### Unaligned Transfer
#### Narrow Transfer

## Verification Plan

| No | Feature | 검증 내용 | 검증 방법 | Test / Sequence | 상태 | 비고 |
|:---:|---|---|---|---|:---:|---|
| 1 | VALID 유지 | VALID는 handshake 완료 전까지 deassert되지 않음 | SVA | axi_base_test / hs_rand | 완료 | |
| 1-1 | VALID assert 시 payload 유지 | VALID가 assert시 handshake 완료 전까지 payload가 변하지 않음 | SVA | axi_base_test / hs_rand | 완료 | |
| 2 | Read Transaction Dependency | AR handshake 완료 전에는 RVALID가 assert되지 않음 | SVA | axi_base_test / hs_rand | 완료 | |
| 3 | Write Transaction Dependency | W, AW handshake 완료 후 BVALID 신호 assert | SVA | axi_base_test / hs_rand | 완료 | |
| 3-1 | W, AW handshake Timing | AW 선행, W 선행, 동시 handshake 3가지 경우 모두 발생 | Coverage | axi_base_test / hs_rand | 완료 | |
| 4 | Write → Read 데이터 무결성 | 쓴 데이터를 같은 주소에서 읽으면 일치 | Scoreboard | axi_base_test / multi_beat_rand | 완료 | |
| 5 | Read/Write 병렬 | read와 write 채널 동시 구동 시 정상 동작 | Coverage + Scoreboard | - | 미진행 | Outstanding Transaction 검증 시 진행 |
| 6 | Narrow transfer | size < bus width인 모든 size 발생 | Coverage + Scoreboard | axi_base_test / multi_beat_rand | 완료 | |
| 7 | 주소 범위 | 생성된 주소가 DUT 주소 범위를 벗어나지 않고, 범위 내 모든 4KB 블록에 접근함 | Constraint + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 8 | 4KB boundary | INCR burst가 하나의 4KB 페이지를 넘지 않음 | Constraint + SVA | axi_base_test / multi_beat_rand | 완료 | |
| 9 | Write strobe | WSTRB 패턴에 따라 WSTRB=1인 유효한 lane만 저장 | Constraint + Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 10 | Unaligned Address Write Transfer | Unaligned Address Transfer시 첫 beat의 유효한 Lane만 Write | Constraint + Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 11 | Unaligned Address Read Transfer | Unaligned Address Transfer시 첫 beat의 유효한 Lane만 Read | Constraint + Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 12 | FIXED Burst | 모든 beat가 같은 주소에 쓰이고, read 시 마지막 beat 데이터와 일치 | Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 12-1 | FIXED length Limit | FIXED Burst beat 길이 16 beat 이하 (AxLEN ≤ 15) | Constraint + SVA | axi_base_test / multi_beat_rand | 완료 | |
| 13 | INCR Burst | beat마다 주소가 size만큼 증가하며 데이터 일치 | Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 14 | WRAP Burst | WRAP boundary에서 주소가 되돌아가며 데이터 일치 | Constraint + Scoreboard + Coverage | - | 미진행 | Constraint 구현, DUT가 WRAP Burst 미지원 |
| 14-1 | WRAP Burst len | WRAP burst 길이가 2/4/8/16 중 하나로 설정됨 | Constraint + SVA | - | 미진행 | Constraint 구현, DUT가 WRAP Burst 미지원 |
| 14-2 | WRAP Burst address aligned | WRAP burst는 transfer size에 정렬된 주소에서만 시작 | Constraint + Scoreboard | - | 미진행 | Constraint 구현, DUT가 WRAP Burst 미지원 |
| 15 | WLAST | len에 따라 len+1 번째 beat에만 WLAST assert | SVA | axi_base_test / multi_beat_rand | 완료 | |
| 16 | RLAST | len에 따라 len+1 번째 beat에만 RLAST assert | SVA | axi_base_test / multi_beat_rand | 완료 | |
| 17 | BRESP | Write Transaction 완료시 00 OKAY response 확인 | Scoreboard | axi_base_test / multi_beat_rand | 완료 | |
| 18 | RRESP | Read Transaction 완료시 00 OKAY response 확인 | Scoreboard | axi_base_test / multi_beat_rand | 완료 | |

## Result
<img width="1902" height="518" alt="image" src="https://github.com/user-attachments/assets/0a9079a8-b737-4417-8b2d-aa05b62f7d42" />
