# File Site Finder

`curl_find_file.sh` — это простой скрипт на Bash для поиска и проверки прямых ссылок на файлы на веб-странице по заданным расширениям и остановки при первом обнаружении доступного файла.

## Возможности

* Загружает HTML заданной страницы через `curl`.
* Ищет ссылки на файлы с нужными расширениями (по умолчанию: `pdf`, `zip`, `tar.gz`, `docx`, `xlsx`, `pptx`, `mp3`, `mp4`, `jpg`, `png`).
* Проверяет каждую ссылку на HTTP-ответ `200 OK`.
* Останавливается при первом найденном доступном файле.
* Поддерживает флаг `--debug` для вывода промежуточной отладки.
* Порядок аргументов не важен: можно указывать `--debug` до или после URL/расширений.

## Установка

1. Скачайте или скопируйте скрипт `curl_find_file.sh` в рабочую директорию.
2. Сделайте его исполняемым:

   ```bash
   chmod +x curl_find_file.sh
   ```

## Использование

```bash
./curl_find_file.sh <URL> [расширения через запятую] [--debug]
```

* `<URL>` — адрес страницы, на которой нужно искать файлы.
* `[расширения через запятую]` — (необязательно) перечень расширений файлов без точки, например `pdf,zip,iso`.
  Если не указан, используются расширения по умолчанию.
* `[--debug]` — (необязательно) включает подробный вывод отладочной информации.

### Примеры

* Поиск первого PDF или ZIP на странице без отладки:

  ```bash
  ./curl_find_file.sh https://example.com/downloads
  ```

* Поиск первого ISO или EXE с отладочным выводом:

  ```bash
  ./curl_find_file.sh https://example.com/downloads iso,exe --debug
  ```

* Вариант с `--debug` в начале:

  ```bash
  ./curl_find_file.sh --debug https://file-examples.com/index.php/sample-documents-download/sample-pdf-download/
  ```

## Выходные коды

* `0` — файл найден и выведена его ссылка.
* `1` — подходящие файлы не найдены или недоступны.
