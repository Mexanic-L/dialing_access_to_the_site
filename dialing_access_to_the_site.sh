#!/bin/bash

# ==================================================
# Мониторинг доступности сайта (помощник для Zapret)
# Использование: ./monitor.sh [URL]
# Пример: ./monitor.sh https://open.spotify.com:443
# ==================================================

TARGET_URL="${1:-https://open.spotify.com}"   # URL для проверки (можно с портом)
CHECK_INTERVAL=2                              # пауза между попытками (сек)
CONNECT_TIMEOUT=5                              # таймаут соединения
MAX_TIME=10                                    # общий таймаут запроса

echo "Monitoring $TARGET_URL every $CHECK_INTERVAL sec. Press Ctrl+C to stop."
echo "Waiting for any successful response (any HTTP code, not connection error)..."

while true; do
    # Выполняем GET-запрос, следуем редиректам, игнорируем SSL-ошибки
    HTTP_CODE=$(curl -L -k -s -o /dev/null -w "%{http_code}" \
                --connect-timeout "$CONNECT_TIMEOUT" \
                --max-time "$MAX_TIME" "$TARGET_URL" 2>/dev/null)
    CURL_EXIT=$?

    if [[ $CURL_EXIT -eq 0 && "$HTTP_CODE" =~ ^[0-9]{3}$ ]]; then
        # Получен HTTP-ответ (любой код) – считаем успехом
        echo "$(date): ✅ SUCCESS! HTTP $HTTP_CODE"
        # Звуковой сигнал (3 гудка)
        for _ in {1..3}; do echo -ne "\a"; sleep 0.2; done
        # Можно завершить скрипт, если нужно – раскомментируйте следующую строку
        # exit 0
    else
        # Анализируем ошибки соединения по коду возврата curl
        case $CURL_EXIT in
            6)  echo "$(date): ❌ Couldn't resolve host." ;;
            7)  echo "$(date): ❌ Failed to connect (connection refused)." ;;
            28) echo "$(date): ❌ Timeout." ;;
            35) echo "$(date): ❌ SSL connect error." ;;
            56) echo "$(date): ❌ Network data failure (possible RST)." ;;
            *)  echo "$(date): ❌ Curl error $CURL_EXIT (HTTP_CODE=$HTTP_CODE)" ;;
        esac
    fi

    sleep "$CHECK_INTERVAL"
done