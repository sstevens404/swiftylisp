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

enum Node:CustomStringConvertible {
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

func parseList(fp:UnsafeMutablePointer<FILE>)->[Node] {
    var list = [Node]()
    let c = fgetc(fp).s
    if c != "(" {
        print("error, expected '(', got '\(c)'\nexiting.");
        exit(0)
    }
    
    while true {
        list.append(parseNode(fp))
        let c = fgetc(fp)
        if c.s == ")" || c == EOF {
            return list
        }
    }
}

func parseNode(fp:UnsafeMutablePointer<FILE>)->Node {
    let c = fgetc(fp).s
    fseek(fp,-1,SEEK_CUR)
    
    if c == "(" {
        return .List(parseList(fp))
    } else {
        return .Atom(parseAtom(fp))
    }
}

func evaluateList(list:[Node])->Int {
    guard list.count > 1 else { return 0 }
    switch list.first! {
    case .Atom(let a):
        let oprand = String(a[a.startIndex])
        switch oprand {
        case "+": return list.dropFirst().reduce(0) { sum,item in sum+evaluateNode(item)}
        case "*": return list.dropFirst().reduce(1) { product,item in product*evaluateNode(item)}
        default: return 0
        }
    case .List: return 0 // TODO: handle list as first element
    }
}

func evaluateNode(node:Node)->Int {
    switch node {
    case .Atom(let a): return Int(a) ?? 0
    case .List(let l): return evaluateList(l)
    }
}

guard Process.arguments.count > 1 else { print("specify lisp file to run"); exit(-1) }
let fp = fopen(Process.arguments[1], "r")
guard fp != nil else { print("couldn't open file");  exit(-1) }
defer { fclose(fp) }

let rootNode = parseNode(fp)
print(rootNode)
let result = evaluateNode(rootNode)
print("result: \(result)")
