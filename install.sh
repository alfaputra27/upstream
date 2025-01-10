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
# Fungsi Install screen
function install_screen() {
apt-get install screen -y > /dev/null 2>&1
}

# Fungsi Install All
function migrasi_liveStream() {
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
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 3: Perbarui sistem
print_step "Memperbarui sistem" "blue"
apt-get update -y > /dev/null 2>&1

# Step 4: Instal Docker
print_step "Menginstal Docker" "green"
progress_bar 20
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

# Instal dan jalankan container aplikasi
print_step "Membuat Server chillstep port 2706..." "green"
docker run -d --restart=always --name chillstep \
   -v /opt/chillstep/config:/core/config -v /opt/chillstep/data:/core/data \
   -p 2706:8080 \
   datarhei/restreamer:latest
print_step "Membuat Server ytlofi port 2707..." "green"
docker run -d --restart=always --name ytlofi \
   -v /opt/ytlofi/config:/core/config -v /opt/ytlofi/data:/core/data \
   -p 2707:8080 \
   datarhei/restreamer:latest
print_step "Membuat Server lofime port 2708..." "green"
docker run -d --restart=always --name lofime \
   -v /opt/lofime/config:/core/config -v /opt/lofime/data:/core/data \
   -p 2708:8080 \
   datarhei/restreamer:latest
print_color "green" "Semua Livestream server telah dibuat!"

# Stop container aplikasi
print_step "Menghentikan container..." "yellow"
docker stop lofime chillstep ytlofi

print_step "Start Cloning /opt/ Server Streaming $ACTION" "green"
rclone sync -P sftp:/opt/ /opt/

# Menyalakan ulang semua container Docker
print_step "Menyalakan semua container..." "yellow"
docker start $(docker ps -a -q)
print_color "green" "Semua container Docker telah dinyalakan kembali!"

# Selesai
print_color "cyan" "Instalasi & Migrasi selesai!"

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

    # Konfigurasi Docker
    print_step "Buat Server Container"
    progress_bar 6
    create_container

    # Instal Rclone
    print_step "Menginstal Rclone" "cyan"
    progress_bar 4
    apt-get install -y rclone > /dev/null 2>&1

    # Konfigurasi Rclone
    print_step "Mengatur konfigurasi Rclone" "yellow"
    progress_bar 6
    configure_rclone
}

# Membuat container Docker
function create_container() {
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

# Fungsi untuk start container berdasarkan pilihan atau semua
function start_docker() {
    print_step "start Container Docker" "yellow"
    list_docker_containers
    echo
    print_color "cyan" "Pilih container untuk di-restart:"
    echo "1) Pilih container berdasarkan nama atau ID"
    echo "2) start semua container"
    read -p "Masukkan pilihan (1 atau 2): " CHOICE

    if [[ "$CHOICE" == "1" ]]; then
        read -p "Masukkan nama atau ID container: " CONTAINER_ID
        docker start "$CONTAINER_ID"
        print_color "green" "Container $CONTAINER_ID berhasil di-restart."
    elif [[ "$CHOICE" == "2" ]]; then
        docker start $(docker ps -a -q)
        print_color "green" "Semua container berhasil start."
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
echo -e "\033[1;36m Script By www.upstream.id\033[0m"
echo -e "\033[1;33m Jangan menyebar luaskan script ini diluar member upstream.id\033[0m"
echo -e "\033[1;32m Email : support@upstream.id\033[0m"
echo -e "\033[1;36m==========================================\033[0m"

    echo "=========================================="
    echo " Pilihan Menu"
    echo "=========================================="
    echo "A) Migrasi LiveStream"
    echo "B) Install All"
    echo "1) Install Screen"
    echo "2) Config Rclone"
    echo "3) Create Container"
    echo "4) Docker Running List"
    echo "5) Start Container"
    echo "6) Restart Container"
    echo "7) Stop Container"
    echo "8) Run Rclone"
    echo "0) Keluar"
    echo "=========================================="
    read -p "Pilih opsi: " CHOICE
    case $CHOICE in
        A) migrasi_liveStream ;;
        B) install_all ;;
        1) install_screen ;;
        2) configure_rclone ;;
        3) create_container ;;
        4) list_docker_containers ;;
        5) start_docker ;;
        6) restart_docker ;;
        7) stop_docker ;;
        8) run_rclone ;;
        0) print_color "green" "Keluar dari script. Terima kasih!" ; exit ;;
        *) print_color "red" "Pilihan tidak valid!" ;;
    esac
    read -p "Tekan Enter untuk kembali ke menu utama..."
done
