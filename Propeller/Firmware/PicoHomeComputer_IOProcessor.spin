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

  _keyboardTypematicDelay = 2
  _keyboardTypematicRate = 3

  _mouseSampleRate = 3
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
  modus = 1

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
  byte strKeyboardBuffer[2]
  byte strKeyboardCommandBuffer[VGACOLS+1]
  byte iKeyboardCommandBufferPos
  byte strBuffer[_STRBUF_SIZE]      'String Buffer
  byte strText[_TEXTBUF_SIZE]
  byte strFrequencyBuffer[_FREQUENCYBUF_SIZE]
  byte strXPosBuffer[_POSBUF_SIZE]
  byte strYPosBuffer[_POSBUF_SIZE]
  byte xPos
  byte yPos
  word sndFrequency
  byte sndChannelNo
  byte _modus                    ' 0 == direct io processor modus, 1 == forward mode --> forward keyboard to rs232

OBJ
  pst   :       "Parallax Serial Terminal"
  hid   :       "PS2_HIDEngine.spin"
  snd   :       "Synth.spin"                         
  str   :       "ASCII0_STREngine.spin"
  vga   :       "VGA_HiRes_Text"

PUB Main  | id, gx ' cmd, len, err 'value, base, width, offset, ch, eventElem

  _modus := 1                         ' start with direct RS232 modus

  clearKeyboardCommandBuffer

  dira[_Led1] := 1
  dira[_Led2] := 1

  pst.Start(115_200)                 'Set Parallax Serial Terminal to 115200 baud                        ' cognew+1

  ' text cursor
  cx0 := 0
  cy0 := 1
  if modus == 0
    cm0 := %110
  else
    cm0 := %010
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
  
  'pst.Str(String("INIT IO_Processor..."))

  ClearScreen( %%330, %%003 )

  PrintStr(0, 0, String("Welcome to the PicoHomeComputer !"), 0)
  SetLineColor(20,%%300, %%003)   
  PrintStr(20, 45, String("center"), 1)  
  PrintStr(49, 95, String("done."), 0)  
  
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
    strLen := strsize( strPtr )
    vgaIdx := prRow * VGACOLS + prCol
    bytemove( @scrn.byte[vgaIdx], strPtr, strLen )
  if inv
    repeat idx from 1 to strLen
      byte[@scrn][vgaIdx] += 128
      vgaIdx++

PRI clearKeyboardCommandBuffer
    byte[@strKeyboardCommandBuffer] := 0
    iKeyboardCommandBufferPos := 0

PRI processKeyboardCommandBuffer
    'if str.stringCompareCS(@strKeyboardCommandBuffer, @CmdDirectMode) == 0
    '  modus := 0
    'else
      pst.Str(@strKeyboardCommandBuffer)  
      pst.Str(String(pst#NL))    
     
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
   if ch == 13
     'cy0 := cy0 + 1
     cx0 := 0
   elseif ch == 10
     newLine
     ''cy0 := cy0 + 1     
     'cx0 := 0
   elseif ch == 8  ' backspace
     if cx0 > 0
       cx0 := cx0 - 1
       byte[@strKeyboardBuffer] := 32   'space
       byte[@strKeyboardBuffer+1] := 0
       PrintStr(cy0, cx0, @strKeyboardBuffer, 0)       
   else   
     byte[@strKeyboardBuffer] := ch
     byte[@strKeyboardBuffer+1] := 0
     PrintStr(cy0, cx0, @strKeyboardBuffer, 0)
     cx0 := cx0 + 1
   if cx0 => VGACOLS
     newLine        

PRI appendToCommandBuffer(ch)
  if ch == 13
    ' x
  elseif ch == 10
    if str.stringCompareCS(@strKeyboardCommandBuffer, @CmdDirectMode) == 0
      _modus := 0
      cm0 := %110
    elseif str.stringCompareCS(@strKeyboardCommandBuffer, @CmdForwardMode) == 0
      _modus := 1
      cm0 := %010
    if modus == 1
      processKeyboardCommandBuffer
    clearKeyboardCommandBuffer  
  else
    byte[@strKeyboardCommandBuffer][iKeyboardCommandBufferPos] := ch
    byte[@strKeyboardCommandBuffer][iKeyboardCommandBufferPos+1] := 0
    iKeyboardCommandBufferPos := iKeyboardCommandBufferPos + 1

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
          'pst.Dec(ch)
          'pst.Str(String(pst#NL))
          writeCharToScreen(ch)
          appendToCommandBuffer(ch)
        else
          ch := hid.keyboardEventCharacter(result)
          sendSpecialKeyMessage(ch)

PRI sendKeyMessage(ch)
    if modus == 0
      outa[_Led2] := 1
      repeat until not LOCKSET(semIDrs232)
      pst.Str(@CmdKeyboard)
      pst.Char(ch)
      pst.Str(String(pst#NL))
      LOCKCLR(semIDrs232)
      outa[_Led2] := 0
       
PRI sendSpecialKeyMessage(ch)
    if modus == 0
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
    if modus == 0
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
    if modus == 0
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
       
{
' read commands from RS232
PRI readCommandFromRS232 | rxCount
    ' only main cog receives characters via RS232 !
    'repeat until not LOCKSET(semIDrs232)
    rxCount := pst.RxCount
    pst.CharIn
    pst.StrIn(@strBuffer)
    'LOCKCLR(semIDrs232)
}

PRI processCommands | err, len, ch
  repeat
{    err := 0
    if modus == 0
      pst.StrIn(@strBuffer)
      len := STRSIZE(@strBuffer)
      if len > 0 and strBuffer[0] <> "#"
         err := 1
      else 
        if str.stringCompareCS(@strBuffer, @CmdForwardMode) == 0
          modus := 1
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
    elseif modus == 1
}
    ch := pst.CharIn
    if ch <> 0
      writeCharToScreen(ch)
      if ch == 13
        writeCharToScreen(10)
    'pst.Dec(ch)
    'pst.Char(32)
    'pst.Str(String(pst#NL))  
{
      StrInLF(@strBuffer)
      len := STRSIZE(@strBuffer)
      if byte[@strBuffer][len-1] == 13    ' remove CR from string if command is terminated with CR LF
        byte[@strBuffer][len-1] := 0        
      len := STRSIZE(@strBuffer)
      if byte[@strBuffer][len-1] == 10    ' remove LF from string if command is terminated with CR LF
        byte[@strBuffer][len-1] := 0        
      len := STRSIZE(@strBuffer)
      if str.stringCompareCS(@strBuffer, @CmdDirectMode) == 0
        _modus := 0
      else
        PrintStr(cy0, cx0, @strBuffer, 0)
        newLine
}

PRI StrInLF(stringptr)
{{Receive a string (line feed terminated) and stores it (zero terminated) starting at stringptr.
Waits until full string received.
  Parameter:
    stringptr - pointer to memory in which to store received string characters.
                Memory reserved must be large enough for all string characters plus a zero terminator.}}
    
  StrInMaxLF(stringptr, -1)

PRI StrInMaxLF(stringptr, maxcount)
{{Receive a string of characters (either line feed terminated or maxcount in length) and stores it (zero terminated)
starting at stringptr.  Waits until either full string received or maxcount characters received.
  Parameters:
    stringptr - pointer to memory in which to store received string characters.
                Memory reserved must be large enough for all string characters plus a zero terminator (maxcount + 1).
    maxcount  - maximum length of string to receive, or -1 for unlimited.}}
    
  repeat while (maxcount--)                                                     'While maxcount not reached
    if (byte[stringptr++] := pst.CharIn) == pst#LF                                      'Get chars until LF
      quit
  byte[stringptr+(byte[stringptr-1] == pst#LF)]~                                    'Zero terminate string; overwrite LF or append 0 char

  
DAT
    CmdNoSound      byte "#S:NO", 0
    CmdClearScreen  byte "#V:CLR", 0
    CmdDirectMode   byte "#DIRECT", 0  
    CmdForwardMode  byte "#FORWARD", 0  
    CmdMouse        byte "@M:", 0
    CmdKeyboard     byte "@K:", 0
  
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