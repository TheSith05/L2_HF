#!/bin/bash

echo "====================================================="
echo "   Установка сервера Lineage 2 High Five (Mobius)    "
echo "====================================================="

# --- ПУНКТ 1: Выбор пути и скачивание репозитория ---
DEFAULT_PATH="/DATA/AppData/l2mobius"
read -p "1. Укажите путь для установки сервера [Enter = $DEFAULT_PATH]: " USER_PATH
INSTALL_PATH=${USER_PATH:-$DEFAULT_PATH}

echo "-> Скачиваем файлы из репозитория TheSith05/L2_HF..."
rm -rf /tmp/l2_clone_temp
git clone --depth 1 https://github.com/TheSith05/L2_HF.git /tmp/l2_clone_temp

mkdir -p "$INSTALL_PATH"
cp -rf /tmp/l2_clone_temp/l2mobius/* "$INSTALL_PATH"/

# --- ПУНКТ 2: Замена конфигов .ini на переведенные из папки ru ---
echo ""
read -p "2. Заменить файлы настроек (.ini) на версию с русским описанием? (y/n) [Enter = y]: " RU_INI
RU_INI=${RU_INI:-y}

if [[ "$RU_INI" =~ ^[YyДд]$ ]]; then
    cp -rf /tmp/l2_clone_temp/ru/game/config/* "$INSTALL_PATH/server/game/config/"
    cp -rf /tmp/l2_clone_temp/ru/login/config/* "$INSTALL_PATH/server/login/config/"
    echo "[OK] Файлы настроек заменены на русские."
fi

rm -rf /tmp/l2_clone_temp
cd "$INSTALL_PATH" || exit 1

# --- ПУНКТ 3: Включение русского языка диалогов/квестов (MultilingualSupport.ini) ---
echo ""
read -p "3. Включить русский язык серверной части (квесты/диалоги)? (y/n) [Enter = y]: " RU_LANG
RU_LANG=${RU_LANG:-y}

MULTI_INI="server/game/config/Custom/MultilingualSupport.ini"
if [[ "$RU_LANG" =~ ^[YyДд]$ ]] && [ -f "$MULTI_INI" ]; then
    sed -i "s/^MultiLangEnable =.*/MultiLangEnable = true/" "$MULTI_INI"
    sed -i "s/^MultiLangDefault =.*/MultiLangDefault = ru/" "$MULTI_INI"
    sed -i "s/^MultiLangAllowed =.*/MultiLangAllowed = en;ru/" "$MULTI_INI"
    sed -i "s/^MultiLangVoiceCommand =.*/MultiLangVoiceCommand = True/" "$MULTI_INI"
    echo "[OK] Русский язык квестов и диалогов активирован."
fi

# --- ПУНКТ 4: Настройка IP адреса для локальной сети / интернета ---
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo ""
read -p "4. Укажите IP адрес вашего сервера для подключения клиентов [Enter = $LOCAL_IP]: " SERVER_IP
SERVER_IP=${SERVER_IP:-$LOCAL_IP}

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo "<gameserver address=\"$SERVER_IP\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"../data/xsd/ipconfig.xsd\">"
  echo '	<define subnet="127.0.0.0/8" address="127.0.0.1" />'
  echo "	<define subnet=\"10.0.0.0/8\" address=\"$SERVER_IP\" />"
  echo "	<define subnet=\"172.16.0.0/19\" address=\"$SERVER_IP\" />"
  echo "	<define subnet=\"192.168.0.0/16\" address=\"$SERVER_IP\" />"
  echo '</gameserver>'
} > server/game/config/ipconfig.xml

echo "[OK] Создан файл ipconfig.xml с адресом $SERVER_IP."

# --- ПУНКТ 5: Скачивание и распаковка Геодаты ---
echo ""
read -p "5. Скачать и распаковать Геодату (200 МБ)? (y/n) [Enter = y]: " GEO_DL
GEO_DL=${GEO_DL:-y}

if [[ "$GEO_DL" =~ ^[YyДд]$ ]]; then
    echo "-> Скачиваем geodata.tar.gz из релизов..."
    wget -q --show-progress -O geodata.tar.gz "https://github.com/TheSith05/L2_HF/releases/download/goe/geodata.tar.gz"
    mkdir -p server/game/data/geodata
    echo "-> Распаковываем геодату..."
    tar -xzf geodata.tar.gz -C server/game/data/
    mv server/game/data/*.l2j server/game/data/geodata/ 2>/dev/null
    mv server/game/data/*.l2d server/game/data/geodata/ 2>/dev/null
    mv server/game/data/*.dat server/game/data/geodata/ 2>/dev/null
    rm -f geodata.tar.gz
    echo "[OK] Геодата успешно распакована!"
fi

# --- ПУНКТ 6: Запуск сервера через Docker Compose ---
echo ""
read -p "6. Запустить контейнеры сервера прямо сейчас? (y/n) [Enter = y]: " RUN_NOW
RUN_NOW=${RUN_NOW:-y}

if [[ "$RUN_NOW" =~ ^[YyДд]$ ]]; then
    docker compose up -d
    echo "====================================================="
    echo " ГОТОВО! Сервер развернут в папке: $INSTALL_PATH"
    echo " IP сервера для клиента: $SERVER_IP"
    echo " Смотреть загрузку Гейм-сервера: docker logs -f l2-game"
    echo "====================================================="
fi
