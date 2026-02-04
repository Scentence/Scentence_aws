# 🌸 Scentence - 프로덕션 배포 레포지토리

> **이 레포지토리는 프로덕션 배포 전용입니다.**  
> 개발 및 테스트는 [개발 레포지토리](https://github.com/Scentence/Scentence)에서 진행됩니다.

## 📍 서비스 접속

| 서비스 | URL |
|--------|-----|
| **🌐 프로덕션 사이트** | https://scentence.kro.kr |
| **📚 API 문서** | https://scentence.kro.kr/api/backend-openapi |
| **🗺️ Scentmap Health** | https://scentence.kro.kr/api/scentmap-health |
| **🎨 Layering Health** | https://scentence.kro.kr/api/layering-health |

---

## 🏗️ 시스템 아키텍처

### 인프라 구성

```
┌─────────────────────────────────────────────────────┐
│                   CloudFront CDN                    │
│               (Profile Image Deploy)                │
└─────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────┐
│            Application Load Balancer                │
│           (SSL/TLS Termination - ACM)               │
└─────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────┐
│                   EC2 Instance                      │
│                 (Docker Compose)                    │
│    ┌──────────┬──────────┬──────────┬──────────┐    │
│    │ Frontend │ Backend  │ Scentmap │ Layering │    │
│    │ Next.js  │ FastAPI  │ FastAPI  │ FastAPI  │    │
│    │  :3000   │  :8000   │  :8001   │  :8002   │    │
│    └──────────┴──────────┴──────────┴──────────┘    │
└─────────────────────────────────────────────────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
    ┌───────▼────────┐       ┌────────▼────────┐
    │ RDS PostgreSQL │       │     AWS S3      │
    │ & pgvector     │       │ (Profile Image) │
    └────────────────┘       └─────────────────┘
```

### 주요 컴포넌트

| 컴포넌트 | 기술 스택 | 포트 | 설명 |
|---------|----------|------|------|
| **Frontend** | Next.js 16 | 3000 | 사용자 인터페이스 |
| **Backend** | FastAPI | 8000 | 회원가입, 챗봇, 향수옷장 API |
| **Scentmap** | FastAPI | 8001 | 향수 지도 시각화 서비스 |
| **Layering** | FastAPI | 8002 | 향수 레이어링 추천 서비스 |
| **Database** | PostgreSQL 17 + pgvector | 5435 | 메인 데이터베이스) |
| **Storage** | AWS S3 + CloudFront | - | 프로필 이미지 저장 및 배포 |
| **Load Balancer** | AWS ALB | 80/443 | 부하 분산 및 SSL 종료 |
| **SSL/TLS** | AWS ACM | - | SSL 인증서 관리 |

---

## 💻 프로덕션 서버 사양

### EC2 인스턴스

| 항목 | 사양 |
|------|------|
| **인스턴스 타입** | t3.large |
| **vCPU** | 2 코어 |
| **메모리** | 8GB RAM |
| **스토리지** | 30GB EBS (gp3) |
| **운영체제** | Ubuntu 22.04 LTS |
| **리전** | ap-northeast-2 (서울) |

### 데이터베이스

| 항목 | 사양 |
|------|------|
| **엔진** | PostgreSQL 17 |
| **확장** | pgvector (벡터 검색) |
| **데이터베이스** | `perfume_db`, `recom_db`, `member_db` |

---

## 🔧 소프트웨어 버전

| 소프트웨어 | 버전 | 비고 |
|-----------|------|------|
| **Docker** | 29.2.0 | 컨테이너 런타임 |
| **Docker Compose** | v5.0.2 | 오케스트레이션 도구 |
| **Node.js** | 20.x(LTS) | Frontend 빌드용 (Next.js 16.1.1) |
| **Python** | 3.11 | Backend 서비스용 (FastAPI + Uvicorn) |
| **PostgreSQL** | 17.x | pgvector 확장 포함 |
| **AWS ALB** | - | 리버스 프록시 및 SSL 종료 역할 |

> 💡 **리버스 프록시**: Nginx 대신 AWS Application Load Balancer 사용

---

## 🔐 환경변수 설정

프로덕션 환경변수는 **EC2 서버의 `.env` 파일**에 설정되어 있습니다.

### 환경변수 카테고리

- 🗄️ **데이터베이스**: RDS, VectorDB PostgreSQL 연결 정보
- ☁️ **AWS 자격증명**: S3, CloudFront 접근용
- 🤖 **AI 서비스**: OpenAI, LangSmith API 키
- 👤 **관리자 설정**: 관리자 이메일 목록
- 🔒 **인증**: Kakao OAuth, NextAuth 시크릿

### 환경변수 파일 위치

```bash
# EC2 서버
/home/ubuntu/Scentence_aws/.env
```

### 환경변수 템플릿

자세한 환경변수 목록 및 설명은 [`../.env.example`](../.env.example) 파일을 참조하세요.

---

## 📚 배포 관련 문서

### 배포 프로세스

- 📖 **[배포 가이드](./DEPLOYMENT.md)** - 전체 배포 프로세스 및 워크플로우
- 🔄 **[롤백 가이드](./DEPLOYMENT.md#3단계-롤백-문제-발생-시)** - 긴급 롤백 방법
- ✅ **[배포 후 확인사항](./DEPLOYMENT.md#-워크플로우-실행-후-확인-사항)** - 헬스체크 및 모니터링

### GitHub Actions

- 🚀 [Deploy Workflow](./workflows/deploy.yml) - 자동 배포 워크플로우
- ⏮️ [Rollback Workflow](./workflows/rollback.yml) - 롤백 워크플로우

---

## 🚀 로컬에서 프로덕션 환경 테스트

프로덕션 설정으로 로컬에서 테스트하는 방법:

```bash
# 1. 레포지토리 클론
git clone <repository-url>
cd Scentence_aws

# 2. 환경변수 설정
cp .env.example .env
# .env 파일을 실제 값으로 수정

# 3. 프로덕션 모드로 실행
docker compose -f docker-compose.production.yml up --build

# 4. 접속 확인
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000/docs
# Scentmap: http://localhost:8001/health
# Layering: http://localhost:8002/health
```

### 컨테이너 중지 및 정리

```bash
# 컨테이너 중지
docker compose -f docker-compose.production.yml down

# 볼륨까지 삭제 (DB 데이터 초기화)
docker compose -f docker-compose.production.yml down -v
```

---

## 📊 모니터링 및 로그

### 헬스체크 엔드포인트

| 서비스 | 헬스체크 URL |
|--------|-------------|
| **Backend** | https://scentence.kro.kr/api/backend-openapi |
| **Scentmap** | https://scentence.kro.kr/api/scentmap-health |
| **Layering** | https://scentence.kro.kr/api/layering-health |

### EC2 서버 로그 확인

```bash
# EC2 서버 접속
ssh -i your-key.pem ubuntu@<server-ip>

# 전체 서비스 로그 (실시간)
docker compose -f docker-compose.production.yml logs -f

# 특정 서비스 로그
docker compose logs -f frontend
docker compose logs -f backend
docker compose logs -f scentmap
docker compose logs -f layering

# 최근 로그만 보기
docker compose logs --tail=100 frontend
```

### 컨테이너 상태 확인

```bash
# 실행 중인 컨테이너 확인
docker ps

# 리소스 사용량 확인
docker stats
```

---

## 👥 담당자 및 연락처

### 배포 담당
- **배포 총괄**: [@sosodoit]

### 백엔드 담당
- **향수추천**: [@Melonmacaron]
- **레이어링**: [@gitsgetit]
- **향수지도**: [@sosodoit]
- **향수옷장**: [@souluk319]
- **회원가입**: [@ChocolateStrawberryYumYum]

### 프론트엔드 담당
- **프론트엔드**: [@souluk319]

### AI/데이터 담당
- **데이터수집**: [@Melonmacaron], [@gitsgetit], [@ChocolateStrawberryYumYum]
- **향수사전구축**: [@gitsgetit], [@ChocolateStrawberryYumYum]
- **향수추천**: [@Melonmacaron], [@GitHub_ID_2]
- **레이어링**: [@gitsgetit]
- **향수지도**: [@sosodoit]

---

## 🆘 긴급 상황 대응

### 장애 발생 시 조치

1. **즉시 롤백 실행**
   - GitHub Actions → Rollback 워크플로우 실행
   - 자세한 방법: [롤백 가이드](./DEPLOYMENT.md#3단계-롤백-문제-발생-시)

2. **담당자에게 연락**
   - 배포 담당자에게 Discord로 긴급 연락
   - 해당 기능 담당자에게 상황 전달

3. **장애 보고서 작성**
   - [GitHub Issues](../../issues)에 장애 내용 기록
   - 발생 시간, 증상, 조치 내용 상세 기록

### 유용한 링크

- 🔄 [GitHub Actions](../../actions) - 배포 히스토리 및 로그
- 🐛 [Issues](../../issues) - 버그 및 장애 보고
- 📥 [Pull Requests](../../pulls) - 배포 대기 중인 PR 목록

---

## 🔒 보안 주의사항

### ⚠️ 절대 커밋 금지 항목

다음 파일들은 **절대 Git에 커밋하지 마세요**:

- `.env` - 환경변수 파일
- `*.pem` - SSH 개인 키
- `*.key` - 인증 키 파일
- 비밀번호, API 키 등 민감 정보

---

## 📁 프로젝트 구조

```
Scentence_aws/
├── .github/
│   ├── workflows/                 # GitHub Actions 워크플로우
│   │   ├── deploy.yml             # 배포 자동화
│   │   └── rollback.yml           # 롤백 자동화
│   ├── DEPLOYMENT.md              # 배포 가이드
│   └── README.md                  
├── frontend/                      # Next.js 프론트엔드
│   ├── app/                       # App Router
│   ├── components/                # React 컴포넌트
│   └── Dockerfile.production
├── backend/                       # FastAPI 백엔드
│   ├── app/
│   ├── routers/
│   └── Dockerfile.production
├── scentmap/                      # 향수 지도 서비스
│   └── Dockerfile.production
├── layering/                      # 레이어링 추천 서비스
│   └── Dockerfile.production
├── scripts/                       # 배포/운영 스크립트
│   ├── deploy.sh
│   └── rollback.sh
├── docker-compose.production.yml  # 프로덕션 Docker 구성
└── .env.example                   # 환경변수 템플릿
```

---

## 📌 버전 정보

| 항목 | 정보 |
|------|------|
| **현재 버전** | v1.0.0 |
| **마지막 배포** | 2026-02-03 |
| **배포 방식** | 수동 트리거 → 자동 배포 |
| **프로덕션 시작** | 2026-02-04 |

자세한 변경 이력은 [Releases](../../releases) 및 [배포 히스토리](./DEPLOYMENT.md#-배포-히스토리) 참조

---

## 📝 라이선스

이 프로젝트의 라이선스는 [LICENSE](../LICENSE) 파일을 참조하세요.

---

**🌸 Scentence Team**  
**Last Updated**: 2026-02-03
