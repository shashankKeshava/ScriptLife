# ScriptLife

> Utility scripts for macOS system monitoring and administration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

## Quick Start

```bash
# Clone and run
git clone https://github.com/shashankKeshava/ScriptLife.git
cd ScriptLife
chmod +x *.sh
./system_stats.sh
```

## Scripts

### `system_stats.sh`

Comprehensive macOS system information monitor

**Features:**

- Hardware specs and CPU details
- Memory, storage, and network info
- Battery status and temperature monitoring
- Process information and system summary

## Installation

### Basic (required)

```bash
git clone https://github.com/shashankKeshava/ScriptLife.git
cd ScriptLife
chmod +x *.sh
```

### Enhanced features (optional)

```bash
brew install bc osx-cpu-temp
sudo gem install iStats
```

## Example Output

```text
================================================================
                 macOS System Monitor
================================================================

🖥️  HARDWARE INFORMATION
----------------------------------------
Model Name: MacBook Pro
Processor Name: Apple M1 Pro
Memory: 32 GB

📊 SYSTEM PERFORMANCE
----------------------------------------
Uptime: 5 days, 12:34
Load Average: 2.1 1.8 1.5
CPU Usage: 15.2% user, 8.1% system, 76.7% idle

💾 MEMORY INFORMATION
----------------------------------------
Total Memory: 32768 MB
Free Memory: 8192 MB
Memory Usage: 75.0%
```

## Troubleshooting

**Permission denied:** `chmod +x system_stats.sh`

**Missing temperature data:** Install optional tools above

**Script hangs:** Normal during CPU collection (1-3 seconds)

## Contributing

1. Fork the repository
2. Create feature branch
3. Follow existing code style
4. Test on multiple macOS versions
5. Submit pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.
