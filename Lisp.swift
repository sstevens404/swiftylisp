#!/usr/bin/env xcrun swift

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

func fnext(fp: UnsafeMutablePointer<FILE>)->Int32 {
    var c = fgetc(fp)
    while c.s == ";" {
        repeat {
            c = fgetc(fp)
        } while c.s != "\n" && c != EOF
        c = fgetc(fp)
    }
    
    return c
}

func fpeek(fp: UnsafeMutablePointer<FILE>)->Int32 {
    let c = fnext(fp)
    fseek(fp,-1,SEEK_CUR)
    return c
}



enum Node:CustomStringConvertible, Equatable {
    case Atom(String)
    case Str(String)
    case Number(Double)
    case List([Node])
    case Function(([Node],Frame)->(Node))
    case Lambda([Node],[Node], Frame)
    
    var description: String {
        switch self {
        case .Atom(let a): return a
        case .List(let l):
            return "(" + l.map { $0.description }.joinWithSeparator(" ") + ")"
        case .Number(let l): return "\(l)"
        case .Str(let s): return s
        case .Lambda(_, let b, _): return b.description
        default: return ""
        }
    }
    
    static let nilList = Node.List([Node]())
}

class Frame {
    let parent: Frame?
    private var variables:[String:Node] = ["else":Node.Atom("true")]
    
    init(parent:Frame?) {
        self.parent = parent
    }
    
    func define(name:String, toBe value:Node) {
        guard variables[name] == nil else {
            fail("Variable '\(name)' already defined. Exiting")
        }
        variables[name] = value
    }
    
    func valueOf(name:String)->Node? {
        return variables[name] ?? parent?.valueOf(name)
    }
    
    func defineFunc(name:String, function:([Node],Frame)->Node) {
        define(name, toBe:.Function(function))
    }
}

func ==(a:Node, b:Node)->Bool {
    switch (a, b) {
    case (.Atom(let a), .Atom(let b)): return a == b
    case (.List(let a), .List(let b)): return a == b
    case (.Number(let a), .Number(let b)): return a == b
    case (.Str(let a), .Str(let b)): return a == b
    case (.Str(let a), .Atom(let b)): return a == b
    case (.Atom(let a), .Str(let b)): return a == b
    default: return false;
    }
}

func parseAtom(fp:UnsafeMutablePointer<FILE>)->Node {
    var atom = ""
    
    let makeString:Bool
    if fnext(fp).s == "\"" {
        makeString = true
    } else {
        makeString = false
        fseek(fp,-1,SEEK_CUR)
    }
    while true {
        let c = fnext(fp)
        
        if c == EOF {
            break
        }
        
        if makeString {
            if c.s == "\"" {
                break
            }
        } else {
            if (c.s == " " || c.s == ")" || c.s == "\n" || c.s == "\r") {
                break
            }
        }
        
        atom+=c.s
    }
    
    if makeString {
        return .Str(atom)
    }
    
    fseek(fp,-1,SEEK_CUR)
    
    if let number = Double(atom) {
        return .Number(number)
    }
    
    return .Atom(atom)
}

func eatWhitespace(fp:UnsafeMutablePointer<FILE>) {
    var c:Int32
    repeat {
        c = fnext(fp)
    } while c == 10 || c == 9 || c.s == " "
    
    fseek(fp,-1,SEEK_CUR)
}

func parseList(fp:UnsafeMutablePointer<FILE>)->[Node] {
    var list = [Node]()
    let next = fnext(fp)
    if next.s != "(" {
        fail("error, expected '(', got '\(next)'\nexiting.");
    }
    
    while true {
        list.append(parseNode(fp))
        eatWhitespace(fp)
        
        let c = fnext(fp)
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
        return parseAtom(fp)
    }
}


func evaluateToNumber(node:Node, _ environment:Frame) -> Double{
    let number = evaluateNode(node, environment:environment)
    switch number {
    case .Number(let n): return n
    default: fail("unexpected non-number type: \"\(node)\". Exiting. ")
    }
}

@noreturn func fail(reason: String) {
    print(reason)
    exit(-1)
}

func evaluateNode(node:Node, environment: Frame)->Node {
    switch node {
    case .List(let list):
        guard list.count > 0 else { fail("calling empty list.\nExiting.") }
        
        switch evaluateNode(list[0], environment:environment) {
        case .Lambda(let params, let body, let lambdaEnvironment):
            let newFrame = Frame(parent:lambdaEnvironment)
            for (param,value) in zip(params,list.dropFirst()) {
                switch param {
                case .Atom(let a):
                    let parameterValue = evaluateNode(value, environment:environment)
                    newFrame.define(a,toBe:parameterValue)
                default:
                    fail("couldn't set param: \(param) to value: \(value)")
                }
            }
            
            return eval(0)(list: body, environment:newFrame)
        case .Function(let function):
            return function(list,environment)
        default:
            fail("Failed to call non-function:\n\(list)\n\nExiting.")
        }
    case .Atom(let a):
        if let variableValue = environment.valueOf(a) {
            return variableValue // TODO: variable names should maybe be limited to atoms with letters
        } else {
            fail("Use of undefined variable \"\(a)\". exiting.")
        }
    default: return node
    }
}

func eval(startingIndex:Int = 0)(list:[Node], environment:Frame)->Node {
    var result = Node.nilList
    for node in list.dropFirst(startingIndex) {
        result = evaluateNode(node, environment:environment)
    }
    return result
}

var globalEnvironment = Frame(parent:nil)
globalEnvironment.defineFunc("define") { list, environment in
    guard list.count == 3 else { fail("define statements must have 2 parameters in the list. exiting.") }
    
    switch list[1] {
    case .Atom(let a): environment.define(a,toBe:evaluateNode(list[2], environment:environment))
    default: fail("define's variable name must be an atom. exiting.")
    }
    
    return .nilList
}

globalEnvironment.defineFunc("+") { list, environment in
    return .Number(list.dropFirst().reduce(0) { sum,item in sum + evaluateToNumber(item,environment)})
}

globalEnvironment.defineFunc("*") { list, environment in
    return .Number(list.dropFirst().reduce(1) { product,item in product * evaluateToNumber(item, environment)})
}

globalEnvironment.defineFunc("-") { list, environment in
    let firstValue = evaluateToNumber(list[1],environment)
    let result = list.dropFirst(2).reduce(firstValue) { difference,item in difference - evaluateToNumber(item, environment)}
    return .Number(result)
}

globalEnvironment.defineFunc("/") { list, environment in
    let firstValue = evaluateToNumber(list[1],environment)
    let result = list.dropFirst(2).reduce(firstValue) { difference,item in difference / evaluateToNumber(item,environment)}
    return .Number(result)
}

globalEnvironment.defineFunc("cons") { list, environment in
    guard list.count > 1 else { fail("cons must have at least one parameter")}
    var newList = list.dropFirst().map { evaluateNode($0, environment:environment) }
    return .List(newList)
}

globalEnvironment.defineFunc("car") { list, environment in
    guard list.count == 2 else { fail("cons must have one parameter")}
    let evaluated = evaluateNode(list[1], environment:environment)
    switch evaluated {
    case .List(let items): return items.first ?? Node.nilList
    default: fail("cannot car a non list: \(evaluated)")
    }
}

globalEnvironment.defineFunc("cdr") { list, environment in
    guard list.count == 2 else { fail("cdr must have one parameter") }
    let evaluated = evaluateNode(list[1], environment:environment)
    switch evaluated {
    case .List(let items):
        guard items.count > 0 else {return Node.nilList}
        var newList = items
        newList.removeAtIndex(0)
        return .List(newList)
    default:
        fail("cannot cdr a non list: \(evaluated)")
    }
}

globalEnvironment.defineFunc("write") { list, environment in
    for item in list.dropFirst() {
        print(evaluateNode(item,environment:environment), terminator:" ")
    }
    print(""); // newline
    return .nilList
}

globalEnvironment.defineFunc("lambda") { list, environment in
    guard list.count >= 3 else { fail("lambda expressions must have at least two parameters.") }
    
    let parameters:[Node]
    switch list[1] {
    case .List(let l): parameters = l
    default:
        fail("lambda expressions second parameter must be a list.")
    }
    
    let lambdaBody = Array(list[2..<list.count])
    
    return .Lambda(parameters, lambdaBody, environment)
}

globalEnvironment.defineFunc("cond") { list, environment in
    guard list.count > 1 else { fail("cond statements must have at least one condition. exiting.\n error in:\(list)")}
    
    for conditionExpression in list.dropFirst() {
        switch conditionExpression {
        case .List(let l):
            guard l.count >= 2 else {  fail("cond expressions must be a list exiting.\n error in:\(list)") }
            if evaluateNode(l[0],environment:environment) == .Str("true") {
                return eval(1)(list: l, environment:environment)
            }
        default:
            fail("cond expressions must be a list. exiting.\n error in:\(list)")
        }
    }
    
    return .nilList
}

globalEnvironment.defineFunc("=") { list, environment in
    guard list.count == 3 else { fail("= statements must have 2 parameters. exiting.") }
    
    if evaluateNode(list[1],environment:environment) == evaluateNode(list[2],environment:environment) {
        return .Str("true")
    } else {
        return .nilList
    }
}

globalEnvironment.defineFunc("<") { list, environment in
    guard list.count == 3 else { fail("< statements must have two parameters. exiting.") }
    
    if evaluateToNumber(list[1],environment) < evaluateToNumber(list[2],environment) {
        return .Str("true")
    } else {
        return .nilList
    }
}

guard Process.arguments.count > 1 else { fail("specify lisp file to run") }
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


