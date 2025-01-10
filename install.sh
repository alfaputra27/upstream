#!/bin/bash

# Membersihkan terminal terlebih dahulu
clear

# Fungsi untuk menampilkan warna pada teks
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

# Fungsi untuk menampilkan daftar container Docker
function list_docker_containers() {
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
}

# Fungsi untuk restart container berdasarkan pilihan atau semua
function restart_docker() {
    print_step "Restart Container Docker" "yellow"
    list_docker_containers
    echo
    print_color "cyan" "Pilih container untuk di-restart:"
    echo "1) Pilih container berdasarkan nama atau ID"
    echo "2) Restart semua container"
    read -p "Masukkan pilihan (1 atau 2): " CHOICE

    if [[ "$CHOICE" == "1" ]]; then
        read -p "Masukkan nama atau ID container: " CONTAINER_ID
        docker restart "$CONTAINER_ID"
        print_color "green" "Container $CONTAINER_ID berhasil di-restart."
    elif [[ "$CHOICE" == "2" ]]; then
        docker restart $(docker ps -q)
        print_color "green" "Semua container berhasil di-restart."
    else
        print_color "red" "Pilihan tidak valid."
    fi
}

# Fungsi untuk stop container berdasarkan pilihan atau semua
function stop_docker() {
    print_step "Stop Container Docker" "yellow"
    list_docker_containers
    echo
    print_color "cyan" "Pilih container untuk dihentikan:"
    echo "1) Pilih container berdasarkan nama atau ID"
    echo "2) Stop semua container"
    read -p "Masukkan pilihan (1 atau 2): " CHOICE

    if [[ "$CHOICE" == "1" ]]; then
        read -p "Masukkan nama atau ID container: " CONTAINER_ID
        docker stop "$CONTAINER_ID"
        print_color "green" "Container $CONTAINER_ID berhasil dihentikan."
    elif [[ "$CHOICE" == "2" ]]; then
        docker stop $(docker ps -q)
        print_color "green" "Semua container berhasil dihentikan."
    else
        print_color "red" "Pilihan tidak valid."
    fi
}

# Fungsi untuk menjalankan Rclone
function run_rclone() {
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

# Menampilkan folder yang ada dalam /opt/ untuk dipilih
print_step "Menampilkan folder dalam /opt/" "blue"
print_color "cyan" "Daftar folder dalam /opt/:"
FOLDERS=$(ls /opt)
echo "$FOLDERS"
echo

# Menampilkan folder yang ada di sftp:/opt untuk dipilih
print_step "Menampilkan folder dalam sftp:/opt/" "blue"
print_color "cyan" "Daftar folder dalam sftp:/opt/:"
RCLONE_SFTP_FOLDERS=$(rclone lsd sftp:/opt)
echo "$RCLONE_SFTP_FOLDERS"
echo

    read -p "Masukkan folder sumber (misal: /opt/folder_sumber): " SRC_FOLDER
    read -p "Masukkan folder tujuan (misal: /opt/folder_tujuan): " DEST_FOLDER

    print_step "Menjalankan Rclone $ACTION" "green"
    rclone $ACTION -P $SRC_FOLDER sftp:$DEST_FOLDER
}

# Menu utama
while true; do
    clear
    echo "=========================================="
    echo " Pilihan Menu"
    echo "=========================================="
    echo "1) Install All (Docker dan Rclone)"
    echo "2) Edit Konfigurasi Rclone"
    echo "3) Lihat Docker yang Berjalan"
    echo "4) Restart Container Docker (pilih atau semua)"
    echo "5) Stop Container Docker (pilih atau semua)"
    echo "6) Jalankan Rclone"
    echo "7) Keluar"
    echo "=========================================="
    read -p "Pilih opsi: " CHOICE
    case $CHOICE in
        1) install_all ;;
        2) configure_rclone ;;
        3) show_docker ;;
        4) restart_docker ;;
        5) stop_docker ;;
        6) run_rclone ;;
        7) print_color "green" "Keluar dari script. Terima kasih!" ; exit ;;
        *) print_color "red" "Pilihan tidak valid!" ;;
    esac
    read -p "Tekan Enter untuk kembali ke menu utama..."
done
