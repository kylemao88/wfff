local skynet = require "skynet"
local socket = require "socket"
local string = require "string"
local log = require "log"

skynet.start(function()
    local worker_num = tonumber(skynet.getenv("ws_worker_num")) or 4

    local worker = {}
    for i= 1, worker_num do
        worker[i] = skynet.newservice("ws_worker")
    end

    local ws_port = tonumber(skynet.getenv("ws_port")) or 9555
    local balance = 1
    local id = socket.listen("0.0.0.0", ws_port)
    log("Listen ws port %s",ws_port)

    socket.start(id , function(id, addr)
        if not worker[balance] then
            worker[balance] = skynet.newservice("ws_worker")
            LOG_INFO('add ws_worker<%s>', balance)
        end

        skynet.send(worker[balance], "lua", id)
        log("%s connected, pass it to worker :%08x",
            addr, worker[balance])
        

        balance = balance + 1
        if balance > #worker then
            balance = 1
        end
    end)

    --skynet.register('.ws_master')  -- 旧版api，新版本不推荐使用
    log("web_master booted, ws_port<%s>", ws_port)

end)



