<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

$val = floatval($input['reading_value'] ?? 0);
$unit = trim($input['unit'] ?? 'mg/dL');
$mealType = trim($input['meal_type'] ?? 'Random');
$measuredAt = !empty($input['measured_at']) ? $input['measured_at'] : date('Y-m-d H:i:s');
$notes = trim($input['notes'] ?? '');

if ($val <= 0) {
    sendResponse(false, 'Please enter a valid glucose reading value', null, 400);
}

// Convert mmol/L to mg/dL if needed
$mgDlValue = ($unit === 'mmol/L') ? round($val * 18.0182, 1) : $val;

try {
    $pdo = getDBConnection();

    $stmt = $pdo->prepare("
        INSERT INTO glucose_readings (user_id, reading_value, meal_type, unit, measured_at, notes)
        VALUES (:uid, :val, :meal, 'mg/dL', :measured_at, :notes)
    ");
    $stmt->execute([
        ':uid' => $userId,
        ':val' => $mgDlValue,
        ':meal' => $mealType,
        ':measured_at' => $measuredAt,
        ':notes' => $notes
    ]);

    $readingId = $pdo->lastInsertId();

    sendResponse(true, 'Glucose reading logged successfully', [
        'id' => (int)$readingId,
        'reading_value' => $mgDlValue,
        'meal_type' => $mealType,
        'unit' => 'mg/dL',
        'measured_at' => $measuredAt,
        'notes' => $notes
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to add glucose reading: ' . $e->getMessage(), null, 500);
}
