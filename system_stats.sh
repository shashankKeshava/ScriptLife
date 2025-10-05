#!/bin/bash

# macOS System Stats Monitor
# Comprehensive system information script including temperature and fan data

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to safely get numeric value
safe_calc() {
    if command_exists bc; then
        echo "$1" | bc 2>/dev/null || echo "N/A"
    else
        echo "N/A"
    fi
}

# Header
echo -e "${CYAN}================================================================${NC}"
echo -e "${WHITE}                 macOS System Monitor                          ${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""

# Hardware Information
echo -e "${BLUE}🖥️  HARDWARE INFORMATION${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
system_profiler SPHardwareDataType | grep -E "(Model Name|Model Identifier|Processor Name|Memory|Serial Number)" | sed 's/^[ ]*//' | while read line; do
    echo -e "${WHITE}$line${NC}"
done

# CPU Information
echo ""
echo -e "${BLUE}⚙️  CPU INFORMATION${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
cpu_brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
cpu_cores=$(sysctl -n machdep.cpu.core_count 2>/dev/null || echo "N/A")
cpu_threads=$(sysctl -n machdep.cpu.thread_count 2>/dev/null || echo "N/A")
cpu_freq=$(sysctl -n hw.cpufrequency_max 2>/dev/null || echo "N/A")

echo -e "${WHITE}CPU Brand:${NC} $cpu_brand"
echo -e "${WHITE}CPU Cores:${NC} $cpu_cores"
echo -e "${WHITE}CPU Threads:${NC} $cpu_threads"
if [ "$cpu_freq" != "N/A" ] && command_exists bc; then
    cpu_freq_ghz=$(safe_calc "scale=2; $cpu_freq / 1000000000")
    echo -e "${WHITE}Max Frequency:${NC} ${cpu_freq_ghz} GHz"
elif [ "$cpu_freq" != "N/A" ]; then
    echo -e "${WHITE}Max Frequency:${NC} $cpu_freq Hz"
fi

# System Load and Uptime
echo ""
echo -e "${BLUE}📊 SYSTEM PERFORMANCE${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
uptime_info=$(uptime)
echo -e "${WHITE}Uptime:${NC} $(echo $uptime_info | sed 's/.*up //' | sed 's/,.*load.*//')"
echo -e "${WHITE}Load Average:${NC} $(echo $uptime_info | sed 's/.*load averages: //')"

# CPU Usage - improved error handling and faster execution
if command_exists iostat; then
    echo -e "${YELLOW}Collecting CPU usage data...${NC}"
    # Use shorter sampling time for faster results
    cpu_usage=$(timeout 3s iostat -c 1 1 2>/dev/null | tail -1)
    if [ -n "$cpu_usage" ] && [[ "$cpu_usage" == *"%"* ]]; then
        user_cpu=$(echo $cpu_usage | awk '{print $4}' 2>/dev/null || echo "N/A")
        sys_cpu=$(echo $cpu_usage | awk '{print $5}' 2>/dev/null || echo "N/A")
        idle_cpu=$(echo $cpu_usage | awk '{print $6}' 2>/dev/null || echo "N/A")
        echo -e "${WHITE}CPU Usage:${NC} ${user_cpu}% user, ${sys_cpu}% system, ${idle_cpu}% idle"
    else
        # Fallback to top command for faster CPU info
        if command_exists top; then
            cpu_info=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | head -1)
            if [ -n "$cpu_info" ]; then
                echo -e "${WHITE}CPU Usage:${NC} $cpu_info"
            else
                echo -e "${YELLOW}CPU usage data temporarily unavailable${NC}"
            fi
        else
            echo -e "${YELLOW}CPU usage data temporarily unavailable${NC}"
        fi
    fi
else
    # Alternative method using top
    if command_exists top; then
        echo -e "${YELLOW}Using top for CPU usage (iostat not available)...${NC}"
        cpu_info=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | head -1)
        if [ -n "$cpu_info" ]; then
            echo -e "${WHITE}CPU Usage:${NC} $cpu_info"
        else
            echo -e "${YELLOW}CPU usage data unavailable${NC}"
        fi
    else
        echo -e "${YELLOW}CPU usage tools not available${NC}"
    fi
fi

# Memory Information
echo ""
echo -e "${BLUE}💾 MEMORY INFORMATION${NC}"
echo -e "${CYAN}----------------------------------------${NC}"

# Get memory info from vm_stat with better error handling
if vm_stat_output=$(vm_stat 2>/dev/null); then
    page_size=$(echo "$vm_stat_output" | head -1 | sed 's/.*(\([0-9]*\) bytes).*/\1/' 2>/dev/null || echo "4096")
    pages_free=$(echo "$vm_stat_output" | grep "Pages free" | awk '{print $3}' | tr -d '.' 2>/dev/null || echo "0")
    pages_active=$(echo "$vm_stat_output" | grep "Pages active" | awk '{print $3}' | tr -d '.' 2>/dev/null || echo "0")
    pages_inactive=$(echo "$vm_stat_output" | grep "Pages inactive" | awk '{print $3}' | tr -d '.' 2>/dev/null || echo "0")
    pages_wired=$(echo "$vm_stat_output" | grep "Pages wired down" | awk '{print $4}' | tr -d '.' 2>/dev/null || echo "0")

    # Convert to MB with error checking
    if [[ "$page_size" =~ ^[0-9]+$ ]] && [[ "$pages_free" =~ ^[0-9]+$ ]]; then
        free_mb=$((pages_free * page_size / 1024 / 1024))
        active_mb=$((pages_active * page_size / 1024 / 1024))
        inactive_mb=$((pages_inactive * page_size / 1024 / 1024))
        wired_mb=$((pages_wired * page_size / 1024 / 1024))
        total_mb=$((free_mb + active_mb + inactive_mb + wired_mb))

        echo -e "${WHITE}Total Memory:${NC} ${total_mb} MB"
        echo -e "${WHITE}Free Memory:${NC} ${free_mb} MB"
        echo -e "${WHITE}Active Memory:${NC} ${active_mb} MB"
        echo -e "${WHITE}Inactive Memory:${NC} ${inactive_mb} MB"
        echo -e "${WHITE}Wired Memory:${NC} ${wired_mb} MB"
        
        # Calculate memory usage percentage
        if [ $total_mb -gt 0 ] && command_exists bc; then
            used_mb=$((total_mb - free_mb))
            usage_percent=$(safe_calc "scale=1; $used_mb * 100 / $total_mb")
            echo -e "${WHITE}Memory Usage:${NC} ${usage_percent}%"
        fi
    else
        echo -e "${YELLOW}Unable to parse memory statistics${NC}"
    fi
else
    echo -e "${YELLOW}Memory statistics unavailable${NC}"
fi

# Storage Information
echo ""
echo -e "${BLUE}💽 STORAGE INFORMATION${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
df -h 2>/dev/null | grep -E "^/dev/disk" | head -5 | while read line; do
    filesystem=$(echo $line | awk '{print $1}')
    size=$(echo $line | awk '{print $2}')
    used=$(echo $line | awk '{print $3}')
    avail=$(echo $line | awk '{print $4}')
    capacity=$(echo $line | awk '{print $5}')
    mount=$(echo $line | awk '{print $9}')
    
    if [[ "$mount" == "/" ]]; then
        echo -e "${WHITE}Main Drive:${NC} $size total, $used used, $avail available ($capacity full)"
    elif [[ "$mount" == *"Data"* ]]; then
        echo -e "${WHITE}Data Volume:${NC} $used used"
    elif [[ -n "$mount" ]]; then
        echo -e "${WHITE}$(basename $mount):${NC} $size total, $used used ($capacity full)"
    fi
done

# Network Information
echo ""
echo -e "${BLUE}🌐 NETWORK INFORMATION${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
if active_interface=$(route get default 2>/dev/null | grep interface | awk '{print $2}'); then
    if [ -n "$active_interface" ]; then
        ip_address=$(ifconfig $active_interface 2>/dev/null | grep "inet " | awk '{print $2}')
        echo -e "${WHITE}Active Interface:${NC} $active_interface"
        echo -e "${WHITE}IP Address:${NC} ${ip_address:-"Not available"}"
        
        # Get additional network info
        if ifconfig $active_interface 2>/dev/null | grep -q "status: active"; then
            echo -e "${WHITE}Status:${NC} ${GREEN}Active${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Network interface information unavailable${NC}"
fi

# Battery Information
echo ""
echo -e "${BLUE}🔋 BATTERY INFORMATION${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
if battery_info=$(pmset -g batt 2>/dev/null); then
    echo "$battery_info" | grep -v "Now drawing" | while read line; do
        if [[ "$line" == *"InternalBattery"* ]]; then
            battery_status=$(echo $line | sed 's/.*InternalBattery[^	]*	//' | sed 's/ present:.*//')
            echo -e "${WHITE}Battery:${NC} $battery_status"
        fi
    done
    power_source=$(echo "$battery_info" | head -1 | sed "s/Now drawing from '//" | sed "s/'//")
    echo -e "${WHITE}Power Source:${NC} $power_source"
else
    echo -e "${YELLOW}Battery information unavailable (desktop system?)${NC}"
fi

# Temperature and Fan Information
echo ""
echo -e "${BLUE}🌡️  TEMPERATURE & FAN INFORMATION${NC}"
echo -e "${CYAN}----------------------------------------${NC}"

# Try multiple methods to get temperature data
temp_found=false

# Method 1: Try istats first (most comprehensive)
if command_exists istats; then
    echo -e "${GREEN}Using iStats for sensor data...${NC}"
    if temp_data=$(timeout 5s istats all 2>/dev/null); then
        echo "$temp_data" | grep -E "(CPU|GPU|Fan|Battery)" | while read line; do
            echo -e "${WHITE}  $line${NC}"
        done
        temp_found=true
    fi
fi

# Method 2: Try osx-cpu-temp if istats didn't work
if ! $temp_found && command_exists osx-cpu-temp; then
    echo -e "${GREEN}Using osx-cpu-temp for CPU temperature...${NC}"
    if cpu_temp=$(timeout 3s osx-cpu-temp 2>/dev/null); then
        echo -e "${WHITE}CPU Temperature:${NC} $cpu_temp"
        temp_found=true
    fi
fi

# Method 3: Try powermetrics (requires sudo)
if ! $temp_found && command_exists powermetrics; then
    echo -e "${YELLOW}Attempting to get temperature data with powermetrics (requires sudo)...${NC}"
    if temp_data=$(timeout 5s sudo powermetrics --samplers smc -n 1 -i 100 2>/dev/null | grep -E "(CPU die temperature|GPU die temperature|Fan)" 2>/dev/null); then
        if [ -n "$temp_data" ]; then
            echo "$temp_data" | while read line; do
                echo -e "${WHITE}$line${NC}"
            done
            temp_found=true
        fi
    fi
fi

# If no temperature tools worked
if ! $temp_found; then
    echo -e "${YELLOW}Temperature data not available.${NC}"
    echo -e "${WHITE}Troubleshooting:${NC}"
    if ! command_exists istats; then
        echo -e "  • ${CYAN}sudo gem install iStats${NC} - Comprehensive system sensors"
    fi
    if ! command_exists osx-cpu-temp; then
        echo -e "  • ${CYAN}brew install osx-cpu-temp${NC} - Simple CPU temperature"
    fi
    echo -e "  • Run with sudo for powermetrics access"
    echo -e "  • Check if tools are properly installed and in PATH"
fi

# Process Information
echo ""
echo -e "${BLUE}🔧 TOP PROCESSES (by CPU)${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
echo -e "${WHITE}PID    %CPU   %MEM   COMMAND${NC}"
if ps_output=$(ps aux 2>/dev/null | sort -k3 -nr | head -5); then
    echo "$ps_output" | while read line; do
        pid=$(echo $line | awk '{print $2}')
        cpu=$(echo $line | awk '{print $3}')
        mem=$(echo $line | awk '{print $4}')
        cmd=$(echo $line | awk '{print $11}' | sed 's/.*\///' 2>/dev/null || echo $line | awk '{print $11}')
        printf "${WHITE}%-6s %-6s %-6s %s${NC}\n" "$pid" "$cpu%" "$mem%" "$cmd"
    done
else
    echo -e "${YELLOW}Process information unavailable${NC}"
fi

# System Information Summary
echo ""
echo -e "${BLUE}📋 SYSTEM SUMMARY${NC}"
echo -e "${CYAN}----------------------------------------${NC}"
os_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
kernel_version=$(uname -r 2>/dev/null || echo "Unknown")
current_shell=$(basename "$SHELL" 2>/dev/null || echo "Unknown")

# Better shell version detection
if [[ "$SHELL" == *"zsh"* ]] && [ -n "$ZSH_VERSION" ]; then
    shell_info="$current_shell ($ZSH_VERSION)"
elif [[ "$SHELL" == *"bash"* ]] && [ -n "$BASH_VERSION" ]; then
    shell_info="$current_shell ($BASH_VERSION)"
else
    shell_info="$current_shell"
fi

echo -e "${WHITE}macOS Version:${NC} $os_version"
echo -e "${WHITE}Kernel Version:${NC} $kernel_version"
echo -e "${WHITE}Shell:${NC} $shell_info"
echo -e "${WHITE}Terminal:${NC} ${TERM:-"Unknown"}"
echo -e "${WHITE}User:${NC} $(whoami 2>/dev/null || echo "Unknown")"
echo -e "${WHITE}Hostname:${NC} $(hostname 2>/dev/null || echo "Unknown")"

# Check if running in Rosetta (for Apple Silicon Macs)
if [[ $(uname -m) == "x86_64" ]] && [[ $(sysctl -n machdep.cpu.brand_string 2>/dev/null) == *"Apple"* ]]; then
    echo -e "${WHITE}Architecture:${NC} ${YELLOW}x86_64 (Rosetta)${NC}"
elif [[ $(uname -m) == "arm64" ]]; then
    echo -e "${WHITE}Architecture:${NC} ${GREEN}ARM64 (Native)${NC}"
else
    echo -e "${WHITE}Architecture:${NC} $(uname -m 2>/dev/null || echo "Unknown")"
fi

# Footer
echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${WHITE}                   Generated: $(date)                    ${NC}"
echo -e "${CYAN}================================================================${NC}"