# Research Report: USDZ — tap mở cửa xe, có cần thêm file USDZ không?

> Ngày research: 2026-06-12 · Nguồn: 3 WebSearch + mổ xẻ trực tiếp `Resources/car_model.usdz` bằng usd-core

## TL;DR (Executive Summary)

**KHÔNG cần tạo thêm file USDZ thứ hai.** 1 file là đủ. Nhưng tin xấu: file `car_model.usdz` hiện tại **không thể** mở cửa được dù làm cách gì, vì:

1. **Cửa không phải node riêng** — mesh xe bị gộp theo *material* (Paint, Base, Interior, Window, Grille, Light...), không phải theo *bộ phận*. Cửa trái dính liền vào mesh `Dodge_Paint_Geo...` + `Dodge_Base_Geo...` + `Dodge_Window_Geo...`. Không có prim nào tên "Door".
2. **Không có animation nào trong file** — `timeCodes: 0.0 → 0.0` (timeline rỗng).

Chỉ có bánh xe + calliper là node riêng (`_DWheel_Front_L`, `CalliperBody_Front_L`...) — model gốc rig để quay bánh, không rig cửa.

→ Muốn mở cửa: phải **thay model** (hoặc sửa model trong Blender). Sau đó code RealityKit chỉ ~15 dòng.

## Kết quả mổ xẻ file hiện tại

```
/scene/Meshes/Sketchfab_model/FINAL_MODEL_toretto_fbx/RootNode/Object_3/
├── _rootJoint/
│   ├── Wheel1A_3D_00/ _DWheel_Front_L, _DWheel_Front_R, _DWheel_Rear_L, _DWheel_Rear_R   ← bánh: node riêng ✅
│   └── Common_01/ CalliperBody_Front_L/R, Rear_L/R                                        ← calliper: node riêng ✅
├── Dodge_Paint_Geo_lodA...      ← TOÀN BỘ vỏ sơn (gồm cả cửa) = 1 mesh ❌
├── Dodge_Base_Geo_lodA...       ← gầm/khung = 1 mesh ❌
├── Dodge_Interior_Geo_lodA...   ← nội thất = 1 mesh
├── Dodge_Window_Geo_lodA...     ← toàn bộ kính (gồm kính cửa) = 1 mesh ❌
├── Dodge_Grille1/Light/ManufacturerPlate/Coloured...
└── (125 prims, timeline 0→0 = không có animation)
```

Model nguồn: Sketchfab, convert FBX → glTF → USDZ ("FINAL_MODEL_toretto_fbx" = xe Dom Toretto, Fast & Furious 😄).

## 3 cách làm "tap mở cửa" (xếp theo độ khuyến nghị)

### Cách 1 — Model có animation baked sẵn trong CHÍNH file USDZ đó (khuyến nghị ⭐)

USDZ chứa được animation ngay trong file (skeletal hoặc transform animation). RealityKit tự load vào `entity.availableAnimations`, tap thì play:

```swift
// CarARShowroomView: trong tap handler
if let anim = carEntity.availableAnimations.first {
    carEntity.playAnimation(anim, transitionDuration: 0.3)
}
```

- Lưu ý đã được xác nhận trên Apple Forums: phải load bằng `Entity(named:)` / `Entity.load` (project đang dùng đúng cái này ở `CarModelLoader.swift:14` ✅), **không** dùng `loadModel` — `loadModel` vứt animation đi.
- Lưu ý thứ 2: gọi `playAnimation` khi entity **chưa add vào scene** → animation tự nhảy về trạng thái "xong", không chạy gì cả.
- Giới hạn: USDZ thuần về cơ bản là **1 timeline duy nhất**. Muốn nhiều hành động (mở cửa trái / cửa phải / capo) trong 1 file thì bake tất cả lên 1 timeline rồi play từng đoạn (trim `definition.trimStart/trimEnd`), hơi cực. Từ iOS 18 có `AnimationLibraryComponent` đỡ hơn nhưng cần pipeline Reality Composer Pro.

**Nguồn model:** lên Sketchfab tìm car model có filter **"Animated"** (nhiều model có sẵn animation mở cửa), tải glTF → kéo vào **Reality Converter** (app free của Apple) → ra USDZ có animation. Thay `car_model.usdz` là xong — vẫn chỉ 1 file.

### Cách 2 — Cửa là node RIÊNG, xoay bằng code (linh hoạt nhất)

Không cần animation baked. Chỉ cần model có node cửa tách rời **với pivot đặt tại bản lề**, rồi RealityKit xoay bằng code:

```swift
if let door = carEntity.findEntity(named: "Door_L") {
    var openTransform = door.transform
    openTransform.rotation = simd_quatf(angle: -.pi / 3, axis: [0, 1, 0]) // mở 60°
    door.move(to: openTransform, relativeTo: door.parent,
              duration: 0.8, timingFunction: .easeInOut)
}
```

- Ưu: điều khiển hoàn toàn — mở/đóng, mở từ từ theo gesture kéo, mở góc tùy ý, mỗi cửa độc lập. Hợp với app showroom đang có sẵn hand-gesture controller.
- Nhược: nếu pivot của node cửa nằm sai chỗ (thường ở tâm xe sau khi convert), cửa sẽ xoay quanh tâm xe thay vì bản lề → phải sửa origin trong Blender, hoặc code workaround: tạo 1 Entity rỗng đặt tại vị trí bản lề, re-parent node cửa vào đó rồi xoay entity rỗng.
- Vẫn là **1 file USDZ**.

### Cách 3 — Hack 2 file USDZ (xe đóng cửa + xe mở cửa, tap thì swap) — ĐỪNG LÀM ❌

Đây chính là cái anh hỏi "tạo thêm 1 file usdz nữa à???". Về kỹ thuật làm được, nhưng:
- Cửa "nhảy phụt" từ đóng sang mở, không có chuyển động — nhìn rất rẻ tiền.
- RAM x2 (file hiện tại 4.4MB, ~145k tam giác — clone cache trong `CarModelLoader` thành vô nghĩa).
- Có nháy hình lúc swap entity.
- Muốn thêm trạng thái (mở capo, mở cốp, mở nửa cửa) → bùng nổ số file.

Chỉ chấp nhận được khi deadline 1 ngày và không có ai biết Blender.

## Pipeline sửa model (nếu muốn giữ con Charger này)

Blender (free):
1. Import glTF gốc từ Sketchfab (file FBX/glTF trước khi convert).
2. Edit mode → select phần cửa của mesh Paint + Window + Interior → `P` Separate Selection → thành object `Door_L` riêng.
3. Đặt origin của `Door_L` tại mép bản lề (Object > Set Origin > 3D Cursor đặt ở bản lề).
4. (Tùy chọn cho Cách 1) Keyframe rotation mở cửa.
5. Export glTF (.glb) → kéo vào **Reality Converter** → save USDZ. (Cộng đồng xác nhận route glTF→Reality Converter ăn animation ổn hơn export USD trực tiếp từ Blender.)

> Thực tế: tách cửa từ mesh gộp là việc mất 1–3 giờ Blender thủ công (phải vá lỗ trên thân xe sau khi tách). **Tìm model khác đã rig sẵn cửa thường nhanh hơn.**

## So sánh nhanh

| | Cách 1: anim baked | Cách 2: node riêng + code | Cách 3: 2 file swap |
|---|---|---|---|
| Số file USDZ | 1 | 1 | 2+ |
| Có chuyển động mượt | ✅ | ✅ | ❌ nhảy phụt |
| Mở theo gesture kéo | ❌ | ✅ | ❌ |
| Nhiều bộ phận (capo, cốp) | khó (1 timeline) | ✅ dễ | ❌ bùng nổ file |
| Cần sửa/đổi model | ✅ | ✅ | ✅ (vẫn phải có bản mở cửa) |
| Code phía iOS | ~5 dòng | ~15 dòng | ~20 dòng |

**Đề xuất cho app showroom này:** Cách 2 (node riêng + xoay bằng code) — vì app đã có hand-gesture, sau này làm "kéo tay mở cửa từ từ" được luôn. Nếu kiếm được model Sketchfab có sẵn animation mở cửa thì Cách 1 nhanh nhất.

## Nguồn

- [Apple Forums — USDZ Animations with RealityKit](https://developer.apple.com/forums/thread/661443)
- [Apple Forums — USDZ multiple animations](https://developer.apple.com/forums/thread/724145)
- [createwithswift.com — Play an animation in RealityKit](https://www.createwithswift.com/play-an-animation-in-realitykit/)
- [Apple Forums — rotate an entity in RealityKit](https://developer.apple.com/forums/thread/658620)
- [Medium — Blender → Reality Converter animated USDZ workflow](https://medium.com/audiometaverse/export-blender-animated-3d-objects-with-usdz-extension-with-reality-converter-c8f4752779ef)
- [Medium — Prototype AR with Blender, Reality Converter, Reality Composer](https://yingsc.medium.com/prototype-ar-experiences-3452901e3347)
- Mổ xẻ trực tiếp: `unzip` + `usd-core` trên `Resources/car_model.usdz` (125 prims, timeCodes 0→0)

## Câu hỏi chưa chốt

1. Anh muốn giữ con Dodge Charger này (→ phải tách cửa trong Blender) hay đổi sang model khác đã rig sẵn cửa?
2. Muốn mở cửa kiểu tap-một-phát-mở-hết, hay kéo tay mở từ từ theo gesture (ảnh hưởng chọn Cách 1 vs Cách 2)?
