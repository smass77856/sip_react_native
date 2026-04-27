# 📦 HƯỚNG DẪN BUILD ỨNG DỤNG ONECX

Tài liệu này hướng dẫn chi tiết các bước build ứng dụng OneCX cho macOS và Windows.

---

## 📋 MỤC LỤC

- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Build cho macOS](#build-cho-macos)
- [Build cho Windows](#build-cho-windows)
- [Xử lý lỗi thường gặp](#xử-lý-lỗi-thường-gặp)

---

## 🔧 YÊU CẦU HỆ THỐNG

### Chung cho cả macOS và Windows

- **Flutter SDK**: 3.7.2 trở lên
- **Dart SDK**: 3.7.2 trở lên
- **Git**: Để clone project

Kiểm tra phiên bản Flutter:
```bash
flutter --version
flutter doctor
```

### Riêng cho macOS

- **macOS**: 10.15 (Catalina) trở lên
- **Xcode**: 14.0 trở lên
- **CocoaPods**: Để quản lý dependencies iOS/macOS
  ```bash
  sudo gem install cocoapods
  ```

### Riêng cho Windows

- **Windows**: 10 trở lên (64-bit)
- **Visual Studio 2022**: Với C++ desktop development workload
- **Inno Setup 6** (tùy chọn): Để tạo file installer
  - Download tại: https://jrsoftware.org/isdl.php
  - Cài đặt vào: `C:\Program Files (x86)\Inno Setup 6`

---

## 🍎 BUILD CHO MACOS

### Bước 1: Chuẩn bị môi trường

1. **Clone project và cài đặt dependencies:**
   ```bash
   cd /path/to/project
   flutter pub get
   ```

2. **Cài đặt CocoaPods dependencies:**
   ```bash
   cd macos
   pod install
   cd ..
   ```

3. **Kiểm tra cấu hình:**
   ```bash
   flutter doctor
   ```

### Bước 2: Cấu hình Firebase (nếu cần)

1. Đảm bảo file `GoogleService-Info.plist` đã được thêm vào `macos/Runner/`
2. Kiểm tra file `lib/firebase_options.dart` đã được cấu hình đúng

### Bước 3: Cấu hình .env

1. Copy file `.env.example` thành `.env`:
   ```bash
   cp .env.example .env
   ```

2. Cập nhật các biến môi trường trong file `.env`

### Bước 4: Build ứng dụng

#### Phương án 1: Build đơn giản (chỉ tạo .app)

```bash
flutter build macos --release
```

File output: `build/macos/Build/Products/Release/siprix_voip_sdk_example.app`

#### Phương án 2: Build và tạo DMG (khuyến nghị)

**Sử dụng script đơn giản:**
```bash
chmod +x build_dmg.sh
./build_dmg.sh
```

**Hoặc sử dụng script nâng cao (với custom UI):**
```bash
chmod +x build_dmg_advanced.sh
./build_dmg_advanced.sh
```

### Bước 5: Kết quả

Sau khi build thành công:

- **File .app**: `build/macos/Build/Products/Release/OneCX.app`
- **File .dmg**: `build/OneCX-1.0.0.dmg`

File DMG có thể phân phối cho người dùng. Họ chỉ cần:
1. Mở file DMG
2. Kéo OneCX.app vào thư mục Applications
3. Chạy ứng dụng

### Chi tiết các script build

#### build_dmg.sh - Script đơn giản

Script này thực hiện:
1. Build ứng dụng với `flutter build macos --release`
2. Đổi tên app từ `siprix_voip_sdk_example.app` thành `OneCX.app`
3. Tạo thư mục tạm để chứa app
4. Tạo symlink đến thư mục Applications
5. Đóng gói thành file DMG nén (UDZO format)
6. Mở thư mục build để xem kết quả

**Ưu điểm:**
- Đơn giản, nhanh chóng
- Phù hợp cho testing và development

**Nhược điểm:**
- Giao diện DMG mặc định, không có custom

#### build_dmg_advanced.sh - Script nâng cao

Script này thực hiện thêm:
1. Tất cả các bước của script đơn giản
2. Tạo DMG tạm với format UDRW (read-write)
3. Mount DMG để chỉnh sửa
4. Sử dụng AppleScript để:
   - Đặt kích thước cửa sổ
   - Đặt kích thước icon
   - Sắp xếp vị trí icon
   - Thêm background image (nếu có)
5. Unmount và convert sang format nén UDZO

**Ưu điểm:**
- Giao diện DMG chuyên nghiệp
- Phù hợp cho production release

**Nhược điểm:**
- Phức tạp hơn
- Mất thời gian hơn

### Tùy chỉnh thông tin ứng dụng

Để thay đổi tên app, version, icon:

1. **Tên ứng dụng**: Sửa trong `macos/Runner/Configs/AppInfo.xcconfig`
   ```
   PRODUCT_NAME = OneCX
   ```

2. **Version**: Sửa trong `pubspec.yaml`
   ```yaml
   version: 1.0.0+1
   ```

3. **Icon**: Thay thế file `assets/logo.png` và chạy:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. **Bundle ID**: Sửa trong `macos/Runner.xcodeproj/project.pbxproj`
   ```
   PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.onecx
   ```

### Code signing và notarization (cho distribution)

Để phân phối ứng dụng ngoài App Store:

1. **Đăng ký Apple Developer Account** ($99/năm)

2. **Tạo certificates và provisioning profiles** trong Xcode

3. **Code sign ứng dụng:**
   ```bash
   codesign --deep --force --verify --verbose \
     --sign "Developer ID Application: Your Name (TEAM_ID)" \
     build/macos/Build/Products/Release/OneCX.app
   ```

4. **Notarize với Apple:**
   ```bash
   xcrun notarytool submit build/OneCX-1.0.0.dmg \
     --apple-id "your@email.com" \
     --team-id "TEAM_ID" \
     --password "app-specific-password" \
     --wait
   ```

5. **Staple ticket:**
   ```bash
   xcrun stapler staple build/OneCX-1.0.0.dmg
   ```

---

## 🪟 BUILD CHO WINDOWS

### Bước 1: Chuẩn bị môi trường

1. **Cài đặt Visual Studio 2022:**
   - Download từ: https://visualstudio.microsoft.com/
   - Chọn workload: "Desktop development with C++"
   - Bao gồm: MSVC, Windows SDK, CMake tools

2. **Kiểm tra Flutter:**
   ```powershell
   flutter doctor
   ```

3. **Clone project và cài đặt dependencies:**
   ```powershell
   cd C:\path\to\project
   flutter pub get
   ```

### Bước 2: Cấu hình Firebase (nếu cần)

1. Đảm bảo file `google-services.json` đã được thêm vào `android/app/`
2. Kiểm tra file `lib/firebase_options.dart` đã được cấu hình đúng

### Bước 3: Cấu hình .env

1. Copy file `.env.example` thành `.env`:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Cập nhật các biến môi trường trong file `.env`

### Bước 4: Build ứng dụng

#### Phương án 1: Build thủ công

```powershell
# Clean build cũ
flutter clean

# Get dependencies
flutter pub get

# Generate icons
flutter pub run flutter_launcher_icons

# Build release
flutter build windows --release
```

File output: `build\windows\x64\runner\Release\`

Thư mục này chứa:
- `siprix_voip_sdk_example.exe` - File thực thi chính
- Các file DLL cần thiết
- Thư mục `data` chứa assets

#### Phương án 2: Sử dụng script tự động (khuyến nghị)

```powershell
# Cho phép chạy script
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Chạy script build
.\build_release.ps1
```

### Bước 5: Kết quả

Sau khi build thành công, bạn sẽ có:

1. **Portable Version** (không cần cài đặt):
   - Thư mục: `dist\OneCX_Portable\`
   - Chứa tất cả file cần thiết
   - User chỉ cần copy và chạy `OneCX.exe`

2. **Setup Installer** (nếu có Inno Setup):
   - File: `dist\OneCX_Setup\OneCX_Setup.exe`
   - Installer tự động cài đặt vào Program Files
   - Tạo shortcut trên Desktop và Start Menu

### Chi tiết script build_release.ps1

Script này thực hiện:

1. **Clean build cũ:**
   ```powershell
   flutter clean
   ```

2. **Get dependencies:**
   ```powershell
   flutter pub get
   ```

3. **Generate icons:**
   ```powershell
   flutter pub run flutter_launcher_icons
   ```

4. **Build release:**
   ```powershell
   flutter build windows --release
   ```

5. **Tạo Portable version:**
   - Tạo thư mục `dist\OneCX_Portable`
   - Copy tất cả file từ `build\windows\x64\runner\Release\`

6. **Tạo Inno Setup script:**
   - Tạo file `setup_script.iss`
   - Cấu hình app name, version, install path
   - Định nghĩa files cần đóng gói
   - Tạo shortcuts

7. **Compile installer:**
   - Tìm Inno Setup compiler tại `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`
   - Compile script thành file `.exe`
   - Output: `dist\OneCX_Setup\OneCX_Setup.exe`

### Tùy chỉnh thông tin ứng dụng

1. **Tên ứng dụng**: Sửa trong `windows/runner/Runner.rc`
   ```c
   VALUE "ProductName", "OneCX"
   VALUE "FileDescription", "OneCX VoIP Application"
   ```

2. **Version**: Sửa trong `pubspec.yaml`
   ```yaml
   version: 1.0.0+1
   ```

3. **Icon**: Thay thế file `assets/logo.png` và chạy:
   ```powershell
   flutter pub run flutter_launcher_icons
   ```

4. **Company name**: Sửa trong `windows/runner/Runner.rc`
   ```c
   VALUE "CompanyName", "Your Company Name"
   ```

### Cài đặt Inno Setup (tùy chọn)

Nếu bạn muốn tạo installer:

1. **Download Inno Setup 6:**
   - Truy cập: https://jrsoftware.org/isdl.php
   - Download phiên bản mới nhất

2. **Cài đặt:**
   - Chạy file installer
   - Cài đặt vào đường dẫn mặc định: `C:\Program Files (x86)\Inno Setup 6`

3. **Kiểm tra:**
   ```powershell
   Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
   ```

### Tùy chỉnh Inno Setup script

File `setup_script.iss` được tạo tự động, nhưng bạn có thể chỉnh sửa:

```ini
[Setup]
AppName=OneCX
AppVersion=1.0.0
AppPublisher=Your Company Name
AppPublisherURL=https://yourwebsite.com
DefaultDirName={autopf}\OneCX
DefaultGroupName=OneCX
OutputDir=.
OutputBaseFilename=OneCX_Setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=..\OneCX_Portable\data\flutter_assets\assets\logo.ico
UninstallDisplayIcon={app}\OneCX.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "vietnamese"; MessagesFile: "compiler:Languages\Vietnamese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "Create a &Quick Launch icon"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\OneCX_Portable\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\OneCX"; Filename: "{app}\OneCX.exe"
Name: "{group}\Uninstall OneCX"; Filename: "{uninstallexe}"
Name: "{autodesktop}\OneCX"; Filename: "{app}\OneCX.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\OneCX"; Filename: "{app}\OneCX.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\OneCX.exe"; Description: "{cm:LaunchProgram,OneCX}"; Flags: nowait postinstall skipifsilent
```

### Code signing cho Windows (tùy chọn)

Để ký số ứng dụng:

1. **Mua certificate** từ CA (Comodo, DigiCert, etc.)

2. **Import certificate** vào Windows Certificate Store

3. **Sign file .exe:**
   ```powershell
   & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
     /n "Your Company Name" `
     /t http://timestamp.digicert.com `
     /fd SHA256 `
     /v `
     dist\OneCX_Portable\OneCX.exe
   ```

4. **Sign installer:**
   ```powershell
   & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
     /n "Your Company Name" `
     /t http://timestamp.digicert.com `
     /fd SHA256 `
     /v `
     dist\OneCX_Setup\OneCX_Setup.exe
   ```

---

## ⚠️ XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi chung

#### 1. "Flutter SDK not found"
```bash
# Kiểm tra PATH
echo $PATH  # macOS/Linux
echo $env:PATH  # Windows

# Thêm Flutter vào PATH
export PATH="$PATH:/path/to/flutter/bin"  # macOS/Linux
$env:PATH += ";C:\path\to\flutter\bin"  # Windows
```

#### 2. "Pub get failed"
```bash
# Xóa cache và thử lại
flutter clean
rm -rf pubspec.lock  # macOS/Linux
Remove-Item pubspec.lock  # Windows
flutter pub get
```

#### 3. "License key error"
- Kiểm tra file `lib/main.dart`
- Đảm bảo `iniData.license` được set đúng
- Liên hệ Siprix để lấy license key hợp lệ

### Lỗi macOS

#### 1. "CocoaPods not installed"
```bash
sudo gem install cocoapods
pod setup
```

#### 2. "Xcode build failed"
```bash
# Mở Xcode và accept license
sudo xcodebuild -license accept

# Clean build
cd macos
pod deintegrate
pod install
cd ..
flutter clean
flutter build macos
```

#### 3. "Code signing error"
- Mở `macos/Runner.xcworkspace` trong Xcode
- Chọn Runner target
- Signing & Capabilities tab
- Chọn team và certificate phù hợp

#### 4. "DMG creation failed"
```bash
# Kiểm tra quyền
chmod +x build_dmg.sh

# Chạy với sudo nếu cần
sudo ./build_dmg.sh
```

### Lỗi Windows

#### 1. "Visual Studio not found"
- Cài đặt Visual Studio 2022
- Đảm bảo đã cài "Desktop development with C++"
- Chạy lại `flutter doctor`

#### 2. "CMake error"
```powershell
# Cài đặt CMake qua Visual Studio Installer
# Hoặc download từ: https://cmake.org/download/
```

#### 3. "Execution policy error"
```powershell
# Cho phép chạy script
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Hoặc
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 4. "Inno Setup not found"
- Cài đặt Inno Setup 6 từ: https://jrsoftware.org/isdl.php
- Đảm bảo cài vào đường dẫn mặc định
- Hoặc sửa đường dẫn trong `build_release.ps1`:
  ```powershell
  $IsccPath = "C:\Your\Custom\Path\ISCC.exe"
  ```

#### 5. "DLL missing error"
- Đảm bảo copy toàn bộ thư mục `build\windows\x64\runner\Release\`
- Không chỉ copy file `.exe`
- Cần có tất cả file `.dll` và thư mục `data`

---

## 📊 CHECKLIST TRƯỚC KHI RELEASE

### Chung

- [ ] Cập nhật version trong `pubspec.yaml`
- [ ] Cập nhật CHANGELOG.md
- [ ] Test ứng dụng trên môi trường production
- [ ] Kiểm tra tất cả tính năng hoạt động
- [ ] Kiểm tra Firebase configuration
- [ ] Kiểm tra .env file
- [ ] Kiểm tra license key

### macOS

- [ ] Test trên nhiều phiên bản macOS (10.15+)
- [ ] Kiểm tra permissions (microphone, camera, notifications)
- [ ] Test CallKit integration
- [ ] Test PushKit notifications
- [ ] Code sign và notarize (nếu phân phối)
- [ ] Test DMG installation
- [ ] Kiểm tra app icon và metadata

### Windows

- [ ] Test trên Windows 10 và 11
- [ ] Kiểm tra permissions
- [ ] Test FCM notifications
- [ ] Test portable version
- [ ] Test installer
- [ ] Code sign (nếu có certificate)
- [ ] Kiểm tra app icon và metadata
- [ ] Test uninstaller

---

## 🚀 PHÂN PHỐI

### macOS

**Phương án 1: Direct Download**
- Upload file DMG lên website/server
- User download và cài đặt

**Phương án 2: Mac App Store**
- Cần Apple Developer Account ($99/năm)
- Submit qua App Store Connect
- Tuân thủ App Store Review Guidelines

### Windows

**Phương án 1: Direct Download**
- Upload file installer hoặc portable lên website/server
- User download và cài đặt

**Phương án 2: Microsoft Store**
- Cần Microsoft Developer Account ($19 one-time)
- Submit qua Partner Center
- Tuân thủ Microsoft Store Policies

**Phương án 3: Package Managers**
- Chocolatey: https://chocolatey.org/
- Winget: https://github.com/microsoft/winget-pkgs

---

## 📞 HỖ TRỢ

Nếu gặp vấn đề:

1. Kiểm tra phần [Xử lý lỗi thường gặp](#xử-lý-lỗi-thường-gặp)
2. Chạy `flutter doctor -v` để kiểm tra môi trường
3. Xem logs chi tiết khi build
4. Tham khảo tài liệu Flutter: https://docs.flutter.dev/
5. Tham khảo tài liệu Siprix: https://docs.siprix-voip.com/

---

## 📝 GHI CHÚ

- Build time trung bình: 5-10 phút (tùy máy)
- Kích thước ứng dụng:
  - macOS: ~50-80 MB (DMG)
  - Windows: ~30-50 MB (Portable), ~40-60 MB (Installer)
- Khuyến nghị test trên nhiều thiết bị trước khi release
- Nên có CI/CD pipeline để tự động hóa build process

---

**Cập nhật lần cuối:** December 2024
**Version:** 1.0.0
