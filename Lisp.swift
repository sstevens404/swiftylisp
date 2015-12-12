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

func evaluateList(list:[Node])->Node {
    if let first = list.first {
        switch first {
        case .Atom(let a):
            switch a {
            case "+": return .Atom(String(list.dropFirst().reduce(0) { sum,item in sum + (Double(String(evaluateNode(item))) ?? 0)}))
            case "*": return .Atom(String(list.dropFirst().reduce(1) { product,item in product * (Double(String(evaluateNode(item))) ?? 0)}))
            case "-":
                let firstValue = Double(String(evaluateNode(list[1])))
                return .Atom(String(list.dropFirst(2).reduce(firstValue) { difference,item in difference - (Double(String(evaluateNode(item))) ?? 0)}))
            case "write":
                for item in list.dropFirst() {
                    print(evaluateNode(item), terminator:" ")
                }
                print(""); // newline
                return .List([Node]())
            default:
                print ("Unrecognized command: " + a)
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
    default: return node
    }
}

guard Process.arguments.count > 1 else { print("specify lisp file to run"); exit(-1) }
let fp = fopen(Process.arguments[1], "r")
guard fp != nil else { print("couldn't open file");  exit(-1) }
defer { fclose(fp) }

let rootNode = parseNode(fp)
print(rootNode)
evaluateNode(rootNode)
