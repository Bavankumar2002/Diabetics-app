<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

$type = trim($input['activity_type'] ?? 'Walking');
$steps = intval($input['steps'] ?? 0);
$duration = intval($input['duration_mins'] ?? 20);
$calories = intval($input['calories_burned'] ?? 0);
$date = !empty($input['date']) ? $input['date'] : date('Y-m-d');

if ($duration <= 0) $duration = 15;

// Estimate calories if 0 based on type
if ($calories <= 0) {
    if (stripos($type, 'run') !== false) {
        $calories = round($duration * 9.5);
    } elseif (stripos($type, 'walk') !== false) {
        $calories = round($duration * 4.2);
    } elseif (stripos($type, 'cycl') !== false) {
        $calories = round($duration * 7.0);
    } elseif (stripos($type, 'yoga') !== false) {
        $calories = round($duration * 3.5);
    } else {
        $calories = round($duration * 5.0);
    }
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("
        INSERT INTO activity_logs (user_id, activity_type, steps, duration_mins, calories_burned, logged_date)
        VALUES (:uid, :type, :steps, :dur, :cal, :date)
    ");
    $stmt->execute([
        ':uid' => $userId,
        ':type' => $type,
        ':steps' => $steps,
        ':dur' => $duration,
        ':cal' => $calories,
        ':date' => $date
    ]);

    $id = $pdo->lastInsertId();

    sendResponse(true, 'Activity recorded successfully', [
        'id' => (int)$id,
        'activity_type' => $type,
        'steps' => $steps,
        'duration_mins' => $duration,
        'calories_burned' => $calories,
        'date' => $date
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to log activity: ' . $e->getMessage(), null, 500);
}
