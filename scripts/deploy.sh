#!/bin/bash

# ==================================================
# Scentence 프로덕션 배포 스크립트
# ==================================================

set -e  # 오류 발생 시 스크립트 중단

echo "🚀 Scentence 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 프로젝트 루트 디렉토리 자동 찾기
if [ -d "$HOME/scentence" ]; then
    PROJECT_DIR="$HOME/scentence"
elif [ -d "$HOME/Scentence_aws_test" ]; then
    PROJECT_DIR="$HOME/Scentence_aws_test"
elif [ -d "$HOME/scentence_aws_test" ]; then
    PROJECT_DIR="$HOME/scentence_aws_test"
elif [ -d "/home/ubuntu/scentence" ]; then
    PROJECT_DIR="/home/ubuntu/scentence"
else
    echo -e "${RED}❌ 프로젝트 디렉토리를 찾을 수 없습니다!${NC}"
    echo "다음 경로들을 확인했습니다:"
    echo "  - $HOME/scentence"
    echo "  - $HOME/Scentence_aws_test"
    echo "  - $HOME/scentence_aws_test"
    exit 1
fi

cd "$PROJECT_DIR"
echo -e "${GREEN}✅ 프로젝트 디렉토리: $PROJECT_DIR${NC}"

# 2. .env 파일 확인
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env 파일이 없습니다!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ .env 파일 확인 완료${NC}"

# 3. 최신 코드 가져오기
echo -e "${YELLOW}📥 최신 코드 가져오는 중...${NC}"
git fetch origin
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "현재 브랜치: $CURRENT_BRANCH"

# 4. 변경사항 확인
if git diff --quiet origin/$CURRENT_BRANCH; then
    echo -e "${YELLOW}⚠️  변경사항이 없습니다.${NC}"
    read -p "계속 배포하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "배포를 취소합니다."
        exit 0
    fi
fi

# 5. 코드 업데이트
echo -e "${YELLOW}🔄 코드 업데이트 중...${NC}"
git reset --hard origin/$CURRENT_BRANCH
echo -e "${GREEN}✅ 코드 업데이트 완료${NC}"

# 6. 기존 컨테이너 중지
echo -e "${YELLOW}🛑 기존 컨테이너 중지 중...${NC}"
docker compose -f docker-compose.production.yml down

# 7. Docker 이미지 빌드
echo -e "${YELLOW}🔨 Docker 이미지 빌드 중...${NC}"
docker compose -f docker-compose.production.yml build --no-cache

# 8. 컨테이너 시작
echo -e "${YELLOW}🚀 컨테이너 시작 중...${NC}"
docker compose -f docker-compose.production.yml up -d

# 9. 컨테이너 상태 확인
echo -e "${YELLOW}🔍 컨테이너 상태 확인 중...${NC}"
sleep 5
docker ps

# 10. 헬스체크
echo -e "${YELLOW}🏥 헬스체크 대기 중 (30초)...${NC}"
sleep 30

# Frontend 헬스체크
if curl -f http://localhost:3000/api/backend-openapi > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend 정상${NC}"
else
    echo -e "${RED}❌ Frontend 헬스체크 실패${NC}"
    exit 1
fi

# Backend 헬스체크
if curl -f http://localhost:8000/openapi.json > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend 정상${NC}"
else
    echo -e "${RED}❌ Backend 헬스체크 실패${NC}"
    exit 1
fi

# Scentmap 헬스체크
if curl -f http://localhost:8001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Scentmap 정상${NC}"
else
    echo -e "${RED}❌ Scentmap 헬스체크 실패${NC}"
    exit 1
fi

# Layering 헬스체크
if curl -f http://localhost:8002/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Layering 정상${NC}"
else
    echo -e "${RED}❌ Layering 헬스체크 실패${NC}"
    exit 1
fi

# 11. 오래된 이미지 정리
echo -e "${YELLOW}🧹 오래된 Docker 이미지 정리 중...${NC}"
docker image prune -af --filter "until=24h"

# 12. 완료
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  🎉 배포 완료!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "서비스 URL: https://scentence.kro.kr"
echo "배포 시간: $(date)"
echo ""
echo "컨테이너 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
