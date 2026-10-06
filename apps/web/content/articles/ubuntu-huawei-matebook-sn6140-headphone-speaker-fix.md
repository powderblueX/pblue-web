---
title: Ubuntu / Huawei MateBook 16s 有线耳机与扬声器同时出声问题排查与修复
description: Ubuntu 下 Huawei MateBook 16s 有线耳机与扬声器同时出声问题的排查与修复记录。
publishedAt: '2026-09-25'
tags:
  - Ubuntu
  - 音频
  - Huawei MateBook 16s
draft: false
---

> 适用场景：Ubuntu 下插入 3.5 mm 有线耳机后，耳机正常出声，但笔记本内置扬声器仍然同时播放；在系统设置中选择 `Headphones`、在 `alsamixer` 中启用 `Auto-Mute` 后仍无法解决。

本文记录一次在 Huawei MateBook 16s 类设备上的完整排障过程，包括问题定位、硬件信息确认、HDA Codec 路由测试，以及最终通过 systemd 服务实现自动切换耳机 / 扬声器。

---

## 1. 问题现象

系统可以正常识别有线耳机。

在：

```text
Settings -> Sound -> Output
```

中可以看到：

```text
Speaker
Headphones
HDMI / DisplayPort
```

选择 `Headphones` 后：

- 耳机有声音；
- 笔记本内置扬声器仍然有声音。

也就是说，实际状态类似：

```text
应用程序
   ↓
PipeWire
   ↓
Headphones
   ↓
HDA Codec
   ├── Headphone   有声音
   └── Speaker     仍然有声音
```

正常行为应该是：

```text
插入耳机
   ├── Headphone   ON
   └── Speaker     OFF
```

---

# 2. 第一阶段：检查 Auto-Mute

首先进入 ALSA Mixer：

```bash
alsamixer
```

如果默认界面顶部显示：

```text
Card: PipeWire
Chip: PipeWire
```

说明当前看到的是 PipeWire 虚拟 Mixer，而不是实际声卡。

按：

```text
F6
```

选择：

```text
default:0  sof-hda-dsp
```

然后按：

```text
F5
```

显示所有控件。

找到：

```text
Auto-Mute Mode
```

将：

```text
Disabled
```

改为：

```text
Enabled
```

此时在本机上可以看到：

```text
Auto-Mute = Enabled
Headphone = OO
Speaker   = MM
```

其中：

```text
OO = 未静音
MM = 已静音
```

按理来说，此时扬声器应该已经关闭。

但实际测试发现：

```text
alsamixer:
Speaker = MM

实际：
笔记本扬声器仍然在出声
```

因此可以判断：

> 问题已经不是普通的 PipeWire 输出选择或 ALSA Auto-Mute 设置，而更可能发生在更底层的 HDA Codec 硬件路由。

---

# 3. 获取硬件和 Codec 信息

为了继续定位，执行：

```bash
echo "===== Kernel ====="
uname -r

echo
echo "===== Machine ====="
cat /sys/class/dmi/id/product_name
cat /sys/class/dmi/id/board_name 2>/dev/null

echo
echo "===== Audio PCI ====="
lspci -nnvv -s 00:1f.3 | grep -E 'Audio|Multimedia|Subsystem'

echo
echo "===== HDA codecs ====="
for f in /proc/asound/card*/codec#*; do
    echo "---- $f ----"
    grep -E '^Codec:|^Subsystem Id:' "$f"
done
```

本机结果：

```text
===== Kernel =====
7.0.0-34-generic

===== Machine =====
CREF-XX
CREF-XX-PCB

===== Audio PCI =====
00:1f.3 Multimedia audio controller:
Intel Corporation Alder Lake PCH-P High Definition Audio Controller [8086:51c8]

Subsystem:
Huawei Technologies Co., Ltd. Device [19e5:3e5f]

===== HDA codecs =====
Codec: Conexant SN6140
Subsystem Id: 0x19e53281

Codec: Intel Alderlake-P HDMI
Subsystem Id: 0x80860101
```

因此实际音频硬件为：

```text
CPU / PCH      : Intel Alder Lake PCH-P
ALSA card      : sof-hda-dsp
Codec          : Conexant SN6140
Codec Subsystem: 0x19e53281
Vendor ID      : 0x14f11f87
```

---

# 4. 查看 HDA Codec 节点

继续检查关键 Pin：

```bash
grep -A20 'Node 0x16' /proc/asound/card0/codec#0
```

得到：

```text
Node 0x16 [Pin Complex]
Pincap 0x0001001c: OUT HP EAPD Detect
EAPD 0x2: EAPD

Pin Default 0x03211040:
[Jack] HP Out at Ext Left

Pin-ctls: 0xc0: OUT HP

Connection: 2
   0x10* 0x11
```

说明：

```text
0x16 = 外接耳机 Pin
```

再检查：

```bash
grep -A20 'Node 0x17' /proc/asound/card0/codec#0
```

得到：

```text
Node 0x17 [Pin Complex]
Pincap 0x00010010: OUT EAPD

EAPD 0x2: EAPD

Pin Default 0x91170110:
[Fixed] Speaker at Int Rear

Connection: 2
   0x10 0x11*
```

说明：

```text
0x17 = 内置扬声器 Pin
```

同时查看 GPIO：

```bash
grep -i -A10 -B2 'GPIO' /proc/asound/card0/codec#0
```

其中：

```text
GPIO: io=5

IO[0]: enable=1, dir=1, data=1
IO[1]: enable=1, dir=1, data=0
IO[4]: enable=1, dir=0, data=0
```

---

# 5. 为什么 Speaker 已经是 MM，物理扬声器仍然响？

这一步是整个排障的关键。

在 `alsamixer` 中：

```text
Speaker = MM
```

只能说明 ALSA 暴露出来的 Mixer 控件处于静音状态。

但这台机器上，真正决定物理扬声器是否工作的还包括：

```text
CONNECT_SEL
EAPD
GPIO
```

其中 EAPD 可以理解为：

```text
External Amplifier Power Down
```

也就是外部功放控制。

在耳机插入后，我们观察到：

```text
Node 0x17:
EAPD 0x2: EAPD
```

也就是说：

> 虽然 ALSA Mixer 已经认为 Speaker 被静音，但扬声器功放仍然处于启用状态。

因此物理扬声器仍然会播放。

---

# 6. 安装 hda-verb

Ubuntu 可以通过 `alsa-tools` 提供 `hda-verb`：

```bash
sudo apt install alsa-tools
```

检查：

```bash
command -v hda-verb
```

正常应输出类似：

```text
/usr/bin/hda-verb
```

`hda-verb` 可以直接向 HDA Codec 发送 Verb，用于读取或修改 Codec 节点状态。

---

# 7. 最小化测试：关闭扬声器 EAPD

保持耳机插入，并播放音频。

执行：

```bash
sudo hda-verb /dev/snd/hwC0D0 0x17 0x70c 0x0
```

本机输出：

```text
nid = 0x17, verb = 0x70c, param = 0x0
value = 0x0
```

执行后：

```text
耳机：正常有声音
扬声器：立即停止出声
```

这一步几乎可以直接确认：

> 问题的核心就是 Speaker 节点 `0x17` 的 EAPD 没有随着耳机插入被正确关闭。

但此时如果拔掉耳机：

```text
耳机     已拔出
Speaker  没有声音
```

这是因为我们只是手动把 EAPD 改成了 `0`，系统并不会自动重新打开它。

所以还需要实现完整的 Speaker / Headphone 路由切换。

---

# 8. 手动验证完整 Speaker 模式

拔掉耳机后执行：

```bash
sudo hda-verb /dev/snd/hwC0D0 0x01 0x717 0x2
sudo hda-verb /dev/snd/hwC0D0 0x01 0x716 0x2
sudo hda-verb /dev/snd/hwC0D0 0x16 0x701 0x1
sudo hda-verb /dev/snd/hwC0D0 0x17 0x70c 0x2
sudo hda-verb /dev/snd/hwC0D0 0x01 0x715 0x2
```

对应含义：

```text
GPIO direction = 0x2
GPIO mask      = 0x2
CONNECT_SEL    = 1
Speaker EAPD   = 2
GPIO data      = 0x2
```

测试结果：

```text
只从笔记本扬声器播放
```

符合预期。

---

# 9. 手动验证完整 Headphone 模式

插入耳机后执行：

```bash
sudo hda-verb /dev/snd/hwC0D0 0x01 0x717 0x2
sudo hda-verb /dev/snd/hwC0D0 0x01 0x716 0x2
sudo hda-verb /dev/snd/hwC0D0 0x16 0x701 0x0
sudo hda-verb /dev/snd/hwC0D0 0x17 0x70c 0x0
sudo hda-verb /dev/snd/hwC0D0 0x01 0x715 0x0
```

对应：

```text
GPIO direction = 0x2
GPIO mask      = 0x2
CONNECT_SEL    = 0
Speaker EAPD   = 0
GPIO data      = 0
```

测试结果：

```text
耳机有声音
笔记本扬声器无声音
```

符合预期。

---

# 10. 验证耳机插拔检测

下一步检查 HDA Codec 能否准确知道耳机是否插入。

耳机插着时：

```bash
sudo hda-verb /dev/snd/hwC0D0 0x16 0xf09 0
```

输出：

```text
nid = 0x16, verb = 0xf09, param = 0x0
value = 0x80000000
```

拔掉耳机：

```bash
sudo hda-verb /dev/snd/hwC0D0 0x16 0xf09 0
```

输出：

```text
nid = 0x16, verb = 0xf09, param = 0x0
value = 0x0
```

Linux HDA 定义中：

```text
0xf09 = GET_PIN_SENSE
```

其 bit 31：

```text
0x80000000
```

表示：

```text
Presence Detect = 1
```

因此：

```text
value & 0x80000000 != 0
    → 耳机已插入

value & 0x80000000 == 0
    → 耳机未插入
```

这意味着自动切换所需的检测条件已经完全具备。

---

# 11. 最终自动修复方案

最终目标：

```text
检测 0x16 Pin Sense
          │
          ├── 有耳机
          │      ↓
          │   Headphone Mode
          │
          └── 无耳机
                 ↓
              Speaker Mode
```

同时，为避免 ALSA card 编号发生变化，脚本不固定依赖：

```text
/dev/snd/hwC0D0
```

而是根据：

```text
Vendor Id:    0x14f11f87
Subsystem Id: 0x19e53281
```

自动寻找实际 HDA 设备。

---

# 12. 创建自动修复脚本

执行：

```bash
sudo tee /usr/local/sbin/huawei-sn6140-audio-fix >/dev/null <<'EOF'
#!/usr/bin/env bash

set -u

HDA_VERB="/usr/bin/hda-verb"

# 仅允许当前验证过的 Codec 运行。
VENDOR_ID="0x14f11f87"
SUBSYSTEM_ID="0x19e53281"

POLL_INTERVAL=1
REFRESH_INTERVAL=10

find_hda_device() {
    local codec card addr dev

    for codec in /proc/asound/card*/codec#*; do
        [[ -r "$codec" ]] || continue

        grep -qx "Vendor Id: $VENDOR_ID" "$codec" || continue
        grep -qx "Subsystem Id: $SUBSYSTEM_ID" "$codec" || continue

        card="${codec#/proc/asound/card}"
        card="${card%%/*}"

        addr="$(awk '/^Address:/ {print $2; exit}' "$codec")"

        [[ "$card" =~ ^[0-9]+$ ]] || continue
        [[ "$addr" =~ ^[0-9]+$ ]] || continue

        dev="/dev/snd/hwC${card}D${addr}"

        if [[ -e "$dev" ]]; then
            printf '%s\n' "$dev"
            return 0
        fi
    done

    return 1
}

verb() {
    "$HDA_VERB" "$DEV" "$1" "$2" "$3" >/dev/null 2>&1
}

set_speaker_mode() {
    verb 0x01 0x717 0x2 &&
    verb 0x01 0x716 0x2 &&
    verb 0x16 0x701 0x1 &&
    verb 0x17 0x70c 0x2 &&
    verb 0x01 0x715 0x2
}

set_headphone_mode() {
    verb 0x01 0x717 0x2 &&
    verb 0x01 0x716 0x2 &&
    verb 0x16 0x701 0x0 &&
    verb 0x17 0x70c 0x0 &&
    verb 0x01 0x715 0x0
}

get_mode() {
    local output value

    output="$("$HDA_VERB" "$DEV" 0x16 0xf09 0 2>/dev/null)" || return 1

    value="$(awk '/value =/ {print $3; exit}' <<<"$output")"

    [[ "$value" =~ ^0x[0-9a-fA-F]+$ ]] || return 1

    if (( value & 0x80000000 )); then
        printf '%s\n' "headphone"
    else
        printf '%s\n' "speaker"
    fi
}

if [[ ! -x "$HDA_VERB" ]]; then
    echo "hda-verb not found: $HDA_VERB" >&2
    exit 1
fi

DEV=""
PREVIOUS_MODE=""
REFRESH_COUNTER=0

while true; do

    # 如果设备还没找到，或者设备在休眠恢复后重新编号，则重新扫描。
    if [[ -z "$DEV" || ! -e "$DEV" ]]; then
        DEV="$(find_hda_device || true)"

        if [[ -z "$DEV" ]]; then
            sleep 2
            continue
        fi

        echo "Huawei SN6140 codec found: $DEV"
        PREVIOUS_MODE=""
        REFRESH_COUNTER=0
    fi

    MODE="$(get_mode || true)"

    if [[ -z "$MODE" ]]; then
        DEV=""
        PREVIOUS_MODE=""
        sleep 2
        continue
    fi

    REFRESH_COUNTER=$((REFRESH_COUNTER + 1))

    # 状态变化时立即设置；
    # 同时每隔一段时间重新应用，避免 SOF / runtime PM 恢复后寄存器被重置。
    if [[ "$MODE" != "$PREVIOUS_MODE" ]] ||
       (( REFRESH_COUNTER >= REFRESH_INTERVAL )); then

        if [[ "$MODE" == "headphone" ]]; then
            if ! set_headphone_mode; then
                DEV=""
                PREVIOUS_MODE=""
                sleep 1
                continue
            fi
        else
            if ! set_speaker_mode; then
                DEV=""
                PREVIOUS_MODE=""
                sleep 1
                continue
            fi
        fi

        if [[ "$MODE" != "$PREVIOUS_MODE" ]]; then
            echo "Audio route switched to: $MODE"
        fi

        PREVIOUS_MODE="$MODE"
        REFRESH_COUNTER=0
    fi

    sleep "$POLL_INTERVAL"
done
EOF

sudo chmod 755 /usr/local/sbin/huawei-sn6140-audio-fix
```

---

# 13. 创建 systemd 服务

执行：

```bash
sudo tee /etc/systemd/system/huawei-sn6140-audio-fix.service >/dev/null <<'EOF'
[Unit]
Description=Huawei MateBook SN6140 speaker/headphone routing fix
After=sound.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/huawei-sn6140-audio-fix
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
```

重新加载 systemd：

```bash
sudo systemctl daemon-reload
```

启用并立即启动：

```bash
sudo systemctl enable --now huawei-sn6140-audio-fix.service
```

---

# 14. 查看服务状态

执行：

```bash
systemctl status huawei-sn6140-audio-fix.service --no-pager
```

正常应看到：

```text
Active: active (running)
```

查看日志：

```bash
journalctl -u huawei-sn6140-audio-fix.service -n 30 --no-pager
```

正常日志类似：

```text
Huawei SN6140 codec found: /dev/snd/hwC0D0
Audio route switched to: speaker
Audio route switched to: headphone
```

实时查看：

```bash
sudo journalctl -fu huawei-sn6140-audio-fix.service
```

此时插拔耳机可以观察到：

```text
插入：
Audio route switched to: headphone

拔出：
Audio route switched to: speaker
```

---

# 15. 最终结果

修复完成后：

## 未插耳机

```text
Speaker    ON
Headphone  OFF
```

声音只从笔记本扬声器播放。

## 插入耳机

```text
Speaker    OFF
Headphone  ON
```

声音只从有线耳机播放。

## 拔掉耳机

系统自动重新切换到 Speaker 模式。

整个切换过程大约在：

```text
0 ~ 1 秒
```

内完成。

重启 Ubuntu 后 systemd 服务会自动启动，不需要再次手动运行 `hda-verb`。

---

# 16. 最终问题分析

整个问题可以概括为：

```text
PipeWire
   │
   │ 输出设备选择正常
   ↓
ALSA
   │
   │ Auto-Mute 正常
   │ Speaker 显示 MM
   ↓
SOF / HDA
   │
   │ Hardware Route 未完整切换
   ↓
Conexant SN6140
   │
   ├── CONNECT_SEL
   ├── EAPD
   └── GPIO
          ↓
     物理扬声器功放
```

真正的问题不是：

```text
Ubuntu 不认识耳机
```

因为：

```text
GET_PIN_SENSE:
插入 = 0x80000000
拔出 = 0x0
```

说明耳机检测完全正常。

问题也不是：

```text
PipeWire 同时把音频发送给两个设备
```

因为手动关闭 Speaker EAPD 后，耳机仍然可以正常播放。

真正的问题是：

> 耳机插入后，Linux 当前的 HDA 路由没有为这台 Huawei + Conexant SN6140 完整同步 CONNECT_SEL、EAPD 和 GPIO 状态，导致内置扬声器物理功放仍保持开启。

最终 workaround 通过监听耳机 Pin Sense，并在耳机插拔时主动切换三组硬件状态解决问题。

---

# 17. 本机验证的路由状态

最终验证得到：

| 模式 | 0x16 CONNECT_SEL | 0x17 EAPD | GPIO1 |
|---|---:|---:|---:|
| Speaker | `1` | `2` | `2` |
| Headphone | `0` | `0` | `0` |

对应命令：

### Speaker

```bash
sudo hda-verb /dev/snd/hwC0D0 0x01 0x717 0x2
sudo hda-verb /dev/snd/hwC0D0 0x01 0x716 0x2
sudo hda-verb /dev/snd/hwC0D0 0x16 0x701 0x1
sudo hda-verb /dev/snd/hwC0D0 0x17 0x70c 0x2
sudo hda-verb /dev/snd/hwC0D0 0x01 0x715 0x2
```

### Headphone

```bash
sudo hda-verb /dev/snd/hwC0D0 0x01 0x717 0x2
sudo hda-verb /dev/snd/hwC0D0 0x01 0x716 0x2
sudo hda-verb /dev/snd/hwC0D0 0x16 0x701 0x0
sudo hda-verb /dev/snd/hwC0D0 0x17 0x70c 0x0
sudo hda-verb /dev/snd/hwC0D0 0x01 0x715 0x0
```

---

# 18. HDA Verb 简单说明

本文实际用到的 Verb：

| Verb | Linux 定义 | 作用 |
|---|---|---|
| `0xf09` | `GET_PIN_SENSE` | 获取耳机插入状态 |
| `0x701` | `SET_CONNECT_SEL` | 选择输入连接 / DAC 路由 |
| `0x70c` | `SET_EAPD_BTLENABLE` | 设置 EAPD / 外部功放 |
| `0x715` | `SET_GPIO_DATA` | 设置 GPIO 数据 |
| `0x716` | `SET_GPIO_MASK` | 设置 GPIO Mask |
| `0x717` | `SET_GPIO_DIRECTION` | 设置 GPIO 方向 |

其中 `GET_PIN_SENSE` 的 bit 31：

```text
AC_PINSENSE_PRESENCE = 1 << 31
```

用于表示插孔 Presence。

---

# 19. 安全说明

这个方案：

- 不修改 BIOS；
- 不刷写声卡固件；
- 不修改 Codec 永久配置；
- 不更换内核；
- 不修改 PipeWire 配置；
- 不替换 SOF 驱动。

`hda-verb` 修改的是当前运行状态下的 HDA Codec 寄存器。

如果服务停止，或者机器重启，而不再启动该服务，就不会继续应用 workaround。

另外脚本限定：

```text
Vendor ID     = 0x14f11f87
Subsystem ID  = 0x19e53281
```

因此本文脚本**不是 Huawei MateBook 全系列通用脚本**。

不同机型即使同样使用 SN6140，其：

```text
Node ID
GPIO
CONNECT_SEL
Subsystem ID
```

都有可能不同。

在其他机器上使用前，应先自行确认：

```bash
cat /proc/asound/card*/codec#*
```

中的实际 Codec 拓扑。

---

# 20. 如何撤销修复

如果未来 Linux 内核已经原生支持这台机器，可以删除 workaround。

停止并禁用服务：

```bash
sudo systemctl disable --now huawei-sn6140-audio-fix.service
```

删除 service：

```bash
sudo rm /etc/systemd/system/huawei-sn6140-audio-fix.service
```

删除脚本：

```bash
sudo rm /usr/local/sbin/huawei-sn6140-audio-fix
```

重新加载：

```bash
sudo systemctl daemon-reload
```

然后重启：

```bash
sudo reboot
```

即可恢复为系统默认音频处理逻辑。

---

# 21. 快速诊断命令汇总

如果遇到类似问题，可以先执行：

```bash
echo "===== Kernel ====="
uname -r

echo
echo "===== DMI ====="
for f in \
    sys_vendor \
    product_name \
    product_version \
    board_vendor \
    board_name \
    board_version
do
    printf "%-18s: " "$f"
    cat "/sys/class/dmi/id/$f" 2>/dev/null
done

echo
echo "===== Audio PCI ====="
lspci -nn | grep -iE 'audio|multimedia'

echo
echo "===== Codecs ====="
for f in /proc/asound/card*/codec#*; do
    echo "---- $f ----"
    grep -E '^Codec:|^Vendor Id:|^Subsystem Id:' "$f"
done
```

进一步检查：

```bash
grep -A20 'Node 0x16' /proc/asound/card0/codec#0
grep -A20 'Node 0x17' /proc/asound/card0/codec#0
grep -i -A10 -B2 'GPIO' /proc/asound/card0/codec#0
```

检查耳机检测：

```bash
sudo hda-verb /dev/snd/hwC0D0 0x16 0xf09 0
```

---

# 22. 环境

本文实际验证环境：

```text
OS            : Ubuntu
Kernel        : 7.0.0-34-generic
Machine       : HUAWEI CREF-XX
Product Ver.  : M1010
Board         : CREF-XX-PCB
Audio         : Intel Alder Lake PCH-P
ALSA          : sof-hda-dsp
Codec         : Conexant SN6140
Vendor ID     : 0x14f11f87
Subsystem ID  : 0x19e53281
```

最终结果：

```text
插入耳机 → 仅耳机出声
拔出耳机 → 自动恢复笔记本扬声器
重启系统 → 自动修复继续生效
```

---

## 参考

Linux 内核中的 HDA Verb 定义可以在：

```text
include/sound/hda_verbs.h
```

中查看。

本文涉及的关键定义包括：

```c
AC_VERB_GET_PIN_SENSE          0x0f09
AC_VERB_SET_CONNECT_SEL        0x701
AC_VERB_SET_EAPD_BTLENABLE     0x70c
AC_VERB_SET_GPIO_DATA          0x715
AC_VERB_SET_GPIO_MASK          0x716
AC_VERB_SET_GPIO_DIRECTION     0x717

AC_PINSENSE_PRESENCE           (1 << 31)
```

建议在其他机型上应用本文方案之前，先根据自身 `/proc/asound/card*/codec#*` 输出验证 Codec、Node 和 GPIO 拓扑，而不要直接照搬寄存器参数。
