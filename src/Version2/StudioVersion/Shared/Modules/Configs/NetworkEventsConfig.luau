local NetworkEventsConfig = {}

NetworkEventsConfig["DataEvent"] = {
	Name = "DataEvent",
	IsReliable = false,
	Middlewares = {
		ServerInbound = {
			RateLimiter = { Order = 1, MaxFires = 30 },
		},
	},
}

NetworkEventsConfig["WeaponActionEvent"] = {
	Name = "WeaponActionEvent",
	IsReliable = false,
	Middlewares = {
		ServerInbound = {
			RateLimiter = { Order = 1, MaxFires = 30 },
		},
	},
}
NetworkEventsConfig["WeaponFireEvent"] = {
	Name = "WeaponFireEvent",
	IsReliable = false,
	Middlewares = {
		ServerInbound = {
			RateLimiter = { Order = 1, MaxFires = 30 },
		},
	},
}
NetworkEventsConfig["PlayerActionEvent"] = {
	Name = "PlayerActionEvent",
	IsReliable = false,
	Middlewares = {
		ServerInbound = {
			RateLimiter = { Order = 1, MaxFires = 30 },
		},
	},
}

return NetworkEventsConfig
