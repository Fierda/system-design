#!/usr/bin/env python3
import argparse
import json
from collections import defaultdict
from datetime import datetime
import sys

# AWS SDK (optional - install with: pip install boto3)
try:
    import boto3
    AWS_AVAILABLE = True
except ImportError:
    AWS_AVAILABLE = False


class NginxLogAnalyzer:
    def __init__(self):
        self.total_requests = 0
        self.brute_force_attempts = 0
        self.ip_brute_force_count = defaultdict(int)
        self.failed_logins_by_ip = defaultdict(list)
        
        # Common login-related paths
        self.login_paths = {'/login'}
        
        # HTTP methods for faster lookup
        self.http_methods = {'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 
                           'OPTIONS', 'TRACE', 'CONNECT'}
    
    def parse_log_line(self, line):
        """
        Parse NGINX log line using string operations instead of regex
        Expected format: IP - - [timestamp] "METHOD path protocol" status size "referer" "user_agent"
        """
        line = line.strip()
        if not line:
            return None
        
        try:
            # Split line into major components
            parts = line.split(' ')
            if len(parts) < 7:
                return None
            
            # Extract IP (first part)
            ip = parts[0]
            
            # Find timestamp (between square brackets)
            timestamp_start = line.find('[')
            timestamp_end = line.find(']')
            if timestamp_start == -1 or timestamp_end == -1:
                timestamp = ''
            else:
                timestamp = line[timestamp_start + 1:timestamp_end]
            
            # Find request line (between first quotes)
            quote_start = line.find('"')
            if quote_start == -1:
                return None
            
            quote_end = line.find('"', quote_start + 1)
            if quote_end == -1:
                return None
            
            request_line = line[quote_start + 1:quote_end]
            
            # Parse request line
            request_parts = request_line.split(' ')
            if len(request_parts) < 3:
                return None
            
            method = request_parts[0]
            path = request_parts[1]
            protocol = request_parts[2] if len(request_parts) > 2 else ''
            
            # Extract status code (after closing quote of request)
            after_request = line[quote_end + 1:].strip()
            status_parts = after_request.split(' ')
            if len(status_parts) < 1:
                return None
            
            status = status_parts[0]
            
            # Extract size
            size = status_parts[1] if len(status_parts) > 1 else '-'
            
            # Extract user agent (between last pair of quotes)
            last_quote = line.rfind('"')
            if last_quote > quote_end:
                user_agent_start = line.rfind('"', 0, last_quote)
                if user_agent_start > quote_end:
                    user_agent = line[user_agent_start + 1:last_quote]
                else:
                    user_agent = ''
            else:
                user_agent = ''
            
            return {
                'ip': ip,
                'timestamp': timestamp,
                'method': method,
                'path': path,
                'protocol': protocol,
                'status': status,
                'size': size,
                'user_agent': user_agent
            }
            
        except (IndexError, ValueError):
            return None
    
    def is_brute_force_attempt(self, log_entry):
        """
        Identify brute force attempts using string operations
        Criteria: login-related path + 403 status
        """
        if not log_entry:
            return False
        
        path = log_entry.get('path', '').lower()
        status = log_entry.get('status', '')
        
        # Fast path check using set lookup
        if status != '403':
            return False
        
        # Check if path contains any login-related strings
        for login_path in self.login_paths:
            if login_path in path:
                return True
        
        return False
    
    def analyze_log_file(self, file_path, chunk_size=8192):
        """
        Analyze local log file with efficient reading
        Uses chunked reading to handle large files
        """
        print(f"Analyzing log file: {file_path}")
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
                buffer = ""
                line_count = 0
                
                while True:
                    chunk = file.read(chunk_size)
                    if not chunk:
                        # Process remaining buffer
                        if buffer:
                            self.process_log_line(buffer, line_count + 1)
                        break
                    
                    buffer += chunk
                    
                    # Process complete lines
                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        line_count += 1
                        self.process_log_line(line, line_count)
                        
                        # Progress indicator for large files
                        if line_count % 10000 == 0:
                            print(f"Processed {line_count:,} lines...")
            
            print(f"Completed processing {line_count:,} lines")
            return True
            
        except FileNotFoundError:
            print(f"Error: File {file_path} not found")
            return False
        except Exception as e:
            print(f"Error reading file: {e}")
            return False
    
    def analyze_cloudwatch_logs(self, log_group_name, region='us-east-1', hours=24):
        """Analyze logs from AWS CloudWatch"""
        if not AWS_AVAILABLE:
            print("Error: boto3 not installed. Install with: pip install boto3")
            return False
            
        try:
            client = boto3.client('logs', region_name=region)
            
            # Calculate time range
            end_time = int(datetime.now().timestamp() * 1000)
            start_time = end_time - (hours * 60 * 60 * 1000)
            
            print(f"Fetching logs from CloudWatch group: {log_group_name}")
            print(f"Time range: last {hours} hours")
            
            # Start query
            response = client.start_query(
                logGroupName=log_group_name,
                startTime=start_time,
                endTime=end_time,
                queryString='fields @timestamp, @message | sort @timestamp desc | limit 10000'
            )
            
            query_id = response['queryId']
            
            # Poll for completion
            import time
            max_wait = 300  # 5 minutes timeout
            wait_time = 0
            
            while wait_time < max_wait:
                result = client.get_query_results(queryId=query_id)
                if result['status'] == 'Complete':
                    break
                elif result['status'] == 'Failed':
                    print("CloudWatch query failed")
                    return False
                
                time.sleep(2)
                wait_time += 2
                print(f"Waiting for query completion... ({wait_time}s)")
            
            if wait_time >= max_wait:
                print("Query timeout")
                return False
            
            # Process results
            print(f"Processing {len(result['results'])} log entries...")
            for line_num, log_result in enumerate(result['results'], 1):
                message = None
                for field in log_result:
                    if field['field'] == '@message':
                        message = field['value']
                        break
                
                if message:
                    self.process_log_line(message, line_num)
            
            return True
            
        except Exception as e:
            print(f"Error accessing CloudWatch: {e}")
            return False
    
    def process_log_line(self, line, line_num=None):
        """Process a single log line efficiently"""
        log_entry = self.parse_log_line(line)
        
        if not log_entry:
            return
        
        self.total_requests += 1
        
        # Check for brute force attempts
        if self.is_brute_force_attempt(log_entry):
            self.brute_force_attempts += 1
            ip = log_entry['ip']
            self.ip_brute_force_count[ip] += 1
            
            # Store attack details (limit to prevent memory issues)
            if len(self.failed_logins_by_ip[ip]) < 100:  # Limit per IP
                self.failed_logins_by_ip[ip].append({
                    'timestamp': log_entry.get('timestamp', ''),
                    'path': log_entry.get('path', ''),
                    'status': log_entry.get('status', ''),
                    'user_agent': log_entry.get('user_agent', '')[:200]  # Limit UA length
                })
    
    def get_threat_level(self, attempt_count):
        """Classify threat level based on attempt count"""
        if attempt_count >= 100:
            return "CRITICAL"
        elif attempt_count >= 50:
            return "HIGH"
        elif attempt_count >= 10:
            return "MEDIUM"
        else:
            return "LOW"
    
    def generate_report(self):
        """Generate comprehensive analysis report"""
        print("\n" + "="*70)
        print("LOG ANALYSIS REPORT")
        print("="*70)
        
        # Summary statistics
        print(f"\n📊 SUMMARY STATISTICS")
        print("-" * 30)
        print(f"Total requests analyzed: {self.total_requests:,}")
        print(f"Brute force attempts: {self.brute_force_attempts:,}")
        print(f"Unique attacking IPs: {len(self.ip_brute_force_count):,}")
        
        if self.total_requests > 0:
            attack_percentage = (self.brute_force_attempts / self.total_requests) * 100
            print(f"Attack rate: {attack_percentage:.2f}%")
        
        # IP-based analysis
        if self.ip_brute_force_count:
            print(f"\n🚨 ATTACKING IP ADDRESSES")
            print("-" * 50)
            
            # Sort by attempt count (descending)
            sorted_attackers = sorted(
                self.ip_brute_force_count.items(),
                key=lambda x: x[1],
                reverse=True
            )
            
            print(f"{'IP Address':<18} {'Attempts':<10} {'Threat Level':<12}")
            print("-" * 50)
            
            for ip, count in sorted_attackers[:20]:  # Top 20
                threat_level = self.get_threat_level(count)
                print(f"{ip:<18} {count:<10} {threat_level:<12}")
            
            if len(sorted_attackers) > 20:
                print(f"\n... and {len(sorted_attackers) - 20} more IPs")
            
            # Detailed analysis of top threats
            critical_ips = [(ip, count) for ip, count in sorted_attackers 
                          if self.get_threat_level(count) in ['CRITICAL', 'HIGH']]
            
            if critical_ips:
                print(f"\n🔥 TOP THREATS ANALYSIS")
                print("-" * 50)
                
                for i, (ip, count) in enumerate(critical_ips[:5], 1):
                    print(f"\n{i}. IP Address: {ip}")
                    print(f"   Total attempts: {count}")
                    print(f"   Threat level: {self.get_threat_level(count)}")
                    
                    # Show recent attack patterns
                    recent_attacks = self.failed_logins_by_ip[ip][-3:]
                    if recent_attacks:
                        print("   Recent attacks:")
                        for attack in recent_attacks:
                            timestamp = attack.get('timestamp', 'Unknown')[:19]  # Truncate timestamp
                            path = attack.get('path', 'Unknown')
                            print(f"   - {timestamp} -> {path}")
        else:
            print("\n✅ No brute force attempts detected!")
        
        print("\n" + "="*70)
        
        # Security recommendations
        if self.brute_force_attempts > 0:
            print("\n🛡️  SECURITY RECOMMENDATIONS")
            print("-" * 30)
            print("1. Consider implementing rate limiting")
            print("2. Block suspicious IP addresses at firewall level")
            print("3. Enable fail2ban or similar intrusion detection")
            print("4. Implement CAPTCHA for login pages")
            print("5. Consider using Web Application Firewall (WAF)")
    
    def export_json(self, output_file):
        """Export results to JSON with memory efficiency"""
        # Create summary data
        top_attackers = sorted(
            self.ip_brute_force_count.items(),
            key=lambda x: x[1],
            reverse=True
        )[:50]  # Limit to top 50 for file size
        
        data = {
            'analysis_timestamp': datetime.now().isoformat(),
            'summary': {
                'total_requests': self.total_requests,
                'brute_force_attempts': self.brute_force_attempts,
                'unique_attacking_ips': len(self.ip_brute_force_count),
                'attack_rate_percentage': (
                    (self.brute_force_attempts / self.total_requests * 100) 
                    if self.total_requests > 0 else 0
                )
            },
            'top_attackers': [
                {
                    'ip': ip,
                    'attempts': count,
                    'threat_level': self.get_threat_level(count)
                }
                for ip, count in top_attackers
            ],
            'attack_details': {
                ip: {
                    'total_attempts': len(attempts),
                    'sample_attacks': attempts[-5:]  # Last 5 attempts
                }
                for ip, attempts in list(self.failed_logins_by_ip.items())[:20]  # Top 20 IPs
            }
        }
        
        try:
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=2, default=str)
            print(f"\n💾 Results exported to: {output_file}")
        except Exception as e:
            print(f"❌ Error exporting to JSON: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="High-performance NGINX log analyzer for brute force detection",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Analyze local log file
  python nginx_analyzer.py /var/log/nginx/access.log
  
  # Analyze CloudWatch logs
  python nginx_analyzer.py my-log-group --cloudwatch --region us-west-2
  
  # Export results to JSON
  python nginx_analyzer.py /var/log/nginx/access.log --output report.json
        """
    )
    
    parser.add_argument(
        'input',
        help="Log file path or CloudWatch log group name"
    )
    parser.add_argument(
        '--cloudwatch', '-c',
        action='store_true',
        help="Analyze CloudWatch logs instead of local file"
    )
    parser.add_argument(
        '--region', '-r',
        default='us-east-1',
        help="AWS region for CloudWatch (default: us-east-1)"
    )
    parser.add_argument(
        '--hours',
        type=int,
        default=24,
        help="Hours of logs to analyze from CloudWatch (default: 24)"
    )
    parser.add_argument(
        '--output', '-o',
        help="Export results to JSON file"
    )
    
    args = parser.parse_args()
    
    print("🔍 Starting Log Analysis...")
    print(f"Target: {'CloudWatch' if args.cloudwatch else 'Local file'}")
    
    # Initialize analyzer
    analyzer = NginxLogAnalyzer()
    
    # Record start time for performance metrics
    start_time = datetime.now()
    
    # Analyze logs
    if args.cloudwatch:
        success = analyzer.analyze_cloudwatch_logs(
            args.input, 
            region=args.region, 
            hours=args.hours
        )
    else:
        success = analyzer.analyze_log_file(args.input)
    
    if not success:
        print("❌ Analysis failed!")
        sys.exit(1)
    
    # Calculate performance metrics
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    print(f"\n⏱️  Analysis completed in {duration:.2f} seconds")
    if analyzer.total_requests > 0:
        rate = analyzer.total_requests / duration
        print(f"📈 Processing rate: {rate:,.0f} requests/second")
    
    # Generate report
    analyzer.generate_report()
    
    # Export if requested
    if args.output:
        analyzer.export_json(args.output)


if __name__ == "__main__":
    main()