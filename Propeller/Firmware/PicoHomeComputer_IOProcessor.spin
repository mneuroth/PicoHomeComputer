{{
┌───────────────────────────────────────┐
│ PicoHomeComputer IOProcessor firmware │
│ Author: Michael Neuroth               │                     
│ Copyright (c) 2020 Michael Neuroth.   │                     
│ See end of file for terms of use.     │                      
└───────────────────────────────────────┘

 This is the firmware to run the PicoHomeComputer IOProcessor.
 The IOProcesser handles the following tasks:

   * Keyboard Input --> RS232 Commands to PIC32
       Example: @K:a                         ' key press of character
       Example: @K:#154                      ' key press of special key like F1
   * Mouse Input    --> RS232 Commands to PIC32
       Example: @M:MM=176,216                ' mouse move to position x,y
       Example: @M:LP=176,216                ' left mouse button pressed at x,y
   
   * RS232 Commands from PIC32 --> Sound Output
       Example: #S:L=440                     ' frequency
       Example: #S:R=440,200                 ' frequency,time_in_ms
       Example: #S:NO                        ' switch off sound
       Return:  #OK
       Return:  #ERROR: invalid command: ...
   * RS232 Commands from PIC32 --> VGA Output
       Example: #V:00,12,text output         ' write text to position x,y
       Example: #V:C=255,128,64              ' set text colour to r,g,b value
       Example: #V:S=U                       ' scroll screen up, down, left right
       Example: #V:CLR                       ' clear screen
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  VGACOLS = vga#cols
  VGAROWS = vga#rows
  
CON
  _keyboardLocks = 2

  _keyboardTypematicDelay = 0 ' 2
  _keyboardTypematicRate = 0 ' 3

  _mouseSampleRate = 0 '3
  _mouseScaling = 1

  ' pin numbers
  _vga_base = 16        'VGA - VSync 
  _keyboardClock = 25
  _keyboardData = 24
  _mouseClock = 27
  _mouseData = 26
  _soundOutputA = 4
  _soundOutputB = 5
  _Led1 = 1
  _Led2 = 2

  _STRBUF_SIZE = 64
  _TEXTBUF_SIZE = 101
  _FREQUENCYBUF_SIZE = 6
  _POSBUF_SIZE = 3

  _modus_terminal = 0                ' graphical terminal mode with mouse, key, vga and sound messages                                     
  _modus_shell = 1                   ' simple shell modus, just forward key events to RS232 interface
  _modus_solo = 2                    ' solo modus, run the io processor in standalone modus

VAR
  long scrn[VGACOLS*VGAROWS/4]     'screen buffer - could be bytes, but longs allow more efficient scrolling
  word colors[VGAROWS]             'row colors
  long sync                        'sync long - written to -1 by VGA driver after each screen refresh
  byte cx0,cy0,cm0,cx1,cy1,cm1     'cursor control bytes  
  long blinkStack[100]
  long keyboardStack[100]
  long mouseStack[100]
  long commandsStack[100]
  byte semIDrs232
  byte semIDscreen
  byte strKeyboardBuffer[2]
  byte strTempKeyboardCommandBuffer[VGACOLS+1+2]
  byte strKeyboardCommandBuffer[VGACOLS+1]
  byte iKeyboardCommandBufferPos
  byte strLastKeyboardCommand[VGACOLS+1]
  byte iStartCursorPosForKeyboardCmd
  byte strTemp[VGACOLS+1]
  byte strTempInfos[16]
  byte strBuffer[_STRBUF_SIZE]      'String Buffer
  byte strText[_TEXTBUF_SIZE]
  byte strFrequencyBuffer[_FREQUENCYBUF_SIZE]
  byte strXPosBuffer[_POSBUF_SIZE]
  byte strYPosBuffer[_POSBUF_SIZE]
  byte xPos
  byte yPos
  word sndFrequency
  byte sndChannelNo
  byte modus                    ' 0 == direct io processor modus, 1 == shell / forward mode --> forward keyboard to rs232
  long receivedCharCount

OBJ
  pst   :       "Parallax Serial Terminal"
  'pst   :       "FullDuplexSerial_rr004"
  'pst   :       "pcFullDuplexSerial4FC"  '1 COG for 4 serial ports
  hid   :       "PS2_HIDEngine.spin"
  snd   :       "Synth.spin"                         
  str   :       "ASCII0_STREngine.spin"
  vga   :       "VGA_HiRes_Text"

PUB Main  | id, msg

  receivedCharCount := 0

  modus := _modus_shell              ' start with direct RS232 modus

  clearKeyboardCommandBuffer
  clearLastKeyboardCommand

  dira[_Led1] := 1
  dira[_Led2] := 1

  'pst.Start(115_200)                 'Set Parallax Serial Terminal to 115200 baud                        ' cognew+1
  'pst.Start(57_600)                 'Set Parallax Serial Terminal to 115200 baud                        ' cognew+1
  'pst.Start(38_400)                 'Set Parallax Serial Terminal to 115200 baud                        ' cognew+1
  pst.Start(19_200)                 'Set Parallax Serial Terminal to 115200 baud                        ' cognew+1

  'pst.Start(31, 30, 0, 115_200)
  'pst.Init
  'pst.AddPort(0,31,30,pst#PINNOTUSED,pst#PINNOTUSED,pst#DEFAULTTHRESHOLD, pst#NOMODE, pst#BAUD115200)
  'pst.Start

  ' text cursor
  cx0 := 0
  cy0 := 1
  updateCursorModus(modus)
    
  ' mouse cursor  
  cx1 := VGACOLS / 2
  cy1 := VGAROWS / 2
  cm1 := %011
  
  vga.start(_vga_base,@scrn,@colors,@cx0,@sync) 'start VGA HI RES TEXT driver                            ' cognew+2

  hid.HIDEngineStart(_keyboardClock, _keyboardData, _mouseClock, _mouseData, _keyboardLocks, VGACOLS-1, VGAROWS-1)     ' cognew+1
  hid.keyboardConfiguration(_keyboardTypematicDelay, _keyboardTypematicRate)
  hid.mouseConfiguration(_mouseSampleRate, _mouseScaling)

  if ((semIDrs232 := locknew) == -1)
    pst.Str(String("ERROR: no lock available for RS232 communication"))
  if ((semIDscreen := locknew) == -1)
    pst.Str(String("ERROR: no lock available for SCREEN"))
  
  'pst.Str(String("INIT IO_Processor..."))

  ClearScreen( %%330, %%003 )

  WriteLine(String("Welcome to the PicoHomeComputer !"))
  ' for tests:
  'SetLineColor(20,%%300, %%003)   
  'PrintStr(20, 45, String("center"), 1)  
  'PrintStr(49, 95, String("done."), 0)
  msg := String("Current modus: ")
  cy0 := 2
  WriteLine(String("Enter #HELP for available commands"))
  cy0 := 4
  Write(msg)
  WriteLine(getModus(modus))

  ' update cursor
  cy0 := 6

  
  'id := cognew(blinkLedsFunction, @blinkStack)
  'pst.Dec(id)
  'pst.Str(String(" "))
  id := cognew(processCommands, @commandsStack)
  'pst.Dec(id)
  'pst.Str(String(" "))
  id := cognew(processKeyboard, @keyboardStack)
  'pst.Dec(id)
  'pst.Str(String(" "))
  id := cognew(processMouse, @mouseStack)
  'pst.Dec(id)
  'pst.Str(String(" "))

'  repeat
'    snd.Synth("A", _soundOutputA, 400)
'    snd.Synth("B", _soundOutputB, 0)
'    waitcnt(clkfreq/4 + cnt) 
'    snd.Synth("A", _soundOutputA, 0)
'    snd.Synth("B", _soundOutputB, 1400)
'    waitcnt(clkfreq/4 + cnt) 

  dira[_Led1] := 1    
  repeat
    outa[_Led1] := 1
    waitcnt(clkfreq/4 + cnt)
    outa[_Led1] := 0
    waitcnt(clkfreq/4 + cnt)
    
PUB ClearScreen( ForeClr, BackClr ) | wdClr
' This clears the whole screen and sets all rows to the given colours
' ForeClr and BackClr are best represented as quaternary numbers (base 4)
' - these are represented as %%RGB where there are 4 levels for each ( R, G, B)
' - thus entering %%003 is brightest Green

  wdClr := BackClr << 10 + ForeClr << 2 
  LONGFILL( @scrn, $20202020, VGACOLS*VGAROWS/4 )   '4 space characters in long
  WORDFILL( @colors, wdClr, VGAROWS )
  CursorHome

PUB CursorHome
  cx0 := 0
  cy0 := 0  

PUB SetLineColor( line, ForeClr, BackClr ) | wdClr
' This sets a single row to the given colours
' ForeClr and BackClr are best represented as quaternary numbers (base 4)
' - these are represented as %%RGB where there are 4 levels for each ( R, G, B)
' - thus entering %%003 is brightest Green

  if line < VGAROWS
    wdClr := BackClr << 10 + ForeClr << 2 
    colors[line] := wdClr

PUB PrintStr( prRow, prCol, strPtr, inv ) | strLen, vgaIdx, idx
'this places text anywhere on the screen and can overwrite UI elements
'
' prRow  = row
' prCol  = column
' strPtr = pointer to null terminated string
' inv    = 0 for normal   1 for inverted video

  if ( prRow < VGAROWS ) AND ( prCol < VGACOLS )
    strLen := STRSIZE( strPtr )
    vgaIdx := prRow * VGACOLS + prCol
    bytemove( @scrn.byte[vgaIdx], strPtr, strLen )
  if inv
    repeat idx from 1 to strLen
      byte[@scrn][vgaIdx] += 128
      vgaIdx++

PUB Write(strPtr) | len, shift
  len := STRSIZE(strPtr)
  PrintStr(cy0, cx0, strPtr, 0)
  cx0 := cx0 + len
  if cx0 => VGACOLS
    shift := cx0 - VGACOLS 
    newLine
    cx0 := shift

PUB WriteLine(strPtr)
  Write(strPtr)
  newLine 

PRI getModus(mode) 
  if mode == _modus_terminal
    return @TerminalMode
  elseif mode == _modus_shell
    return @ShellMode    
  elseif mode == _modus_solo
    return @SoloMode
  else
    return @UnknownMode

PRI updateCursorModus(mode)
  if mode == _modus_terminal
    cm0 := %110                      ' block & slow
  elseif mode == _modus_shell
    cm0 := %010                      ' underscore & slow
  elseif mode == _modus_solo
    cm0 := %111                      ' block & fast

PRI clearKeyboardCommandBuffer
    byte[@strKeyboardCommandBuffer] := 0
    iKeyboardCommandBufferPos := 0

PRI clearLastKeyboardCommand
    byte[@strLastKeyboardCommand] := 0
    iStartCursorPosForKeyboardCmd := 0

PRI forwardKeyboardCommandBuffer
    repeat until not LOCKSET(semIDrs232)
    pst.Str(@strKeyboardCommandBuffer)  
    pst.Str(String(pst#NL))    
    LOCKCLR(semIDrs232)

' add lisp brackets if missing in shell modus    
PRI autoWrapLispBraces | len, ptrStrTrimed
    ptrStrTrimed := str.trimString(@strKeyboardCommandBuffer)
    len := STRSIZE(ptrStrTrimed)
    if len > 0 and byte[ptrStrTrimed][0] <> 40 ' == (
       byte[@strTempKeyboardCommandBuffer][0] := 40
       bytemove(@strTempKeyboardCommandBuffer.byte[1],ptrStrTrimed,len) 
       byte[@strTempKeyboardCommandBuffer][len+1] := 41  ' == )
       byte[@strTempKeyboardCommandBuffer][len+2] := 0
       bytemove(@strKeyboardCommandBuffer,@strTempKeyboardCommandBuffer,len+3)
       
' Example: #V:00,12,text output      ' write text to position x,y
PRI parseVideoCommand(len, ptrCmd) | err
    err := 0
    if len > 9 and byte[ptrCmd+5] == "," and byte[ptrCmd+8] == "," and len < _TEXTBUF_SIZE+9
      bytemove(@strXPosBuffer, ptrCmd+3, 2)
      xPos := str.decimalToInteger(@strXPosBuffer)
      bytemove(@strYPosBuffer, ptrCmd+6, 2)
      yPos := str.decimalToInteger(@strYPosBuffer)
      bytemove(@strText, ptrCmd+9, len-9+1)
      PrintStr(xPos, yPos, @strText, 0)
    else
      err := 12
    return err      

PRI parseSoundCommand(len, ptrCmd) | err
    err := 0
    if len > 4 and (byte[ptrCmd+3] == "L" or byte[ptrCmd+3] == "R")
      if byte[ptrCmd+3] == "R" 
        sndChannelNo := 1
      else
        sndChannelNo := 0
    if len > 5 and byte[ptrCmd+4] == "="
      bytemove(@strFrequencyBuffer, ptrCmd+5, len-5)
      sndFrequency := str.decimalToInteger(@strFrequencyBuffer)
    else
      err := 11
    return err      

PRI writeViaRS232(msg, txt, err)
    repeat until not LOCKSET(semIDrs232)
    pst.Str(msg)
    pst.Str(String(" "))
    pst.Str(txt)
    if err <> 0
      pst.Str(String(" "))
      pst.Str(String("Error="))
      pst.Dec(err)
    pst.Str(String(pst#NL))
    LOCKCLR(semIDrs232)    

PRI blinkLedsFunction
    dira[_Led1] := 1    
    repeat
      outa[_Led1] := 1
      waitcnt(clkfreq/4 + cnt)
      outa[_Led1] := 0
      waitcnt(clkfreq/4 + cnt)

PRI writeCharToScreen(ch)
    'repeat until not LOCKSET(semIDscreen)
    if ch == 13
      'cx0 := 0
    elseif ch == 10
      newLine
    elseif ch == 8  ' backspace
      if cx0 > 0 and cx0 > iStartCursorPosForKeyboardCmd
        cx0 := cx0 - 1
        byte[@strKeyboardBuffer] := 32   'space
        byte[@strKeyboardBuffer+1] := 0
        PrintStr(cy0, cx0, @strKeyboardBuffer, 0)       
    else   
      byte[@strKeyboardBuffer] := ch
      byte[@strKeyboardBuffer+1] := 0
      Write(@strKeyboardBuffer)
    'LOCKCLR(semIDscreen)    

PRI appendToCommandBufferAndProc(ch)
  ' we receive CR LF sequence for new line
  if ch == 13
    ' ignore
  elseif ch == 10
    if checkCommands(@strKeyboardCommandBuffer)
      ' command already processed
    elseif modus == _modus_shell
      autoWrapLispBraces
      forwardKeyboardCommandBuffer
    str.stringCopy(@strLastKeyboardCommand, @strKeyboardCommandBuffer)
    clearKeyboardCommandBuffer
  elseif ch == 8  ' backspace
    if iKeyboardCommandBufferPos > 0
      iKeyboardCommandBufferPos := iKeyboardCommandBufferPos - 1
      byte[@strKeyboardCommandBuffer][iKeyboardCommandBufferPos] := 0      
  else
    if iKeyboardCommandBufferPos == 0
      iStartCursorPosForKeyboardCmd := cx0 - 1
    byte[@strKeyboardCommandBuffer][iKeyboardCommandBufferPos] := ch
    byte[@strKeyboardCommandBuffer][iKeyboardCommandBufferPos+1] := 0
    iKeyboardCommandBufferPos := iKeyboardCommandBufferPos + 1

PRI swapWithLastCommand | len, len2
    ' clear current command
    len := STRSIZE(@strKeyboardCommandBuffer)
    len2 := STRSIZE(@strLastKeyboardCommand)
    BYTEFILL(@strTemp, 32, len)
    byte[@strTemp][len] := 0        
    PrintStr(cy0, iStartCursorPosForKeyboardCmd, @strTemp, 0)
    ' write new command
    PrintStr(cy0, iStartCursorPosForKeyboardCmd, @strLastKeyboardCommand, 0)
    ' update cursor
    cx0 := iStartCursorPosForKeyboardCmd + len2
    ' swap data
    str.stringCopy(@strTemp, @strLastKeyboardCommand)
    str.stringCopy(@strLastKeyboardCommand, @strKeyboardCommandBuffer)
    str.stringCopy(@strKeyboardCommandBuffer, @strTemp)
    ' update command buffer position
    iKeyboardCommandBufferPos := len2
    
PRI newLine
    cx0 := 0
    cy0 := cy0 + 1
    if cy0 => VGAROWS
      scrollUp
      cy0 := cy0 - 1
      
PRI scrollUp
    longmove(@byte[@scrn][0],@byte[@scrn][VGACOLS],VGAROWS*VGACOLS/4-VGACOLS/4)
    wordmove(@word[@colors][0],@word[@colors][1],VGAROWS-1)
    ' clear last line
    longfill(@byte[@scrn][VGAROWS*VGACOLS-VGACOLS+1],$20202020,VGACOLS/4)    

PRI processKeyboard | ch
    dira[_Led2] := 1
    repeat
      result := hid.keyboardEvent
      if(hid.keyboardEventMakeOrBreak(result))
        if(hid.keyboardEventPrintable(result))
          ch := hid.keyboardEventCharacter(result)
          sendKeyMessage(ch)
          repeat until not LOCKSET(semIDscreen)
          writeCharToScreen(ch)
          appendToCommandBufferAndProc(ch)
          LOCKCLR(semIDscreen)
        else
          ch := hid.keyboardEventCharacter(result)
          if ch == 142 or ch == 143 ' Cursor Up or Curso Down
            swapWithLastCommand    
          sendSpecialKeyMessage(ch)

PRI sendKeyMessage(ch)
    if modus == _modus_terminal
      outa[_Led2] := 1
      repeat until not LOCKSET(semIDrs232)
      pst.Str(@CmdKeyboard)
      pst.Char(ch)
      pst.Str(String(pst#NL))
      LOCKCLR(semIDrs232)
      outa[_Led2] := 0
       
PRI sendSpecialKeyMessage(ch)
    if modus == _modus_terminal
      outa[_Led2] := 1
      repeat until not LOCKSET(semIDrs232)
      pst.Str(@CmdKeyboard)
      pst.Str(String("#"))
      pst.Dec(ch)
      pst.Str(String(pst#NL))
      LOCKCLR(semIDrs232)
      outa[_Led2] := 0
       
PRI processMouse | ch
    dira[_Led2] := 1
    repeat
      result := hid.mouseEvent
      if(hid.mouseEventLeftPressed(result))
        sendMouseMessage(String("LP"), result)
      elseif(hid.mouseEventRightPressed(result))
        sendMouseMessage(String("RP"), result)                                                                           
      elseif(hid.mouseEventMiddlePressed(result))
        sendMouseMessage(String("MP"), result)
      elseif(hid.mouseEventLeftReleased(result))
        sendMouseMessage(String("LR"), result)
      elseif(hid.mouseEventRightReleased(result))
        sendMouseMessage(String("RR"), result)
      elseif(hid.mouseEventMiddleReleased(result))
        sendMouseMessage(String("MR"), result)
      elseif(hid.mouseEventXMovement(result) or hid.mouseEventYMovement(result))
        sendMouseMoveMessage(result)
      
PRI sendMouseMoveMessage(posInfo)
    cx1 := hid.mouseEventXPosition(posInfo)
    cy1 := hid.mouseEventYPosition(posInfo)
    if modus == _modus_terminal
      outa[_Led2] := 1
      repeat until not LOCKSET(semIDrs232)
      pst.Str(@CmdMouse)
      pst.Str(String("MM"))       ' Mouse Move
      pst.Str(String("="))
      pst.Dec(cx1)
      pst.Str(String(","))
      pst.Dec(cy1)    
      pst.Str(String(pst#NL))
      LOCKCLR(semIDrs232)
      outa[_Led2] := 0
       
PRI sendMouseMessage(actionName, posInfo)
    cx1 := hid.mouseEventXPosition(posInfo)
    cy1 := hid.mouseEventYPosition(posInfo)
    if modus == _modus_terminal
      outa[_Led2] := 1
      repeat until not LOCKSET(semIDrs232)
      pst.Str(@CmdMouse)
      pst.Str(actionName)
      pst.Str(String("="))
      pst.Dec(cx1)
      pst.Str(String(","))
      pst.Dec(cy1)
      pst.Str(String(pst#NL))
      LOCKCLR(semIDrs232)
      outa[_Led2] := 0
       
PRI processCommands | err, len, ch
  repeat
    err := 0
    if modus == _modus_terminal
      pst.StrIn(@strBuffer)
      len := STRSIZE(@strBuffer)
      if len > 0 and strBuffer[0] <> "#"
         err := 1
      else 
        if checkCommands(@strBuffer)
          ' command already processed
        elseif str.stringCompareCS(@strBuffer, @cmdClearScreen) == 0
          ClearScreen( %%330, %%003 )
        elseif len > 3 and strBuffer[1] == "V" and strBuffer[2] == ":"
          err := parseVideoCommand(len, @strBuffer)
        elseif str.stringCompareCS(@strBuffer, @cmdNoSound) == 0
          snd.Synth("A", _soundOutputA, 0) 
          snd.Synth("B", _soundOutputB, 0) 
        elseif len > 3 and strBuffer[1] == "S" and strBuffer[2] == ":"
           err := parseSoundCommand(len, @strBuffer)
           if err == 0
             if sndChannelNo == 0
                snd.Synth("A", _soundOutputA, sndFrequency)
             elseif sndChannelNo == 1
                snd.Synth("B", _soundOutputB, sndFrequency)
             else
                err := 2
        else
           err := 3               
      if err <> 0                                                        
        writeViaRS232(String("#ERROR: invalid command:"), @strBuffer, err)
      else
        writeViaRS232(String("#OK"), @strBuffer, err)
      'cmd := readCommandFromRS232
      'waitcnt(clkfreq/4 + cnt) 
      'eventElem := readFromEventQueue
      'sendMessageViaRS232(eventElem)
    elseif modus == _modus_shell       
      ch := pst.CharIn
      if ch <> 0
        receivedCharCount := receivedCharCount + 1
        repeat until not LOCKSET(semIDscreen)
        writeCharToScreen(ch)
        ' update start position for keyboard cmd if no character was consumed yet
        if iKeyboardCommandBufferPos == 0
          iStartCursorPosForKeyboardCmd := cx0
        LOCKCLR(semIDscreen)        

PRI showHelp | col
    col := 15
    Write(@CmdHelp)
    Write(@HelpSep)
    cx0 := col                 
    WriteLine(String("show all available commands of io processor"))
    Write(@CmdVersion)
    Write(@HelpSep)
    cx0 := col                 
    WriteLine(String("show firmware version of io processor"))
    Write(@CmdClr)
    Write(@HelpSep)
    cx0 := col                 
    WriteLine(String("clear screen"))
    Write(@CmdInfo)
    Write(@HelpSep)
    cx0 := col                 
    WriteLine(String("show infos"))
    Write(@CmdTerminalMode)
    Write(@HelpSep)
    cx0 := col                 
    WriteLine(String("switch to terminal modus"))
    Write(@CmdShellMode)
    Write(@HelpSep)
    cx0 := col                 
    WriteLine(String("switch to shell modus"))
    Write(@CmdSoloMode)
    Write(@HelpSep)
    cx0 := col                 
    WriteLine(String("switch to solo modus"))

PRI showVersion    
    Write(String("IO Processer firmware version: "))
    WriteLine(@Version)

PRI showInfos    
    WriteLine(String("Infos: "))
    Write(String("Clock frequency: "))
    itoa10(clkfreq,@strTempInfos)
    WriteLine(@strTempInfos)
    Write(String("Received bytes:  "))
    itoa10(receivedCharCount,@strTempInfos)
    WriteLine(@strTempInfos)
    
PRI checkCommands(pBuffer) | ok
    ok := true 
    if str.stringCompareCI(pBuffer, @CmdTerminalMode) == 0
      modus := _modus_terminal
      updateCursorModus(modus)
    elseif str.stringCompareCI(pBuffer, @CmdShellMode) == 0
      modus := _modus_shell
      updateCursorModus(modus)
    elseif str.stringCompareCI(pBuffer, @CmdSoloMode) == 0
      modus := _modus_solo
      updateCursorModus(modus)
    elseif str.stringCompareCI(pBuffer, @CmdHelp) == 0
      showHelp
    elseif str.stringCompareCI(pBuffer, @CmdVersion) == 0
      showVersion
    elseif str.stringCompareCI(pBuffer, @cmdClr) == 0
      ClearScreen( %%330, %%003 )
    elseif str.stringCompareCI(pBuffer, @cmdInfo) == 0
      showInfos
    else
      ok := false
    return ok

' see: https://forums.parallax.com/discussion/159774/integer-to-ascii-object    
PRI itoa10(number, strVal) | str0, divisor, temp
{{
  This private routine is used to convert a signed integer contained in
  "number" to a decimal character string.
}}
  str0 := strVal
  if (number < 0)
    byte[strVal++] := "-"
    if (number == $80000000)
      byte[strVal++] := "2"
      number += 2_000_000_000
    number := -number
  elseif (number == 0)
    byte[strVal++] := "0"
    byte[strVal] := 0
    return 1
  divisor := 1_000_000_000
  repeat while (divisor > number)
    divisor /= 10
  repeat while (divisor > 0)
    temp := number / divisor
    byte[strVal++] := temp + "0"
    number -= temp * divisor
    divisor /= 10
  byte[strVal++] := 0
  return strVal - str0 - 1
  
DAT
    CmdNoSound      byte "#S:NO", 0
    CmdClearScreen  byte "#V:CLR", 0
    CmdTerminalMode byte "#TERMINAL", 0  
    CmdMouse        byte "@M:", 0
    CmdKeyboard     byte "@K:", 0

    CmdShellMode    byte "#SHELL", 0  
    CmdSoloMode     byte "#SOLO", 0
    CmdInfo         byte "#INFO", 0
    CmdClr          byte "#CLR", 0  
    CmdHelp         byte "#HELP", 0  
    CmdVersion      byte "#VERSION", 0  

    TerminalMode    byte "TERMINAL", 0
    ShellMode       byte "SHELL", 0
    SoloMode        byte "SOLO", 0
    UnknownMode     byte "UNKNOWN", 0
    HelpSep         byte " ", 0

    Version         byte "1.0c from 10.4.2020", 0
  
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                                                    