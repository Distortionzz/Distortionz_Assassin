# Distortionz Assassin

> Illegal assassination contract job for Qbox/FiveM — target dispatch, contract acceptance NUI, weapon handout, escalating police alerts, and tiered payouts.

![FiveM](https://img.shields.io/badge/FiveM-cerulean-yellow?style=flat-square&labelColor=181b20)
![Qbox](https://img.shields.io/badge/Qbox-required-red?style=flat-square&labelColor=dfb317)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square)
![Version](https://img.shields.io/github/v/release/Distortionzz/Distortionz_Assassin?style=flat-square&color=d4aa62&label=version)

---

## Overview

Underground contract assassin job. Players accept hits via a contact ped, get dispatched to a target spawn (standing, walking, or building), and earn payouts scaled by speed, stealth, and headshot accuracy.

## Features

- Random target spawn types (standing, walking, building entry)
- Contract acceptance NUI with target intel and payout preview
- Optional weapon handout per contract tier
- Escalating police alert chance based on collateral / stealth breaks
- Cooldowns + max active contracts per player
- Protected-ped flagging so other distortionz scripts skip the contact ped

## Dependencies

| Resource | Required | Purpose |
|---|---|---|
| `qbx_core` | yes | Player data, money |
| `ox_lib` | yes | Callbacks, notify fallback |
| `ox_target` | yes | Contact ped interaction |
| `ox_inventory` | yes | Weapon handout, item rewards |
| `distortionz_notify` | optional | Branded notifications |

## Installation

```cfg
ensure distortionz_assassin
```

## Configuration

See [`config.lua`](config.lua) for contact ped location, target spawn pools, payout tiers, weapon handout, and police alert thresholds.

## Credits

- **Author:** Distortionz
- **Framework:** [Qbox Project](https://github.com/Qbox-project)

## License

MIT — see [LICENSE](LICENSE).
