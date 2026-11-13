<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

$name = trim($input['name'] ?? '');
if (empty($name)) {
    sendResponse(false, 'Name is required', null, 400);
}

$age = intval($input['age'] ?? 30);
$gender = trim($input['gender'] ?? 'Prefer not to say');
$country = trim($input['country'] ?? 'India');
$state = trim($input['state'] ?? '');
$district = trim($input['district'] ?? '');
$city = trim($input['city'] ?? '');
$pincode = trim($input['pincode'] ?? '');
$heightCm = floatval($input['height_cm'] ?? 170.0);
$weightKg = floatval($input['weight_kg'] ?? 70.0);
$activityLevel = trim($input['activity_level'] ?? 'Moderately Active');
$healthGoals = is_array($input['health_goals'] ?? null) 
    ? json_encode($input['health_goals']) 
    : trim($input['health_goals'] ?? '["Manage blood sugar"]');
$foodPreference = trim($input['food_preference'] ?? 'Vegetarian');
$allergies = trim($input['allergies'] ?? '');
$dietaryRestrictions = trim($input['dietary_restrictions'] ?? '');
$sleepHours = floatval($input['sleep_hours'] ?? 7.5);
$sleepQuality = trim($input['sleep_quality'] ?? 'Good');
$waterGoal = intval($input['water_goal_ml'] ?? 2500);
$stepGoal = intval($input['step_goal'] ?? 8000);
$exerciseGoal = intval($input['exercise_goal_mins'] ?? 30);
$calorieGoal = intval($input['calorie_goal'] ?? 1800);

// Diabetes Details
$diabetesType = trim($input['diabetes_type'] ?? 'Type 2 Diabetes');
$diagnosisDate = trim($input['diagnosis_date'] ?? '');
$durationYears = trim($input['duration_years'] ?? '');
$familyHistory = !empty($input['family_history']) ? 1 : 0;
$comorbidities = trim($input['comorbidities'] ?? '');
$fastingGlucose = isset($input['current_fasting_glucose']) && $input['current_fasting_glucose'] !== '' 
    ? floatval($input['current_fasting_glucose']) : null;
$postMealGlucose = isset($input['current_post_meal_glucose']) && $input['current_post_meal_glucose'] !== '' 
    ? floatval($input['current_post_meal_glucose']) : null;
$hba1c = isset($input['current_hba1c']) && $input['current_hba1c'] !== '' 
    ? floatval($input['current_hba1c']) : null;
$lastHba1cDate = !empty($input['last_hba1c_date']) ? $input['last_hba1c_date'] : null;

// Initial Medication if provided
$medName = trim($input['medication_name'] ?? '');
$medDosage = trim($input['medication_dosage'] ?? '');
$medSchedule = trim($input['medication_schedule'] ?? '08:00 AM');
$isInsulin = !empty($input['insulin_usage']) ? 1 : 0;

try {
    $pdo = getDBConnection();
    $pdo->beginTransaction();

    // Upsert user_profiles
    $profileStmt = $pdo->prepare("
        INSERT INTO user_profiles 
        (user_id, name, age, gender, country, state, district, city, pincode, height_cm, weight_kg, activity_level, health_goals, food_preference, allergies, dietary_restrictions, sleep_hours, sleep_quality, water_goal_ml, step_goal, exercise_goal_mins, calorie_goal)
        VALUES 
        (:uid, :name, :age, :gender, :country, :state, :district, :city, :pincode, :height, :weight, :act, :goals, :food, :allergies, :diet, :sleep_h, :sleep_q, :water, :steps, :exercise, :calorie)
        ON DUPLICATE KEY UPDATE 
            name = VALUES(name),
            age = VALUES(age),
            gender = VALUES(gender),
            country = VALUES(country),
            state = VALUES(state),
            district = VALUES(district),
            city = VALUES(city),
            pincode = VALUES(pincode),
            height_cm = VALUES(height_cm),
            weight_kg = VALUES(weight_kg),
            activity_level = VALUES(activity_level),
            health_goals = VALUES(health_goals),
            food_preference = VALUES(food_preference),
            allergies = VALUES(allergies),
            dietary_restrictions = VALUES(dietary_restrictions),
            sleep_hours = VALUES(sleep_hours),
            sleep_quality = VALUES(sleep_quality),
            water_goal_ml = VALUES(water_goal_ml),
            step_goal = VALUES(step_goal),
            exercise_goal_mins = VALUES(exercise_goal_mins),
            calorie_goal = VALUES(calorie_goal)
    ");
    $profileStmt->execute([
        ':uid' => $userId,
        ':name' => $name,
        ':age' => $age,
        ':gender' => $gender,
        ':country' => $country,
        ':state' => $state,
        ':district' => $district,
        ':city' => $city,
        ':pincode' => $pincode,
        ':height' => $heightCm,
        ':weight' => $weightKg,
        ':act' => $activityLevel,
        ':goals' => $healthGoals,
        ':food' => $foodPreference,
        ':allergies' => $allergies,
        ':diet' => $dietaryRestrictions,
        ':sleep_h' => $sleepHours,
        ':sleep_q' => $sleepQuality,
        ':water' => $waterGoal,
        ':steps' => $stepGoal,
        ':exercise' => $exerciseGoal,
        ':calorie' => $calorieGoal
    ]);

    // Upsert diabetes_details
    $diabStmt = $pdo->prepare("
        INSERT INTO diabetes_details 
        (user_id, diabetes_type, diagnosis_date, duration_years, family_history, comorbidities, current_fasting_glucose, current_post_meal_glucose, current_hba1c, last_hba1c_date)
        VALUES 
        (:uid, :dtype, :ddate, :duration, :fam, :comorbid, :fasting, :postmeal, :hba1c, :hdate)
        ON DUPLICATE KEY UPDATE 
            diabetes_type = VALUES(diabetes_type),
            diagnosis_date = VALUES(diagnosis_date),
            duration_years = VALUES(duration_years),
            family_history = VALUES(family_history),
            comorbidities = VALUES(comorbidities),
            current_fasting_glucose = VALUES(current_fasting_glucose),
            current_post_meal_glucose = VALUES(current_post_meal_glucose),
            current_hba1c = VALUES(current_hba1c),
            last_hba1c_date = VALUES(last_hba1c_date)
    ");
    $diabStmt->execute([
        ':uid' => $userId,
        ':dtype' => $diabetesType,
        ':ddate' => $diagnosisDate,
        ':duration' => $durationYears,
        ':fam' => $familyHistory,
        ':comorbid' => $comorbidities,
        ':fasting' => $fastingGlucose,
        ':postmeal' => $postMealGlucose,
        ':hba1c' => $hba1c,
        ':hdate' => $lastHba1cDate
    ]);

    // If fasting glucose is provided, also insert an initial reading
    if ($fastingGlucose !== null && $fastingGlucose > 0) {
        $readingStmt = $pdo->prepare("
            INSERT INTO glucose_readings (user_id, reading_value, meal_type, unit, measured_at, notes)
            VALUES (:uid, :val, 'Fasting', 'mg/dL', NOW(), 'Initial fasting glucose during onboarding')
        ");
        $readingStmt->execute([':uid' => $userId, ':val' => $fastingGlucose]);
    }

    // If medication provided, insert into medication table
    if (!empty($medName)) {
        $medStmt = $pdo->prepare("
            INSERT INTO medication (user_id, name, dosage, frequency, is_insulin, start_date, reminder_time, instructions)
            VALUES (:uid, :name, :dosage, 'Daily', :is_insulin, CURDATE(), :reminder, 'Take as prescribed by doctor')
        ");
        $medStmt->execute([
            ':uid' => $userId,
            ':name' => $medName,
            ':dosage' => $medDosage ?: '1 Tablet',
            ':is_insulin' => $isInsulin,
            ':reminder' => $medSchedule ?: '08:00 AM'
        ]);
    }

    $pdo->commit();

    sendResponse(true, 'Onboarding profile saved successfully', [
        'user_id' => $userId,
        'name' => $name,
        'is_onboarded' => true
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendResponse(false, 'Failed to save onboarding profile: ' . $e->getMessage(), null, 500);
}
