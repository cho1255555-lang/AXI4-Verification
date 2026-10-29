# Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Verification Plan](#verification-plan)
- [Result](#result)
- [Issues & Solutions](#issues--solutions)
  - [Issue 1. AW, W Channel Handshake Coverage Hole 발생](#issue-1-aw-w-channel-handshake-coverage-hole-발생)
  - [Issue 2. WRAP Burst Transaction Data Mismatch 발생](#issue-2-wrap-burst-transaction-data-mismatch-발생)
  - [Issue 3. Cross Coverage에서 도달할 수 없는 Bin 발생](#issue-3-cross-coverage에서-도달할-수-없는-bin-발생)

# Overview

AXI4 Memory IP ([verilog-axi](https://github.com/alexforencich/verilog-axi)의 `axi_ram`)을 DUT로 선정하고, UVM 기반 AXI4 Master Agent를 설계하여 검증 환경을 구축했습니다. Verification Plan을 기반으로 Handshake, Burst, Narrow Transfer, Unaligned Transfer를 검증하고 Functional Coverage hole 분석과 Regression을 통해 검증 환경의 완성도를 높였습니다.

### 주요 검증 내용

- Verification Plan 기반으로 Handshake, Burst(INCR/FIXED), Narrow Transfer, Unaligned 전송을 Constrained Random Sequence로 Functional Coverage 검증
- spec 기반 SVA Protocol Checker로 버스 프로토콜 규칙 검증
- spec 기반 바이트 단위 메모리를 모델링하여 Scoreboard로 Write-Read 데이터 무결성 검증
- seed 기반 Regression으로 Coverage Hole을 분석하고 보완하여 Functional Coverage [90%] 달성

### Language and Tools

- **Language**: SystemVerilog
- **Methodology**: UVM 1.2
- **Assertions**: SystemVerilog Assertions (SVA)
- **Simulators**: Cadence Xcelium (EDA Playground), Vivado xsim 2023.2
- **Coverage**: xcrg (Functional Coverage Merge / HTML Report)

# Architecture

<img width="1280" height="720" alt="Axi4_ram IP검증 Block Diagram" src="https://github.com/user-attachments/assets/403860d7-ca4e-4c28-8fcf-b3b7e2346949" />


# Key Features
#### 1. Independent Channel Handshake
#### 2. Burst Transaction
-FIXED
-INCR
-WRAP
#### 3. Unaligned Transfer
#### 4. Narrow Transfer


# Verification Plan

| No | Feature | 검증 내용 | 검증 방법 | Test / Sequence | 상태 | 비고 |
|:---:|---|---|---|---|:---:|---|
| 1 | VALID 유지 | VALID는 handshake 완료 전까지 deassert되지 않음 | SVA | axi_base_test / hs_rand | 완료 | |
| 1-1 | VALID assert 시 payload 유지 | VALID가 assert시 handshake 완료 전까지 payload가 변하지 않음 | SVA | axi_base_test / hs_rand | 완료 | |
| 2 | Read Transaction Dependency | AR handshake 완료 전에는 RVALID가 assert되지 않음 | SVA | axi_base_test / hs_rand | 완료 | |
| 3 | Write Transaction Dependency | W, AW handshake 완료 후 BVALID 신호 assert | SVA | axi_base_test / hs_rand | 완료 | |
| 3-1 | W, AW handshake Timing | AW 선행, W 선행, 동시 handshake 3가지 경우 모두 발생 | Coverage | axi_base_test / hs_rand | 완료 |DUT 구조상 AW->W 순으로 READY 신호 assert되어 AW 선행만 가능|
| 4 | 데이터 무결성 | Write로 메모리에 저장한 데이터를 동일 주소로 Read 시 Write 데이터와 일치 | Scoreboard | axi_base_test / multi_beat_rand | 완료 | |
| 5 | Read/Write 병렬 | read와 write 채널 동시 구동 시 정상 동작 | Coverage + Scoreboard | - | 미진행 | Outstanding Transaction 검증 시 진행 |
| 6 | Narrow transfer | size < bus width인 모든 size 발생 | Coverage + Scoreboard | axi_base_test / multi_beat_rand | 완료 | |
| 7 | 주소 범위 | 생성된 주소가 DUT 주소 범위를 벗어나지 않고, 범위 내 모든 4KB 블록에 접근함 | Constraint + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 8 | 4KB boundary | INCR burst 시 4KB boundary를 넘지 않음 | Constraint + SVA | axi_base_test / multi_beat_rand | 완료 | |
| 9 | Write strobe | WSTRB 패턴에 따라 WSTRB=1인 유효한 lane만 저장 | Constraint + Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 10 | Unaligned Address Write Transfer | Unaligned Address Transfer시 첫 beat의 유효한 Lane만 Write | Constraint + Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 11 | Unaligned Address Read Transfer | Unaligned Address Transfer시 첫 beat의 유효한 Lane만 Read | Constraint + Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 12 | FIXED Burst | 모든 beat가 같은 주소에 쓰이고, read 시 마지막 beat 데이터와 일치 | Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 12-1 | FIXED length Limit | FIXED Burst beat 길이 16 이하 (AxLEN ≤ 15) | Constraint + SVA | axi_base_test / multi_beat_rand | 완료 | |
| 13 | INCR Burst | beat마다 주소가 size만큼 증가하며 데이터 일치 | Scoreboard + Coverage | axi_base_test / multi_beat_rand | 완료 | |
| 14 | WRAP Burst | WRAP boundary에서 주소가 되돌아가며 데이터 일치 | Constraint + Scoreboard + Coverage | - | 제외 | DUT가 WRAP Burst 미지원 |
| 14-1 | WRAP Burst len | WRAP burst 길이가 2/4/8/16 중 하나로 설정됨 | Constraint + SVA | - | 제외 | DUT가 WRAP Burst 미지원 |
| 14-2 | WRAP Burst address aligned | WRAP burst는 transfer size에 정렬된 주소에서만 시작 | Constraint + Scoreboard | - | 제외 |  DUT가 WRAP Burst 미지원 |
| 15 | WLAST | len에 따라 len+1 번째 beat에만 WLAST assert | SVA | axi_base_test / multi_beat_rand | 완료 | |
| 16 | RLAST | len에 따라 len+1 번째 beat에만 RLAST assert | SVA | axi_base_test / multi_beat_rand | 완료 | |
| 17 | BRESP | Write Transaction 완료시 00 OKAY response 확인 | Scoreboard | axi_base_test / multi_beat_rand | 완료 | |
| 18 | RRESP | Read Transaction 완료시 00 OKAY response 확인 | Scoreboard | axi_base_test / multi_beat_rand | 완료 | |

# Result

- **Functional Coverage: 90%**

### Coverage Report
---
<img width="263" height="147" alt="image" src="https://github.com/user-attachments/assets/a8dd220f-f12e-4e24-96da-7739cb49d917" />

### Covergroup 별 Coverage Report
---
<img width="599" height="797" alt="image" src="https://github.com/user-attachments/assets/5be288cf-d931-4af0-85c8-80efa6e5f135" />


<img width="907" height="376" alt="image" src="https://github.com/user-attachments/assets/62dec4ca-648e-40bd-ae49-78735fb99eec" />
<img width="491" height="284" alt="image" src="https://github.com/user-attachments/assets/b2db293e-83cc-49e6-94b3-34617c8b9c3c" />



### Log기반 Scoreboard 검증
---
<img width="444" height="155" alt="image" src="https://github.com/user-attachments/assets/dbcceb2e-6041-42eb-80c5-3f957244360c" />


- Seed별 Simulation Log 결과를 통해 Scoreboard Data Mismatch 0건 확인

# Issues & Solutions

## Issue 1. AW, W Channel Handshake Coverage Hole 발생

**문제 상황**
- Regression을 진행했지만 AW/W Handshake 순서 Coverage에서 **AW 선행** Bin만 수집되고, **W 선행**과 **동시 Handshake** Bin은 채워지지 않음

**분석**
- Coverage Hole의 원인을 파악하기 위해 Write transaction Waveform 분석
- 그 결과 매번 AWREADY가 먼저 assert된 뒤에 WREADY가 assert되는 것을 발견
- RTL 코드 확인하여 AW Handshake가 완료된 뒤에야 WREADY를 assert하는 구조인 것을 확인
<img width="1280" height="720" alt="Axi4_ram IP검증 Block Diagram" src="https://github.com/user-attachments/assets/cd13ca29-da5c-4d7a-8c7e-4a66ca609042" />


**원인**
- AXI4 Specification은 AW와 W 채널의 독립적인 Handshake를 허용하지만 해당 DUT는 AW Handshake가 완료되어야 WREADY를 Assert하므로 W 선행 및 동시 Handshake가 발생할 수 없음

**해결**
-  DUT의 동작 구조를 확인했고 해당 DUT에서 발생할 수 없는 Handshake 조합임을 확인하고 Verification Plan에 issue 명시

**배운 점**
- Coverage Hole을 분석할 때 DUT의 RTL 구조 한계에 따른 시나리오 미발생 가능성도 함께 검토해야 함을 깨닫게 됨

## Issue 2. WRAP Burst Transaction Data Mismatch 발생

**문제 상황**
- Scoreboard에서 Data Mismatch 발생
- 에러는 모두 WRAP Burst에서 발생했지만 WRAP Burst 중에도 Match된 Case가 존재해 원인 특정 불가

**분석**
- Scoreboard Log에서 WRAP Burst의 Match/Mismatch Transaction을 비교해 WRAP Boundary를 넘는 Transaction에서만 Mismatch가 발생함을 확인
- Address 0x4C, AxSIZE=2, AxLEN=3 (4 beat) WRAP Write 시 0x4C → 0x40 → 0x44 → 0x48 순으로 저장되어야 하지만 DUT는 0x4C → 0x50 → 0x54 → 0x58 순으로 저장해 0x50 Read 시 0x40에 있어야 할 Data가 Read되는 것을 확인
<img width="1438" height="606" alt="스크린샷 2026-10-25 151054" src="https://github.com/user-attachments/assets/e82ce978-4cd3-44bb-bc0d-a91ab746d056" />

**원인**
- 해당 DUT는 WRAP burst를 지원하지 않아 Wrap-around 로직을 구현하지 않음

**해결**
- WRAP Burst에 대한 상황 Log를 Capture하고 Verification Plan에 상황을 명확히 기록

**배운 점**
- 로그를 비교하고 분석하며 Data Mismatch의 원인을 구체화하고 찾아내는 방법 학습

## Issue 3. Cross Coverage에서 도달할 수 없는 Bin 발생

**문제 상황**
- Multi beat Coverage에서 Size × Unaligned Offset Cross Coverage의 일부 Bin이 채워지지 않음

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






