import Foundation
// MARK: - Create 建立
let socketFD = Darwin.socket(AF_INET, SOCK_STREAM, 0)

func converIPToUInt32(a: Int, b: Int, c: Int, d: Int) -> in_addr {
    return Darwin.in_addr(s_addr: __uint32_t((a << 0) | (b << 8) | (c << 16) | (d << 24)))
}
// MARK: - Connect 连接
var sock4: sockaddr_in = sockaddr_in()

sock4.sin_len = __uint8_t(MemoryLayout.size(ofValue: sock4))
// 将ip转换成UInt32
sock4.sin_addr = converIPToUInt32(a: 47, b: 246, c: 3, d: 228)
// 因内存字节和网络通讯字节相反，顾我们需要交换大小端 我们连接的端口是80
sock4.sin_port = CFSwapInt16HostToBig(80)
// 设置sin_family 为 AF_INET表示着这个为IPv4 连接
sock4.sin_family = sa_family_t(AF_INET)
// Swift 中指针强转比OC要复杂
let pointer: UnsafePointer<sockaddr> = withUnsafePointer(to: &sock4, {$0.withMemoryRebound(to: sockaddr.self, capacity: 1, {$0})})

var result = Darwin.connect(socketFD, pointer, socklen_t(MemoryLayout.size(ofValue: sock4)))
guard result != -1 else {
    fatalError("Error in connect() function code is \(errno)")
}
// 组装文本协议 访问 菜鸟教程Http教程
let sendMessage = "GET /http/http-tutorial.html HTTP/1.1\r\n"
    + "Host: www.runoob.com\r\n"
    + "Connection: keep-alive\r\n"
    + "USer-Agent: Socket-Client\r\n\r\n"
// 转换成二进制
guard let data = sendMessage.data(using: .utf8) else {
    fatalError("Error occur when transfer to data")
}
// 转换指针
let dataPointer = data.withUnsafeBytes({UnsafeRawPointer($0)})

let status = Darwin.write(socketFD, dataPointer, data.count)

guard status != -1 else {
    fatalError("Error in write() function code is \(errno)")
}
// 设置32Kb字节存储防止溢出
let readData = Data(count: 64 * 1024)

let readPointer = readData.withUnsafeBytes({UnsafeMutableRawPointer(mutating: $0)})
// 记录当前读取多少字节
var currentRead = 0

while true {
    // 读取socket数据
    let result = Darwin.read(socketFD, readPointer + currentRead, readData.count - currentRead)

    guard result >= 0 else {
        fatalError("Error in read() function code is \(errno)")
    }
    // 这里睡眠是减少调用频率
    sleep(2)
    if result == 0 {
        print("无新数据")
        continue
    }
    // 记录最新读取数据
    currentRead += result
    // 打印
    print(String(data: readData, encoding: .utf8) ?? "")

}





