import imgui, imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw], glm
import sequtils, os, strutils
import stb_image/read as stbi

proc screenReset*();
proc setPixel*(x,y, value:int):bool;

var   
  log*: string = ""
  str_ram_sec1*: string = """"""
  str_ram_sec2*: string = """"""
  PC*: ptr int
  keys*: uint16 = 0

include src/cpu
include src/instructions

var 
  window_width = 1280f
  window_height = 720f
  roms = toSeq(walkDir("roms", relative=true))
  romsStrings: seq[cstring]
  currentItemRom: int32 = 0
  screenMap*: seq[seq[bool]]
  cpu*: Cpu = newCPU()
  work*: bool = false



proc screenInit*()=
  screenMap = @[]
  for y in 0..31:
    var row: seq[bool] 
    for x in 0..63:
      row.add(false)
    screenMap.add(row)

proc screenReset*() = screenInit()    

proc setPixel*(x,y, value:int): bool =
  if ((screenMap[y][x]==true) and value==1):
    result = true
  screenMap[y][x] = if value>0: true else: false

proc main() =
  for i in roms:
    romsStrings.add(i[1])
  screenInit()
  assert glfwInit()
  
  var window: GLFWWindow = glfwCreateWindow(1280, 720, "CHIP 8 EMULATOR")
  if window == nil:
    quit(-1)

  window.makeContextCurrent()

  assert glInit()
  echo "OpenGL version: ", cast[cstring](glGetString(GL_VERSION))
  echo "OpenGL renderer: ", cast[cstring](glGetString(GL_RENDERER))

  let context = igCreateContext()
  
  assert igGlfwInitForOpenGL(window, true)
  assert igOpenGL3Init()

  glClearColor(0.1f, 0.1f, 0.1f, 1.0f)

  while not window.windowShouldClose: 
    
    keys = 0
    if (window.getKey(GLFWKey.Kp0)>0): keys.setBit(0)
    if (window.getKey(GLFWKey.Kp1)>0): keys.setBit(1)
    if (window.getKey(GLFWKey.Kp2)>0): keys.setBit(2)
    if (window.getKey(GLFWKey.Kp3)>0): keys.setBit(3)
    if (window.getKey(GLFWKey.Kp4)>0): keys.setBit(4)
    if (window.getKey(GLFWKey.Kp5)>0): keys.setBit(5)
    if (window.getKey(GLFWKey.Kp6)>0): keys.setBit(6)
    if (window.getKey(GLFWKey.Kp7)>0): keys.setBit(7)
    if (window.getKey(GLFWKey.Kp8)>0): keys.setBit(8)
    if (window.getKey(GLFWKey.Kp9)>0): keys.setBit(9)
    #echo keys


   # os.sleep(5)
    igOpenGL3NewFrame()
    igGlfwNewFrame() 
    igNewFrame()  

    if work == true:
      cpu.step()

    glClear(GL_COLOR_BUFFER_BIT)  
    #work = false   
    igSetNextWindowPos(ImVec2(x: 1, y: 26))
    igSetNextWindowSize(ImVec2(x: 1278, y: 34))
    igBegin("Panel bar", nil, NoTitleBar)
    igSetCursorPosX((windowWidth - 40f) * 0.5f);
    igSetCursorPosY(0)
    if igButton(if work==false:"PLAY" else: "PAUSE"):
      work = not work
    igEnd()
    
    igSetNextWindowSize(ImVec2(x: 300, y: 347))
    igSetNextWindowPos(ImVec2(x: 1, y: 60))
    igBegin("SETTINGS")  
    igSeparator()
    igText("ROMS CLICK FOR LOAD")
    igSeparator()
    if igListBox("##listbox", addr currentItemRom, addr romsStrings[0], romsStrings.len.int32):
      echo "Select rom: " & $romsStrings[currentItemRom]
    # igSetCursorPosX(40)
    # igSetCursorPosY(20)
    if igButton("LOAD ROM"):
      echo "LOAD ROM: " & $romsStrings[currentItemRom]
      cpu = newCPU()
      work = false
      cpu.loadRom("roms/" & $romsStrings[currentItemRom])
      cpu.`interface`.clearDisplay()
    igSeparator()
    igText("BUTTONS PAD")
    igSeparator()


    if igButton("1"): 
      keys.setBit(1)
    igSameLine()
    if igButton("2"): keys.setBit(2)
    igSameLine()
    if igButton("3"): keys.setBit(3)
    igSameLine()
    if igButton("C"): keys.setBit(12)


    
    if igButton("4"): keys.setBit(4)
    igSameLine()
    if igButton("5"): keys.setBit(5)
    igSameLine()
    if igButton("6"): keys.setBit(6)
    igSameLine()
    if igButton("D"): keys.setBit(13)


    if igButton("7"): keys.setBit(7)
    igSameLine()
    if igButton("8"): keys.setBit(8)
    igSameLine()
    if igButton("9"): keys.setBit(9)
    igSameLine()
    if igButton("E"): keys.setBit(14)

    
    if igButton("A"): keys.setBit(10)
    igSameLine()
    if igButton("0") or (window.getKey(GLFWKey.Kp0)>0): keys.setBit(0)
    igSameLine()
    if igButton("B"): keys.setBit(11)
    igSameLine()
    if igButton("F"): keys.setBit(15)

  

    igEnd()
    
    
    igSetNextWindowSize(ImVec2(x: 648, y: 347))
    igSetNextWindowPos(ImVec2(x: 307, y: 60)) # 310 60
    igBegin("DISPLAY")
    let startPoint = ImVec2(x: 310, y: 81)
    var drawlist = igGetWindowDrawList()
    let color = ImColor(value:ImVec4(x:1.0f, y:1.0f, z:0.4f, w:1.0f))
    for y in 0..31:
      for x in 0..63:
        if screenMap[y][x] == true:
          var min, max: ImVec2
          min.x= startPoint.x + 10.float * x.float
          min.y= startPoint.y + 10.float * y.float
          max.x = min.x + 10f
          max.y = min.y + 10f
          drawlist.addRectFilled(min, max, 0b1111_1111_1111_1111_1111_1111_1111_1111.uint32)
  
    igEnd()

    # Inspector 
    igSetNextWindowSize(ImVec2(x: 319, y: 659))
    igSetNextWindowPos(ImVec2(x: 960, y: 60))
    igBegin("CPU LOG") 
    igSeparator() 
    igText("opcode\t command\t args")
    igSeparator()
    igText(log)
    igEnd()

    # Project 
    igSetNextWindowSize(ImVec2(x: 950, y: 303))
    igSetNextWindowPos(ImVec2(x: 1, y: 417))
    igBegin("RAM")  
    igSeparator()
    igText("addr\t 00 01 02 03 04 05 06 07\t	08 09 10 11 12 13 14 15\t ASCI")
    igSeparator()
    igTextUnformatted(str_ram_sec1)
    igTextUnformatted(str_ram_sec2)
    igEnd()
    
    igRender()
    igOpenGL3RenderDrawData(igGetDrawData()) 
    window.swapBuffers()
    
    glfwPollEvents()

  igOpenGL3Shutdown()
  igGlfwShutdown()
  context.igDestroyContext()
  window.destroyWindow()
  glfwTerminate()

main()