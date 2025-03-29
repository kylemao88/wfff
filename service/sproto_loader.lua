local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local service = require "service"
local log = require "log"

local loader = {}
local data = {}

-- 从单个文件加载内容
local function load_file_content(name)
    local filename = string.format("proto/%s.sproto", name)
    log.info("读取文件内容: %s", filename)
    local f = assert(io.open(filename), "Can't open " .. filename)
    local t = f:read "a"
    log.debug("读取到的内容长度: %d 字节", #t)
    
    f:close()
    return t
end

-- 合并多个协议文件内容并解析
local function load_merged(files)
    log.info("开始合并协议文件: %s", table.concat(files, ", "))
    local contents = {}
    
    -- 先加载基础包定义
    local base_content = load_file_content("base.c2s")
    table.insert(contents, base_content)
    
    -- 然后加载其他模块协议，跳过基础包
    for _, file in ipairs(files) do
        if file ~= "base.c2s" then
            local content = load_file_content(file)
            table.insert(contents, content)
        end
    end
    
    local merged = table.concat(contents, "\n\n")
    log.info("合并后的协议内容长度: %d 字节", #merged)
    
    -- 保存合并后的内容用于调试
    local debug_file = io.open("merged_proto.txt", "w")
    if debug_file then
        debug_file:write(merged)
        debug_file:close()
        log.info("合并后的协议内容已保存到 merged_proto.txt")
    end
    
    log.info("开始解析合并协议...")
    local binary = sprotoparser.parse(merged)
    log.info("协议解析完成，二进制数据长度: %d 字节", #binary)
    
    return binary
end

-- 加载并解析单个协议文件
local function load(name)
    local filename = string.format("proto/%s.sproto", name)
    log.info("加载单个协议文件: %s", filename)
    local f = assert(io.open(filename), "Can't open " .. name)
    local t = f:read "a"
    log.debug("协议内容长度: %d 字节", #t)
    f:close()
    
    log.info("开始解析协议...")
    local binary = sprotoparser.parse(t)
    log.info("协议解析完成，二进制数据长度: %d 字节", #binary)
    return binary
end

function loader.load(list)
    log.info("开始加载协议列表: %s", table.concat(list, ", "))
    for i, name in ipairs(list) do
        local p
        if name == "proto.c2s" then
            -- 对于c2s协议，使用分拆后的文件
            log.info("加载分拆后的C2S协议文件")
            p = load_merged({"base.c2s", "ping.c2s", "login.c2s"})
        else
            p = load(name)
        end
        log.info("加载Sproto协议 [%s] 到槽位 %d，数据长度: %d 字节", name, i, #p)
        data[name] = i
        sprotoloader.save(p, i)
    end
    log.info("所有协议加载完成!")
    
    -- 打印协议加载总结
    local summary = {}
    for name, slot in pairs(data) do
        table.insert(summary, string.format("协议[%s] -> 槽位[%d]", name, slot))
    end
    log.info("协议加载总结: %s", table.concat(summary, ", "))
end

function loader.index(name)
    return data[name]
end

service.init {
    command = loader,
    info = data
}
