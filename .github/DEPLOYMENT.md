# 🚀 Scentence 프로덕션 배포 가이드

## 📋 개요

이 레포지토리는 **프로덕션 배포 전용**입니다. 
개발용 레포지토리에서 검사를 완료한 코드가 PR을 통해 이 레포로 병합됩니다.

```
Scentence_aws_test/
├── .github/
│   ├── workflows/
│   │   ├── deploy.yml      🔧 배포 워크플로우 (수동 트리거)
│   │   └── rollback.yml    ✅ 롤백 워크플로우 (수동)
│   └── DEPLOYMENT.md       ✅ 배포 가이드
├── scripts/
│   ├── deploy.sh           ✅ 배포 스크립트
│   └── rollback.sh         ✅ 롤백 스크립트
```

> ⚠️ **현재 배포 방식: 수동 트리거 → 자동 배포**  
> PR마다 배포가 여러 번 트리거되는 이슈로 인해, 현재는 수동으로 워크플로우를 실행합니다.  
> 실행 후에는 GitHub Actions가 자동으로 EC2에 배포를 진행합니다.  

## 🔄 배포 프로세스 플로우

```
[개발 레포] 
   ↓ (코드 작성 & 테스트)
   ↓ (CI: Lint, Test 통과)
   ↓ (코드 리뷰 완료)
   ↓
[프로덕션 레포 PR 생성]
   ↓ (충돌 확인)
   ↓ (PR 승인)
   ↓
[main 브랜치 merge]
   ↓
[⏸️  배포 대기 상태]
   ↓
[👤 배포 담당자가 워크플로우 실행]  ← 수동 트리거
   ↓
[🤖 GitHub Actions 자동 실행]    ← 이후 자동화
   ├─ EC2 SSH 접속
   ├─ 코드 Pull
   ├─ Docker 재빌드
   └─ 헬스체크
   ↓
[✅ EC2 프로덕션 서버 배포 완료]
```

## 🔧 워크플로우

### 1. CD (Continuous Deployment) - `deploy.yml`
- **트리거 방식**: ~~자동 트리거~~ → **수동 트리거 (현재)**
- **배포 프로세스**: 트리거 후 **자동으로 EC2에 배포**
- **실행 단계** (자동화):
  - EC2 서버에 SSH 접속
  - 최신 코드 pull
  - Docker 컨테이너 재빌드 및 재시작
  - 헬스체크 수행
  - 배포 결과 알림

> ⚠️ **자동 트리거 비활성화 이유**  
> PR마다 배포가 여러 번 트리거되는 이슈로 인해, 현재는 수동으로 워크플로우를 실행합니다.  
> 워크플로우 실행 후에는 모든 배포 과정이 자동으로 진행됩니다.

### 2. Rollback - `rollback.yml`
- **트리거**: 수동 실행만 가능
- **작업** (자동화):
  - 이전 커밋으로 되돌리기
  - Docker 재시작
  - 헬스체크

> ℹ️ **CI는 개발 레포에서 완료됩니다**  
> 이 레포는 이미 검증된 코드만 받으므로 별도의 CI 워크플로우가 없습니다.

## 🔐 필수 Secrets 설정

GitHub Repository → Settings → Secrets and variables → Actions에서 설정:

| Secret 이름 | 설명 | 예시 |
|-------------|------|------|
| `EC2_HOST` | EC2 퍼블릭 IP 또는 도메인 | `12.34.56.78` 또는 `yourdomain.com` |
| `EC2_USER` | EC2 SSH 사용자명 | `ubuntu` |
| `EC2_SSH_KEY` | EC2 SSH Private Key (전체 내용) | `-----BEGIN RSA PRIVATE KEY-----...` |

## 📝 배포 프로세스

### 1단계: PR 생성 및 Merge

```bash
# 1. 개발 레포에서 작업 완료 후

# 2. 프로덕션 레포에 PR 생성
# - 제목: "[배포] 기능명 또는 버전"
# - 내용: 배포할 변경사항 요약

# 3. PR 검토 및 승인
# - 충돌 여부 확인
# - 변경사항 최종 검토

# 4. PR Merge
# - "Squash and merge" 또는 "Merge pull request" 선택
# - Merge 완료
```

### 2단계: 배포 워크플로우 실행 (현재 운영 방식)

PR이 main에 merge된 후, 배포 담당자가 워크플로우를 수동으로 트리거합니다:

**👤 수동 작업 (트리거)**
1. **GitHub Repository → Actions**
2. **"CD - Deploy to EC2" 워크플로우 선택**
3. **"Run workflow" 버튼 클릭**
4. **브랜치 선택 (main) → "Run workflow" 클릭**

**🤖 자동 실행 (배포 프로세스)**
5. GitHub Actions가 자동으로 다음을 수행:
   - EC2 SSH 접속
   - 최신 코드 Pull
   - Docker 컨테이너 재빌드
   - 서비스 재시작
   - 헬스체크 수행
6. 배포 완료! (약 5-10분 소요)

**✅ 배포 후 확인**
7. Actions 로그에서 배포 성공 확인
8. 프로덕션 서비스 헬스체크
9. 최소 10분간 모니터링

> 💡 **배포 타이밍 권장사항**  
> - 트래픽이 적은 시간대 (새벽 2-4시 또는 점심시간)
> - 긴급 배포가 아니라면 팀원들과 배포 시간 공유
> - 금요일 오후 배포는 가급적 피하기

### 향후: 자동 트리거 방식 (예정)

워크플로우 개선 후 다시 활성화 예정:
- PR merge 시 자동으로 워크플로우 트리거
- 중복 실행 방지 로직 추가
- 배포 완료 알림 자동화
- 배포 결과 Slack/Discord 알림

### 3단계: 롤백 (문제 발생 시)

배포 후 문제가 발생한 경우, 이전 버전으로 되돌립니다:

**👤 수동 작업 (트리거)**
1. **GitHub Repository → Actions**
2. **"Rollback - 이전 버전으로 되돌리기" 선택**
3. **"Run workflow" 클릭**
4. **(선택) 특정 커밋 SHA 입력** (비워두면 직전 커밋으로 롤백)
5. **"Run workflow" 실행**

**🤖 자동 실행 (롤백 프로세스)**
6. GitHub Actions가 자동으로:
   - 이전 커밋으로 코드 되돌리기
   - Docker 컨테이너 재시작
   - 헬스체크 수행
7. 롤백 완료!

**✅ 롤백 후 확인**
8. 서비스가 정상적으로 작동하는지 확인
9. 문제 원인 파악 및 개발 레포에서 수정

## 🔍 배포 상태 확인

### GitHub Actions 로그
- Repository → Actions → 최근 워크플로우 실행 클릭
- 각 단계별 로그 확인 가능

### 직접 EC2 서버 확인

```bash
# SSH 접속
ssh -i <your-key-file>.pem ubuntu@<your-ec2-ip>

# Docker 컨테이너 상태 확인
docker ps

# 실시간 로그 확인
docker compose -f docker-compose.production.yml logs -f

# 특정 서비스 로그만 확인
docker compose -f docker-compose.production.yml logs -f backend
docker compose -f docker-compose.production.yml logs -f frontend
```

## ⚠️ 주의사항

### 1. 이 레포지토리는 프로덕션 전용입니다
- ❌ 직접 코드 수정 금지
- ❌ main 브랜치에 직접 push 금지
- ✅ 개발 레포에서 검증된 코드만 PR로 받기
- ✅ PR 승인 후 merge로만 배포

### 2. 절대 커밋하지 말아야 할 파일
- `.env` (환경변수)
- `*.pem` (SSH 키)
- `*.key` (인증 키)
- 개인 정보 또는 민감 정보

### 3. PR 생성 전 체크리스트
- [ ] 개발 레포에서 모든 테스트 통과
- [ ] 코드 리뷰 완료
- [ ] 변경사항 문서화 완료
- [ ] 충돌 없음 확인

### 4. 워크플로우 실행 전 체크리스트
- [ ] PR이 main에 merge되었는지 확인
- [ ] PR 내용 최종 검토 완료
- [ ] 배포 타이밍 적절한지 확인 (트래픽이 적은 시간)
- [ ] 롤백 계획 수립
- [ ] 다른 팀원이 배포 중이지 않은지 확인

### 5. 배포 실패 시 대응
1. GitHub Actions 로그 확인
2. EC2 SSH 접속하여 Docker 로그 확인
3. 즉시 Rollback 워크플로우 실행
4. 문제 원인 파악 후 개발 레포에서 수정
5. 다시 PR 생성

## 🎯 워크플로우 실행 후 확인 사항

워크플로우가 완료되면 아래 항목들을 반드시 확인하세요:

**1. GitHub Actions 확인**
- [ ] 워크플로우가 성공적으로 완료되었는지 확인 (녹색 체크)
- [ ] 각 단계별 로그 확인 (실패한 단계가 있는지)

**2. 서비스 헬스체크**
- [ ] 웹사이트 정상 접속: https://scentence.kro.kr
- [ ] Backend API: https://scentence.kro.kr/api/backend-openapi
- [ ] Scentmap: https://scentence.kro.kr/api/scentmap-health
- [ ] Layering: https://scentence.kro.kr/api/layering-health

**3. 기능 테스트**
- [ ] 주요 기능 동작 확인 (회원가입, 로그인 등)
- [ ] 새로 배포한 기능이 정상 작동하는지 확인
- [ ] 기존 기능에 문제가 없는지 확인

**4. 모니터링**
- [ ] 에러 로그 모니터링 (최소 10분)
- [ ] 서버 리소스 사용률 확인
- [ ] 사용자 피드백 모니터링

## 📊 배포 히스토리

모든 배포는 GitHub에서 추적 가능:
- **PR 기록**: Pull requests → Closed
- **배포 로그**: Actions → Workflow runs
- **커밋 이력**: Commits → main 브랜치

## 🆘 트러블슈팅

### 배포가 시작되지 않을 때
- 현재는 수동 트리거만 가능합니다 (자동 트리거 비활성화 상태)
- GitHub Actions → "CD - Deploy to EC2"에서 "Run workflow" 버튼으로 실행하세요
- Secrets 설정이 올바른지 확인 (EC2_HOST, EC2_USER, EC2_SSH_KEY)

### 배포가 여러 번 실행될 때 (Known Issue)
- 이 문제로 인해 현재 자동 트리거가 비활성화되었습니다
- 수동 트리거를 사용하여 중복 실행을 방지합니다
- 워크플로우 파일의 트리거 조건 개선 필요
- ⚠️ "Run workflow" 버튼을 여러 번 클릭하지 마세요!

### 워크플로우는 실행됐는데 배포가 안 될 때
- GitHub Actions 로그를 확인하세요 (어느 단계에서 실패했는지)
- EC2 SSH 키가 올바른지 확인
- EC2 서버가 정상 작동하는지 확인
- Docker 관련 오류는 EC2에 직접 접속하여 확인

### 배포는 성공했지만 서비스가 안 될 때
- EC2 서버 상태 확인
- Docker 컨테이너 로그 확인
- 환경 변수 설정 확인
- 포트 및 방화벽 설정 확인

### 긴급 상황
1. 즉시 Rollback 실행
2. 팀에 알림
3. 로그 수집 및 분석
4. 원인 파악 후 핫픽스 준비

<br>

---

**마지막 업데이트**: 2026-02-03  
**배포 방식**: 수동 트리거 → 자동 배포 (자동 트리거 일시 비활성화)  
**관리자**: Scentence 팀