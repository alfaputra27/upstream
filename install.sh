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

# Fungsi progress bar
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

# Fungsi Install All
function install_all() {
    # GPG Key Docker
    print_step "Menambahkan GPG key resmi Docker" "green"
    progress_bar 5
    apt-get update -y > /dev/null 2>&1
    apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1
    install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null 2>&1
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Tambah Repository
    print_step "Menambahkan repository Docker ke Apt sources" "yellow"
    progress_bar 3
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update Sistem
    print_step "Memperbarui sistem" "blue"
    progress_bar 5
    apt-get update -y > /dev/null 2>&1

    # Instal Docker
    print_step "Menginstal Docker" "green"
    progress_bar 7
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1

    # Instal Rclone
    print_step "Menginstal Rclone" "cyan"
    progress_bar 4
    apt-get install -y rclone > /dev/null 2>&1

    # Konfigurasi Rclone
    print_step "Mengatur konfigurasi Rclone" "yellow"
    progress_bar 6
    configure_rclone
}

# Fungsi untuk konfigurasi Rclone
function configure_rclone() {
    if [ -f "/root/.config/rclone/rclone.conf" ]; then
        print_color "yellow" "Profil Rclone sudah ada. Edit konfigurasi?"
        read -p "(y/n): " EDIT_CONFIG
        if [[ "$EDIT_CONFIG" == "y" || "$EDIT_CONFIG" == "Y" ]]; then
            nano /root/.config/rclone/rclone.conf
        else
            print_color "yellow" "Edit konfigurasi Rclone dilewati."
        fi
    else
        print_color "red" "Tidak ada profil Rclone. Membuat profil baru..."
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
    fi
}

# Fungsi untuk menampilkan daftar container Docker
function show_docker() {
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
    echo -e "\033[1;36m==========================================\033[0m"
echo -e "\033[1;36m Script By www.pstream.id\033[0m"
echo -e "\033[1;33m Jangan menyebar luaskan script ini diluar member upstream.id\033[0m"
echo -e "\033[1;32m Email : support@upstream.id\033[0m"
echo -e "\033[1;36m==========================================\033[0m"

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
