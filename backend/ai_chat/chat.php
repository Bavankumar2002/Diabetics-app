<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();
$userMessage = trim($input['message'] ?? '');

if (empty($userMessage)) {
    sendResponse(false, 'Message cannot be empty', null, 400);
}

try {
    $pdo = getDBConnection();

    // 1. Save user message to history
    $saveUserMsg = $pdo->prepare("INSERT INTO ai_chat_history (user_id, role, message) VALUES (:uid, 'user', :msg)");
    $saveUserMsg->execute([':uid' => $userId, ':msg' => $userMessage]);

    // 2. Fetch user profile context for personalized educational responses
    $ctxStmt = $pdo->prepare("
        SELECT p.name, p.food_preference, d.diabetes_type, d.current_hba1c
        FROM user_profiles p
        LEFT JOIN diabetes_details d ON d.user_id = p.user_id
        WHERE p.user_id = :uid LIMIT 1
    ");
    $ctxStmt->execute([':uid' => $userId]);
    $userCtx = $ctxStmt->fetch() ?: [];
    $userName = $userCtx['name'] ?? 'Friend';
    $diabetesType = $userCtx['diabetes_type'] ?? 'Diabetes';
    $foodPref = $userCtx['food_preference'] ?? 'Vegetarian';

    // 3. Process with diabetes clinical knowledge engine
    $lowerMsg = strtolower($userMessage);
    $aiReply = "";
    $isEmergency = false;

    // Emergency Detection: Severe hypoglycemia or acute symptoms
    if (preg_match('/\b(shaking|sweating|dizzy|passed out|faint|below 70|under 70|hypo|sugar 50|sugar 60|sugar 40)\b/', $lowerMsg)) {
        $isEmergency = true;
        $aiReply = "⚠️ **EMERGENCY GUIDANCE: POTENTIAL HYPOGLYCEMIA (< 70 mg/dL)**\n\n"
                 . "Low blood sugar can become severe quickly. Follow the **'Rule of 15'** immediately:\n"
                 . "1. **Consume 15 grams of fast-acting carbohydrate right now:**\n"
                 . "   - 1/2 cup (120 ml) of fruit juice or regular non-diet soda, OR\n"
                 . "   - 3 to 4 glucose tablets or 1 tablespoon of sugar/honey dissolved in water.\n"
                 . "2. **Wait 15 minutes and rest.**\n"
                 . "3. **Re-check your blood glucose.** If still under 70 mg/dL, repeat the 15g fast carbohydrate.\n"
                 . "4. Once blood sugar is above 70 mg/dL, eat a small snack with complex carbs and protein (such as a whole wheat cracker with cheese or a cup of milk) if your next meal is more than an hour away.\n\n"
                 . "🚨 **If the person is confused, unable to swallow, or losing consciousness, DO NOT give food or liquids. Call emergency services (112 or local hospital) or administer emergency glucagon immediately.**";
    } elseif (preg_match('/\b(above 300|over 300|high sugar 350|sugar 400|ketones|vomiting|fruity breath|deep breathing)\b/', $lowerMsg)) {
        $isEmergency = true;
        $aiReply = "⚠️ **URGENT MEDICAL ALERT: SEVERE HYPERGLYCEMIA**\n\n"
                 . "Blood glucose levels above 250–300 mg/dL, especially with nausea, vomiting, confusion, or fruity breath, can indicate **Diabetic Ketoacidosis (DKA)** or **Hyperosmolar Hyperglycemic State (HHS)**.\n\n"
                 . "• Drink plenty of plain water to avoid severe dehydration.\n"
                 . "• Check for blood or urine ketones if you have Type 1 diabetes and ketone strips available.\n"
                 . "• Contact your physician or visit the nearest emergency medical clinic immediately.\n\n"
                 . "*(Disclaimer: Do not self-adjust insulin or prescription medication dosages without direct physician instruction.)*";
    } elseif (preg_match('/\b(hba1c|a1c|three month)\b/', $lowerMsg)) {
        $aiReply = "📊 **Understanding HbA1c (Glycated Hemoglobin):**\n\n"
                 . "HbA1c measures the percentage of your red blood cells that have sugar attached to them, representing your **average blood glucose level over the past 2 to 3 months**.\n\n"
                 . "• **Normal:** Below 5.7%\n"
                 . "• **Prediabetes:** 5.7% to 6.4%\n"
                 . "• **Diabetes:** 6.5% or higher\n"
                 . "• **General Target for Most Adults with Diabetes:** Generally below 7.0%, though your physician will personalize this based on your age, hypoglycemia risk, and medical history.\n\n"
                 . "Would you like advice on lifestyle changes that help optimize your HbA1c over time?";
    } elseif (preg_match('/\b(fasting|morning sugar|dawn phenomenon)\b/', $lowerMsg)) {
        $aiReply = "🌅 **Fasting Blood Glucose & Morning Spikes:**\n\n"
                 . "Fasting blood sugar is taken in the morning after at least 8 hours of overnight fasting.\n\n"
                 . "• **Standard Non-Diabetic Fasting:** 70 to 99 mg/dL\n"
                 . "• **ADA Fasting Target for Diabetics:** 80 to 130 mg/dL\n\n"
                 . "If your fasting reading is higher than your bedtime reading, you might be experiencing:\n"
                 . "1. **The Dawn Phenomenon:** Natural morning surge of cortisol and growth hormone prompting the liver to release glucose.\n"
                 . "2. **Late-night heavy carb snacks or dinners.**\n\n"
                 . "💡 *Tip:* A light evening dinner rich in soluble fiber (like methi roti or vegetable soup) and a 15-minute gentle post-dinner stroll can significantly improve fasting numbers.";
    } elseif (preg_match('/\b(idli|dosa|rice|roti|chapati|sambar|south indian|indian food)\b/', $lowerMsg)) {
        $aiReply = "🍛 **Diabetes-Friendly Indian Meal Strategies:**\n\n"
                 . "Indian staples can fit wonderfully into a healthy diabetes meal plan when balanced properly:\n\n"
                 . "• **Idli & Dosa:** Conventional batter is rice-heavy. Make them diabetes-friendly by using **Ragi (finger millet), Oats, or Moong Dal chillas**, or adding more urad dal and fenugreek seeds.\n"
                 . "• **Rice:** Replace refined white rice with **Brown Rice, Brown Basmati, or Red Matta rice**, and keep portion size to 1 moderate cup paired with double portions of vegetables.\n"
                 . "• **Chapatis:** Opt for whole-wheat multigrain flour mixed with chickpea (besan) or barley flour for higher fiber and lower glycemic response.\n"
                 . "• **Always eat in this order:** Vegetables/Salad first ➡️ Dal/Protein second ➡️ Carbohydrates last. This slows glucose absorption by up to 30%!";
    } elseif (preg_match('/\b(exercise|walking|steps|gym|workout)\b/', $lowerMsg)) {
        $aiReply = "🏃 **Exercise & Blood Sugar Management:**\n\n"
                 . "Physical activity acts like natural insulin by allowing muscle cells to take up glucose directly from the bloodstream:\n\n"
                 . "• **Post-Meal Walks:** A brisk 15 to 20-minute walk within 30 minutes after meals is one of the most effective ways to blunt postprandial glucose spikes.\n"
                 . "• **Aerobic + Resistance:** Combining 150 minutes/week of moderate cardio (walking, cycling) with 2 sessions of light resistance training improves insulin sensitivity for up to 48 hours.\n"
                 . "• **Safety Tip:** If taking insulin or sulfonylureas, always carry 15g of fast-acting glucose (glucose tablets or candy) when exercising to safeguard against hypoglycemia.";
    } elseif (preg_match('/\b(fruit|mango|banana|apple|sweet)\b/', $lowerMsg)) {
        $aiReply = "🍎 **Can Diabetics Eat Fruits?**\n\n"
                 . "Yes! Whole fruits provide vital antioxidants, vitamins, and dietary fiber that slows sugar absorption:\n\n"
                 . "• **Best Low-GI Fruits:** Green apples, berries (strawberries, blueberries), guava, papaya, and amla (Indian gooseberry).\n"
                 . "• **High-Sugar Fruits (Enjoy in strict moderation):** Mangoes, bananas, chiku (sapodilla), grapes, and watermelon. Never drink fruit juice as the beneficial fiber is stripped away.\n"
                 . "• **Smart Rule:** Eat whole fruits between meals rather than as dessert immediately after a carb-heavy meal.";
    } elseif (preg_match('/\b(metformin|insulin|tablet|dose|medicine|prescribe)\b/', $lowerMsg)) {
        $aiReply = "💊 **Important Medication Notice & Safety:**\n\n"
                 . "As an AI healthcare assistant, **I am strictly programmed NOT to prescribe medication or recommend dosage adjustments**, as modifying prescriptions without your doctor's supervision can lead to dangerous hypoglycemia or complications.\n\n"
                 . "• **General Guidelines:** Always take diabetes medications (such as Metformin, Glimepiride, or Insulin) strictly as instructed by your diabetologist.\n"
                 . "• Never skip or double a dose without medical approval.\n"
                 . "• If you notice recurring hypoglycemia (<70 mg/dL) or frequent highs, log your readings in Diacare and share the PDF report with your doctor for dosage fine-tuning.";
    } else {
        $aiReply = "Hello $userName! 👋\n\n"
                 . "I am your personal Diacare Diabetes Educational Assistant. I can help guide you with:\n"
                 . "• **Nutritional guidance:** Diabetes-friendly Indian foods, meal combinations, and portion control.\n"
                 . "• **Blood sugar education:** Explaining fasting, post-meal targets, and HbA1c ranges.\n"
                 . "• **Lifestyle habits:** Physical activity timing, hydration, and sleep quality.\n\n"
                 . "What specific aspect of your diabetes routine would you like to explore today?\n\n"
                 . "*Medical Disclaimer: Diacare AI provides health information for educational purposes only and does not replace medical advice, diagnosis, or physician treatment.*";
    }

    // 4. Save AI reply to history
    $saveAiMsg = $pdo->prepare("INSERT INTO ai_chat_history (user_id, role, message) VALUES (:uid, 'assistant', :msg)");
    $saveAiMsg->execute([':uid' => $userId, ':msg' => $aiReply]);

    sendResponse(true, 'Reply generated', [
        'reply' => $aiReply,
        'is_emergency' => $isEmergency,
        'suggested_questions' => [
            'What is the Rule of 15 for low blood sugar?',
            'What should my fasting blood sugar be?',
            'What South Indian foods are diabetes-friendly?',
            'How does walking after meals help?',
            'What is a healthy HbA1c target?'
        ]
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to process AI chat: ' . $e->getMessage(), null, 500);
}
