Config = {}

Config.Debug = false

Config.ResourceName = 'distortionz_assassin'
Config.CurrentVersion = '1.1.1'

Config.VersionCheck = {
    enabled = false,

    -- Change this to your real GitHub raw version.json URL when uploaded.
    url = 'https://raw.githubusercontent.com/YOUR_GITHUB/YOUR_REPO/main/distortionz_assassin/version.json',

    checkOnStart = true
}

Config.Notify = {
    title = 'Assassin Contracts',
    useDistortionzNotify = true
}

Config.Cooldown = {
    enabled = true,
    seconds = 20 * 60
}

Config.Boss = {
    model = 'g_m_m_chigoon_02',
    coords = vector4(144.41, -2203.39, 4.69, 355.0),

    scenario = 'WORLD_HUMAN_SMOKING',

    blip = {
        enabled = true,
        sprite = 310,
        color = 1,
        scale = 0.85,
        label = 'Assassin Boss',
        shortRange = true
    },

    target = {
        icon = 'fa-solid fa-skull',
        label = 'Open Contract Board',
        distance = 2.0
    }
}

Config.Contract = {
    requireItem = false,
    requiredItem = 'burnerphone',
    removeRequiredItem = false,

    rewardItem = 'black_money',

    reward = {
        min = 2500,
        max = 6500
    },

    drivingBonus = {
        enabled = true,
        min = 500,
        max = 1500
    },

    timeLimit = 25 * 60,

    useSearchRadius = true,
    searchRadius = 120.0,

    -- Makes the search area follow the target while they move.
    movingSearchArea = true,

    -- How often the search area updates in milliseconds.
    -- Lower = smoother. Higher = more mystery.
    movingSearchUpdateInterval = 3000,

    -- Keep false for realistic contracts.
    -- Set true for testing.
    showExactTargetBlip = false
}

Config.Police = {
    enabled = true,
    alertChance = 35,

    jobs = {
        police = true,
        sheriff = true,
        state = true
    },

    alertBlip = {
        sprite = 432,
        color = 1,
        scale = 1.1,
        duration = 60
    }
}

Config.Target = {
    relationshipGroup = 'DISTORTIONZ_ASSASSIN_TARGET',

    aliases = {
        'The Accountant',
        'The Courier',
        'The Collector',
        'Ghost Runner',
        'Red Jackal',
        'The Dealer',
        'Loose Ends',
        'The Witness',
        'The Informant',
        'The Cleaner',
        'Black Ledger',
        'The Snake'
    },

    models = {
        'a_m_m_business_01',
        'a_m_m_eastsa_02',
        'a_m_m_farmer_01',
        'a_m_m_genfat_01',
        'a_m_m_hillbilly_01',
        'a_m_m_og_boss_01',
        'a_m_m_soucent_03',
        'a_m_y_business_02',
        'a_m_y_soucent_01',
        'g_m_y_mexgang_01',
        'g_m_y_lost_01'
    },

    weapons = {
        'WEAPON_PISTOL',
        'WEAPON_SNSPISTOL',
        'WEAPON_KNIFE',
        'WEAPON_BAT'
    },

    health = 200,
    armor = 50,
    accuracy = 35,

    canFightBack = true,

    behaviors = {
        standing = true,
        walking = true,
        driving = true,
        building = true
    },

    drivingVehicles = {
        'primo',
        'stanier',
        'asea',
        'ingot',
        'emperor',
        'tailgater'
    },

    standingScenarios = {
        'WORLD_HUMAN_SMOKING',
        'WORLD_HUMAN_STAND_MOBILE',
        'WORLD_HUMAN_DRUG_DEALER',
        'WORLD_HUMAN_HANG_OUT_STREET'
    },

    buildingScenarios = {
        'WORLD_HUMAN_STAND_MOBILE',
        'WORLD_HUMAN_SMOKING',
        'WORLD_HUMAN_LEANING'
    }
}

Config.TargetSpawns = {
    {
        label = 'Davis Liquor Store',
        coords = vector4(115.35, -1285.25, 28.26, 120.0),
        behaviors = { 'standing', 'walking' }
    },
    {
        label = 'Rancho Apartment Block',
        coords = vector4(390.77, -1864.62, 26.72, 45.0),
        behaviors = { 'standing', 'walking', 'building' }
    },
    {
        label = 'Mirror Park Alley',
        coords = vector4(1112.68, -645.47, 56.81, 283.0),
        behaviors = { 'standing', 'walking' }
    },
    {
        label = 'La Mesa Warehouse',
        coords = vector4(930.52, -1558.78, 30.74, 92.0),
        behaviors = { 'standing', 'walking', 'building' }
    },
    {
        label = 'Vespucci Canals',
        coords = vector4(-1146.37, -1458.22, 4.38, 33.0),
        behaviors = { 'standing', 'walking' }
    },
    {
        label = 'Strawberry Motel',
        coords = vector4(308.73, -209.55, 54.09, 74.0),
        behaviors = { 'standing', 'walking', 'building' }
    },
    {
        label = 'Sandy Shores Trailer',
        coords = vector4(1907.05, 3710.25, 32.77, 208.0),
        behaviors = { 'standing', 'walking', 'building' }
    },
    {
        label = 'Paleto Side Street',
        coords = vector4(-105.43, 6346.87, 31.49, 45.0),
        behaviors = { 'standing', 'walking' }
    },
    {
        label = 'Airport Service Road',
        coords = vector4(-1032.35, -2734.44, 20.16, 235.0),
        behaviors = { 'driving' }
    },
    {
        label = 'Great Ocean Highway',
        coords = vector4(-2165.83, 4283.37, 49.12, 143.0),
        behaviors = { 'driving' }
    },
    {
        label = 'East Vinewood Road',
        coords = vector4(787.76, -317.05, 59.94, 75.0),
        behaviors = { 'driving', 'walking' }
    },
    {
        label = 'Downtown Construction',
        coords = vector4(-139.91, -949.32, 29.31, 160.0),
        behaviors = { 'standing', 'walking', 'building' }
    }
}

Config.IntelLines = {
    standing = {
        'Target was last seen posted up near %s.',
        'The mark is staying low around %s.',
        'Intel says the target is standing around %s waiting for someone.'
    },

    walking = {
        'Target is moving on foot near %s.',
        'The mark is walking around %s. Keep your eyes open.',
        'Intel says the target keeps pacing near %s.'
    },

    driving = {
        'Target is mobile near %s. Expect a vehicle.',
        'The mark is driving around %s.',
        'Intel says the target is on wheels near %s.'
    },

    building = {
        'Target may be inside or near a building around %s.',
        'The mark is hiding around %s. Check corners and interiors.',
        'Intel says the target is tucked away near %s.'
    }
}