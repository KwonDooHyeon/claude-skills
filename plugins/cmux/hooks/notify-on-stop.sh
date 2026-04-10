#!/bin/bash
# Claude Code 작업 완료(Stop 이벤트) 시 cmux notify로 알림 전송
#
# 이 훅은 cmux 환경에서만 의미가 있으므로:
# - cmux 명령어가 없거나 실패해도 조용히 종료 (다른 환경 영향 없음)
# - CMUX_SURFACE_ID 환경변수가 있을 때만 surface 정보 포함

set -e

# cmux CLI가 없으면 아무것도 안 함
if ! command -v cmux &> /dev/null; then
  exit 0
fi

# surface 이름을 얻어서 알림에 포함 (있으면)
SURFACE_INFO=""
if [ -n "$CMUX_SURFACE_ID" ]; then
  SURFACE_INFO=" (surface: $CMUX_SURFACE_ID)"
fi

# 현재 작업 디렉토리의 마지막 경로명을 프로젝트 이름으로 사용
PROJECT_NAME=$(basename "$PWD")

# cmux notify 실행 — 실패해도 종료코드 0 유지 (훅 오류로 세션 방해하지 않음)
cmux notify \
  --title "Claude Code — $PROJECT_NAME" \
  --body "작업이 완료되었습니다$SURFACE_INFO" \
  2>/dev/null || true

exit 0
