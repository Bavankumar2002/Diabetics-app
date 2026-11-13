<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

// List of reminder objects or map of reminder settings
// e.g. reminders: [ {type: 'medication', title: 'Morning Medication', reminder_time: '08:00 AM', is_enabled: 1}, ... ]
$reminders = $input['reminders'] ?? [];

if (empty($reminders)) {
    // Default standard setup if submitted with simple boolean flags
    $reminders = [
        ['type' => 'medication', 'title' => 'Medication Reminder', 'time' => $input['medication_time'] ?? '08:00 AM', 'enabled' => !empty($input['enable_medication']) ? 1 : 0],
        ['type' => 'glucose', 'title' => 'Blood Glucose Check', 'time' => $input['glucose_time'] ?? '07:30 AM', 'enabled' => !empty($input['enable_glucose']) ? 1 : 0],
        ['type' => 'breakfast', 'title' => 'Breakfast Reminder', 'time' => $input['breakfast_time'] ?? '08:30 AM', 'enabled' => !empty($input['enable_breakfast']) ? 1 : 0],
        ['type' => 'lunch', 'title' => 'Lunch Reminder', 'time' => $input['lunch_time'] ?? '01:00 PM', 'enabled' => !empty($input['enable_lunch']) ? 1 : 0],
        ['type' => 'evening_snack', 'title' => 'Evening Snack', 'time' => $input['snack_time'] ?? '05:00 PM', 'enabled' => !empty($input['enable_snack']) ? 1 : 0],
        ['type' => 'dinner', 'title' => 'Dinner Reminder', 'time' => $input['dinner_time'] ?? '08:00 PM', 'enabled' => !empty($input['enable_dinner']) ? 1 : 0],
        ['type' => 'water', 'title' => 'Drink Water', 'time' => $input['water_time'] ?? 'Every 2 Hours', 'enabled' => !empty($input['enable_water']) ? 1 : 0],
        ['type' => 'exercise', 'title' => 'Daily Exercise & Walk', 'time' => $input['exercise_time'] ?? '06:30 PM', 'enabled' => !empty($input['enable_exercise']) ? 1 : 0],
    ];
}

try {
    $pdo = getDBConnection();
    
    // Clear previous reminders for this user
    $del = $pdo->prepare("DELETE FROM reminders WHERE user_id = :uid");
    $del->execute([':uid' => $userId]);

    $insert = $pdo->prepare("
        INSERT INTO reminders (user_id, reminder_type, title, reminder_time, is_enabled)
        VALUES (:uid, :type, :title, :time, :enabled)
    ");

    foreach ($reminders as $r) {
        $type = $r['type'] ?? $r['reminder_type'] ?? 'general';
        $title = $r['title'] ?? ucfirst(str_replace('_', ' ', $type));
        $time = $r['time'] ?? $r['reminder_time'] ?? '08:00 AM';
        $enabled = isset($r['enabled']) ? ($r['enabled'] ? 1 : 0) : (!empty($r['is_enabled']) ? 1 : 0);

        $insert->execute([
            ':uid' => $userId,
            ':type' => $type,
            ':title' => $title,
            ':time' => $time,
            ':enabled' => $enabled
        ]);
    }

    sendResponse(true, 'Reminders configured successfully', [
        'count' => count($reminders)
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to save reminders: ' . $e->getMessage(), null, 500);
}
