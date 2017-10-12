# SimpleInstaller

SimpleInstaller is an application designed to be run from a NetInstall environment created with AutoNBI. 


# Create nbi

make nbi URL="http://munki.example.com/install/config.plist"

# config.plist

```xml

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>workflows</key>
  <array>
    <dict>
      <key>name</key>
      <string>Install macOS</string>
      <key>description</key>
      <string>Installs OS X on the target volume.</string>
      <key>components</key>
      <array>
        <dict>
            <key>type</key>
            <string>eraseDisk</string>
            <key>name</key>
            <string>Macintosh HD</string>
            <key>format</key>
            <string>APFS</string>
        </dict>
        <dict>
          <key>type</key>
          <string>installer</string>
          <key>url</key>
          <string>http://172.16.39.1:8080/pkgs/OS/Apple/HighSierra/Install macOS High Sierra Beta-10.13.dmg</string>
        </dict>
      </array>
    </dict>
  </array>
</dict>
</plist>

```
