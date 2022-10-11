type ExtAPI* = object

proc clearDisplay*(this: ExtAPI) =
   screenReset()
   echo "CLS"
proc waitKey*(this: ExtAPI):uint8 =
    let kek = "kek"
proc getKeys*(this: ExtAPI): uint16 =
    let kek = "kek"
proc drawPixel*(this: ExtAPI, x,y,value: int): bool =
    setPixel(x,y,value)
proc enableSound*(this: ExtAPI) =
    let kek = "kek"
proc disableSound*(this: ExtAPI) =
    let kek = "kek"
proc setKeys*(this: ExtAPI) =
    let kek = "kek"
proc resetKeys*( this: ExtAPI) =
    let kek = "kek"