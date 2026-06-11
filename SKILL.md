---
name: p-ai-design-system-swiftui
description: P-AI Design System cho SwiftUI — purple as the new neutral. Dùng khi build/sửa UI trong app này để giữ đúng brand: tokens, components, voice & tone.
---

# P-AI Design System — SwiftUI

P-AI là AI product (chat assistant, text writer, image generator) với identity **royal purple**. Purple là *the new neutral*: lavender wash thay cho gray, royal purple cho mọi action.

## Quy tắc bắt buộc

1. **Không hardcode màu/spacing/radius** — luôn dùng tokens trong `DesignSystem/Tokens/`:
   - Màu: `PAIColor.brand` (royal purple #5B21B6), `PAIColor.brandAccent` (violet #8B5CF6), `PAIColor.surfaceTint` (lavender #EDE9FE), `PAIColor.textStrong` (ink #1A1625), `PAIColor.surfacePage` (paper #FAF9FC). Ưu tiên semantic alias, không dùng raw scale trừ khi cần.
   - Spacing: `PAISpace.s1...s12` (4px grid). Cards pad 16–24, sections cách 32–48.
   - Radius: `PAIRadius.lg` (14) cho card/chip, `.xl/.xxl` (20/28) cho sheet, `.composer` (22), Capsule cho buttons.
   - Motion: `PAIDuration.fast/base` (0.12/0.20s), easeOut, press scale 0.97. Không bounce.

2. **Shadow tím, không đen**: `.paiShadowSoft()` cho cards, `.paiShadowBrand()` cho primary button. Card không có border — shadow thay border.

3. **Gradient violet→fuchsia (`PAIGradient.ai`) CHỈ cho AI moments**: avatar orb, hero glow. Cấm dùng trên text body/surface chức năng. Nền page light: `PAIGradient.page` (lavender→paper).

4. **Components có sẵn** (`DesignSystem/Components/`) — dùng lại, đừng tạo mới trùng:
   - `PAIPrimaryButtonStyle` / `PAIGhostButtonStyle` — pill, glow, press scale
   - `PAICard { }` — trắng, radius lớn, shadow mềm
   - `PAIChip(icon:title:action:)` — frosted, icon trong ô brand hue
   - `PAIAvatarOrb(size:)` — orb gradient AI
   - `PAIComposer(text:onSend:)` — input pill + nút send tròn ↑
   - `PAIEyebrow(text:)` — label UPPERCASE 12px wide tracking

5. **Typography**: `PAIFont.display/h1/h2/h3/lg/body/sm/xs/mono`. Display dùng `.tracking(PAITracking.tight)`. Hiện là system font placeholder — khi bundle Epilogue, chỉ sửa `PAITypography.swift`.

## Voice & tone (copy trong UI)

- Sentence case mọi nơi (button, label, list). UPPERCASE chỉ cho eyebrow.
- Placeholder: "Type to start a new chat…" — ellipsis cuối.
- Status copy numeric-first: "74 remaining credits" (không viết tắt "74 cr.").
- Assistant nói ngôi thứ nhất, ấm: "Let me know what you want to create today."
- Không emoji trong product UI. Feature naming lowercase: "AI text writer".

## Icons

SF Symbols outline (tương đương Lucide ~2px stroke). Filled circle chỉ cho primary send (↑). Icon màu ink trên light, trắng trên brand/dark.

## Nguồn gốc tokens

Map 1:1 từ web design system tại `~/Documents/p-ai-design-system/tokens/*.css`. Khi sửa token, sync cả 2 phía.
