----------------------------------------
--$Id: gololog.lua 4082 2014-05-19 02:44:03Z zork $
----------------------------------------
--[[
-- 执行GM指令获在线人数
--]]

-- 需要读取的文件名
--
module(...,package.seeall)

--统计指标
IndexName = "Online" 
--请求参数类型
RequestType = "executegm"
--需要执行的GM指令
Cmd = "return MASTER_ALLINFO:GetOnlineCnt()"


--构造请求参数
function GenerateReqParams(self, PlatformID, HostID)
	local NowTime = os.time()
	local TransID = CommonFunc.GenerateTransID(NowTime)
	NowTime = os.date("%Y-%m-%d %H:%M:%S",NowTime)
	local ShellValues = {HostID, 0, '"' .. Cmd .. '"', "'" .. NowTime .. "'", TransID}
	ShellValues = table.concat(ShellValues, ";") --用分号拼接
	local Params = {
		shellname = CommonData.ShellMap[4],
		shellparam = ShellValues,
		IsPend = "true", --挂起等待返回结果
	}
	return Params
end

--判断返回结果是否是错误的
function CheckErr(self, HostID, Response)
	-- 先判断是否返回的是数字错误
	if tonumber(Response) then
		--记录入错误日志库
		local Options = {
			HostID = HostID,
			FileName = "",
			StaticsIndex = IndexName,
			ErrContent = Response,
		}
		StaticsErrData:Insert(Options)
		return false
	end
	return true
end

--处理回调结果
function HandleResponse(self, PlatformID, HostID, Response, Time)
	if not self:CheckErr(HostID, Response) then
		return false
	end
	if not Response or Response == "" or Response == " " then
		return 0 -- 如果是空字符串直接返回0
	end
	local OnlineNum = Response.Result or 0 --解析在线人数
	if tonumber(OnlineNum) ~= 0 then
		OnlineData:Insert(PlatformID, HostID, OnlineNum, Time)
		self:CheckPreDataErro(PlatformID, HostID, Time)
	end
	local Params = {
		HostID = HostID,
		FileName = "",
		IndexName = IndexName,
		StaticsTime = os.date("%Y-%m-%d %H:%M:%S",os.time()),
	}
	StaticsModuleData:Update(Params)
	return true
end

--验证返回结果是否正确，如果返回为空或者0再次发送请求验证一下
function VerifyResponse(self, HostID, Params, Response)
	if not Response or not Response.Result or tonumber(Response.Result) == 0 then
		local Flag = nil
		Flag, Response = ReqCmcsByServerId(tonumber(HostID), RequestType, Params)
		Response  = UnSerialize(Response) 
	end
	return Response
end

--检查前5分钟的在线人数数据是否正确，检查的标准是：此次有数据，前5分钟没有，但是前10分钟又有数据，
--所以用前10分钟的数据填入进前5分钟进来
function CheckPreDataErro(self, PlatformID, HostID, Time)
	local Timestamp = GetTimeStamp(Time)
	local Pre5Time = os.date("%Y-%m-%d %H:%M:%S", Timestamp - 300) --前5分钟
	local Pre10Time = os.date("%Y-%m-%d %H:%M:%S", Timestamp - 600) --前10分钟
	local Pre5Info = OnlineData:Get({PlatformID = PlatformID, HostID = HostID, ExactTime = Pre5Time})
	--前5分钟的数据没有但是前10分钟的数据有的话需要补齐前分钟的数据
	if #Pre5Info == 0 then 
		local Pre10Info = OnlineData:Get({PlatformID = PlatformID, HostID = HostID, ExactTime = Pre10Time})
		if #Pre10Info > 0 then --前10分钟有数据，所以补齐前5分钟的数据
			local OnlineNum = Pre10Info[1].Num
			OnlineData:Insert(PlatformID, HostID, OnlineNum, Pre5Time) --填入前5分钟数据
		end
	end
end



