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
    case Function(([Node],Frame)->(Node))
    
    var description: String {
        switch self {
        case .Atom(let a): return a
        case .List(let l):
            return "(" + l.map { $0.description }.joinWithSeparator(" ") + ")"
        default: return ""
        }
    }
}

class Frame {
    let parent: Frame?
    private var variables:[String:Node] = ["else":Node.Atom("true")]
    
    init(parent:Frame?) {
        self.parent = parent
    }
    
    func define(name:String, toBe value:Node) {
        guard variables[name] == nil else {
            print("Variable '\(name)' already defined. Exiting")
            exit(-1)
        }
        variables[name] = value
    }
    
    func valueOf(name:String)->Node? {
        return variables[name] ?? parent?.valueOf(name)
    }
}

func ==(a:Node, b:Node)->Bool {
    switch (a, b) {
    case (.Atom(let a), .Atom(let b)): return a == b
    case (.List(let a), .List(let b)): return a == b
    default: return false;
    }
}

var globalEnvironment = Frame(parent:nil)

func parseAtom(fp:UnsafeMutablePointer<FILE>)->String {
    var atom = ""
    
    while true {
        let c = fgetc(fp)
        if (c.s == " " || c.s == ")" || c == EOF || c.s == "\n" || c.s == "\r") {
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


func multiply(list:[Node], environment:Frame)->Node {
    let result = list.dropFirst().reduce(1) { product,item in product * (Double(String(evaluateNode(item, environment:environment))) ?? 0)}
    return .Atom(String(result))
}

func subtract(list:[Node], environment:Frame)->Node {
    let firstValue = Double(String(evaluateNode(list[1],environment:environment))) ?? 0
    let result = list.dropFirst(2).reduce(firstValue) { difference,item in difference - (Double(String(evaluateNode(item, environment:environment))) ?? 0)}
    return .Atom(String(result))
}

func write(list:[Node], environment:Frame)->Node {
    for item in list.dropFirst() {
        print(evaluateNode(item,environment:environment), terminator:" ")
    }
    print(""); // newline
    return .List([Node]())
}

func divide(list:[Node], environment:Frame)->Node {
    let firstValue = Double(String(evaluateNode(list[1],environment:environment))) ?? 0
    let result = list.dropFirst(2).reduce(firstValue) { difference,item in difference / (Double(String(evaluateNode(item,environment:environment))) ?? 0)}
    return .Atom(String(result))
}

func condition(list:[Node],environment:Frame)->Node {
    guard (list.count-1) % 2 == 0 else { print("cond statements must havean odd number of elements in the list. exiting.\n error in:\(list)"); exit(-1) }
    
    for i in 2.stride(to:list.count, by:2) {
        let condition = evaluateNode(list[i-1],environment:environment)
        if condition != Node.List([Node]()) {
            return evaluateNode(list[i],environment:environment)
        }
    }
    
    return .List([Node]())
}

func equal(list:[Node], environment: Frame)->Node {
    guard list.count == 3 else { print("= statements must have at least 3 elements in the list. exiting."); exit(-1) }
    
    if evaluateNode(list[1],environment:environment) == evaluateNode(list[2],environment:environment) {
        return .Atom("true")
    } else {
        return .List([Node]())
    }
}

func applyLambda(lambda: [Node], withParameters parameters: [Node], environment: Frame)->Node {

    guard lambda.count >= 3 else {
        print("lambda definitions must have at least 3 items: \n \(lambda)");
        exit(-1)
    }

    let newFrame = Frame(parent:environment)

    switch lambda[1] {
    case .List(let l):
        // bind variables
        for (param,value) in zip(l,parameters.dropFirst()) {
            switch param {
            case .Atom(let a):
                newFrame.define(a,toBe:(value))
            default:
                print("couldn't set param: \(param) to value: \(value)")
                continue
            }
        }
        default:
            print("lambda doesn't have parameter list: \n \(lambda)");
            exit(-1)
    }

    return eval(2)(list: lambda, environment:newFrame)
}

func define(list:[Node], environment:Frame)->Node {
    guard list.count == 3 else { print("define statements must have at least 3 elements in the list. exiting."); exit(-1) }

    switch list[1] {
    case .Atom(let a):
        environment.define(a,toBe:evaluateNode(list[2], environment:environment))
    case .List:
        print("define's variable name must be an atom. exiting.")
        exit(-1)
    default: break
    }

    return .List([Node]())
}

func evaluateList(list:[Node],environment: Frame)->Node {
    
    func tryToApplyLambda(lambda: Node)->Node? {
        switch lambda {
        case .List(let l) where l.count > 0:
            switch l[0] {
            case .Atom(let a) where a == "lambda":
                //                        guard l.count == list.count else { break }
                return applyLambda(l, withParameters:  list, environment:environment)
            default: return nil
            }
            
        default: return nil
        }
    }
    
    if let first = list.first {
        switch first {
        case .Atom(let atom):
            if let function = functionTable[atom] {
                return function(list,environment)
            }
            
            if let lambda = environment.valueOf(atom), let result = tryToApplyLambda(lambda) {
                return result
            }
        case .List:
            if let result = tryToApplyLambda(first) {
                return result
            }
        default:break
        }
    }
    
    return .List(list)
}

func evaluateNode(node:Node, environment: Frame)->Node {
    switch node {
    case .List(let l): return evaluateList(l, environment:environment)
    case .Atom(let a):
        if let variableValue = environment.valueOf(a) {
            return variableValue // TODO: variable names should maybe be limited to atoms with letters
        } else {
            return node
        }
    default: return .List([Node]())
    }
}

func eval(startingIndex:Int = 0)(list:[Node], environment:Frame)->Node {
    var result = Node.List([Node]())
    for node in list.dropFirst(startingIndex) {
        result = evaluateNode(node, environment:environment)
    }
    return result
}

let functionTable:[String: ([Node],Frame)->(Node)] = [
    "*": multiply,
    "-":subtract,
    "/":divide,
    "write":write,
    "cond": condition,
    "=":equal,
    "define":define]

func fuckSwiftBlockSyntax(list:[Node], environment:Frame) -> Node {
    let result = list.dropFirst().reduce(0) { sum,item in sum + (Double(String(evaluateNode(item,environment:environment))) ?? 0)}
    return Node.Atom(String(result))
}

globalEnvironment.define("+", toBe:.Function(fuckSwiftBlockSyntax))

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
    evaluateNode(rootNode, environment: globalEnvironment)
}


