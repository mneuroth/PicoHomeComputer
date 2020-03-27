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
   * Mouse Input    --> RS232 Commands to PIC32
       Example: @M:MM=176,216                ' mouse move to position x,y
   
   * RS232 Commands from PIC32 --> Sound Output
       Example: #S:L=440                     ' frequency
       Example: #S:R=440,200                 ' frequency,time_in_ms
       Example: #S:NO                        ' switch off sound
       Return:  #OK
       Return:  #ERROR: invalid command: ...
   * RS232 Commands from PIC32 --> VGA Output
       Example: #V:0,12,T="text output"      ' write text to position x,y
       Example: #V:C=255,128,64              ' set text colour to r,g,b value
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

CON
  _keyboardLocks = 2

  _keyboardTypematicDelay = 2
  _keyboardTypematicRate = 3

  _mouseSampleRate = 3
  _mouseScaling = 1

  ' pin numbers 
  _keyboardClock = 25
  _keyboardData = 24
  _mouseClock = 27
  _mouseData = 26
  _soundOutputA = 4
  _soundOutputB = 5
  _Led1 = 1
  _Led2 = 2

  _STRBUF_SIZE = 64
  _FREQUENCYBUF_SIZE = 6

VAR
  long blinkStack[100]
  long keyboardStack[100]
  long mouseStack[100]
  byte semIDrs232
  byte strBuffer[_STRBUF_SIZE]      'String Buffer
  byte strFrequencyBuffer[_FREQUENCYBUF_SIZE]
  word sndFrequency
  byte sndChannelNo

OBJ
  pst   :       "Parallax Serial Terminal"
  hid   :       "PS2_HIDEngine.spin"
  snd   :       "Synth.spin"                         
  str   :       "ASCII0_STREngine.spin"

PUB Main  | cmd, len, err, tmp 'value, base, width, offset, ch, eventElem

  dira[_Led1] := 1
  dira[_Led2] := 1

  pst.Start(115_200)                 'Set Parallax Serial Terminal to 115200 baud

  hid.HIDEngineStart(_keyboardClock, _keyboardData, _mouseClock, _mouseData, _keyboardLocks, 639, 479)
  hid.keyboardConfiguration(_keyboardTypematicDelay, _keyboardTypematicRate)
  hid.mouseConfiguration(_mouseSampleRate, _mouseScaling)

  if ((semIDrs232 := locknew) == -1)
    pst.Str(String("ERROR: no lock available for RS232 communication"))
  
  'pst.Str(String("INIT IO_Processor..."))
  
  cognew(blinkLedsFunction, @blinkStack)
  cognew(processKeyboard, @keyboardStack)
  cognew(processMouse, @MouseStack)

'  repeat
'    snd.Synth("A", _soundOutputA, 400)
'    snd.Synth("B", _soundOutputB, 0)
'    waitcnt(clkfreq/4 + cnt) 
'    snd.Synth("A", _soundOutputA, 0)
'    snd.Synth("B", _soundOutputB, 1400)
'    waitcnt(clkfreq/4 + cnt) 

  ' read commands from RS232 
  repeat
    err := 0
    pst.StrIn(@strBuffer)
    len := STRSIZE(@strBuffer)
    if len > 0 and strBuffer[0] <> "#"
       err := 1
    else
      tmp := str.stringCompareCS(@strBuffer, @NoSound)
      if str.stringCompareCS(@strBuffer, @NoSound) == 0
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

PRI processKeyboard | ch
    dira[_Led2] := 1
    repeat
      result := hid.keyboardEvent
      if(hid.keyboardEventMakeOrBreak(result))
        if(hid.keyboardEventPrintable(result))
          ch := hid.keyboardEventCharacter(result)
          sendKeyMessage(ch)

PRI sendKeyMessage(ch)
    outa[_Led2] := 1
    repeat until not LOCKSET(semIDrs232)
    pst.Str(String("@K:"))
    pst.Char(ch)
    pst.Str(String(pst#NL))
    LOCKCLR(semIDrs232)
    outa[_Led2] := 0

PRI processMouse | ch
    dira[_Led2] := 1
    repeat
      result := hid.mouseEvent
      if(hid.mouseEventLeftPressed(result))
        sendMouseMessage(String("LP"), result)
      if(hid.mouseEventRightPressed(result))
        sendMouseMessage(String("RP"), result)
      if(hid.mouseEventMiddlePressed(result))
        sendMouseMessage(String("MP"), result)
      if(hid.mouseEventLeftReleased(result))
        sendMouseMessage(String("LR"), result)
      if(hid.mouseEventRightReleased(result))
        sendMouseMessage(String("RR"), result)
      if(hid.mouseEventMiddleReleased(result))
        sendMouseMessage(String("MR"), result)
      if(hid.mouseEventXMovement(result) or hid.mouseEventYMovement(result))
        sendMouseMoveMessage(result)
      
PRI sendMouseMoveMessage(posInfo)
    outa[_Led2] := 1
    repeat until not LOCKSET(semIDrs232)
    pst.Str(String("@M:MM"))
    pst.Str(String("="))
    pst.Dec(hid.mouseEventXPosition(posInfo))
    pst.Str(String(","))
    pst.Dec(hid.mouseEventYPosition(posInfo))
    pst.Str(String(pst#NL))
    LOCKCLR(semIDrs232)
    outa[_Led2] := 0
     
PRI sendMouseMessage(actionName, posInfo)
    outa[_Led2] := 1
    repeat until not LOCKSET(semIDrs232)
    pst.Str(String("@M:"))
    pst.Str(actionName)
    pst.Str(String("="))
    'pst.Dec(hid.XPosition)
    pst.Dec(hid.mouseEventXPosition(posInfo))
    pst.Str(String(","))
    'pst.Dec(hid.YPosition)
    pst.Dec(hid.mouseEventYPosition(posInfo))
    pst.Str(String(pst#NL))
    LOCKCLR(semIDrs232)
    outa[_Led2] := 0

PRI readCommandFromRS232 | rxCount
    ' only main cog receives characters via RS232 !
    'repeat until not LOCKSET(semIDrs232)
    rxCount := pst.RxCount
    pst.CharIn
    pst.StrIn(@strBuffer)
    'LOCKCLR(semIDrs232)
    return    

DAT
    NoSound      byte "#S:NO", 0      
  
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