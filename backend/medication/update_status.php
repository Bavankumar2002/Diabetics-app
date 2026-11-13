<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$input = getJsonInput();

$medId = intval($input['medication_id'] ?? 0);
$status = trim($input['status'] ?? 'taken'); // 'taken' or 'skipped'
$date = !empty($input['date']) ? $input['date'] : date('Y-m-d');
$time = !empty($input['time']) ? $input['time'] : date('h:i A');

if ($medId <= 0) {
    sendResponse(false, 'Medication ID is required', null, 400);
}

try {
    $pdo = getDBConnection();

    // Verify medication belongs to user
    $chk = $pdo->prepare("SELECT id FROM medication WHERE id = :id AND user_id = :uid LIMIT 1");
    $chk->execute([':id' => $medId, ':uid' => $userId]);
    if (!$chk->fetch()) {
        sendResponse(false, 'Medication not found or unauthorized', null, 404);
    }

    // Upsert status for today
    $upsert = $pdo->prepare("
        INSERT INTO medication_logs (medication_id, user_id, scheduled_time, status, logged_date)
        VALUES (:mid, :uid, :time, :status, :date)
        ON DUPLICATE KEY UPDATE status = :status_update, scheduled_time = :time_update
    ");
    // Or check if exists first
    $checkLog = $pdo->prepare("SELECT id FROM medication_logs WHERE medication_id = :mid AND logged_date = :date LIMIT 1");
    $checkLog->execute([':mid' => $medId, ':date' => $date]);
    $existing = $checkLog->fetch();

    if ($existing) {
        $update = $pdo->prepare("UPDATE medication_logs SET status = :status, scheduled_time = :time WHERE id = :id");
        $update->execute([':status' => $status, ':time' => $time, ':id' => $existing['id']]);
    } else {
        $insert = $pdo->prepare("INSERT INTO medication_logs (medication_id, user_id, scheduled_time, status, logged_date) VALUES (:mid, :uid, :time, :status, :date)");
        $insert->execute([':mid' => $medId, ':uid' => $userId, ':time' => $time, ':status' => $status, ':date' => $date]);
    }

    sendResponse(true, "Medication marked as $status", [
        'medication_id' => $medId,
        'status' => $status,
        'date' => $date
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to update medication status: ' . $e->getMessage(), null, 500);
}
