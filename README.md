# ☠️ distortionz_assassin

Premium illegal assassin contract job for FiveM Qbox/Ox servers.

`distortionz_assassin` is part of the **Distortionz illegal job ecosystem**. Players meet an underground Assassin Boss, receive contract intel through a premium NUI, track down a target, eliminate them, and receive dirty money through `ox_inventory`.

---

## 📌 Overview

This resource creates a high-end illegal contract system for roleplay servers. It is built around immersive contract hunting, dirty money payouts, police risk, cooldowns, target behaviors, and a premium Distortionz-style user interface.

Players do not just press a button and receive money. They receive a contract, search a marked area, track a moving or hidden target, complete the hit, and then get paid in `black_money`.

---

## ✨ Features

### 🧾 Contract System
- Premium NUI contract board
- Target alias system
- Random target zones
- Random ped models
- Randomized contract reward
- Dirty money payout
- Contract expiration timer
- Cooldown after success or failure

### 🎯 Target Behavior
Targets can spawn with different behaviors:

- 🧍 Standing
- 🚶 Walking
- 🚗 Driving
- 🏚️ Building / hidden nearby

### 🗺️ Search Area System
- Search radius blip
- Center search marker
- Optional exact target blip for testing
- Moving search area that follows the target
- Configurable update interval

### 🚨 Police Risk
- Configurable police alert chance
- Police-only alert blip
- Job-based police alert filtering
- Alert location based on contract area

### 💸 Rewards
- Uses `ox_inventory`
- Pays dirty money item:
  - `black_money`
- Driving contracts can pay bonus rewards
- Reward range is fully configurable

### 🧠 Premium UI
- Dark transparent Distortionz theme
- Red glow accents
- Contract preview board
- Active contract overlay
- Live timer
- Reward display
- Target zone display
- Behavior display

### 🔔 Notifications
- Uses `distortionz_notify` if running
- Falls back to `ox_lib` notifications

### 🧩 Compatibility
- Qbox compatible
- Ox compatible
- ox_lib
- ox_target
- ox_inventory
- Optional Distortionz Notify support

### 🌐 Version Checking
- GitHub `version.json` support
- Configurable version check URL
- Console update notifications

---

## 📁 Resource Name

```txt
distortionz_assassin
