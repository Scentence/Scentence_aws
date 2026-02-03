# 🚀 Scentence CI/CD 가이드

## 📋 개요

이 프로젝트는 GitHub Actions를 사용하여 자동 테스트 및 배포를 수행합니다.

```
Scentence_aws_test/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml          ✅ 자동 테스트 (PR 시)
│   │   ├── deploy.yml      ✅ 자동 배포 (main push 시)
│   │   └── rollback.yml    ✅ 롤백 (수동)
│   └── README.md           ✅ 워크플로우 가이드
├── scripts/
│   ├── deploy.sh           ✅ 배포 스크립트
│   └── rollback.sh         ✅ 롤백 스크립트
```

## 🔧 워크플로우

### 1. CI (Continuous Integration) - `ci.yml`
- **트리거**: PR 생성 또는 main/develop 브랜치에 push
- **작업**:
  - Backend 테스트 및 Lint
  - Frontend 테스트 및 Lint
  - Scentmap 테스트
  - Layering 테스트

### 2. CD (Continuous Deployment) - `deploy.yml`
- **트리거**: main 브랜치에 push 또는 수동 실행
- **작업**:
  - EC2 서버에 SSH 접속
  - 최신 코드 pull
  - Docker 컨테이너 재빌드 및 재시작
  - 헬스체크

### 3. Rollback - `rollback.yml`
- **트리거**: 수동 실행만 가능
- **작업**:
  - 이전 커밋으로 되돌리기
  - Docker 재시작
  - 헬스체크

## 🔐 필수 Secrets 설정

GitHub Repository → Settings → Secrets and variables → Actions에서 설정:

| Secret 이름 | 설명 | 예시 |
|-------------|------|------|
| `EC2_HOST` | EC2 퍼블릭 IP 또는 도메인 | `12.34.56.78` 또는 `yourdomain.com` |
| `EC2_USER` | EC2 SSH 사용자명 | `ubuntu` |
| `EC2_SSH_KEY` | EC2 SSH Private Key (전체 내용) | `-----BEGIN RSA PRIVATE KEY-----...` |

## 📝 배포 프로세스

### 자동 배포 (Automatic)
```bash
# 1. 코드 수정
git add .
git commit -m "새 기능 추가"

# 2. main 브랜치에 push
git push origin main

# 3. 🤖 자동으로 배포 시작!
# GitHub Actions가 자동으로 EC2에 배포합니다.
```

### 수동 배포 (Manual)
1. GitHub Repository → Actions
2. "CD - Deploy to EC2" 워크플로우 선택
3. "Run workflow" 버튼 클릭
4. 브랜치 선택 → "Run workflow"

### 롤백 (Rollback)
1. GitHub Repository → Actions
2. "Rollback - 이전 버전으로 되돌리기" 선택
3. "Run workflow" 클릭
4. (선택) 특정 커밋 SHA 입력
5. "Run workflow"

## 🔍 배포 상태 확인

### GitHub Actions 로그
- Repository → Actions → 최근 워크플로우 실행 클릭

### 직접 확인
```bash
# SSH 접속
ssh -i <your-key-file>.pem ubuntu@<your-ec2-ip>

# Docker 상태 확인
docker ps

# 로그 확인
docker compose -f docker-compose.production.yml logs -f
```

## ⚠️ 주의사항

1. **절대 커밋하지 말아야 할 파일**:
   - `.env` (환경변수)
   - `*.pem` (SSH 키)
   - `*.key` (인증 키)

2. **배포 전 체크리스트**:
   - [ ] 로컬에서 테스트 완료
   - [ ] `.env` 파일에 민감 정보 없는지 확인
   - [ ] 커밋 메시지 명확히 작성

3. **배포 실패 시**:
   - GitHub Actions 로그 확인
   - EC2 SSH 접속하여 Docker 로그 확인
   - 필요시 Rollback 워크플로우 실행

## 🎯 배포 후 확인 사항

- [ ] 웹사이트 정상 접속: https://scentence.kro.kr
- [ ] Backend API: https://scentence.kro.kr/api/backend-openapi
- [ ] Scentmap: https://scentence.kro.kr/api/scentmap-health
- [ ] Layering: https://scentence.kro.kr/api/layering-health

## 📊 배포 히스토리

모든 배포는 GitHub Actions에서 확인 가능:
- Repository → Actions → Workflow runs
