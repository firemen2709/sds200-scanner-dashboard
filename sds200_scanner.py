#!/usr/bin/env python3
"""
SDS200 Scanner Data Collector
Pulls data from Uniden SDS200 scanner via network and provides API for web dashboard
"""

import socket
import json
import time
import threading
from datetime import datetime
from pathlib import Path
import logging

# Configuration
SCANNER_IP = "192.168.2.251"
SCANNER_PORT = 10001
SOCKET_TIMEOUT = 5
DATA_FILE = "/tmp/sds200_data.json"
LOG_FILE = "/tmp/sds200_scanner.log"

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class SDS200Scanner:
    def __init__(self, ip, port):
        self.ip = ip
        self.port = port
        self.socket = None
        self.scanner_data = {
            "timestamp": None,
            "connected": False,
            "model": None,
            "firmware": None,
            "frequency": None,
            "signal_strength": None,
            "volume": None,
            "squelch": None,
            "mode": None,
            "status": None,
            "error": None,
            "all_responses": {}
        }
    
    def connect(self):
        """Connect to the SDS200 scanner"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(SOCKET_TIMEOUT)
            self.socket.connect((self.ip, self.port))
            self.scanner_data["connected"] = True
            self.scanner_data["error"] = None
            logger.info(f"Connected to SDS200 at {self.ip}:{self.port}")
            return True
        except Exception as e:
            self.scanner_data["connected"] = False
            self.scanner_data["error"] = str(e)
            logger.error(f"Failed to connect to SDS200: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from the SDS200 scanner"""
        try:
            if self.socket:
                self.socket.close()
                self.scanner_data["connected"] = False
                logger.info("Disconnected from SDS200")
        except Exception as e:
            logger.error(f"Error disconnecting: {e}")
    
    def send_command(self, command):
        """Send a command to the scanner and receive response"""
        try:
            # Add carriage return if not present
            if not command.endswith('\r'):
                command += '\r'
            
            self.socket.sendall(command.encode())
            response = self.socket.recv(4096).decode().strip()
            return response
        except socket.timeout:
            logger.warning(f"Socket timeout for command: {command}")
            return None
        except Exception as e:
            logger.error(f"Error sending command {command}: {e}")
            return None
    
    def parse_response(self, response, command_type):
        """Parse scanner responses and extract data"""
        if not response:
            return None
        
        try:
            parts = response.split(',')
            
            if command_type == 'MDL' and len(parts) >= 2:
                return parts[1]
            elif command_type == 'VER' and len(parts) >= 2:
                return parts[1]
            elif command_type == 'STS' and len(parts) >= 2:
                # STS response format: STS,FREQUENCY,SIGNAL_STRENGTH,MODE,VOLUME,SQUELCH
                return {
                    'frequency': parts[1] if len(parts) > 1 else None,
                    'signal_strength': parts[2] if len(parts) > 2 else None,
                    'mode': parts[3] if len(parts) > 3 else None,
                    'volume': parts[4] if len(parts) > 4 else None,
                    'squelch': parts[5] if len(parts) > 5 else None,
                }
            else:
                return response
        except Exception as e:
            logger.error(f"Error parsing response: {e}")
            return response
    
    def get_model(self):
        """Get scanner model"""
        response = self.send_command('MDL')
        if response:
            self.scanner_data["model"] = self.parse_response(response, 'MDL')
            self.scanner_data["all_responses"]["MDL"] = response
    
    def get_firmware(self):
        """Get firmware version"""
        response = self.send_command('VER')
        if response:
            self.scanner_data["firmware"] = self.parse_response(response, 'VER')
            self.scanner_data["all_responses"]["VER"] = response
    
    def get_status(self):
        """Get current scanner status"""
        response = self.send_command('STS')
        if response:
            status = self.parse_response(response, 'STS')
            if isinstance(status, dict):
                self.scanner_data.update(status)
            self.scanner_data["status"] = response
            self.scanner_data["all_responses"]["STS"] = response
    
    def pull_all_data(self):
        """Pull all data from scanner"""
        self.scanner_data["timestamp"] = datetime.now().isoformat()
        
        if not self.scanner_data["connected"]:
            if not self.connect():
                return False
        
        try:
            self.get_model()
            self.get_firmware()
            self.get_status()
            return True
        except Exception as e:
            logger.error(f"Error pulling data: {e}")
            self.scanner_data["error"] = str(e)
            return False
    
    def save_to_file(self):
        """Save scanner data to JSON file"""
        try:
            with open(DATA_FILE, 'w') as f:
                json.dump(self.scanner_data, f, indent=2)
            logger.debug(f"Data saved to {DATA_FILE}")
        except Exception as e:
            logger.error(f"Error saving data to file: {e}")
    
    def get_data(self):
        """Get current scanner data"""
        return self.scanner_data

def continuous_scan(scanner, interval=1):
    """Continuously scan the scanner at specified interval"""
    logger.info(f"Starting continuous scan with {interval}s interval")
    
    while True:
        try:
            if not scanner.scanner_data["connected"]:
                scanner.connect()
            
            scanner.pull_all_data()
            scanner.save_to_file()
            
            time.sleep(interval)
        except KeyboardInterrupt:
            logger.info("Scan interrupted by user")
            break
        except Exception as e:
            logger.error(f"Error in continuous scan: {e}")
            scanner.disconnect()
            time.sleep(5)  # Wait before reconnecting

def main():
    """Main function"""
    scanner = SDS200Scanner(SCANNER_IP, SCANNER_PORT)
    
    # Start continuous scanning in background thread
    scan_thread = threading.Thread(target=continuous_scan, args=(scanner, 1), daemon=True)
    scan_thread.start()
    
    logger.info("SDS200 Scanner Data Collector started")
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        scanner.disconnect()

if __name__ == "__main__":
    main()