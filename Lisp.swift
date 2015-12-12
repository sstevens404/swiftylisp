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

enum Node:CustomStringConvertible {
    case Atom(String)
    case List([Node])
    
    var description: String {
        switch self {
        case .Atom(let a): return "'\(a)'"
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

func evaluateList(list:[Node])->Int {
    guard list.count > 0 else { return 0 }
    
    switch list.first! {
    case .Atom(let a):
        switch a {
        case "+": return list.dropFirst().reduce(0) { sum,item in sum+evaluateNode(item)}
        case "*": return list.dropFirst().reduce(1) { product,item in product*evaluateNode(item)}
        case "-":
            var difference = evaluateNode(list[1])
            let newList = list[2...(list.count-1)]
            for item in newList{
                difference = difference - evaluateNode(item)
            }
            return difference
        case "write": for item in list.dropFirst() { print(evaluateNode(item), terminator:" ") }; print(""); return 0
        default:
            print ("Unrecognized command: " + a)
        }
    default: break;
    }
    
    for node in list {
        evaluateNode(node)
    }
    
    return 0
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
evaluateNode(rootNode)
