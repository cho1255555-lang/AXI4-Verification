## Overview

오픈소스 AXI4 slave RAM([verilog-axi](https://github.com/alexforencich/verilog-axi)의 `axi_ram`)을 DUT로, 직접 설계한 UVM AXI4 Master Agent로 검증한 프로젝트입니다.

- Verification Plan 기반으로 handshake, burst(INCR/FIXED), narrow, unaligned 전송을 constrained random으로 검증
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

<img width="1280" height="720" alt="Axi4_ram IP검증 Block Diagram" src="https://github.com/user-attachments/assets/06a53373-648f-4410-b44b-ab5569d27ac4" />

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

## Regression & Coverage

- Seed 기반 Random Regression 수행
- 각 Seed별 Functional Coverage 수집
- xcrg를 이용하여 Coverage Merge
- HTML Report를 통한 Coverage Hole 분석
- 미달성 항목을 분석하고 추가 Sequence를 작성하여 보완

## Result

__Functional Coverage: 90%__

#### Coverage Report
<img width="1902" height="518" alt="image" src="https://github.com/user-attachments/assets/0a9079a8-b737-4417-8b2d-aa05b62f7d42" />

#### Covergroup 별 Coverage Report
<img width="938" height="739" alt="image" src="https://github.com/user-attachments/assets/50f5cf5b-4597-43a8-8122-d7ec08b3bb19" />
<img width="1865" height="907" alt="image" src="https://github.com/user-attachments/assets/3b329a37-48d8-4132-8eb9-c2160207c8f2" />

#### Log기반 Scoreboard 검증
<img width="448" height="140" alt="image" src="https://github.com/user-attachments/assets/34863938-8a4d-4423-b99c-3c42aec593c0" />

Seed별 Simulation Log 결과를 통해 Scoreboard Data Mismatch 0건 확인

## Issues & Solutions

### Issue 1. Cross Coverage에서 도달할 수 없는 Bin 발생

**문제 상황**
- Multi-beat Coverage에서 Size × Unaligned Offset Cross Coverage의 일부 Bin이 채워지지 않음
<img width="492" height="398" alt="스크린샷 2026-10-27 203834" src="https://github.com/user-attachments/assets/c90a7076-407c-4460-9c9b-c7f98abdc314" />


**분석**
- Unaligned 여부는 Transfer Size에 따른 정렬 기준으로 결정됨
- Size=0: Beat 크기가 1 Byte이므로 모든 주소가 정렬 상태이며 Unaligned Transfer가 발생할 수 없음
- Size=1: Beat 크기가 2 Byte이므로 Offset은 0 또는 1만 가능하며 Offset=1인 경우에만 Unaligned Transfer가 발생함

**원인**
- Transfer Size에 따라 달라지는 유효 Offset 범위를 고려하지 않고 모든 Offset 조합을 Cross Bin으로 설정함

**해결**
- AXI4 Specification을 기준으로 발생할 수 없는 조합을 ignore_bins로 처리하여 Coverage에서 제외함

**배운 점**
- Cross Coverage를 설계할 때는 단순히 변수 간 조합을 생성하는 것이 아니라 Specification을 기준으로 각 조합의 유효성을 먼저 판단해야한다는 것을 깨달음

---

### Issue 2. AW, W Channel Handshake Timing Coverage Hole 발생

**문제 상황**
- AW/W Handshake 순서 Coverage에서 **AW 선행** Bin만 수집되고, **W 선행**과 **동시 Handshake** Bin은 채워지지 않음

**분석**
- Coverage Hole의 원인을 파악하기 위해 DUT의 AW, W Handshake 처리 로직을 분석함
- 그 결과 AW Handshake가 완료된 이후에 WREADY를 Assert하는 구조임을 확인함
<img width="819" height="351" alt="스크린샷 2026-10-30 211050" src="https://github.com/user-attachments/assets/09613f17-c5e4-4775-966e-8ae60dd25a54" />


**원인**
- AXI4 Specification은 AW와 W 채널의 독립적인 Handshake를 허용하지만 해당 DUT는 AW Handshake가 완료되어야 WREADY를 Assert하므로 W 선행 및 동시 Handshake가 발생할 수 없음

**해결**
-  DUT의 동작 구조를 확인했고 해당 DUT에서 발생할 수 없는 Handshake 조합임을 확인하고 Coverage bin은 남겨놓지만 Verification Plan에 issue 명시

**배운 점**
- Coverage Hole이 반드시 Random Stimulus 부족을 의미하지는 않음. DUT의 설계 구조에 따라 도달할 수 없는 시나리오가 존재할 수 있으므로 RTL 분석을 통한 원인 파악도 필요하다는 것을 깨달음

---

### Issue 3. WRAP Burst Read 시 Scoreboard Data Mismatch 발생

**문제 상황**
- UVM Report Summary에서 Scoreboard Component의 Data Mismatch UVM_ERROR 발생을 확인함

**분석**
- Simulation Log를 통해 Mismatch가 발생한 Read Transaction을 추적하고 해당 주소에 대한 이전 Write Transaction을 확인함
<img width="1438" height="606" alt="스크린샷 2026-10-25 151054" src="https://github.com/user-attachments/assets/e82ce978-4cd3-44bb-bc0d-a91ab746d056" />


**원인**
- 해당 DUT는 FIXED와 INCR Burst만 지원하며, WRAP Burst는 지원하지 않음

**해결**
- WRAP Burst를 DUT 미지원 항목으로 Verification Plan에 issue를 명시하고 이후 Regression은 FIXED와 INCR Burst를 대상으로 진행

**배운 점**
- Scoreboard에서 Data Mismatch가 발생하면 단순히 오류 여부만 확인할 것이 아니라, Simulation Log로 Transaction 흐름을 추적하고 DUT의 지원 범위와 비교하여 원인을 분석하는 과정이 중요함을 깨달음

