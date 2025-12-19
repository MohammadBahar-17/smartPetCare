const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.askAi = onRequest(async (req, res) => {
  try {
    // ✅ السؤال اختياري (لو فاضي = ملخص)
    const q = ((req.body || {}).question || "").toString().trim().toLowerCase();

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

    const tankPercent = water.tank_percentage ?? null;
    const dishEmpty = water.dish_empty ?? null;
    const tankFull = water.tank_full ?? null;

    // ===== ملخص افتراضي (لو ما في سؤال) =====
    const reportLines = [
      "ملخص الحالة:",
      `- أكل القط: ${catFood}%`,
      `- أكل الكلب: ${dogFood}%`,
      `- وزن الأكل في صحن القط: ${catWeight} g`,
      `- وزن الأكل في صحن الكلب: ${dogWeight} g`,
    ];
    if (tankPercent != null) reportLines.push(`- التنك: ${tankPercent}%`);
    if (dishEmpty != null) {
      reportLines.push(`- الصحن فاضي: ${dishEmpty ? "نعم" : "لا"}`);
    }
    if (tankFull != null) {
      reportLines.push(`- التنك ممتلئ: ${tankFull ? "نعم" : "لا"}`);
    }
    const report = reportLines.join("\n");

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
      answer = `وزن الأكل الحالي في صحن القط هو ${catWeight} غرام.`;
    } else if (
      q.includes("كلب") &&
      (q.includes("وزن") || q.includes("weight"))
    ) {
      answer = `وزن الأكل الحالي في صحن الكلب هو ${dogWeight} غرام.`;
    } else if (q.includes("مي") || q.includes("ماء") || q.includes("water")) {
      answer =
        `حالة نظام المي:\n` +
        (tankPercent != null ? `- نسبة التنك: ${tankPercent}%\n` : "") +
        (tankFull != null
          ? `- التنك ممتلئ: ${tankFull ? "نعم" : "لا"}\n`
          : "") +
        (dishEmpty != null ? `- الصحن فاضي: ${dishEmpty ? "نعم" : "لا"}` : "");
    } else if (
      q.includes("ملخص") ||
      q.includes("حالة") ||
      q.includes("status") ||
      q === ""
    ) {
      answer = report;
    }

    // ===== Intent detection =====
    let intent = "summary"; // default
    if (q.includes("قط") && q.includes("أكل")) intent = "cat_food";
    else if (q.includes("كلب") && q.includes("أكل")) intent = "dog_food";
    else if (q.includes("مي") || q.includes("ماء") || q.includes("water")) {
      intent = "water";
    } else if (q.includes("وزن")) intent = "weight";
    else if (q.includes("ملخص") || q.includes("حالة") || q.includes("status")) {
      intent = "summary";
    }

    // ===== Severity =====
    let severity = "low";
    if (catFood <= 10 || dogFood <= 10) severity = "high";
    else if (catFood <= 20 || dogFood <= 20) severity = "medium";

    // ===== Suggested actions (اقتراحات فقط) =====
    const actions = [];
    if (catFood <= 20) actions.push("إطعام القط (يدوي)");
    if (dogFood <= 20) actions.push("إطعام الكلب (يدوي)");
    if (tankPercent != null && tankPercent <= 10)
      actions.push("تعبئة خزان الماء");

    // ===== توصيات عامة =====
    const tips = [];

    if (catFood <= 20)
      tips.push("أكل القط منخفض (≤20%). يفضّل تعبئة الطعام قريبًا.");
    if (dogFood <= 20)
      tips.push("أكل الكلب منخفض (≤20%). يفضّل تعبئة الطعام قريبًا.");

    if (tankPercent != null && tankPercent <= 10) {
      tips.push("التنك أقل من 10%. لازم تعبيه اليوم.");
    }
    if (dishEmpty === true) {
      tips.push("الصحن فاضي. افحص المضخة/التعبئة أو حسّاس الصحن.");
    }

    if (tips.length === 0) tips.push("كل القراءات ضمن الطبيعي ✅");

    return res.json({
      answer,
      tips,
      intent,
      severity,
      actions_suggested: actions,
      snapshot: {
        cat_food_level: catFood,
        dog_food_level: dogFood,
        tank_percentage: tankPercent,
        dish_empty: dishEmpty,
      },
    });
  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
});
