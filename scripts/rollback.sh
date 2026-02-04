#!/bin/bash

# ==================================================
# Scentence Rollback 스크립트
# ==================================================

set -e

echo "⚠️  Rollback 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 프로젝트 디렉토리 자동 찾기
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
    exit 1
fi

echo "📁 프로젝트 디렉토리: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 현재 커밋 정보
CURRENT_COMMIT=$(git rev-parse HEAD)
echo "현재 커밋: $CURRENT_COMMIT"

# 이전 커밋 정보
PREVIOUS_COMMIT=$(git rev-parse HEAD~1)
echo "이전 커밋: $PREVIOUS_COMMIT"

# 확인 메시지
echo -e "${YELLOW}⚠️  이전 버전으로 되돌리시겠습니까?${NC}"
echo "현재: $CURRENT_COMMIT"
echo "이전: $PREVIOUS_COMMIT"
read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback을 취소합니다."
    exit 0
fi

# 이전 커밋으로 되돌리기
echo -e "${YELLOW}🔙 이전 커밋으로 되돌리는 중...${NC}"
git reset --hard HEAD~1

# Docker 재시작
echo -e "${YELLOW}🔄 Docker 컨테이너 재시작 중...${NC}"
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d --build

# 헬스체크
echo -e "${YELLOW}🏥 헬스체크 대기 중...${NC}"
sleep 30

if curl -f http://localhost:3000/api/backend-openapi > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Rollback 성공!${NC}"
else
    echo -e "${RED}❌ Rollback 실패! 헬스체크 실패${NC}"
    exit 1
fi

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Rollback 완료!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo "롤백된 커밋: $PREVIOUS_COMMIT"
