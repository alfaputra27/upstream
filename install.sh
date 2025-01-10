#!/bin/bash

# ===========================================
#        \033[1;36mScript By www.pstream.id\033[0m
#     \033[1;33mJangan menyebar luaskan script ini diluar member upstream.id\033[0m
#           \033[1;32mEmail: support@upstream.id\033[0m
# ===========================================

# Fungsi untuk mencetak teks dengan warna
function print_color() {
    local COLOR=$1
    local TEXT=$2
    case $COLOR in
        "red") echo -e "\033[31m$TEXT\033[0m" ;;
        "green") echo -e "\033[32m$TEXT\033[0m" ;;
        "yellow") echo -e "\033[33m$TEXT\033[0m" ;;
        "blue") echo -e "\033[34m$TEXT\033[0m" ;;
        "cyan") echo -e "\033[36m$TEXT\033[0m" ;;
        "bold") echo -e "\033[1m$TEXT\033[0m" ;;
        "bg_red") echo -e "\033[41m$TEXT\033[0m" ;;
        "bg_green") echo -e "\033[42m$TEXT\033[0m" ;;
        "bg_yellow") echo -e "\033[43m$TEXT\033[0m" ;;
        *) echo "$TEXT" ;;
    esac
}

# Header Tampilan Awal
clear
print_color "cyan" "=========================================="
print_color "bold" "        \033[1;36mScript By www.pstream.id\033[0m"
print_color "yellow" "     \033[1;33mJangan menyebar luaskan script ini diluar member upstream.id\033[0m"
print_color "green" "           \033[1;32mEmail: support@upstream.id\033[0m"
print_color "cyan" "=========================================="
echo
echo "Memulai instalasi... Harap tunggu."

# Fungsi untuk menampilkan progress bar
function progress_bar() {
    local DURATION=$1
    local PROGRESS=0
    local INCREMENT=$((100 / DURATION))
    echo -n "["
    for ((i=0; i<100; i+=INCREMENT)); do
        sleep 1
        echo -n "#"
        ((PROGRESS += INCREMENT))
    done
    echo "]"
}

# Fungsi untuk mencetak header proses
function print_step() {
    local STEP=$1
    local COLOR=$2
    print_color "$COLOR" "======================================="
    print_color "$COLOR" "   $STEP"
    print_color "$COLOR" "======================================="
}

# Periksa apakah dijalankan dengan hak akses root
if [ "$(id -u)" != "0" ]; then
    print_color "red" "Skrip ini harus dijalankan sebagai root. Gunakan sudo."
    exit 1
fi

# Step 1: Tambahkan GPG key resmi Docker
print_step "Menambahkan GPG key resmi Docker" "green"
progress_bar 5
apt-get update -y > /dev/null 2>&1
apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1
install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null 2>&1
chmod a+r /etc/apt/keyrings/docker.gpg

# Step 2: Tambahkan repository Docker
print_step "Menambahkan repository Docker ke Apt sources" "yellow"
progress_bar 3
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 3: Perbarui sistem
print_step "Memperbarui sistem" "blue"
progress_bar 5
apt-get update -y > /dev/null 2>&1

# Step 4: Instal Docker
print_step "Menginstal Docker" "green"
progress_bar 7
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1

# Step 5: Instal Rclone
print_step "Menginstal Rclone" "cyan"
progress_bar 4
apt-get install -y rclone > /dev/null 2>&1

# Step 6: Konfigurasi Rclone
print_step "Mengatur konfigurasi Rclone" "yellow"
progress_bar 6
mkdir -p /root/.config/rclone
read -p "Masukkan nama host: " RCLONE_HOST
read -p "Masukkan port (default: 22): " RCLONE_PORT
RCLONE_PORT=${RCLONE_PORT:-22}
read -p "Masukkan username: " RCLONE_USER
read -sp "Masukkan password: " RCLONE_PASSWORD
echo
cat <<EOF > /root/.config/rclone/rclone.conf
[sftp]
type = sftp
host = $RCLONE_HOST
user = $RCLONE_USER
port = $RCLONE_PORT
pass = $(rclone obscure $RCLONE_PASSWORD)
EOF
print_color "green" "Konfigurasi Rclone selesai!"

# Step 7: Membuat container Docker
print_step "Membuat container Docker" "blue"
read -p "Masukkan jumlah container yang ingin dibuat: " NUM_CONTAINERS
for (( i=1; i<=NUM_CONTAINERS; i++ ))
do
    echo "Konfigurasi untuk container ke-$i:"
    read -p "Masukkan nama container: " CONTAINER_NAME
    read -p "Masukkan port yang digunakan: " CONTAINER_PORT
    CONFIG_PATH="/opt/${CONTAINER_NAME}/config"
    DATA_PATH="/opt/${CONTAINER_NAME}/data"
    mkdir -p $CONFIG_PATH $DATA_PATH
    docker run -d --restart=always --name $CONTAINER_NAME \
        -v $CONFIG_PATH:/core/config -v $DATA_PATH:/core/data \
        -p $CONTAINER_PORT:8080 \
        datarhei/restreamer:latest
done
print_color "green" "Semua container Docker telah dibuat!"

# Step 8: Pilih fungsi Rclone
print_step "Pilih fungsi Rclone (Sync atau Copy)" "cyan"
echo "1) Sync"
echo "2) Copy"
read -p "Masukkan pilihan Anda (1 atau 2): " RCLONE_ACTION
if [[ "$RCLONE_ACTION" == "1" ]]; then
    ACTION="sync"
elif [[ "$RCLONE_ACTION" == "2" ]]; then
    ACTION="copy"
else
    ACTION="sync"
fi
read -p "Masukkan folder sumber: " SRC_FOLDER
read -p "Masukkan folder tujuan: " DEST_FOLDER
print_step "Menjalankan Rclone $ACTION" "green"
rclone $ACTION -P sftp:$SRC_FOLDER $DEST_FOLDER

# Step 9: Menyalakan ulang container Docker
print_step "Menyalakan ulang semua container Docker" "yellow"
docker start $(docker ps -a -q)
print_color "green" "Semua container Docker telah dinyalakan kembali!"

# Selesai
print_color "cyan" "Instalasi selesai!"
