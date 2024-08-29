
type ExtAPI* = object


proc clearDisplay*(this: ExtAPI) =
   screenReset()
   echo "CLS"
proc waitKey*(this: ExtAPI):int =
    result = -1
    if (keys and 0b0000000000000001) > 0: result = 0
    if (keys and 0b0000000000000010) > 0: result = 1
    if (keys and 0b0000000000000100) > 0: result = 2
    if (keys and 0b0000000000001000) > 0: result = 3
    if (keys and 0b0000000000010000) > 0: result = 4
    if (keys and 0b0000000000100000) > 0: result = 5
    if (keys and 0b0000000001000000) > 0: result = 6
    if (keys and 0b0000000010000000) > 0: result = 7
    if (keys and 0b0000000100000000) > 0: result = 8
    if (keys and 0b0000001000000000) > 0: result = 9
    if (keys and 0b0000010000000000) > 0: result = 0xA
    if (keys and 0b0000100000000000) > 0: result = 0xB
    if (keys and 0b0001000000000000) > 0: result = 0xC
    if (keys and 0b0010000000000000) > 0: result = 0xD
    if (keys and 0b0100000000000000) > 0: result = 0xE
    if (keys and 0b1000000000000000) > 0: result = 0xF




proc getKeys*(this: ExtAPI): uint16 =
    result = keys
proc drawPixel*(this: ExtAPI, x,y,value: int): bool =
    result = setPixel(x,y,value)
proc enableSound*(this: ExtAPI) =
    let kek = "kek"
proc disableSound*(this: ExtAPI) =
    let kek = "kek"
proc setKeys*(this: ExtAPI) =
    let kek = "kek"
proc resetKeys*( this: ExtAPI) =
    let kek = "kek"