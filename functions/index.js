const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.askAi = onRequest(async (req, res) => {
  try {
    // ✅ السؤال اختياري (لو فاضي = ملخص)
    const q = (req.body?.question ?? "").toString().trim().toLowerCase();

    const db = admin.database();

    const [feedingSnap, waterSnap] = await Promise.all([
      db.ref("feeding/sensors").get(),
      db.ref("water/sensors").get(),
    ]);

    const feeding = feedingSnap.val() || {};
    const water = waterSnap.val() || {}; // ✅ كانت ناقصة عندك

    const catFood = feeding.cat_food_level ?? 0;
    const dogFood = feeding.dog_food_level ?? 0;
    const catWeight = feeding.cat_weight ?? 0;
    const dogWeight = feeding.dog_weight ?? 0;

    const dishEmpty = water.dish_empty ?? false;
    const tankFull = water.tank_full ?? false;
    const tankPercent = water.tank_percentage ?? 0;

    // ===== ملخص افتراضي (لو ما في سؤال) =====
    const report =
      `ملخص الحالة:\n` +
      `- أكل القط: ${catFood}%\n` +
      `- أكل الكلب: ${dogFood}%\n` +
      `- وزن القط: ${catWeight} g\n` +
      `- وزن الكلب: ${dogWeight} g\n` +
      `- التنك: ${tankPercent}%\n` +
      `- الصحن فاضي: ${dishEmpty ? "نعم" : "لا"}\n` +
      `- التنك ممتلئ: ${tankFull ? "نعم" : "لا"}`;

    // ===== جواب حسب السؤال =====
    let answer = report; // ✅ default: ملخص

    if (q.includes("قط") && (q.includes("أكل") || q.includes("food"))) {
      answer = `نسبة الأكل المتبقي للقطة هي ${catFood}%.`;
    } else if (q.includes("كلب") && (q.includes("أكل") || q.includes("food"))) {
      answer = `نسبة الأكل المتبقي للكلب هي ${dogFood}%.`;
    } else if (
      q.includes("قط") &&
      (q.includes("وزن") || q.includes("weight"))
    ) {
      answer = `وزن القطة الحالي حسب الميزان هو ${catWeight} غرام.`;
    } else if (
      q.includes("كلب") &&
      (q.includes("وزن") || q.includes("weight"))
    ) {
      answer = `وزن الكلب الحالي حسب الميزان هو ${dogWeight} غرام.`;
    } else if (q.includes("مي") || q.includes("ماء") || q.includes("water")) {
      answer =
        `حالة نظام المي:\n` +
        `- نسبة التنك: ${tankPercent}%\n` +
        `- التنك ممتلئ: ${tankFull ? "نعم" : "لا"}\n` +
        `- الصحن فاضي: ${dishEmpty ? "نعم" : "لا"}`;
    } else if (
      q.includes("ملخص") ||
      q.includes("حالة") ||
      q.includes("status") ||
      q === ""
    ) {
      answer = report;
    }

    // ===== توصيات عامة =====
    const tips = [];

    if (catFood <= 20)
      tips.push("أكل القط منخفض (≤20%). يفضّل تعبئة الطعام قريبًا.");
    if (dogFood <= 20)
      tips.push("أكل الكلب منخفض (≤20%). يفضّل تعبئة الطعام قريبًا.");

    if (tankPercent <= 10) tips.push("التنك أقل من 10%. لازم تعبيه اليوم.");
    if (dishEmpty) tips.push("الصحن فاضي. افحص المضخة/التعبئة أو حسّاس الصحن.");

    if (tips.length === 0) tips.push("كل القراءات ضمن الطبيعي ✅");

    return res.json({
      answer,
      tips,
      snapshot: {
        cat_food_level: catFood,
        dog_food_level: dogFood,
        cat_weight: catWeight,
        dog_weight: dogWeight,
        tank_percentage: tankPercent,
        tank_full: tankFull,
        dish_empty: dishEmpty,
      },
    });
  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
});
