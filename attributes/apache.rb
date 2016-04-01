default.apache.mod_ssl.cipher_suite = "ALL:+ECDH:+EDH:+RSA:!ADH:!EXP:!SSLv2:!SSLv3:!PSK:!SRP:!MEDIUM:!LOW:!RC4:!3DES"
default.apache.traceenable = 'Off'
default.apache.timeout = 600
default.apache.mpm = "event" if platform_family?("rhel") && node.platform_version.to_i == 7
