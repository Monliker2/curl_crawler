#!/bin/bash

# --- 1) Парсим аргументы ---
DEBUG=0
EXTENSIONS=""
URL=""

for arg in "$@"; do
  case "$arg" in
  --debug)
    DEBUG=1
    ;;
  http*://*)
    URL="$arg"
    ;;
  *)
    EXTENSIONS="$arg"
    ;;
  esac
done

if [[ -z "$URL" ]]; then
  echo "Использование: $0 <URL> [расширения через запятую] [--debug]"
  exit 1
fi

EXTENSIONS="${EXTENSIONS:-pdf,zip,tar.gz,docx,xlsx,pptx,mp3,mp4,jpg,png}"

# --- 2) Готовим регулярку для расширений ---
IFS=',' read -r -a EXT_ARR <<<"$EXTENSIONS"
EXT_REGEX="\.(${EXT_ARR[0]}"
for e in "${EXT_ARR[@]:1}"; do
  EXT_REGEX+="|$e"
done
EXT_REGEX+=")$"

# --- 3) Вывод отладки (если включён) ---
if [[ $DEBUG -eq 1 ]]; then
  echo "▶ URL:        $URL"
  echo "▶ Расширения: ${EXT_ARR[*]}"
  echo "▶ Регэксп:    $EXT_REGEX"
fi

# --- 4) Определяем домен для нормализации относительных ссылок ---
DOMAIN=$(echo "$URL" | awk -F/ '{print $3}')

# Хранилище уже посещённых URL
declare -A VISITED

# --- 5) Рекурсивная функция обхода ---
crawl() {
  local page_url="$1"

  # Пропускаем, если уже были
  if [[ -n "${VISITED[$page_url]}" ]]; then
    return
  fi
  VISITED[$page_url]=1

  if [[ $DEBUG -eq 1 ]]; then
    echo "▶ Обход страницы: $page_url"
  fi

  # Загружаем HTML
  local html
  html=$(curl -Ls "$page_url") || return

  if [[ $DEBUG -eq 1 ]]; then
    echo "▶ HTML получен:"
    echo "$html"
  fi

  # 5.1) Ищем прямые ссылки на файлы (учитываем пробелы вокруг =)
  local files
  files=$(echo "$html" |
    grep -Eo 'href\s*=\s*"[^"]+"' |
    cut -d\" -f2 |
    grep -Ei "$EXT_REGEX" |
    sort -u)

  if [[ $DEBUG -eq 1 ]]; then
    echo "▶ Ссылки на файлы перед HEAD-запросом:"
    echo "$files"
  fi

  if [[ -n "$files" ]]; then
    while IFS= read -r f; do
      # Нормализуем относительные пути
      if [[ "$f" =~ ^/ ]]; then
        f="http://$DOMAIN$f"
      elif [[ ! "$f" =~ ^https?:// ]]; then
        # Относительный путь без / в начале
        f="http://$DOMAIN/$f"
      fi
      if [[ $DEBUG -eq 1 ]]; then
        echo "  • Проверяю: $f"
      fi
      # HEAD-запрос, проверяем HTTP 200
      if curl -s --head --fail "$f" >/dev/null; then
        echo "✅ Найден файл: $f"
        exit 0
      fi
    done <<<"$files"
  fi

  # 5.2) Ищем ссылки на другие страницы внутри того же домена
  local pages
  pages=$(echo "$html" |
    grep -Eo 'href\s*=\s*"[^"]+"' |
    cut -d\" -f2 |
    grep -Ev "$EXT_REGEX" |
    grep -E "^https?://$DOMAIN/|^/" |
    sort -u)

  while IFS= read -r p; do
    if [[ "$p" =~ ^/ ]]; then
      p="http://$DOMAIN$p"
    fi
    crawl "$p"
  done <<<"$pages"
}

# --- 6) Старт обхода ---
if [[ $DEBUG -eq 1 ]]; then
  echo "▶ Старт рекурсии по $URL"
  echo
fi
crawl "$URL"

# --- 7) Если ничего не найдено ---
echo "❌ Файлы с расширениями ($EXTENSIONS) не найдены."
exit 1
