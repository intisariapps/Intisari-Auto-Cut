#!/bin/bash
# FILE: main.sh
# FILE: Modular main V 1.9 (Clean UI Fix) CORE=6.0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# --- [1] LOAD MODULES ---
if [ -d "$MODULES_DIR" ]; then
    source "$MODULES_DIR/config.sh"
    source "$MODULES_DIR/utils.sh"
    source "$MODULES_DIR/installer.sh"
    source "$MODULES_DIR/auth.sh"
    source "$MODULES_DIR/downloader.sh"
    source "$MODULES_DIR/processor.sh"
    source "$MODULES_DIR/viral_downloader.sh"
else
    echo "Error: Folder modules tidak ditemukan!"
    exit 1
fi

# --- [2] STARTUP SEQUENCE ---
install_kebutuhan
cek_update_otomatis
setup_autorun

clear
if [ ! -d "$HOME/storage" ]; then 
    echo -e "\e[1;33m[*] Meminta Izin Penyimpanan Android...\e[0m"
    termux-setup-storage
    sleep 2
fi

# --- [3] SECURITY CHECK ---
amankan_lisensi # Cek restore dari SD Card
if [ -f "$FILE_LISENSI" ]; then 
    amankan_lisensi # Double check backup
    silent_security_check
    G_TEMP=$(cat "$FILE_LISENSI")
    K_TEMP=$(echo "$G_TEMP" | rev | cut -d'-' -f1 --complement | rev)
    I_TEMP=$(echo "$G_TEMP" | rev | cut -d'-' -f1 | rev)
    cek_lisensi_online "$K_TEMP" "$I_TEMP" "silent"
else 
    menu_aktivasi
fi

# --- KONFIGURASI WARNA (FIXED) ---
ORANGE='\033[38;5;208m'
GOLD='\033[38;5;220m'
CYAN='\033[38;5;44m'
WHITE='\033[1;37m'
GRAY='\033[1;30m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- [4] UI FUNCTIONS (CLEAN VERSION) ---

header_pro() {
    clear
    echo -e "${CYAN}"
    echo "  ___ _   _ _____ ___ ____   _    ____ ___ "
    echo " |_ _| \ | |_   _|_ _/ ___| / \  |  _ \_ _| "
    echo "  | ||  \| | | |  | |\___ \/ _ \ | |_) | |  "
    echo "  | || |\  | | |  | | ___) / ___ \|  _ <| |  "
    echo " |___|_| \_| |_| |___|____/_/   \_\_| \_\___| "
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
}

status_bar() {
    # LOGIC FIX: Pastikan data terambil
    if declare -f get_total_stats > /dev/null; then
        TOTAL_CUT_GLOBAL=$(get_total_stats)
    else
        TOTAL_CUT_GLOBAL="0"
    fi

    # Fallback jika kosong
    if [[ -z "$TOTAL_CUT_GLOBAL" ]]; then TOTAL_CUT_GLOBAL="0"; fi
    
    # Fallback jika Member ID belum load
    if [[ -z "$MEMBER_ID" || "$MEMBER_ID" == "???" ]]; then MEMBER_ID="Guest_User"; fi

    # TAMPILAN CLEAN (Tanpa Garis Kotak)
    echo -e " ${GRAY}SYSTEM  :${NC} ${GREEN}ONLINE${NC} ${GRAY}|${NC} ${WHITE}V$SYS_VER${NC}"
    echo -e " ${GRAY}USER ID :${NC} ${CYAN}#${MEMBER_ID}${NC}"
    echo -e " ${GRAY}STATS   :${NC} ${GOLD}${TOTAL_CUT_GLOBAL} Video(s) Created${NC}"
    echo -e " ${GRAY}MODE    :${NC} ${RED}PRO LICENSE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
}

# --- [5] MAIN MENU LOOP ---
while true; do
    cek_update_otomatis
    header_pro
    status_bar
    
    echo -e ""
    echo -e " ${GOLD}SELECT MODULE:${NC}"
    echo -e " ${CYAN}[1]${NC} • ${WHITE}YouTube Downloader ${GREEN}(Anti-Ban V2)${NC}"
    echo -e " ${CYAN}[2]${NC} • ${WHITE}TikTok Downloader ${GRAY}(No Watermark)${NC}"
    echo -e " ${CYAN}[3]${NC} • ${WHITE}Instagram Downloader${NC}"
    echo -e " ${CYAN}[4]${NC} • ${WHITE}Facebook Downloader${NC}"
    echo -e " ${CYAN}[5]${NC} • ${WHITE}Potong Video Galeri ${GRAY}(Manual Pick)${NC}"
    echo -e " ${CYAN}[7]${NC} • ${WHITE}Download Video Viral ${GOLD}(Auto-Split)${NC}"
    echo -e " ${CYAN}[6]${NC} • ${WHITE}Update Engine ${GRAY}${NC}"
    echo -e " ${GRAY}[8]${NC} • ${GRAY}Fitur Akan Datang (Coming Soon) 🔥${NC}"
    echo -e " ${CYAN}[u]${NC} • ${WHITE}Update Tools${NC}"
    echo -e " ${RED}[x]${NC} • ${WHITE}Exit Program${NC}"
    echo -e ""
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "  Command > " choice

    case $choice in
      1) run_youtube_downloader ;;
      2|3|4) run_sosmed_downloader "$choice" ;;
      5)
        while true; do
            header_potong 
            echo -e "${WHITE}  MODE: PILIH VIDEO DARI GALERI${NC}"
            echo -e "${GRAY}  Direktori: $VIDEO_SOURCE_DIR${NC}"
            echo -e "${GRAY}  Tekan 'x' untuk kembali ke menu utama${NC}\n"
            
            vids=(); idx=1
            # Menggunakan process substitution untuk membaca file dengan aman
            while IFS= read -r -d $'\0' file; do 
                vids+=("$file")
                echo -e " [$idx] ${WHITE}$(basename "$file")${NC}"
                ((idx++))
            done < <(find "$VIDEO_SOURCE_DIR" -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.mkv" \) -print0 2>/dev/null)
            
            if [ ${#vids[@]} -eq 0 ]; then 
                echo -e "${RED}[!] Folder Video Kosong!${NC}"; sleep 2; break
            fi
            
            read -p " Nomor Video > " v_num
            
            [[ "$v_num" == "x" || "$v_num" == "X" ]] && break
            
            if [ -n "$v_num" ] && [ "$v_num" -le ${#vids[@]} ] 2>/dev/null; then 
                proses_potong "${vids[$((v_num-1))]}"
                break 
            else
                echo -e "${RED}[!] Nomor tidak valid!${NC}"; sleep 1
            fi
        done
        ;;
      6) clear; echo -e "${GOLD}[*] Update Engine YT-DLP...${NC}"; "$YTDLP_CMD" -U; echo -e "\n${GREEN}[V] Selesai!${NC}"; sleep 3 ;;
      7) run_viral_downloader ;; 
      8) 
        clear
        echo -e "${CYAN}========================================${NC}"
        echo -e "${YELLOW}       COMING SOON - NEXT UPDATE        ${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo -e "${WHITE}[*] Fitur: Auto Upload Sosial Media"
        echo -e "${WHITE}[*] Fitur: Caption Generator PerClip"
        echo -e "${WHITE}[*] Fitur: Intisari Viral Lens With Gemini"
        echo -e "${WHITE}[*] Fitur: ---------Next-----------"
        echo -e "[*] Status: Dalam Pengembangan"
        echo -e "${CYAN}----------------------------------------${NC}"
        read -p "Tekan Enter untuk kembali..." 
        ;;
      u|U) update_tools ;;
      x|X) 
        echo -e "${RED}Terima kasih telah menggunakan Intisari Clipper.${NC}"
        sleep 2
        
        cd "$HOME"
        clear
        echo -e "${GREEN}Anda sekarang berada di menu utama Termux.${NC}"
        exit 0
        ;;
      *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
      echo 'if [ -f "$HOME/Intisari-Auto-Cut/main.sh" ]; then bash "$HOME/Intisari-Auto-Cut/main.sh"; fi' >> ~/.bashrc
    esac
done
