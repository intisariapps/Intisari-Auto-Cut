#!/bin/bash
# FILE: modules/installer.sh
# FILE: modules/installer V2.0 (MODULAR REALTIME UPDATE) INSTALLER=2.0

# --- [1] FUNGSI DASAR INSTALLASI ---
cek_paket() {
    local pkg_name=$1
    local cmd_check=$2
    if ! command -v "$cmd_check" &> /dev/null; then
        echo -e "\e[1;33m[*] Menginstall paket: $pkg_name...\e[0m"
        pkg install "$pkg_name" -y
    fi
}

install_kebutuhan() {
    if [ ! -d "$TOOLS_DIR" ]; then mkdir -p "$TOOLS_DIR"; fi
    
    cek_paket "bc" "bc"
    cek_paket "aria2" "aria2c"
    cek_paket "ffmpeg" "ffmpeg"
    cek_paket "termux-api" "termux-media-scan"
    cek_paket "jq" "jq"
    cek_paket "curl" "curl"
    cek_paket "figlet" "figlet"
    cek_paket "git" "git"
    cek_paket "nodejs-lts" "node"
    
    if ! gem list -i lolcat &> /dev/null; then gem install lolcat; fi

    # Setup Cookies
    if [ ! -d "/sdcard/INTISARI_DATA" ]; then mkdir -p "/sdcard/INTISARI_DATA"; fi
    if [ ! -s "/sdcard/INTISARI_DATA/cookies.txt" ]; then
        echo "# Netscape HTTP Cookie File" > "/sdcard/INTISARI_DATA/cookies.txt"
    fi

    # YT-DLP Setup
    if [ ! -f "$YTDLP_CMD" ]; then
        echo -e "\e[1;33m[*] Mengunduh Engine YouTube (YT-DLP)...\e[0m"
        curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$YTDLP_CMD"
        chmod +x "$YTDLP_CMD"
    fi
}

# --- [2] CORE: FUNGSI UPDATE MODULAR AMAN ---

safe_update_module() {
    local mod_name="$1"       # Nama Modul (utk Display)
    local local_ver="$2"      # Versi Lokal
    local remote_ver="$3"     # Versi Server
    local file_target="$4"    # Lokasi File Lokal
    local raw_url="$5"        # URL Raw File Server
    local config_var="$6"     # Nama Variabel di config.sh (misal: MOD_DL_VER)

    # 1. Cek Apakah Perlu Update
    local need_up=$(awk -v srv="$remote_ver" -v loc="$local_ver" 'BEGIN {print (srv > loc) ? 1 : 0}')
    
    if [ "$need_up" -eq 1 ]; then
        echo -e "\e[1;33m[UPDATE] $mod_name: v$local_ver -> v$remote_ver\e[0m"
        
        # 2. Download ke Temp
        local temp_file="${file_target}.new"
        curl -s -L "$raw_url" -o "$temp_file"
        
        # 3. INTEGRITY CHECK (Cek Code Error/Corrupt)
        if bash -n "$temp_file"; then
            # A. Jika Script Valid (Aman)
            mv "$temp_file" "$file_target"
            chmod +x "$file_target"
            
            # B. Update Versi di Config.sh menggunakan SED
            # Mencari baris VAR="x.x" dan menggantinya dengan VAR="ver_baru"
            sed -i "s/^${config_var}=.*/${config_var}=\"${remote_ver}\"/" "$MODULES_DIR/config.sh"
            sed -i "s/^${config_var}=.*/${config_var}=\"${remote_ver}\"/" "modules/config.sh" 2>/dev/null # Fallback path
            
            echo -e "\e[1;32m   [V] Sukses Update $mod_name\e[0m"
            return 0 # Berhasil update
        else
            # C. Jika Script Error (Corrupt)
            echo -e "\e[1;41m[BAHAYA] UPDATE $mod_name GAGAL! DETEKSI KERUSAKAN CODE.\e[0m"
            echo -e "\e[1;31m   -> Script server error/tidak lengkap. Membatalkan update modul ini.\e[0m"
            echo -e "\e[1;31m   -> Silakan Hubungi Developer: Modul $mod_name Rusak.\e[0m"
            rm -f "$temp_file"
            sleep 2
            return 1 # Gagal
        fi
    else
        # Tidak perlu update
        return 2 
    fi
}

cek_update_otomatis() {
    # Cek Koneksi
    if ! curl -s --head --request GET https://google.com --max-time 3 | grep "200 OK" > /dev/null; then
        return
    fi

    # 1. Ambil Manifest Server
    # Pastikan LINK_MANIFEST di config.sh benar
    local manifest_data=$(curl -s --max-time 5 "$LINK_MANIFEST")
    
    if [ -z "$manifest_data" ]; then return; fi

    # 2. Parsing Versi Server
    local s_core=$(echo "$manifest_data" | grep "^CORE=" | cut -d'=' -f2 | tr -d '\r')
    local s_dl=$(echo "$manifest_data" | grep "^DOWNLOADER=" | cut -d'=' -f2 | tr -d '\r')
    local s_proc=$(echo "$manifest_data" | grep "^PROCESSOR=" | cut -d'=' -f2 | tr -d '\r')
    local s_auth=$(echo "$manifest_data" | grep "^AUTH=" | cut -d'=' -f2 | tr -d '\r')
    local s_inst=$(echo "$manifest_data" | grep "^INSTALLER=" | cut -d'=' -f2 | tr -d '\r')
    local s_utils=$(echo "$manifest_data" | grep "^UTILS=" | cut -d'=' -f2 | tr -d '\r')
    local s_viral=$(echo "$manifest_data" | grep "^VIRAL=" | cut -d'=' -f2 | tr -d '\r')

    # Base URL Raw Github (Sesuaikan jika path berubah di config)
    # Default: https://raw.githubusercontent.com/USER/REPO/BRANCH/modules/
    local BASE_URL="$LINK_RAW_MODULES"
    # Fallback jika LINK_RAW_MODULES kosong
    if [ -z "$BASE_URL" ]; then BASE_URL="https://raw.githubusercontent.com/intisariapps/Intisari-AutoCut/main/modules"; fi
    local ROOT_URL="https://raw.githubusercontent.com/intisariapps/Intisari-AutoCut/main"

    local RESTART_REQ=0

    echo -e "\e[1;30m[*] Mengecek integritas modul server...\e[0m"

    # --- EKSEKUSI CEK PER MODUL ---
    
    # 1. Installer (Self Update)
    safe_update_module "Installer" "$MOD_INST_VER" "$s_inst" "$MODULES_DIR/installer.sh" "$BASE_URL/installer.sh" "MOD_INST_VER"
    
    # 2. Utils
    safe_update_module "Utils" "$MOD_UTILS_VER" "$s_utils" "$MODULES_DIR/utils.sh" "$BASE_URL/utils.sh" "MOD_UTILS_VER"
    
    # 3. Auth
    safe_update_module "Auth System" "$MOD_AUTH_VER" "$s_auth" "$MODULES_DIR/auth.sh" "$BASE_URL/auth.sh" "MOD_AUTH_VER"

    # 4. Downloader
    safe_update_module "Downloader" "$MOD_DL_VER" "$s_dl" "$MODULES_DIR/downloader.sh" "$BASE_URL/downloader.sh" "MOD_DL_VER"
    
    # 5. Processor
    safe_update_module "Processor" "$MOD_PROC_VER" "$s_proc" "$MODULES_DIR/processor.sh" "$BASE_URL/processor.sh" "MOD_PROC_VER"

    # 6. Viral
    safe_update_module "Viral Mod" "$MOD_VIRAL_VER" "$s_viral" "$MODULES_DIR/viral_downloader.sh" "$BASE_URL/viral_downloader.sh" "MOD_VIRAL_VER"

    # 7. MAIN CORE (Terakhir karena butuh restart)
    # Lokasi main.sh ada di folder root, bukan modules
    safe_update_module "System Core" "$SYS_VER" "$s_core" "$SCRIPT_DIR/main.sh" "$ROOT_URL/main.sh" "SYS_VER"
    if [ $? -eq 0 ]; then RESTART_REQ=1; fi

    # Restart jika Core berubah
    if [ "$RESTART_REQ" -eq 1 ]; then
        echo -e "\e[1;32m[!] CORE SYSTEM DIPERBARUI. MERESTART...\e[0m"
        sleep 2
        exec bash "$SCRIPT_DIR/main.sh"
    fi
}

update_tools() {
    clear
    echo -e "\e[1;34m[*] Mengecek Update Server (Realtime)...\e[0m"
    cek_update_otomatis
    echo -e "\e[1;32m[V] Pengecekan Selesai.\e[0m"
    read -p "Tekan Enter untuk kembali..."
}
