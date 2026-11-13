<?php
require_once __DIR__ . '/../config.php';

$user = authenticateUser();
$userId = $user['id'];
$today = date('Y-m-d');

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("
        SELECT m.*, 
               COALESCE(ml.status, 'pending') as today_status,
               ml.id as log_id
        FROM medication m
        LEFT JOIN medication_logs ml ON ml.medication_id = m.id AND ml.logged_date = :today
        WHERE m.user_id = :uid AND m.is_active = 1
        ORDER BY m.reminder_time ASC
    ");
    $stmt->execute([':uid' => $userId, ':today' => $today]);
    $meds = $stmt->fetchAll();

    sendResponse(true, 'Medications retrieved', [
        'count' => count($meds),
        'medications' => $meds
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to retrieve medications: ' . $e->getMessage(), null, 500);
}
