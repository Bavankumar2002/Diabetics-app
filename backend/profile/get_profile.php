<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];

try {
    $pdo = getDBConnection();

    $stmt = $pdo->prepare("
        SELECT u.id, u.phone, u.country_code, u.created_at as joined_date,
               p.name, p.age, p.gender, p.country, p.state, p.district, p.city, p.pincode,
               p.height_cm, p.weight_kg, p.activity_level, p.health_goals, p.food_preference,
               p.allergies, p.dietary_restrictions, p.sleep_hours, p.sleep_quality,
               p.water_goal_ml, p.step_goal, p.exercise_goal_mins, p.calorie_goal,
               d.diabetes_type, d.diagnosis_date, d.duration_years, d.family_history,
               d.comorbidities, d.current_fasting_glucose, d.current_post_meal_glucose,
               d.current_hba1c, d.last_hba1c_date, d.target_glucose_min, d.target_glucose_max
        FROM users u
        LEFT JOIN user_profiles p ON p.user_id = u.id
        LEFT JOIN diabetes_details d ON d.user_id = u.id
        WHERE u.id = :uid LIMIT 1
    ");
    $stmt->execute([':uid' => $userId]);
    $profileData = $stmt->fetch();

    if (!$profileData) {
        sendResponse(false, 'User profile not found', null, 404);
    }

    // Decode health goals if JSON
    $goals = json_decode($profileData['health_goals'] ?? '[]', true);
    if (!is_array($goals)) {
        $goals = array_filter(explode(',', $profileData['health_goals'] ?? ''));
    }
    $profileData['health_goals_list'] = $goals;

    // Get active medications summary
    $medStmt = $pdo->prepare("SELECT name, dosage, frequency, reminder_time FROM medication WHERE user_id = :uid AND is_active = 1");
    $medStmt->execute([':uid' => $userId]);
    $profileData['medications'] = $medStmt->fetchAll();

    // Get reminders
    $remStmt = $pdo->prepare("SELECT reminder_type, title, reminder_time, is_enabled FROM reminders WHERE user_id = :uid");
    $remStmt->execute([':uid' => $userId]);
    $profileData['reminders'] = $remStmt->fetchAll();

    sendResponse(true, 'Profile loaded', $profileData);

} catch (Exception $e) {
    sendResponse(false, 'Failed to fetch profile: ' . $e->getMessage(), null, 500);
}
