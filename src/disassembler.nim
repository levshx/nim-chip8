import bitOps

proc disassemble*(opcode: uint16): (Instruction, seq[uint16]) =
    let instruction = INSTRUCTION_SET.filter(proc(instr: Instruction): bool = opcode.masked(instr.mask) == instr.pattern)[0]
    var args = instruction.arguments.map(proc (arg: Argument): uint16  = (opcode.masked(arg.mask) shr arg.shift).uint16)
    
    let aligmCommand = 15 - instruction.id.len
    var spacesCommand: string
    for i in 1..aligmCommand:
      spacesCommand &= " "

    log &= "\n" &  toHex(opcode) & "\t" & $instruction.id & spacesCommand
    
    if log.len > 1300:
      let pos = log.find('\n', 0)
      log.delete(0, pos)

    for arg in args:
        log &= toHex(arg) & "\t"
    return (instruction, args)
