local language = aipGetModConfig("language")

local LANG_MAP = {
	chinese = {
		PREPARING = "猪王观光列车正在铺轨，请稍候。",
		START = "六站观光开始！第三视角可移动鼠标调整方向和俯仰，X 键返回猪王村，V 键切换视角。",
		STOP = "途经：%s。请欣赏沿途风景！",
		FINISH = "观光结束，欢迎再次乘坐猪王列车！",
		ABORT = "本次观光已中止，返回猪王村。",
		FAILED = "本次线路无法安全通行，体验券已返还。",
		BUSY = "暂时无法乘车，请稍后再试。",
	},
	english = {
		PREPARING = "The Pig King is preparing your scenic railway.",
		START = "Six stops ahead! Move the mouse to adjust the third-person view. X exits; V changes view.",
		STOP = "Passing %s. Enjoy the scenery!",
		FINISH = "Welcome back! Thank you for riding the Pig King train.",
		ABORT = "The tour has ended early. Returning to the village.",
		FAILED = "This route is unavailable. Your ticket has been returned.",
		BUSY = "Please try the train again later.",
	},
}

return {
	LANG = LANG_MAP[language] or LANG_MAP.english,
	-- 六段 270 度观景圆弧会显著增加里程；流式铺轨后可放宽总量，仍保留规划预检。
	ALLOW_OCEAN = true,
	MAX_DISTANCE = 3600,
	MAX_OCEAN_DISTANCE = 1800,
	MAX_VISUALS = 6400,
	MAX_POINTS = 256,
	MAX_ACTIVE_RUNS = 3,
	MAX_PLAN_ATTEMPTS = 6,
	MAX_SEGMENT = 40,
	SCENIC_ARC_FRACTION = 0.75,
	SCENIC_ARC_SEGMENTS = 12,
	ORBIT_SPACING = 0.6,
	HEIGHT = 6,
	ELEVATION_RAMP_DISTANCE = 32,
	GROUND_HEIGHT = 0.05,
	RIDE_CLEARANCE = 0.1,
	RIDE_DIAGNOSTIC_INTERVAL = 10,
	RIDE_STALL_DISTANCE = 0.01,
	RIDE_STALL_TIMEOUT = 5,
	SPEED = 15,
	SCENIC_SPEED = 7,
	-- 当前段之外再预铺三段，保证正常镜头里能看到连续路线。
	TRACK_LOOKAHEAD = 4,
	TRACK_RETAIN_BEHIND = 1,
	TRACK_FADE_DURATION = 0.65,
	TRACK_FADE_STAGGER = 0.2,
	MAX_DURATION = 600,
}
