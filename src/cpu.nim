import instructions
import random
import bitOps

include extAPI, disassembler

const
    DISPLAY_WIDTH*: uint8 = 64
    DISPLAY_HEIGHT*: uint8 = 32
    FONTSET_START_ADDRESS*: int = 0x50
    FONTSET_SIZE*: int = 80
    FONTSET*: array[FONTSET_SIZE, uint8] = [
        0xF0, 0x90, 0x90, 0x90, 0xF0,
        0x20, 0x60, 0x20, 0x20, 0x70,
        0xF0, 0x10, 0xF0, 0x80, 0xF0,
        0xF0, 0x10, 0xF0, 0x10, 0xF0,
        0x90, 0x90, 0xF0, 0x10, 0x10,
        0xF0, 0x80, 0xF0, 0x10, 0xF0,
        0xF0, 0x80, 0xF0, 0x90, 0xF0,
        0xF0, 0x10, 0x20, 0x40, 0x40,
        0xF0, 0x90, 0xF0, 0x90, 0xF0,
        0xF0, 0x90, 0xF0, 0x10, 0xF0,
        0xF0, 0x90, 0xF0, 0x90, 0x90,
        0xE0, 0x90, 0xE0, 0x90, 0xE0,
        0xF0, 0x80, 0x80, 0x80, 0xF0,
        0xE0, 0x90, 0x90, 0x90, 0xE0,
        0xF0, 0x80, 0xF0, 0x80, 0xF0,
        0xF0, 0x80, 0xF0, 0x80, 0x80]


randomize()

type Cpu = object
    `interface`: ExtAPI
    memory*: array[4096, uint8]
    registers*: array[16, uint8]
    stack*: array[16, uint16]
    ST*: uint8 # Sound Timer
    DT*: uint8 # Delay Timer
    SP*: int
    PC*: uint16 # POINT CURSOR on opcode
    I*: uint16
    halted*: bool
    soundEnabled *: bool

proc newCPU*: Cpu =
    result.ST = 0 # Sound Timer
    result.DT = 0 # Delay Timer
    result.I = 0
    result.SP = -1
    result.PC = 0x200
    result.halted = true
    result.soundEnabled = false

proc loadRom*(this: var Cpu, rom: string) =
    echo "Loading ", rom
    var file = open(rom)
    # roms are loaded at address 0x200
    let byteCount = file.readBytes(this.memory, 0x200, len(this.memory) - 0x200)

    for i in 0..FONTSET_SIZE-1:
        this.memory[FONTSET_START_ADDRESS+i] = FONTSET[i]

    if byteCount < file.getFileSize():
        echo "Couldn't read everything from rom"
    else:
        echo "Rom was successfully loaded"
    str_ram_sec1 = ""
    str_ram_sec2 = ""
    for line in 0..31:
        str_ram_sec1 &= "\n" & toHex(line.uint16) & "\t"
        for first in 0..7:
            str_ram_sec1 &= toHex(this.memory[line*16+first]) & " "
        str_ram_sec1 &= "\t"
        for dol in 8..15:
            str_ram_sec1 &= toHex(this.memory[line*16+dol]) & " "
    str_ram_sec1 &= "\n\n------------------------------------------------------\n Program section"
    str_ram_sec1 &= "\n------------------------------------------------------\n"
    for line in 32..127:
        str_ram_sec2 &= "\n" & toHex(line.uint16) & "\t"
        for first in 0..7:
            str_ram_sec2 &= toHex(this.memory[line*16+first]) & " "
        str_ram_sec2 &= "\t"
        for dol in 8..15:
            str_ram_sec2 &= toHex(this.memory[line*16+dol]) & " "


proc reset(this: var Cpu) =
    this = newCPU()


proc decode(this: Cpu, opcode: uint16): (Instruction, seq[uint16]) =
    return disassemble(opcode)

proc fetch(this: var Cpu): uint16 =
    if (this.PC > 4094):
        this.halted = true
        echo("Memory out of bounds.")
    var val: uint16
    val = this.memory[this.PC]
    return (this.memory[this.PC].uint16 shl 8) or (this.memory[this.PC +
            1].uint16 shl 0)


proc halt(this: var Cpu) =
    this.halted = true

## Move forward four bytes
proc skipInstruction(this: var Cpu) =
    this.PC = this.PC + 4

## Move forward two bytes
proc nextInstruction(this: var Cpu) =
    this.PC = this.PC + 2

## Execute processor commands
proc execute(this: var Cpu, instruction: (Instruction, seq[uint16])) =
    let id = instruction[0].id
    let args = instruction[1]
    case id:
    of "CLS":
        # 00E0 - Clear the display
        this.`interface`.clearDisplay()
        this.nextInstruction()
    of "RET":
        # 00EE - Return from a subroutine
        if (this.SP == -1):
            this.halted = true
            echo("Stack underflow.")
        this.PC = this.stack[this.SP]
        this.SP-=1
    of "JP_ADDR":
        # 1nnn - Jump to location nnn
        this.PC = args[0]
    of "CALL_ADDR":
        # 2nnn - Call subroutine at nnn
        if (this.SP == 15):
            this.halted = true
            echo("Stack overflow.")
        this.SP+=1
        this.stack[this.SP] = this.PC + 2
        this.PC = args[0]
    of "SE_VX_NN":
        # 3xnn - Skip next instruction if Vx = nn
        if (this.registers[args[0]] == args[1]):
            this.skipInstruction()
        else:
            this.nextInstruction()
    of "SNE_VX_NN":
        # 4xnn - Skip next instruction if Vx != nn
        if (this.registers[args[0]] != args[1]):
            this.skipInstruction()
        else:
            this.nextInstruction()
    of "SE_VX_VY":
        # 5xy0 - Skip next instruction if Vx = Vy
        if (this.registers[args[0]] == this.registers[args[1]]):
            this.skipInstruction()
        else:
            this.nextInstruction()
    of "LD_VX_NN":
        # 6xnn - Set Vx = nn
        this.registers[args[0]] = args[1].uint8
        this.nextInstruction()
    of "ADD_VX_NN":
        # 7xnn - Set Vx += nn
        this.registers[args[0]] += args[1].uint8
        this.nextInstruction()
    of "LD_VX_VY":
        # 8xy0 - Set Vx = Vy
        this.registers[args[0]] = this.registers[args[1]]
        this.nextInstruction()
    of "OR_VX_VY":
        # 8xy1 - Set Vx = Vx OR Vy
        this.registers[args[0]] = this.registers[args[0]] or this.registers[args[1]]
        this.nextInstruction()
    of "AND_VX_VY":
        # 8xy2 - Set Vx = Vx AND Vy
        this.registers[args[0]] = this.registers[args[0]] and this.registers[args[1]]
        this.nextInstruction()
    of "XOR_VX_VY":
        # 8xy3 - Set Vx = Vx XOR Vy
        this.registers[args[0]] = this.registers[args[0]] xor this.registers[args[1]]
        this.nextInstruction()
    of "ADD_VX_VY": # ТЕСТ  прошло
        # 8xy4 - Set Vx = Vx + Vy, set VF = carry
        # SET VF (проверка переноса бита 8):
        let tempVF: uint8 = if (this.registers[args[1]].uint16 + this.registers[args[0]].uint16) > 0xff: 1 else: 0
        #SET Vx
        this.registers[args[0]] += this.registers[args[1]]
        this.registers[0xf] = tempVF
        # в конце поставить VF перенос
        this.nextInstruction()
    of "SUB_VX_VY": # ТЕСТ НЕ ПРОЙДЕН ^X^^
        # 8xy5 - Set Vx = Vx - Vy, set VF = NOT borrow
        
        if this.registers[args[0]] > this.registers[args[1]]:            
            this.registers[args[0]] -= this.registers[args[1]]
            this.registers[0xf] = 1
        else:            
            this.registers[args[0]] -= this.registers[args[1]]
            this.registers[0xf] = 0

        this.nextInstruction()
    of "SHR_VX_VY": # ТЕСТ НЕ ПРОЙДЕН ^^X
        # 8xy6 - Set Vx = Vy SHR 1, last bit in VF
        let oldVy = this.registers[args[1]]
        this.registers[args[0]] = oldVy shr 1
        this.registers[0xf] = oldVy and 0b00000001
        this.nextInstruction()
    
    of "SUBN_VX_VY": # ТЕСТ НЕ ПРОЙДЕН ^X^^
        # 8xy7 - Set Vx = Vy - Vx, set VF = NOT borrow
        if this.registers[args[1]] > this.registers[args[0]]:            
            this.registers[args[0]] = this.registers[args[1]] - this.registers[args[0]]
            this.registers[0xf] = 1
        else:            
            this.registers[args[0]] = this.registers[args[1]] - this.registers[args[0]]
            this.registers[0xf] = 0
        this.nextInstruction()
    of "SHL_VX_VY": # тест не пройден
        # 8xyE - Set Vx = Vy SHL 1
        let oldVy = this.registers[args[1]]        
        this.registers[args[0]] = this.registers[args[1]] shl 1
        this.registers[0xf] = oldVy shl 7
        this.nextInstruction()
    of "SNE_VX_VY":
        # 9xy0 - Skip next instruction if Vx != Vy
        if (this.registers[args[0]] != this.registers[args[1]]):
            this.skipInstruction()
        else:
            this.nextInstruction()
    of "LD_I_ADDR":
        # Annn - Set I = nnn
        this.I = args[1]
        this.nextInstruction()
    of "JP_V0_ADDR":
        # Bnnn - Jump to location nnn + V0
        this.PC = this.registers[0] + args[1]
    of "RND_VX_NN":
        # Cxnn - Set Vx = random byte AND nn
        let random: uint8 = rand(255).byte * 0xff
        this.registers[args[0]] = random and args[1].uint8
        this.nextInstruction()
    of "DRW_VX_VY_N":
        # Dxyn - Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision
        if (this.I > 4095 - args[2]):
            this.halted = true
            echo("Memory out of bounds.")
        # If no pixels are erased, set VF to 0
        this.registers[0xf] = 0
        # The interpreter reads n bytes from memory, starting at the address stored in I
        # скорее всего тут хуйня
        for i in 0.uint16..(args[2]-1).uint16:
            let line = this.memory[this.I + i]
            # Each byte is a line of eight pixels
            for position in 0..7:
                # Get the byte to set by position
                let value = if (line and (1.uint8 shl (7 - position))) >
                        0: 1.uint8 else: 0.uint8
                # If this causes any pixels to be erased, VF is set to 1
                var x = (this.registers[args[0]] +
                        position.uint8) mod DISPLAY_WIDTH # wrap around width
                var y = (this.registers[args[1]] + i) mod DISPLAY_HEIGHT # wrap around height

                if (this.`interface`.drawPixel(x.int, y.int, value.int)):
                    this.registers[0xf] = 1                
        this.nextInstruction()
    of "SKP_VX":
        # Ex9E - Skip next instruction if key with the value of Vx is pressed
        # Fuckme
        if (this.`interface`.getKeys() and (1.uint16 shl this.registers[args[
                0]].uint16)) > 0:
            this.skipInstruction()
        else:
            this.nextInstruction()
    of "SKNP_VX":
        # ExA1 - Skip next instruction if key with the value of Vx is not pressed
        if (this.`interface`.getKeys() and (1.uint16 shl this.registers[args[
                0]].uint16)) > 0:
            this.nextInstruction()
        else:
            this.skipInstruction()
    of "LD_VX_DT":
        # Fx07 - Set Vx = delay timer value
        this.registers[args[0]] = this.DT
        this.nextInstruction()
    of "LD_VX_N":
        # Fx0A - Wait for a key press, store the value of the key in Vx
        let keyPress = this.`interface`.waitKey()
        if (keyPress) >= 0:
            this.registers[args[0]] = keyPress.uint8
            this.nextInstruction()
    of "LD_DT_VX":
        # Fx15 - Set delay timer = Vx
        this.DT = this.registers[args[1]]
        this.nextInstruction()
    of "LD_ST_VX":
        # Fx18 - Set sound timer = Vx
        this.ST = this.registers[args[1]]
        if (this.ST > 0):
            this.soundEnabled = true
            this.`interface`.enableSound()
        this.nextInstruction()
    of "ADD_I_VX":
        # Fx1E - Set I = I + Vx
        this.I = this.I + this.registers[args[1]]
        this.nextInstruction()
    of "LD_F_VX":
        # Fx29 - Set I = location of sprite for digit Vx
        if (this.registers[args[1]] > 0xf):
            this.halted = true
            echo("Invalid digit.")
        this.I = this.registers[args[1]]
        this.nextInstruction()
    of "LD_B_VX":
        # // Fx33 - Store BCD representation of Vx in memory locations I, I+1, and I+2
        # // BCD means binary-coded decimal
        # // If VX is 0xef, or 239, we want 2, 3, and 9 in I, I+1, and I+2
        var x = this.registers[args[1]]
        let a = x div 100 # for 239, a is 2
        x = x - a * 100 # subtract value of a * 100 from x (200)
        let b = x div 10 # x is now 39, b is 3
        x = x - b * 10 # subtract value of b * 10 from x (30)
        let c = x # x is now 9

        this.memory[this.I] = a
        this.memory[this.I + 1] = b
        this.memory[this.I + 2] = c

        this.nextInstruction()
    of "LD_I_VX":
        # Fx55 - Store registers V0 through Vx in memory starting at location I
        if (this.I > 4095 - args[1]):
            this.halted = true
            echo("Memory out of bounds.")
        for i in 0.uint8..args[1].uint8:
            this.memory[this.I + i] = this.registers[i]
        this.nextInstruction()
    of "LD_VX_I":
        # Fx65 - Read registers V0 through Vx from memory starting at location I
        if (this.I > 4095 - args[0]):
            this.halted = true
            echo("Memory out of bounds.")
        for i in 0.uint8..args[0].uint8:
            this.registers[i] = this.memory[this.I + i]
        this.nextInstruction()
    else:
        # Data word
        this.halted = true
        echo("Illegal instruction.")


proc step(this: var Cpu) =
    let opcode = this.fetch()
    let instruction = this.decode(opcode)
    this.execute(instruction)
