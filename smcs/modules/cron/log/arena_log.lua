----------------------------------------
--$Id: arena_log.lua 88008 2016-01-18 12:51:31Z xiongyunkun $
----------------------------------------
--[[
-- 拉取login.log相关日志并且入库,相关日志文件有：login.log
--]]

module(...,package.seeall)

--统计指标
IndexName = "ArenaLog" 
--请求参数类型
RequestType = "getlog"
-- 需要读取的文件名
FileNames = {"key/arena.log"}

--前面的HostID和后面的时间都不要在这里填
local Cols = {"Uid", "Urs", "Name", "TargetUid", "TargetUrs", "TargetName", "Rank", "TRank", "FightGroup", "DefendGroup" ,"FightName", "DefendName"}
--区别判断重复的数据，用于统计时间点的数据比对
local UniqueKey = "Uid"

--构造请求参数
function GenerateReqParams(self, HostID)
	local StartDate = os.date("%Y-%m-%d",ngx.time()) 
	local StartTime = os.date("%Y-%m-%d %H:%M:%S",GetTimeStamp(StartDate .. " 00:00:00"))  --默认是当天的0点
	local StartTimes = {}
	for _, FileName in ipairs(FileNames) do
		local Res = StaticsModuleData:Get({HostID = HostID, FileName = FileName, IndexName = IndexName})
		if Res and Res[1] then
			StartTime = Res[1]["StaticsTime"]
		end
		table.insert(StartTimes, StartTime)
	end
	return {
		FileNames = table.concat(FileNames, ","),
		HostID = HostID,
		StartTimes = table.concat(StartTimes, ",")
	}
end

--处理回调结果
function HandleResponse(self, HostID, Response, ExecuteTime, LastSaticsTimes)
	if not CommonFunc.CheckLogErr(HostID, IndexName, Response) then
		return false
	end
	
	local TotalNum = 0 
	for FileName, LogContent in pairs(Response) do
		if LogContent ~= "" or LogContent ~= " " then
			local LastSaticsTime = LastSaticsTimes[FileName]
			local Results = {}
			local Lines = string.split(LogContent, "\n")
			local LastTime = nil
			local PlatformIDs = {}
			for _, Line in ipairs(Lines) do
				if Line ~= "" and Line ~= " " then
					local Result = {["HostID"] = HostID}
					local UniqueValue = nil
					for _, Col in ipairs(Cols) do
						Result[Col] = CommonFunc.GetLogValue(Line, Col)
					end
					local PlatformID = CommonFunc.GetPlatformIDByUrs(Result["Urs"])
					Result["PlatformID"] = PlatformID
					PlatformIDs[PlatformID] = true --加入平台列表，便于过滤重复日志
					--再提取时间
					Result["Time"] = CommonFunc.GetLogTime(Line)
					table.insert(Results, Result)
				end
			end
			local SameTimeStatics = {}
			for PlatformID, _ in pairs(PlatformIDs) do
				SameTimeStatics[PlatformID] = ArenaLogData:GetSameTimeStatics(PlatformID,{HostID=HostID,Time=LastSaticsTime})
			end
			local PlatformResults = {}
			for _, Result in ipairs(Results) do
				if Result["PlatformID"] and SameTimeStatics[Result["PlatformID"]] 
					and SameTimeStatics[Result["PlatformID"]][tonumber(Result[UniqueKey])] ~= Result["Time"] then
					PlatformResults[Result["PlatformID"]] = PlatformResults[Result["PlatformID"]] or {}
					table.insert(PlatformResults[Result["PlatformID"]], Result)
					LastTime = Result["Time"] -- 时间取最后一个
				end
			end
			--分平台记录
			for PlatformID, Results in pairs(PlatformResults) do
				ArenaLogData:BatchInsert(PlatformID, Results)
			end
			-- 更新tblStaticsCfg表中统计时间记录
			if table.size(SameTimeStatics) ~= 0 and not LastTime then
				--如果此次获得数据都是与库里面的数据一样，将统计时间往后推后一秒
				LastSaticsTime = GetTimeStamp(LastSaticsTime)
				LastTime = os.date("%Y-%m-%d %H:%M:%S",LastSaticsTime + 1) --取下一秒
			end
			if LastTime then
				local Params = {
					HostID = HostID,
					FileName = FileName,
					IndexName = IndexName,
					StaticsTime = LastTime,
				}
				StaticsModuleData:Update(Params)
			end
			
		end
	end
	return true
end

