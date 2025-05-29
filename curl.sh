#!/bin/bash

# Инициализация
DEBUG=0
EXTENSIONS=""
URL=""

# --- Обработка аргументов ---
for arg in "$@"; do
  case "$arg" in
  --debug)
    DEBUG=1
    ;;
  http*)
    URL="$arg"
    ;;
  *)
    EXTENSIONS="$arg"
    ;;
  esac
done

# Проверка обязательного URL
if [ -z "$URL" ]; then
  echo "Использование: $0 <URL> [расширения через запятую] [--debug]"
  exit 1
fi

# Установка расширений по умолчанию
EXTENSIONS="${EXTENSIONS:-pdf,zip,tar.gz,docx,xlsx,pptx,mp3,mp4,jpg,png}"

# --- Подготовка регулярки ---
IFS=',' read -r -a EXT_ARRAY <<<"$EXTENSIONS"
EXT_REGEX="\.(${EXT_ARRAY[0]}"
for ext in "${EXT_ARRAY[@]:1}"; do
  EXT_REGEX+="|$ext"
done
EXT_REGEX+=")$"

[[ $DEBUG -eq 1 ]] && {
  echo "▶ URL: $URL"
  echo "▶ Расширения: ${EXT_ARRAY[*]}"
  echo "▶ Регулярка: $EXT_REGEX"
}

# --- Получение HTML ---
HTML=$(curl -Ls "$URL")

# --- Поиск ссылок ---
LINKS=$(echo "$HTML" | grep -Eo 'https?://[^"]+' | grep -Ei "$EXT_REGEX" | sort -u)

[[ $DEBUG -eq 1 ]] && {
  echo "▶ Найдено ссылок с подходящими расширениями:"
  echo "$LINKS"
}

# --- Проверка доступности файлов ---
while IFS= read -r link; do
  [[ $DEBUG -eq 1 ]] && echo "▶ Проверка: $link"
  if curl -s --head --fail "$link" >/dev/null; then
    echo "✅ Найден файл: $link"
    exit 0
  fi
done <<<"$LINKS"

echo "❌ Подходящие файлы не найдены или недоступны."
exit 1
