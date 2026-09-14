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
	GROUND_TRANSITION_MAX_DISTANCE = 96,
	GROUND_TRANSITION_STEP = 4,
	GROUND_TRANSITION_DIRECTIONS = 24,
	GROUND_HEIGHT = 0.05,
	-- 最终路线按真实三维里程保证多数贴地，不满足时由运行时有限替换景点重试。
	MIN_GROUND_RATIO = 0.5,
	RIDE_CLEARANCE = 0.1,
	-- 观光期间仍复用原矿车运动向量；坡度前馈负责跟随轨道，向上补偿抵消空中持续下坠。
	RIDE_VERTICAL_GRAVITY_COMPENSATION = 1,
	RIDE_VERTICAL_PEAK_LOG_STEP = 0.025,
	RIDE_DIAGNOSTIC_INTERVAL = 10,
	RIDE_STALL_DISTANCE = 0.01,
	RIDE_STALL_TIMEOUT = 5,
	SPEED = 15,
	SCENIC_SPEED = 7,
	-- 观光乘客携带大范围冷色随身灯，保证夜间和高架段仍能看清周边景点。
	RIDE_LIGHT_RADIUS = 10,
	RIDE_LIGHT_FALLOFF = 0.45,
	RIDE_LIGHT_INTENSITY = 0.8,
	RIDE_LIGHT_COLOUR = { 0.72, 0.8, 1 },
	-- 当前段之外再预铺三段，保证正常镜头里能看到连续路线。
	TRACK_LOOKAHEAD = 4,
	TRACK_RETAIN_BEHIND = 1,
	TRACK_FADE_DURATION = 0.65,
	TRACK_FADE_STAGGER = 0.2,
	-- 自动测试使用逐帧乘客诊断，并要求整条实机路线多数贴地。
	TEST_MAX_RIDE_VERTICAL_ERROR = 0.25,
	TEST_MIN_GROUND_RATIO = 0.5,
	TEST_CLIENT_PROBE_TIMEOUT = 6,
	-- 游戏内自动测试分帧执行，切夜状态使用有限轮询，路线规划前额外留出冷却时间。
	TEST_STEP_DELAY = 0.75,
	TEST_HEAVY_STEP_DELAY = 2,
	TEST_NIGHT_SYNC_INTERVAL = 0.1,
	TEST_NIGHT_SYNC_ATTEMPTS = 30,
	MAX_DURATION = 600,
}
