#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin
#else
    import Glibc
#endif



extension Int32 {
    var s:String {
        return String(Character(UnicodeScalar(UInt32(self))))
    }
}

func fpeek(fp: UnsafeMutablePointer<FILE>)->Int32 {
    let c = fgetc(fp)
    fseek(fp,-1,SEEK_CUR)
    return c
}

enum Node:CustomStringConvertible, Equatable {
    case Atom(String)
    case List([Node])
    
    var description: String {
        switch self {
        case .Atom(let a): return a
        case .List(let l):
            return "(" + l.map { $0.description }.joinWithSeparator(" ") + ")"
        }
    }
}

func ==(a:Node, b:Node)->Bool {
    switch (a, b) {
    case (.Atom(let a), .Atom(let b)): return a == b
    case (.List(let a), .List(let b)): return a == b
    default: return false;
    }
}

var variables = [String:Node]()

func parseAtom(fp:UnsafeMutablePointer<FILE>)->String {
    var atom = ""
    
    while true {
        let c = fgetc(fp)
        if (c.s == " " || c.s == ")" || c == EOF) {
            break
        }
        atom+=c.s
    }
    fseek(fp,-1,SEEK_CUR)
    return atom
}

func eatWhitespace(fp:UnsafeMutablePointer<FILE>) {
    var c:Int32
    repeat {
        c = fgetc(fp)
    } while c == 10 || c == 9 || c.s == " "
    
    fseek(fp,-1,SEEK_CUR)
}

func parseList(fp:UnsafeMutablePointer<FILE>)->[Node] {
    var list = [Node]()
    let next = fgetc(fp)
    if next.s != "(" {
        print("error, expected '(', got '\(next)'\nexiting.");
        exit(0)
    }
    
    while true {
        list.append(parseNode(fp))
        eatWhitespace(fp)
        
        let c = fgetc(fp)
        if c.s == ")" || c == EOF {
            return list
        }
        fseek(fp,-1,SEEK_CUR)
    }
}

func parseNode(fp:UnsafeMutablePointer<FILE>)->Node {
    eatWhitespace(fp)
    
    if fpeek(fp).s == "(" {
        return .List(parseList(fp))
    } else {
        return .Atom(parseAtom(fp))
    }
}

func add(list:[Node])->Node {
    let result = list.dropFirst().reduce(0) { sum,item in sum + (Double(String(evaluateNode(item))) ?? 0)}
    return .Atom(String(result))
}

func multiply(list:[Node])->Node {
    let result = list.dropFirst().reduce(1) { product,item in product * (Double(String(evaluateNode(item))) ?? 0)}
    return .Atom(String(result))
}

func subtract(list:[Node])->Node {
    let firstValue = Double(String(evaluateNode(list[1]))) ?? 0
    let result = list.dropFirst(2).reduce(firstValue) { difference,item in difference - (Double(String(evaluateNode(item))) ?? 0)}
    return .Atom(String(result))
}

func write(list:[Node])->Node {
    for item in list.dropFirst() {
        print(evaluateNode(item), terminator:" ")
    }
    print(""); // newline
    return .List([Node]())
}

func divide(list:[Node])->Node {
    let firstValue = Double(String(evaluateNode(list[1]))) ?? 0
    let result = list.dropFirst(2).reduce(firstValue) { difference,item in difference / (Double(String(evaluateNode(item))) ?? 0)}
    return .Atom(String(result))
}

func condition(list:[Node])->Node {
    guard list.count > 2 else { print("if statements must have 3 or 4 elements in the list. exiting."); exit(-1) }
    let condition = evaluateNode(list[1])
    if condition != Node.List([Node]()) {
        return evaluateNode(list[2])
    } else if list.count > 3 {
        return evaluateNode(list[3])
    }
    
    return .List([Node]())
}

func equal(list:[Node])->Node {
    guard list.count == 3 else { print("eq? statements must have at least 3 elements in the list. exiting."); exit(-1) }
    
    if evaluateNode(list[1]) == evaluateNode(list[2]) {
        return .Atom("true")
    } else {
        return .List([Node]())
    }
}

func letFunction(list:[Node])->Node {
    guard list.count == 3 else { print("let statements must have at least 3 elements in the list. exiting."); exit(-1) }

    switch list[1] {
    case .Atom(let a):
        guard variables[a] == nil else {
            print("Variable '\(a)' already defined. Exiting")
            exit(-1)
        }
        variables[a] = list[2]
    case .List:
        print("let's variable name must be an atom. exiting.")
        exit(-1)
    }

    return .List([Node]())
}

func evaluateList(list:[Node])->Node {
    if let first = list.first {
        switch first {
        case .Atom(let atom):

            if let function = functionTable[atom] {
                return function(list)
            }
        default: break;
        }
    }
    
    for node in list {
        evaluateNode(node)
    }
    
    return .List([Node]())
}

func evaluateNode(node:Node)->Node {
    switch node {
    case .List(let l): return evaluateList(l)
    case .Atom(let a):
        if let variableValue = variables[a] {
            return variableValue // TODO: variable names should maybe be limited to atoms with letters
        } else {
            return node
        }
    }
}

let functionTable = [
    "+": add,
    "*": multiply,
    "-":subtract,
    "/":divide,
    "write":write,
    "if": condition,
    "eq?":equal,
    "let":letFunction]

guard Process.arguments.count > 1 else { print("specify lisp file to run"); exit(-1) }
var printDebug = false
for param in Process.arguments.dropFirst() {
    
    if param == "--debug" {
        printDebug = true;
        continue
    }
    
    let fp = fopen(param, "r")
    guard fp != nil else { print("Couldn't open file: \(param)");  continue }
    defer { fclose(fp) }
    
    let rootNode = parseNode(fp)
    if printDebug { print(rootNode) }
    evaluateNode(rootNode)
}


