#!/bin/bash

# Membersihkan terminal terlebih dahulu
clear

# Menambahkan teks header dengan warna
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

# Header tampilan awal
echo -e "\033[1;36m==========================================\033[0m"
echo -e "\033[1;36m Script By www.upstream.id\033[0m"
echo -e "\033[1;33m Jangan menyebar luaskan script ini diluar member upstream.id\033[0m"
echo -e "\033[1;32m Email : support@upstream.id\033[0m"
echo -e "\033[1;36m==========================================\033[0m"
echo

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

# Menambahkan opsi untuk instalasi dan konfigurasi Rclone
echo
print_color "cyan" "Apakah Anda ingin menginstal dan mengonfigurasi Rclone? (y/n)"
read -p "Pilih (y/n): " INSTALL_RCLONE

if [[ "$INSTALL_RCLONE" == "y" || "$INSTALL_RCLONE" == "Y" ]]; then
    # Instal dan konfigurasi Rclone
    apt-get install -y rclone > /dev/null 2>&1
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
else
    print_color "yellow" "Langkah Rclone dilewati!"
fi

# Pilih fungsi Rclone (Sync atau Copy)
echo
print_color "cyan" "Pilih fungsi Rclone (Sync atau Copy)"
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

# Menampilkan folder lokal dan sftp
print_step "Menampilkan folder dalam /opt/" "blue"
FOLDERS=$(ls /opt)
echo "$FOLDERS"

print_step "Menampilkan folder dalam sftp:/opt/" "blue"
RCLONE_SFTP_FOLDERS=$(rclone lsd sftp:/opt)
echo "$RCLONE_SFTP_FOLDERS"

# Meminta pengguna memasukkan folder sumber dan tujuan
read -p "Masukkan folder sumber (misal: /opt/folder_sumber): " SRC_FOLDER
read -p "Masukkan folder tujuan (misal: /opt/folder_tujuan): " DEST_FOLDER

# Jalankan proses Rclone
print_step "Menjalankan Rclone $ACTION" "green"
screen -dmS rclone_process rclone $ACTION -P $SRC_FOLDER $DEST_FOLDER

# Menunggu proses Rclone selesai dan menyalakan Docker
print_step "Menunggu Rclone selesai" "yellow"
screen -ls
read -p "Tekan Enter untuk melanjutkan setelah memastikan Rclone selesai berjalan."

print_step "Menyalakan ulang semua container Docker" "yellow"
docker start $(docker ps -a -q)
print_color "green" "Semua container Docker telah dinyalakan kembali!"

print_color "cyan" "Instalasi selesai!"
