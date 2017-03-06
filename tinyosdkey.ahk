; tinyosdkey
;
; Display the status of key input and mouse button on the screen.
;
; use AutoHotKey v1.1.24.05
; License : CC0 / Public Domain
 
#SingleInstance, Force
#InstallMouseHook
#InstallKeybdHook
CoordMode, Mouse, Screen

appliname=tinyosdkey
appliver=1.0.2
wtitle=%appliname% %appliver%
inifn=%A_ScriptDir%\%appliname%.ini

Gosub InitTrayMenu
Gosub ReadIniFile

; mouse button list
btnlist := Object("LButton", "IconLMB"
                , "MButton", "IconMMB"
                , "RButton", "IconRMB")

; modifier key list
modlist := Object("Ctrl", "Ctrl", "Shift", "Shift", "Alt", "Alt"
                , "LWin", "Win", "RWin", "Win")

; parse key list
keylist := Object()
nowstate := Object()
oldstate := Object()
Loop, Parse, keystr, %A_space%
{
  k=%A_LoopField%
  v=%k%
  If k=_
    k=vkE2sc073
  If k=`;
    k=vkBBsc027
  If k=`:
    k=vkBAsc028
  If k=`,
    k=vkBCsc033
  If (k=LWin || k=RWin)
    v=Win
  
  keylist.Insert(k, v)
  nowstate.Insert(k, 0)
  oldstate.Insert(k, 0)
}

; set context menu
Menu, ctmenu, Add, %wtitle%, Settings
Menu, ctmenu, Add,
Menu, ctmenu, Add, Settings, Settings
Menu, ctmenu, Add, Exit, EXIT

; GUI settings

Gui, +Owner +AlwaysOnTop -Resize -SysMenu -MinimizeBox -MaximizeBox -Disabled -Caption -Border -ToolWindow
; Gui, +Owner +AlwaysOnTop +Resize

Gui, Margin, 8, 8
Gui, Color, %bgcol%

cdir=%A_ScriptDir%\%imgdir%
opt=X0 Y0 AltSubmit BackgroundTrans
Gui, Add, Picture, %opt% vIconBas, %cdir%\mouseicon_000.png
Gui, Add, Picture, %opt% vIconLMB, %cdir%\mouseicon_001.png
Gui, Add, Picture, %opt% vIconMMB, %cdir%\mouseicon_002.png
Gui, Add, Picture, %opt% vIconRMB, %cdir%\mouseicon_003.png

Gui, Font, C%fgcol% S%fontsize% W%fontweight% Q2, %fontname%
s=Ctrl + Shift + Alt + Win + NumpadClear
Gui, Add, Text, x+4 yp+4 Vkeytext, %s%

fsz := fontsize / 2
Gui, Font, C%fgcol% S%fsz% W%fontweight% Q2, %fontname%
Gui, Add, Text, xp+0 y+4 Vkeytext1, %s%
Gui, Add, Text, xp+0 y+2 Vkeytext2, %s%
Gui, Add, Text, xp+0 y+2 Vkeytext3, %s%
Gui, Add, Text, xp+0 y+2 Vkeytext4, %s%
Gui, Show, X%posx% Y%posy% NoActivate, %wtitle%

GuiControl, , keytext, ( Ctrl+Alt+Q : Exit )
GuiControl, , keytext1,
GuiControl, , keytext2,
GuiControl, , keytext3,
GuiControl, , keytext4,
GuiControl, Hide, IconLMB
GuiControl, Hide, IconMMB
GuiControl, Hide, IconRMB

WinSet, Transparent, %transparentv%, %wtitle%

cwheeldown = 0
cwheelup = 0
check_cwheeldown = 0
check_cwheelup = 0

mods=
oldmods=
keys=
oldkeys=
nowkeys=
nowkeys_cnt=0

modshold=0
btnshold=0
keyshold=0

keyshistory := Object()
keyshiscnt=5
Loop, %keyshiscnt%
{
  keyshistory.Insert(A_Index, "")
}

Loop, 
{
  For k, v in keylist
  {
    n := nowstate[k]
    oldstate[k] := n
    nowstate[k] := 0
    If k=WheelDown
    {
      If cwheeldown<>%check_cwheeldown%
      {
        check_cwheeldown := cwheeldown
        nowstate[k] := 1
      }
    }
    Else If k=WheelUp
    {
      If cwheelup<>%check_cwheelup%
      {
        check_cwheelup := cwheelup
        nowstate[k] := 1
      }
    }
    Else
      nowstate[k] := GetKeyState(k)
  }
  
  oldmods=%mods%
  oldkeys=%keys%
  mods=
  keys=
  req=0
  
  ; modifier key check
  cnt=0
  For k, v in modlist
  {
    If nowstate[k]=1
    {
      mods := mods . v . " + "
      cnt+=1
      If oldstate[k]=0
        req=1
    }
    Else
      If oldstate[k]=1
        req=1
  }
  modshold=%cnt%
  mods := Trim(mods, " ")
  keys := mods

  ; mouse button check
  cnt=0
  For k, v in btnlist
  {
    If nowstate[k]=1
      cnt+=1
    
    If (nowstate[k] + oldstate[k])=1
      If nowstate[k]=1
      {
        ; pushed button
        GuiControl, Show, %v%
      }
      Else
      {
        ; released button
        GuiControl, Hide, %v%
      }
  }
  btnshold=%cnt%
  
  ; normal key check
  pushkeyfg=0
  cnt=0
  For k, v in keylist
  {
    If modlist.HasKey(k)
      Continue
    
    If nowstate[k]=1
      cnt+=1
    
    If (nowstate[k] + oldstate[k])=1
      If nowstate[k]=1
      {
        ; pushed key
        keys=%keys% %v%
        req=1
        pushkeyfg+=1
      }
  }
  keyshold=%cnt%
  keys := Trim(keys, " ")
  
  if pushkeyfg<>0
    Gosub, PushKeysHistory

  If keys<>%oldkeys%
    If req<>0
    {
      GuiControl, , keytext, %keys%
      Loop, % (keyshiscnt - 1)
      {
        s := keyshistory[A_Index]
        GuiControl, , keytext%A_Index%, %s%
      }
      SetTimer, StatusOff, %dispofftime%
    }
  
  Gosub DragWindow
  
  Sleep, 16
}

EXIT:
GuiClose:
  ExitApp

PushKeysHistory:
  If nowkeys<>%keys%
  {
    Loop, % (keyshiscnt - 1)
    {
      i := (keyshiscnt - A_Index)
      keyshistory[(i+1)] := keyshistory[i]
    }
    keyshistory[1] := keys
    nowkeys_cnt := 1
  }
  Else
  {
    nowkeys_cnt += 1
    keyshistory[1] := nowkeys . " x " . nowkeys_cnt
  }
  nowkeys := keys
  Return
  
StatusOff:
  If (btnshold=0 && modshold=0)
  {
    ; clear display text
    GuiControl, , keytext,
    SetTimer, StatusOff, Off
  }
  Return

DragWindow:
  If GetKeyState("LButton")=0
    Return
    
  MouseGetPos, mx, my, myId
  WinGetTitle, stitle, ahk_id %myId%
  If stitle<>%wtitle%
    Return
    
  WinGetPos, sx, sy, , , ahk_id %myId%
  ax := mx - sx
  ay := my - sy
  Loop,
  {
    MouseGetPos, mx, my
    sx := mx - ax
    sy := my - ay
    WinMove, ahk_id %myId%, , %sx%, %sy%      
    If GetKeyState("LButton")=0
      Break
    Sleep, -1
  }
  Return

ReadIniFile:
  IfNotExist, %inifn%
    Gosub InitDefaultIni
  
  IniRead, dispofftime, %inifn%, Settings, dispofftime
  IniRead, transparentv, %inifn%, Settings, transparentv
  IniRead, posx, %inifn%, Settings, posx
  IniRead, posy, %inifn%, Settings, posy
  IniRead, bgcol, %inifn%, Settings, bgcol
  IniRead, fgcol, %inifn%, Settings, fgcol
  IniRead, fontname, %inifn%, Settings, fontname
  IniRead, fontweight, %inifn%, Settings, fontweight
  IniRead, fontsize, %inifn%, Settings, fontsize
  IniRead, imgdir, %inifn%, Settings, imgdir
  IniRead, keystr, %inifn%, Settings, keys
  Return

InitDefaultIni:
  inis=;%appliname%.ini`n
  inis=%inis%`n
  inis=%inis%[Settings]`n
  inis=%inis%dispofftime=1000`n
  inis=%inis%`n
  inis=%inis%; 0 is transparent. 255 is opaque`n
  inis=%inis%transparentv=200`n
  inis=%inis%`n
  inis=%inis%posx=64`n
  inis=%inis%posy=96`n
  inis=%inis%bgcol=336699`n
  inis=%inis%fgcol=FFFFFF`n
  inis=%inis%fontsize=22`n
  inis=%inis%fontweight=700`n
  inis=%inis%;fontweight=400`n
  inis=%inis%fontname=Arial`n
  inis=%inis%;fontname=Courier New`n
  inis=%inis%;fontname=Impact`n
  inis=%inis%imgdir=img`n

  ks=Tab BS Space Esc
  ks=%ks% Up Down Left Right Ins Del Home End PgUp PgDn Enter
  ks=%ks% Ctrl Shift Alt LWin RWin
  ks=%ks% LButton MButton RButton
  ks=%ks% WheelDown WheelUp

  ks=%ks% 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  ks=%ks% _ - ^ \ @ [ ] . / \
  ks=%ks% `: `, `;

  ks=%ks% F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12
  ks=%ks% F13 F14 F15 F16 F17 F18 F19 F20 F21 F22 F23 F24

  ks=%ks% Numpad0 Numpad1 Numpad2 Numpad3 Numpad4
  ks=%ks% Numpad5 Numpad6 Numpad7 Numpad8 Numpad9
  ks=%ks% NumpadDot NumpadAdd NumpadSub NumpadMult NumpadDiv

  ; ks=%ks% NumpadEnter
  ; ks=%ks% NumpadHome NumpadEnd NumpadPgUp NumpadPgDn NumpadClear
  ; ks=%ks% NumpadUp NumpadDown NumpadLeft NumpadRight NumpadIns NumpadDel

  inis=%inis%`nkeys=%ks%
  inis=%inis%`n

  ; write .ini file
  FileAppend, %inis%, %inifn%
  Return
    
Settings:
  Gosub, ReadIniFile
  Run, %inifn%
  Return
  
InitTrayMenu:
  Menu, Tray, Standard
  Menu, Tray, MainWindow
  Menu, Tray, Add,
  Menu, Tray, Add, %wtitle%, Settings
  Menu, Tray, Add,
  Menu, Tray, Add, Settings, Settings
  ; Menu, Tray, Add, &About, Settings
  Menu, Tray, Add, Exit, EXIT
  Menu, Tray, Tip, %wtitle%
  Return

GuiContextMenu:
  Menu, ctmenu, Show, %A_GuiX%, %A_GuiY%
  Return
  
~*WheelDown::
  cwheeldown += 1
  return
  
~*WheelUp::
  cwheelup += 1
  return

~^!Q Up::
  ; Ctrl+Alt+Q ... Exit
  Goto, EXIT
