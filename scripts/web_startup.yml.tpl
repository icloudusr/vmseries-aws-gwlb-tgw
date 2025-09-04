#cloud-config

# =============================================================================
# MODERNIZED WEB STARTUP SCRIPT FOR UBUNTU 22.04 LTS
# VM-Series GWLB Demo Environment
# =============================================================================

# Update system and install packages
package_update: true
package_upgrade: true

packages:
  - apache2
  - php
  - libapache2-mod-php
  - curl
  - wget
  - net-tools
  - htop

# Write custom index.php with enhanced information
write_files:
  - content: |
      <?php
      $instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
      $instance_type = file_get_contents('http://169.254.169.254/latest/meta-data/instance-type');
      $local_ipv4 = file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4');
      $public_ipv4 = @file_get_contents('http://169.254.169.254/latest/meta-data/public-ipv4');
      $availability_zone = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');
      $region = substr($availability_zone, 0, -1);
      
      echo "<html><head><title>VM-Series GWLB Demo - Spoke VM</title>";
      echo "<style>body{font-family:Arial,sans-serif;margin:40px;background:#f5f5f5;}";
      echo ".container{background:white;padding:30px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1);}";
      echo ".header{background:#0066cc;color:white;padding:20px;margin:-30px -30px 20px -30px;border-radius:8px 8px 0 0;}";
      echo ".info{margin:10px 0;padding:10px;background:#f8f9fa;border-left:4px solid #0066cc;}";
      echo ".success{color:#28a745;font-weight:bold;}";
      echo "table{width:100%;border-collapse:collapse;margin-top:20px;}";
      echo "th,td{border:1px solid #ddd;padding:12px;text-align:left;}";
      echo "th{background-color:#0066cc;color:white;}</style></head><body>";
      
      echo "<div class='container'>";
      echo "<div class='header'><h1>🔥 VM-Series GWLB Demo</h1>";
      echo "<p>Traffic successfully inspected by Palo Alto Networks VM-Series Firewall!</p></div>";
      
      echo "<div class='info'><h2>✅ Connection Status</h2>";
      echo "<p class='success'>✓ Traffic is being routed through Gateway Load Balancer</p>";
      echo "<p class='success'>✓ VM-Series firewall inspection is active</p>";
      echo "<p class='success'>✓ Web server is running on Ubuntu 22.04 LTS</p></div>";
      
      echo "<h2>🖥️ Instance Information</h2>";
      echo "<table><tr><th>Property</th><th>Value</th></tr>";
      echo "<tr><td>Instance ID</td><td>$instance_id</td></tr>";
      echo "<tr><td>Instance Type</td><td>$instance_type</td></tr>";
      echo "<tr><td>Private IP</td><td>$local_ipv4</td></tr>";
      echo "<tr><td>Public IP</td><td>" . ($public_ipv4 ?: 'Not assigned') . "</td></tr>";
      echo "<tr><td>Availability Zone</td><td>$availability_zone</td></tr>";
      echo "<tr><td>Region</td><td>$region</td></tr>";
      echo "<tr><td>Server Time</td><td>" . date('Y-m-d H:i:s T') . "</td></tr></table>";
      
      echo "<h2>🌐 HTTP Request Headers</h2>";
      echo "<table><tr><th>Header</th><th>Value</th></tr>";
      foreach ($_SERVER as $key => $value) {
          if (strpos($key, 'HTTP_') === 0) {
              $header = str_replace('HTTP_', '', $key);
              $header = str_replace('_', '-', $header);
              $header = ucwords(strtolower($header), '-');
              echo "<tr><td>$header</td><td>$value</td></tr>";
          }
      }
      echo "</table>";
      
      echo "<h2>📡 Network Information</h2>";
      echo "<table><tr><th>Property</th><th>Value</th></tr>";
      echo "<tr><td>Remote IP</td><td>{$_SERVER['REMOTE_ADDR']}</td></tr>";
      echo "<tr><td>Server Software</td><td>{$_SERVER['SERVER_SOFTWARE']}</td></tr>";
      echo "<tr><td>Request Method</td><td>{$_SERVER['REQUEST_METHOD']}</td></tr>";
      echo "<tr><td>Request URI</td><td>{$_SERVER['REQUEST_URI']}</td></tr>";
      echo "<tr><td>Query String</td><td>" . ($_SERVER['QUERY_STRING'] ?: 'None') . "</td></tr></table>";
      
      echo "<div style='margin-top:30px;padding:15px;background:#e8f5e8;border-radius:5px;'>";
      echo "<h3>🎯 Demo Instructions</h3>";
      echo "<ul><li>This traffic is being inspected by VM-Series firewalls</li>";
      echo "<li>Check the firewall logs to see this connection</li>";
      echo "<li>Try accessing from different sources to test security policies</li>";
      echo "<li>Use the SSH jump host (spk2) to test east-west traffic</li></ul></div>";
      
      echo "<div style='margin-top:20px;text-align:center;color:#666;'>";
      echo "<p>Powered by Palo Alto Networks VM-Series | Ubuntu 22.04 LTS | AWS Gateway Load Balancer</p></div>";
      echo "</div></body></html>";
      ?>
    path: /var/www/html/index.php
    owner: www-data:www-data
    permissions: '0644'

# Configure Apache
runcmd:
  - echo "Starting VM-Series GWLB Demo web server setup..."
  
  # Wait for system to fully initialize
  - sleep 30
  
  # Remove default Apache index.html
  - rm -f /var/www/html/index.html
  
  # Enable PHP module
  - a2enmod php*
  
  # Configure Apache for better security
  - sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
  - sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf
  - a2enconf security
  
  # Set proper permissions
  - chown -R www-data:www-data /var/www/html
  - chmod -R 755 /var/www/html
  
  # Restart and enable Apache
  - systemctl restart apache2
  - systemctl enable apache2
  
  # Configure firewall to allow HTTP traffic
  - ufw allow 'Apache'
  - ufw --force enable
  
  # Create startup script completion marker
  - echo "VM-Series GWLB Demo web server setup completed at $(date)" >> /var/log/web-startup.log
  - echo "Instance IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)" >> /var/log/web-startup.log
  
  # Set hostname based on instance metadata
  - hostnamectl set-hostname "gwlb-demo-$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

# Final system configuration
power_state:
  delay: 0
  mode: reboot
  message: "Rebooting to complete VM-Series GWLB demo setup"
  timeout: 30
  condition: false  # Set to true if you want automatic reboot

# =============================================================================
# LOG LOCATIONS:
# - Setup log: /var/log/web-startup.log
# - Apache logs: /var/log/apache2/
# - Cloud-init logs: /var/log/cloud-init.log
# =============================================================================