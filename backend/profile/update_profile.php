<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

try {
    $pdo = getDBConnection();

    // Update profile
    $updateFields = [];
    $params = [':uid' => $userId];

    $allowedProfile = ['name', 'age', 'gender', 'city', 'state', 'country', 'pincode', 'height_cm', 'weight_kg', 'activity_level', 'food_preference', 'allergies', 'dietary_restrictions', 'sleep_hours', 'sleep_quality', 'water_goal_ml', 'step_goal', 'exercise_goal_mins', 'calorie_goal'];

    foreach ($allowedProfile as $field) {
        if (isset($input[$field])) {
            $updateFields[] = "$field = :$field";
            $params[":$field"] = $input[$field];
        }
    }

    if (!empty($updateFields)) {
        $sql = "UPDATE user_profiles SET " . implode(', ', $updateFields) . " WHERE user_id = :uid";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
    }

    // Update diabetes details if provided
    $diabFields = [];
    $diabParams = [':uid' => $userId];
    $allowedDiab = ['diabetes_type', 'diagnosis_date', 'duration_years', 'family_history', 'comorbidities', 'current_fasting_glucose', 'current_post_meal_glucose', 'current_hba1c', 'target_glucose_min', 'target_glucose_max'];

    foreach ($allowedDiab as $df) {
        if (isset($input[$df])) {
            $diabFields[] = "$df = :$df";
            $diabParams[":$df"] = $input[$df];
        }
    }

    if (!empty($diabFields)) {
        $diabSql = "UPDATE diabetes_details SET " . implode(', ', $diabFields) . " WHERE user_id = :uid";
        $diabStmt = $pdo->prepare($diabSql);
        $diabStmt->execute($diabParams);
    }

    sendResponse(true, 'Profile updated successfully');

} catch (Exception $e) {
    sendResponse(false, 'Failed to update profile: ' . $e->getMessage(), null, 500);
}
