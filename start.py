#!/usr/bin/env python3
"""
ZViewer Startup Script
=====================

This script provides an easy way to start both the Flutter client and Go server
for the ZViewer multimedia application.

Usage:
    python start.py [options]

Options:
    --client-only    Start only the Flutter client
    --server-only    Start only the Go server
    --no-db          Start server without database (for testing)
    --help           Show this help message

Requirements:
    - Python 3.6+
    - Flutter SDK installed and in PATH
    - Go 1.21+ installed and in PATH
    - PostgreSQL (if not using --no-db)
    - Docker and Docker Compose (for database)

Author: ZViewer Development Team
"""

import os
import sys
import subprocess
import time
import signal
import argparse
import threading
import platform
from pathlib import Path
from typing import List, Optional, Dict, Any

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

class ZViewerStarter:
    def __init__(self):
        self.root_dir = Path(__file__).parent.absolute()
        self.client_dir = self.root_dir / "application"
        self.server_dir = self.root_dir / "server"
        self.processes: List[subprocess.Popen] = []
        self.running = True
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        # Platform-specific commands
        self.is_windows = platform.system() == "Windows"
        self.flutter_cmd = "flutter.bat" if self.is_windows else "flutter"
        self.go_cmd = "go.exe" if self.is_windows else "go"
        self.docker_cmd = "docker.exe" if self.is_windows else "docker"

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        print(f"\n{Colors.YELLOW}Received shutdown signal. Stopping all processes...{Colors.END}")
        self.running = False
        self.stop_all_processes()
        sys.exit(0)

    def log(self, message: str, color: str = Colors.WHITE):
        """Print colored log message"""
        print(f"{color}{message}{Colors.END}")

    def check_requirements(self) -> bool:
        """Check if all required tools are installed"""
        self.log("🔍 Checking requirements...", Colors.CYAN)
        
        requirements = [
            (self.flutter_cmd, "Flutter SDK"),
            (self.go_cmd, "Go"),
            (self.docker_cmd, "Docker")
        ]
        
        missing = []
        for cmd, name in requirements:
            if not self._command_exists(cmd):
                missing.append(name)
        
        if missing:
            self.log(f"❌ Missing requirements: {', '.join(missing)}", Colors.RED)
            self.log("Please install the missing tools and try again.", Colors.YELLOW)
            return False
        
        self.log("✅ All requirements satisfied", Colors.GREEN)
        return True

    def _command_exists(self, command: str) -> bool:
        """Check if a command exists in PATH"""
        try:
            # Use different version flags for different commands
            if command in [self.go_cmd, "go", "go.exe"]:
                subprocess.run([command, "version"], 
                             capture_output=True, check=True, timeout=10)
            else:
                subprocess.run([command, "--version"], 
                             capture_output=True, check=True, timeout=10)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            return False

    def start_database(self) -> bool:
        """Start PostgreSQL database using Docker Compose"""
        self.log("🐘 Starting PostgreSQL database...", Colors.CYAN)
        
        try:
            # Change to server directory and start database
            os.chdir(self.server_dir)
            result = subprocess.run(
                [self.docker_cmd, "compose", "up", "-d", "postgres"],
                capture_output=True, text=True, timeout=60
            )
            
            if result.returncode != 0:
                self.log(f"❌ Failed to start database: {result.stderr}", Colors.RED)
                return False
            
            # Wait for database to be ready
            self.log("⏳ Waiting for database to be ready...", Colors.YELLOW)
            for i in range(30):  # Wait up to 30 seconds
                try:
                    result = subprocess.run(
                        [self.docker_cmd, "compose", "exec", "-T", "postgres", 
                         "pg_isready", "-U", "zviewer", "-d", "zviewer"],
                        capture_output=True, text=True, timeout=5
                    )
                    if result.returncode == 0:
                        self.log("✅ Database is ready", Colors.GREEN)
                        return True
                except subprocess.TimeoutExpired:
                    pass
                time.sleep(1)
            
            self.log("❌ Database failed to start within timeout", Colors.RED)
            return False
            
        except Exception as e:
            self.log(f"❌ Error starting database: {e}", Colors.RED)
            return False
        finally:
            os.chdir(self.root_dir)

    def start_server(self, no_db: bool = False) -> bool:
        """Start the Go server"""
        self.log("🚀 Starting Go server...", Colors.CYAN)
        
        try:
            os.chdir(self.server_dir)
            
            # Set environment variables
            env = os.environ.copy()
            env.update({
                "ENVIRONMENT": "development",
                "SERVER_PORT": "8080",
                "SERVER_HOST": "localhost",
                "DB_HOST": "localhost" if not no_db else "",
                "DB_PORT": "5432",
                "DB_USER": "zviewer",
                "DB_PASSWORD": "password",
                "DB_NAME": "zviewer",
                "DB_SSLMODE": "disable",
                "JWT_SECRET": "your-secret-key-change-in-production",
                "JWT_EXPIRATION": "24h"
            })
            
            # Start the server
            process = subprocess.Popen(
                [self.go_cmd, "run", "cmd/api/main.go"],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8',
                errors='replace',
                bufsize=1,
                universal_newlines=True
            )
            
            self.processes.append(process)
            
            # Monitor server output
            def monitor_server():
                for line in iter(process.stdout.readline, ''):
                    if not self.running:
                        break
                    if "Server starting" in line:
                        self.log(f"✅ Server started on port 8080", Colors.GREEN)
                    elif "Failed to" in line or "Error" in line:
                        self.log(f"❌ Server error: {line.strip()}", Colors.RED)
                    else:
                        self.log(f"🔧 Server: {line.strip()}", Colors.BLUE)
            
            threading.Thread(target=monitor_server, daemon=True).start()
            
            # Wait a moment for server to start
            time.sleep(3)
            
            # Check if server is still running
            if process.poll() is not None:
                self.log("❌ Server failed to start", Colors.RED)
                return False
            
            return True
            
        except Exception as e:
            self.log(f"❌ Error starting server: {e}", Colors.RED)
            return False
        finally:
            os.chdir(self.root_dir)

    def start_client(self) -> bool:
        """Start the Flutter client"""
        self.log("📱 Starting Flutter client...", Colors.CYAN)
        
        try:
            os.chdir(self.client_dir)
            
            # Get dependencies
            self.log("📦 Getting Flutter dependencies...", Colors.YELLOW)
            deps_result = subprocess.run(
                [self.flutter_cmd, "pub", "get"],
                capture_output=True, text=True, timeout=120
            )
            
            if deps_result.returncode != 0:
                self.log(f"❌ Failed to get dependencies: {deps_result.stderr}", Colors.RED)
                return False
            
            # Start Flutter app
            self.log("🎯 Launching Flutter app...", Colors.YELLOW)
            process = subprocess.Popen(
                [self.flutter_cmd, "run", "-d", "windows"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8',
                errors='replace',
                bufsize=1,
                universal_newlines=True
            )
            
            self.processes.append(process)
            
            # Monitor client output
            def monitor_client():
                for line in iter(process.stdout.readline, ''):
                    if not self.running:
                        break
                    if "Flutter run key commands" in line:
                        self.log("✅ Flutter app launched successfully", Colors.GREEN)
                    elif "Error" in line or "Exception" in line:
                        self.log(f"❌ Flutter error: {line.strip()}", Colors.RED)
                    elif "Hot reload" in line or "Hot restart" in line:
                        self.log(f"🔄 Flutter: {line.strip()}", Colors.MAGENTA)
                    else:
                        self.log(f"📱 Flutter: {line.strip()}", Colors.CYAN)
            
            threading.Thread(target=monitor_client, daemon=True).start()
            
            return True
            
        except Exception as e:
            self.log(f"❌ Error starting client: {e}", Colors.RED)
            return False
        finally:
            os.chdir(self.root_dir)

    def stop_all_processes(self):
        """Stop all running processes"""
        self.log("🛑 Stopping all processes...", Colors.YELLOW)
        
        for process in self.processes:
            try:
                if process.poll() is None:  # Process is still running
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
            except Exception as e:
                self.log(f"Warning: Error stopping process: {e}", Colors.YELLOW)
        
        self.processes.clear()

    def wait_for_processes(self):
        """Wait for all processes to complete"""
        try:
            while self.running and self.processes:
                # Check if any process has died
                alive_processes = []
                for process in self.processes:
                    if process.poll() is None:
                        alive_processes.append(process)
                    else:
                        self.log(f"Process {process.pid} has stopped", Colors.YELLOW)
                
                self.processes = alive_processes
                time.sleep(1)
                
        except KeyboardInterrupt:
            self.log("\n🛑 Interrupted by user", Colors.YELLOW)
        finally:
            self.stop_all_processes()

    def run(self, args):
        """Main execution method"""
        self.log("🎬 ZViewer Startup Script", Colors.BOLD + Colors.CYAN)
        self.log("=" * 50, Colors.CYAN)
        
        # Check requirements
        if not self.check_requirements():
            return 1
        
        success = True
        
        try:
            # Start database if not skipping
            if not args.no_db and not args.client_only:
                if not self.start_database():
                    self.log("❌ Failed to start database", Colors.RED)
                    return 1
            
            # Start server if not client-only
            if not args.client_only:
                if not self.start_server(args.no_db):
                    self.log("❌ Failed to start server", Colors.RED)
                    return 1
                
                # Give server time to start
                time.sleep(2)
            
            # Start client if not server-only
            if not args.server_only:
                if not self.start_client():
                    self.log("❌ Failed to start client", Colors.RED)
                    return 1
            
            # Show status
            self.log("\n🎉 ZViewer is running!", Colors.GREEN + Colors.BOLD)
            self.log("=" * 50, Colors.GREEN)
            if not args.client_only:
                self.log("🌐 Server: http://localhost:8080", Colors.WHITE)
                self.log("💾 Database: PostgreSQL on localhost:5432", Colors.WHITE)
            if not args.server_only:
                self.log("📱 Client: Flutter app should open automatically", Colors.WHITE)
            self.log("\nPress Ctrl+C to stop all services", Colors.YELLOW)
            
            # Wait for processes
            self.wait_for_processes()
            
        except Exception as e:
            self.log(f"❌ Unexpected error: {e}", Colors.RED)
            success = False
        finally:
            self.stop_all_processes()
        
        return 0 if success else 1

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Start ZViewer client and server",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    parser.add_argument(
        "--client-only",
        action="store_true",
        help="Start only the Flutter client"
    )
    
    parser.add_argument(
        "--server-only", 
        action="store_true",
        help="Start only the Go server"
    )
    
    parser.add_argument(
        "--no-db",
        action="store_true", 
        help="Start server without database (for testing)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.client_only and args.server_only:
        print("Error: Cannot specify both --client-only and --server-only")
        return 1
    
    starter = ZViewerStarter()
    return starter.run(args)

if __name__ == "__main__":
    sys.exit(main())
