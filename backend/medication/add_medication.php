<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

$name = trim($input['name'] ?? '');
$dosage = trim($input['dosage'] ?? '');
$frequency = trim($input['frequency'] ?? 'Once daily');
$isInsulin = !empty($input['is_insulin']) ? 1 : 0;
$startDate = !empty($input['start_date']) ? $input['start_date'] : date('Y-m-d');
$endDate = !empty($input['end_date']) ? $input['end_date'] : null;
$reminderTime = trim($input['reminder_time'] ?? '08:00 AM');
$instructions = trim($input['instructions'] ?? '');

if (empty($name)) {
    sendResponse(false, 'Medication name is required', null, 400);
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("
        INSERT INTO medication 
        (user_id, name, dosage, frequency, is_insulin, start_date, end_date, reminder_time, instructions, is_active)
        VALUES 
        (:uid, :name, :dosage, :frequency, :is_insulin, :start_date, :end_date, :reminder_time, :instructions, 1)
    ");
    $stmt->execute([
        ':uid' => $userId,
        ':name' => $name,
        ':dosage' => $dosage ?: '1 Dose',
        ':frequency' => $frequency,
        ':is_insulin' => $isInsulin,
        ':start_date' => $startDate,
        ':end_date' => $endDate,
        ':reminder_time' => $reminderTime,
        ':instructions' => $instructions
    ]);

    $medId = $pdo->lastInsertId();

    sendResponse(true, 'Medication added successfully', [
        'id' => (int)$medId,
        'name' => $name,
        'dosage' => $dosage,
        'reminder_time' => $reminderTime
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to add medication: ' . $e->getMessage(), null, 500);
}
