#!/bin/bash

# Skrip instalasi otomatis untuk Ubuntu

# Periksa apakah dijalankan dengan hak akses root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan sebagai root. Gunakan sudo."
    exit 1
fi

echo "Memulai instalasi..."

# Fungsi untuk membaca input Rclone
function input_rclone_config() {
    echo "Konfigurasi Rclone SFTP"
    read -p "Masukkan nama host: " RCLONE_HOST
    read -p "Masukkan port (default: 22): " RCLONE_PORT
    RCLONE_PORT=${RCLONE_PORT:-22}  # Gunakan 22 jika port tidak diisi
    read -p "Masukkan username: " RCLONE_USER
    read -sp "Masukkan password: " RCLONE_PASSWORD
    echo

    # Membuat konfigurasi Rclone untuk SFTP
    echo "[sftp]" >> /root/.config/rclone/rclone.conf
    echo "type = sftp" >> /root/.config/rclone/rclone.conf
    echo "host = $RCLONE_HOST" >> /root/.config/rclone/rclone.conf
    echo "user = $RCLONE_USER" >> /root/.config/rclone/rclone.conf
    echo "port = $RCLONE_PORT" >> /root/.config/rclone/rclone.conf
    echo "pass = $(rclone obscure $RCLONE_PASSWORD)" >> /root/.config/rclone/rclone.conf

    echo "Konfigurasi Rclone selesai!"
}

# Fungsi untuk menentukan sinkronisasi atau copy direktori dengan Rclone
function sync_or_copy_rclone() {
    echo "Pilih fungsi Rclone:"
    echo "1) Sync"
    echo "2) Copy"
    read -p "Masukkan pilihan Anda (1 atau 2): " RCLONE_ACTION

    if [[ "$RCLONE_ACTION" == "1" ]]; then
        ACTION="sync"
    elif [[ "$RCLONE_ACTION" == "2" ]]; then
        ACTION="copy"
    else
        echo "Pilihan tidak valid. Default ke sync."
        ACTION="sync"
    fi

    read -p "Masukkan folder asal pada server (contoh: /opt/): " SRC_FOLDER
    read -p "Masukkan folder tujuan pada lokal (contoh: /opt/): " DEST_FOLDER

    echo "Menjalankan Rclone $ACTION dari $SRC_FOLDER ke $DEST_FOLDER..."
    rclone $ACTION -P sftp:$SRC_FOLDER $DEST_FOLDER
    echo "Proses Rclone $ACTION selesai!"
}

# Fungsi untuk membuat container Docker
function create_docker_containers() {
    echo "Konfigurasi container Docker"
    read -p "Masukkan jumlah container yang ingin dibuat: " NUM_CONTAINERS

    for (( i=1; i<=NUM_CONTAINERS; i++ ))
    do
        echo "Konfigurasi untuk container ke-$i:"
        read -p "Masukkan nama container: " CONTAINER_NAME
        read -p "Masukkan port yang digunakan: " CONTAINER_PORT

        # Path konfigurasi dan data
        CONFIG_PATH="/opt/${CONTAINER_NAME}/config"
        DATA_PATH="/opt/${CONTAINER_NAME}/data"

        # Membuat direktori jika belum ada
        mkdir -p $CONFIG_PATH $DATA_PATH

        # Menjalankan container
        echo "Menjalankan container $CONTAINER_NAME pada port $CONTAINER_PORT..."
        docker run -d --restart=always --name $CONTAINER_NAME \
            -v $CONFIG_PATH:/core/config -v $DATA_PATH:/core/data \
            -p $CONTAINER_PORT:8080 \
            datarhei/restreamer:latest
    done
}

# Tambahkan GPG key Docker
echo "Menambahkan GPG key resmi Docker..."
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Tambahkan repository Docker ke sumber Apt
echo "Menambahkan repository Docker ke Apt sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Perbarui sistem
echo "Memperbarui sistem..."
apt-get update

# Instal Docker
echo "Menginstal Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Instal Rclone
echo "Menginstal Rclone..."
apt-get install -y rclone

# Konfigurasi Rclone
echo "Mengatur konfigurasi Rclone..."
mkdir -p /root/.config/rclone
input_rclone_config

# Membuat container Docker
create_docker_containers

# Pilih fungsi Rclone (Sync atau Copy)
sync_or_copy_rclone

echo "Instalasi selesai!"
