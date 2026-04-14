#!/bin/bash
# ═══════════════════════════════════════════════════════════
#           PEP EDUCATION — Panel de Gestión
# ═══════════════════════════════════════════════════════════

ROOT="$(cd "$(dirname "$0")" && pwd)"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

show_menu() {
  clear
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║         PEP EDUCATION — Panel de Gestión         ║${NC}"
  echo -e "${BOLD}╠══════════════════════════════════════════════════╣${NC}"
  echo -e "${BOLD}║                                                  ║${NC}"
  echo -e "${BOLD}║  ${BLUE}── DESARROLLO ──────────────────────────────${NC}${BOLD}  ║${NC}"
  echo -e "${BOLD}║  1)  Ejecutar app Web   (admin → localhost:3000) ║${NC}"
  echo -e "${BOLD}║  2)  Ejecutar app Móvil (Flutter → simulador)    ║${NC}"
  echo -e "${BOLD}║                                                  ║${NC}"
  echo -e "${BOLD}║  ${YELLOW}── COMPILAR ─────────────────────────────────${NC}${BOLD}  ║${NC}"
  echo -e "${BOLD}║  3)  Compilar APK Android                        ║${NC}"
  echo -e "${BOLD}║  4)  Compilar iOS (ipa)                          ║${NC}"
  echo -e "${BOLD}║  5)  Compilar Android + iOS                      ║${NC}"
  echo -e "${BOLD}║                                                  ║${NC}"
  echo -e "${BOLD}║  ${GREEN}── PUBLICAR ─────────────────────────────────${NC}${BOLD}  ║${NC}"
  echo -e "${BOLD}║  6)  Subir cambios a GitHub                      ║${NC}"
  echo -e "${BOLD}║  7)  Compilar APK + Subir a GitHub               ║${NC}"
  echo -e "${BOLD}║  8)  Pipeline completo (Android+iOS+GitHub)      ║${NC}"
  echo -e "${BOLD}║                                                  ║${NC}"
  echo -e "${BOLD}║  ${RED}0)  Salir${NC}${BOLD}                                         ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  read -p "  Selecciona una opción: " opt
}

# ── 1 ──────────────────────────────────────────────────────
run_admin() {
  echo -e "\n${BLUE}▶ Iniciando app Web en http://localhost:3000 ...${NC}"
  cd "$ROOT/admin" && npm run dev
}

# ── 2 ──────────────────────────────────────────────────────
run_mobile() {
  echo -e "\n${BLUE}▶ Iniciando Flutter (selecciona el dispositivo)...${NC}"
  cd "$ROOT/mobile_flutter" && flutter run
}

# ── 3 ──────────────────────────────────────────────────────
build_apk() {
  echo -e "\n${YELLOW}▶ Compilando APK Android...${NC}"
  cd "$ROOT/mobile_flutter" && flutter build apk --release
  APK="$ROOT/mobile_flutter/build/app/outputs/flutter-apk/app-release.apk"
  SIZE=$(du -sh "$APK" 2>/dev/null | cut -f1)
  echo -e "\n${GREEN}✅ APK listo  ($SIZE)${NC}"
  echo "   $APK"
  open "$(dirname "$APK")" 2>/dev/null
}

# ── 4 ──────────────────────────────────────────────────────
build_ios() {
  echo -e "\n${YELLOW}▶ Compilando IPA iOS...${NC}"
  cd "$ROOT/mobile_flutter" && flutter build ipa --release
  echo -e "\n${GREEN}✅ IPA listo en:${NC}"
  echo "   $ROOT/mobile_flutter/build/ios/ipa/"
}

# ── 5 ──────────────────────────────────────────────────────
build_all_platforms() {
  build_apk
  echo ""
  build_ios
}

# ── 6 ──────────────────────────────────────────────────────
push_github() {
  cd "$ROOT"
  echo ""
  git status
  echo ""
  read -p "  Mensaje de commit: " msg
  if [ -z "$msg" ]; then
    echo -e "${RED}❌ Mensaje vacío — cancelado.${NC}"
    return 1
  fi
  git add .
  git commit -m "$msg"
  git push
  echo -e "\n${GREEN}✅ Cambios subidos a GitHub.${NC}"
}

# ── 7 ──────────────────────────────────────────────────────
release_android() {
  build_apk
  echo ""
  push_github
}

# ── 8 ──────────────────────────────────────────────────────
full_pipeline() {
  echo -e "\n${BOLD}🚀 Pipeline completo: Android + iOS + GitHub${NC}"
  build_apk && echo "" && build_ios && echo "" && push_github
}

# ── Main loop ───────────────────────────────────────────────
while true; do
  show_menu
  case $opt in
    1) run_admin ;;
    2) run_mobile ;;
    3) build_apk ;;
    4) build_ios ;;
    5) build_all_platforms ;;
    6) push_github ;;
    7) release_android ;;
    8) full_pipeline ;;
    0) echo -e "\n  ${BLUE}Hasta luego!${NC}\n"; exit 0 ;;
    *) echo -e "\n${RED}  Opción inválida, intenta de nuevo.${NC}" ;;
  esac
  echo ""
  read -p "  Presiona Enter para continuar..."
done
