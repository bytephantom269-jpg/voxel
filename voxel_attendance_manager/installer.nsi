; Voxel Attendance Manager Windows Installer
!include "MUI2.nsh"
!include "x64.nsh"

; Define constants
!define APP_NAME "Voxel Attendance Manager"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "Voxel"
!define APP_EXE "voxel_attendance_manager.exe"
!define INSTALL_DIR "$PROGRAMFILES\Voxel\AttendanceManager"

; Set compression
SetCompressor /SOLID lzma

; General settings
Name "${APP_NAME} ${APP_VERSION}"
OutFile "voxel_attendance_manager_installer.exe"
InstallDir "${INSTALL_DIR}"
ShowInstDetails show
ShowUnInstDetails show

; MUI Settings
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

; Installer sections
Section "Install"
  SetOutPath "$INSTDIR"
  
  ; Copy main executable
  File "build\windows\x64\runner\Release\${APP_EXE}"
  
  ; Copy all DLL files
  File "build\windows\x64\runner\Release\*.dll"
  
  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  
  ; Create desktop shortcut (optional)
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  
  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Write registry keys for Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME} ${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
SectionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove executable and DLLs
  Delete "$INSTDIR\${APP_EXE}"
  Delete "$INSTDIR\*.dll"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk"
  RMDir "$SMPROGRAMS\${APP_NAME}"
  Delete "$DESKTOP\${APP_NAME}.lnk"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
  
  ; Remove uninstaller and directory
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  RMDir "$PROGRAMFILES\Voxel"
SectionEnd
