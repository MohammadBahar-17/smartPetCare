const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// ===== Normalize Arabic text (removes hamzas) =====
const normalizeArabic = (text) => {
  return text
    .replace(/[أإاآ]/g, "ا") // Alef in various forms
    .replace(/ة/g, "ه") // Taa Marbuta
    .replace(/ي/g, "ي"); // Yaa in various forms
};

exports.askAi = onRequest(async (req, res) => {
  try {
    const q = ((req.body || {}).question || "").toString().trim().toLowerCase();
    const qNorm = normalizeArabic(q); // normalize without hamzas
    const db = admin.database();

    // ===== Detect Language =====
    const isArabic = /[\u0600-\u06FF]/.test(q);

    // ===== Fetch Data =====
    const [
      feedingSnap,
      waterSnap,
      waterStatusSnap,
      waterAlertsSnap,
      entertainmentSnap,
    ] = await Promise.all([
        db.ref("feeding/sensors").get(),
        db.ref("water/sensors").get(),
        db.ref("water/status").get(),
        db.ref("water/alerts").get(),
        db.ref("entertainment/commands").get(),
      ]);

    const feeding = feedingSnap.val() || {};
    const water = waterSnap.val() || {};
    const waterStatus = waterStatusSnap.val() || {};
    const waterAlerts = waterAlertsSnap.val() || {};
    const entertainment = entertainmentSnap.val() || {};

    // ===== Extract Values =====
    const catFood = feeding.cat_food_level ?? 0;
    const dogFood = feeding.dog_food_level ?? 0;
    const catWeight = feeding.cat_weight ?? 0;
    const dogWeight = feeding.dog_weight ?? 0;
    const tankPercent = water.tank_percentage ?? 0;
    const dishEmpty = water.dish_empty ?? false;
    const isDraining = waterStatus.is_draining ?? false;
    const waterLow = waterAlerts.water_low ?? false;
    const entertainmentOn = entertainment.system_on ?? false;

    // ===== Detect Intent =====
    let intent = "summary";
    if (qNorm.includes("قط") && qNorm.includes("اكل")) {
      intent = "cat_food";
    } else if (qNorm.includes("كلب") && qNorm.includes("اكل")) {
      intent = "dog_food";
    } else if (
      (qNorm.includes("قط") || qNorm.includes("كلب")) &&
      (qNorm.includes("وزن") || q.includes("weight"))
    ) {
      intent = "weight";
    } else if (
      qNorm.includes("مي") ||
      qNorm.includes("ماء") ||
      q.includes("water")
    ) {
      intent = "water";
    } else if (
      qNorm.includes("ترفيه") ||
      q.includes("entertainment") ||
      qNorm.includes("لعب")
    ) {
      intent = "entertainment";
    } else if (
      qNorm.includes("ملخص") ||
      qNorm.includes("حالة") ||
      q.includes("status") ||
      q === ""
    ) {
      intent = "summary";
    }

    // ===== بناء الإجابة حسب Intent =====
    let answer = "";
    const tips = [];
    let severity = "low";
    const actions = [];

    if (intent === "cat_food") {
      if (isArabic) {
        answer = `أكل القط المتبقي: ${catFood}%`;
        if (catFood <= 10) {
          severity = "high";
          tips.push("⚠️ أكل القط حرج!");
          actions.push("أطعم القط فوراً");
        } else if (catFood <= 20) {
          severity = "medium";
          tips.push("أكل القط منخفض. يرجى إعادة التعبئة قريباً.");
          actions.push("أطعم القط (يدوي)");
        } else {
          tips.push("أكل القط طبيعي ✅");
        }
      } else {
        answer = `Cat food remaining: ${catFood}%.`;
        if (catFood <= 10) {
          severity = "high";
          tips.push("⚠️ Cat food is critical!");
          actions.push("Feed cat immediately");
        } else if (catFood <= 20) {
          severity = "medium";
          tips.push("Cat food is low. Please refill soon.");
          actions.push("Feed cat (manual)");
        } else {
          tips.push("Cat food is normal ✅");
        }
      }
    } else if (intent === "dog_food") {
      if (isArabic) {
        answer = `أكل الكلب المتبقي: ${dogFood}%`;
        if (dogFood <= 10) {
          severity = "high";
          tips.push("⚠️ أكل الكلب حرج!");
          actions.push("أطعم الكلب فوراً");
        } else if (dogFood <= 20) {
          severity = "medium";
          tips.push("أكل الكلب منخفض. يرجى إعادة التعبئة قريباً.");
          actions.push("أطعم الكلب (يدوي)");
        } else {
          tips.push("أكل الكلب طبيعي ✅");
        }
      } else {
        answer = `Dog food remaining: ${dogFood}%.`;
        if (dogFood <= 10) {
          severity = "high";
          tips.push("⚠️ Dog food is critical!");
          actions.push("Feed dog immediately");
        } else if (dogFood <= 20) {
          severity = "medium";
          tips.push("Dog food is low. Please refill soon.");
          actions.push("Feed dog (manual)");
        } else {
          tips.push("Dog food is normal ✅");
        }
      }
    } else if (intent === "weight") {
      if (isArabic) {
        if (q.includes("قط")) {
          answer = `وزن الأكل في صحن القط: ${catWeight} جرام.`;
        } else if (q.includes("كلب")) {
          answer = `وزن الأكل في صحن الكلب: ${dogWeight} جرام.`;
        } else {
          answer = `القط: ${catWeight}جم | الكلب: ${dogWeight}جم`;
        }
        tips.push("تم تحديث الأوزان من حساسات الميزان.");
      } else {
        if (q.includes("قط") || q.includes("cat")) {
          answer = `Food weight in cat bowl: ${catWeight} grams.`;
        } else if (q.includes("كلب") || q.includes("dog")) {
          answer = `Food weight in dog bowl: ${dogWeight} grams.`;
        } else {
          answer = `Cat: ${catWeight}g | Dog: ${dogWeight}g`;
        }
        tips.push("Weights updated from scale sensors.");
      }
    } else if (intent === "water") {
      if (isArabic) {
        const waterLines = [
          `نسبة المياه بالتنك: ${tankPercent}%`,
          `صحن المياه فارغ: ${dishEmpty ? "نعم ⚠️" : "لا ✅"}`,
        ];
        answer = waterLines.join("\n");

        if (waterLow || tankPercent < 10) {
          severity = "high";
          tips.push("⚠️ مستوى المياه منخفض جدًا. يفضّل تعبئة التنك فورًا.");
          actions.push("تعبئة خزان الماء");
        } else if (tankPercent < 30) {
          severity = "medium";
          tips.push("نسبة المياه آخذة بالانخفاض. يفضّل التجهز للتعبئة.");
        } else {
          tips.push("نسبة المياه ضمن الطبيعي ✅");
        }

        if (dishEmpty) {
          tips.push("صحن الماء فارغ. تحقق من المضخة أو فعّل التعبئة اليدوية.");
        }

        if (isDraining) {
          tips.push("نظام التصريف يعمل حاليًا.");
        }
      } else {
        const waterLines = [
          `Water tank level: ${tankPercent}%`,
          `Water dish empty: ${dishEmpty ? "Yes ⚠️" : "No ✅"}`,
        ];
        answer = waterLines.join("\n");

        if (waterLow || tankPercent < 10) {
          severity = "high";
          tips.push(
            "⚠️ Water level is critically low. Refill the tank!"
          );
          actions.push("Fill water tank");
        } else if (tankPercent < 30) {
          severity = "medium";
          tips.push("Water level is getting low. Consider refilling soon.");
        } else {
          tips.push("Water level is normal ✅");
        }

        if (dishEmpty) {
          tips.push(
            "Water dish is empty. Check pump or enable manual refill."
          );
        }

        if (isDraining) {
          tips.push("Draining system is currently active.");
        }
      }
    } else if (intent === "entertainment") {
      if (isArabic) {
        if (entertainmentOn) {
          answer = "نظام الترفيه نشط 🟢";
          tips.push("الحيوانات تستمتع بأنشطة الترفيه.");
        } else {
          answer = "نظام الترفيه مغلق 🎾";
          severity = "medium";
          tips.push("فعّل نظام الترفيه لتحفيز الحيوانات وتقليل الملل.");
          actions.push("تفعيل نظام الترفيه");
        }
      } else {
        if (entertainmentOn) {
          answer = "Entertainment system is active 🟢";
          tips.push("Animals are enjoying entertainment activities.");
        } else {
          answer = "Entertainment system is off 🎾";
          severity = "medium";
          tips.push(
            "Enable entertainment to stimulate animals."
          );
          actions.push("Enable entertainment system");
        }
      }
    } else if (intent === "summary") {
      // Comprehensive summary of everything
      if (isArabic) {
        const reportLines = [
          "ملخص الحالة:",
          `- أكل القط: ${catFood}%`,
          `- أكل الكلب: ${dogFood}%`,
          `- وزن الأكل (قط): ${catWeight} جم`,
          `- وزن الأكل (كلب): ${dogWeight} جم`,
          `- مستوى خزان الماء: ${tankPercent}%`,
          `- صحن الماء فارغ: ${dishEmpty ? "نعم" : "لا"}`,
          `- نظام الترفيه: ${entertainmentOn ? "نشط 🟢" : "مغلق 🎾"}`,
        ];
        answer = reportLines.join("\n");

        // Severity based on priorities
        if (catFood <= 10 || dogFood <= 10 || waterLow || tankPercent < 10) {
          severity = "high";
        } else if (
          catFood <= 20 || dogFood <= 20 || tankPercent < 30 || dishEmpty
        ) {
          severity = "medium";
        } else if (!entertainmentOn) {
          severity = "medium";
        } else {
          severity = "low";
        }

        // Comprehensive tips in Arabic
        if (catFood <= 20) tips.push(`🔴 أكل القط منخفض (${catFood}%)`);
        if (dogFood <= 20) tips.push(`🔴 أكل الكلب منخفض (${dogFood}%)`);
        if (waterLow || tankPercent < 10) {
          tips.push(`🔴 المياه حرجة (${tankPercent}%)`);
        }
        if (dishEmpty) tips.push(`🟡 صحن الماء فارغ`);
        if (!entertainmentOn) tips.push(`🟡 نظام الترفيه مغلق`);

        // Comprehensive actions in Arabic
        if (catFood <= 20) actions.push("املأ خزان طعام القط");
        if (dogFood <= 20) actions.push("املأ خزان طعام الكلب");
        if (waterLow || tankPercent < 10) actions.push("املأ خزان الماء");
        if (!entertainmentOn) actions.push("فعّل نظام الترفيه");
      } else {
        const reportLines = [
          "Status Summary:",
          `- Cat food: ${catFood}%`,
          `- Dog food: ${dogFood}%`,
          `- Food weight (Cat): ${catWeight} g`,
          `- Food weight (Dog): ${dogWeight} g`,
          `- Water tank level: ${tankPercent}%`,
          `- Water dish empty: ${dishEmpty ? "Yes" : "No"}`,
          `- Entertainment system: ${entertainmentOn ? "Active 🟢" : "Off 🎾"}`,
        ];
        answer = reportLines.join("\n");

        // Severity based on priorities
        if (catFood <= 10 || dogFood <= 10 || waterLow || tankPercent < 10) {
          severity = "high";
        } else if (
          catFood <= 20 || dogFood <= 20 || tankPercent < 30 || dishEmpty
        ) {
          severity = "medium";
        } else if (!entertainmentOn) {
          severity = "medium";
        } else {
          severity = "low";
        }

        // Comprehensive tips
        if (catFood <= 20) tips.push(`🔴 Cat food is low (${catFood}%)`);
        if (dogFood <= 20) tips.push(`🔴 Dog food is low (${dogFood}%)`);
        if (waterLow || tankPercent < 10) {
          tips.push(`🔴 Water is critical (${tankPercent}%)`);
        }
        if (dishEmpty) tips.push(`🟡 Water dish is empty`);
        if (!entertainmentOn) tips.push(`🟡 Entertainment system is off`);

        // Comprehensive actions
        if (catFood <= 20) actions.push("Fill cat food tank");
        if (dogFood <= 20) actions.push("Fill dog food tank");
        if (waterLow || tankPercent < 10) actions.push("Fill water tank");
        if (!entertainmentOn) actions.push("Enable entertainment system");
      }
    }

    if (tips.length === 0) {
      const msg = isArabic
        ? "جميع القراءات طبيعية ✅"
        : "All readings are normal ✅";
      tips.push(msg);
    }

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
        water_low: waterLow,
        entertainment_on: entertainmentOn,
      },
    });
  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
});

// ✅ Button: Generate meals automatically
exports.generateMealsAi = onRequest(async (req, res) => {
  try {
    const db = admin.database();

    // Read profiles + meta kcal
    const [profilesSnap, metaSnap] = await Promise.all([
      db.ref("profiles").get(),
      db.ref("feeding/meta").get(),
    ]);

    const profiles = profilesSnap.val() || {};
    const meta = metaSnap.val() || {};

    const catKcalPerGram = Number(meta.cat_kcal_per_gram ?? 3.6);
    const dogKcalPerGram = Number(meta.dog_kcal_per_gram ?? 3.6);

    // RER
    const rerForKg = (wKg) => 70 * Math.pow(wKg, 0.75);

    // Multipliers (normal adult)
    const CAT_MULT = 1.2;
    const DOG_MULT = 1.6;

    // Aggregate calories for both species
    let catTotalCalories = 0;
    let dogTotalCalories = 0;

    for (const p of Object.values(profiles)) {
      const type = (p.type || "").toString().toLowerCase();
      const wKg = Number(p.weight ?? 0);
      if (!wKg || (type !== "cat" && type !== "dog")) continue;

      const rer = rerForKg(wKg);
      const mer = rer * (type === "cat" ? CAT_MULT : DOG_MULT);

      if (type === "cat") catTotalCalories += mer;
      else dogTotalCalories += mer;
    }

    const catGramsPerDay = Math.max(
      0,
      Math.round(catTotalCalories / catKcalPerGram)
    );
    const dogGramsPerDay = Math.max(
      0,
      Math.round(dogTotalCalories / dogKcalPerGram)
    );

    // Simple fixed schedule (you can change it)
    const catMealsPerDay = 2;
    const dogMealsPerDay = 2;

    const catTimes = [
      { hour: 8, minute: 0 },
      { hour: 18, minute: 0 },
    ];
    const dogTimes = [
      { hour: 8, minute: 0 },
      { hour: 20, minute: 0 },
    ];

    const catAmount = Math.max(1, Math.round(catGramsPerDay / catMealsPerDay));
    const dogAmount = Math.max(1, Math.round(dogGramsPerDay / dogMealsPerDay));

    // (Optional) Clear old meals before adding
    // If you want "add on top of existing" delete these 2 lines
    await db.ref("feeding/meals").remove();

    // Write new meals (push keys)
    const mealsRef = db.ref("feeding/meals");

    const created = [];

    for (const t of catTimes) {
      const key = mealsRef.push().key;
      const meal = {
        animal: "cat",
        hour: t.hour,
        minute: t.minute,
        amount: catAmount,
        days: "all",
      };
      await mealsRef.child(key).set(meal);
      created.push({ id: key, ...meal });
    }

    for (const t of dogTimes) {
      const key = mealsRef.push().key;
      const meal = {
        animal: "dog",
        hour: t.hour,
        minute: t.minute,
        amount: dogAmount,
        days: "all",
      };
      await mealsRef.child(key).set(meal);
      created.push({ id: key, ...meal });
    }

    return res.json({
      ok: true,
      cat: {
        grams_per_day: catGramsPerDay,
        grams_per_meal: catAmount,
        meals: catTimes,
      },
      dog: {
        grams_per_day: dogGramsPerDay,
        grams_per_meal: dogAmount,
        meals: dogTimes,
      },
      created_count: created.length,
      created,
    });
  } catch (e) {
    return res.status(500).json({ok: false, error: e.toString()});
  }
});
